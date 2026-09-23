export type RewardCurrency = "gems" | "coins";

export interface RewardProduct {
  currency: RewardCurrency;
  amount: number;
  item: RewardCurrency;
  /// Full public SDK identifier. Google's signed `ad_unit` callback field
  /// contains only the ten-digit unit suffix, so the allowlist maps that
  /// signed suffix back to this canonical identifier before persistence.
  canonicalAdUnitId: string;
}

export function configuredRewardProducts(
  gemsAdUnitId: string,
  coinsAdUnitId: string,
): ReadonlyMap<string, RewardProduct> {
  const pattern = /^ca-app-pub-[0-9]{16}\/([0-9]{10})$/;
  const gems = gemsAdUnitId.match(pattern);
  const coins = coinsAdUnitId.match(pattern);
  if (
    !gems || !coins || gemsAdUnitId === coinsAdUnitId || gems[1] === coins[1]
  ) {
    throw new Error("rewarded_ad_configuration_missing");
  }
  return new Map([
    [gems[1], {
      currency: "gems",
      amount: 15,
      item: "gems",
      canonicalAdUnitId: gemsAdUnitId,
    }],
    [coins[1], {
      currency: "coins",
      amount: 150,
      item: "coins",
      canonicalAdUnitId: coinsAdUnitId,
    }],
  ]);
}

export interface VerificationRecord {
  customData: string;
  currency: RewardCurrency;
  adUnitId: string;
  rewardItem: string;
  rewardAmount: number;
  transactionId: string;
  adNetwork: string;
  timestampMs: number;
  keyId: number;
  callbackSha256: string;
}

export interface SsvDependencies {
  products: ReadonlyMap<string, RewardProduct>;
  setupProbeCustomData: string;
  publicKey: (keyId: number) => Promise<CryptoKey | null>;
  record: (value: VerificationRecord) => Promise<"verified" | "replayed">;
}

export const setupProbeUserId = "dragonhaven-ssv-setup";

const responseHeaders = {
  "cache-control": "no-store",
  "content-type": "text/plain; charset=utf-8",
  "x-content-type-options": "nosniff",
};

function response(status: number, body: string) {
  return new Response(body, { status, headers: responseHeaders });
}

export function rewardedAdHealth(
  sourceRevision: string,
  gemsAdUnitId: string,
  coinsAdUnitId: string,
): Response {
  return new Response(
    JSON.stringify({
      service: "rewarded-ad-ssv",
      contractVersion: 1,
      sourceRevision,
      gemsAdUnitId,
      coinsAdUnitId,
    }),
    {
      status: 200,
      headers: {
        ...responseHeaders,
        "content-type": "application/json; charset=utf-8",
      },
    },
  );
}

function decode(value: string): string {
  if (/%(?![0-9a-fA-F]{2})/.test(value)) throw new Error("bad_encoding");
  return decodeURIComponent(value.replaceAll("+", " "));
}

function base64Url(value: string): Uint8Array {
  if (!/^[A-Za-z0-9_-]+={0,2}$/.test(value)) throw new Error("bad_base64");
  const unpadded = value.replace(/=+$/, "");
  const padded = unpadded.replaceAll("-", "+").replaceAll("_", "/") +
    "=".repeat((4 - unpadded.length % 4) % 4);
  const decoded = atob(padded);
  return Uint8Array.from(decoded, (character) => character.charCodeAt(0));
}

function derLength(bytes: Uint8Array, offset: number): [number, number] {
  if (offset >= bytes.length) throw new Error("bad_der");
  const first = bytes[offset];
  if (first < 0x80) return [first, offset + 1];
  const count = first & 0x7f;
  if (count < 1 || count > 2 || offset + count >= bytes.length) {
    throw new Error("bad_der");
  }
  if (count > 1 && bytes[offset + 1] === 0) throw new Error("bad_der");
  let value = 0;
  for (let index = 0; index < count; index++) {
    value = value * 256 + bytes[offset + 1 + index];
  }
  if (value < 0x80) throw new Error("bad_der");
  return [value, offset + 1 + count];
}

function derInteger(bytes: Uint8Array, offset: number): [Uint8Array, number] {
  if (bytes[offset] !== 0x02) throw new Error("bad_der");
  const [length, start] = derLength(bytes, offset + 1);
  const end = start + length;
  if (length < 1 || length > 33 || end > bytes.length) {
    throw new Error("bad_der");
  }
  let value = bytes.slice(start, end);
  if (value[0] === 0) {
    if (value.length === 1 || (value[1] & 0x80) === 0) {
      throw new Error("bad_der");
    }
    value = value.slice(1);
  } else if ((value[0] & 0x80) !== 0) {
    throw new Error("bad_der");
  }
  if (value.length > 32) throw new Error("bad_der");
  const normalized = new Uint8Array(32);
  normalized.set(value, 32 - value.length);
  return [normalized, end];
}

/// Google sends ASN.1 DER ECDSA signatures. WebCrypto verifies IEEE-P1363.
export function derEcdsaToP1363(bytes: Uint8Array): Uint8Array {
  if (bytes[0] !== 0x30) throw new Error("bad_der");
  const [length, content] = derLength(bytes, 1);
  if (content + length !== bytes.length) throw new Error("bad_der");
  const [r, afterR] = derInteger(bytes, content);
  const [s, afterS] = derInteger(bytes, afterR);
  if (afterS !== bytes.length) throw new Error("bad_der");
  const raw = new Uint8Array(64);
  raw.set(r, 0);
  raw.set(s, 32);
  return raw;
}

async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return [...new Uint8Array(digest)].map((byte) =>
    byte.toString(16).padStart(2, "0")
  ).join("");
}

function safeInteger(value: string): number {
  if (!/^[0-9]{1,16}$/.test(value)) throw new Error("bad_integer");
  const result = Number(value);
  if (!Number.isSafeInteger(result) || result < 1) {
    throw new Error("bad_integer");
  }
  return result;
}

export async function handleSsv(
  request: Request,
  deps: SsvDependencies,
): Promise<Response> {
  if (request.method !== "GET") return response(405, "method not allowed");
  const question = request.url.indexOf("?");
  if (question < 0) return response(400, "invalid callback");
  const raw = request.url.slice(question + 1);
  if (raw.length < 1 || raw.length > 8192 || raw.includes("#")) {
    return response(400, "invalid callback");
  }
  try {
    const pairs = raw.split("&");
    if (pairs.length < 9) throw new Error("missing_fields");
    const parsed = new Map<string, string>();
    const rawNames: string[] = [];
    for (const pair of pairs) {
      const equals = pair.indexOf("=");
      if (equals < 1) throw new Error("bad_pair");
      const rawName = pair.slice(0, equals);
      if (!/^[a-z_]+$/.test(rawName) || parsed.has(rawName)) {
        throw new Error("bad_name");
      }
      rawNames.push(rawName);
      parsed.set(rawName, decode(pair.slice(equals + 1)));
    }
    if (rawNames.at(-2) !== "signature" || rawNames.at(-1) !== "key_id") {
      throw new Error("unsigned_tail");
    }
    const allowed = new Set([
      "ad_network",
      "ad_unit",
      "custom_data",
      "reward_amount",
      "reward_item",
      "timestamp",
      "transaction_id",
      "user_id",
      "signature",
      "key_id",
    ]);
    if ([...parsed.keys()].some((name) => !allowed.has(name))) {
      throw new Error("unknown_field");
    }
    for (
      const required of [
        "ad_network",
        "ad_unit",
        "custom_data",
        "reward_amount",
        "reward_item",
        "timestamp",
        "transaction_id",
        "signature",
        "key_id",
      ]
    ) {
      if (!parsed.has(required) || parsed.get(required)!.length === 0) {
        throw new Error("missing_field");
      }
    }
    const signed = pairs.slice(0, -2).join("&");
    const keyId = safeInteger(parsed.get("key_id")!);
    const key = await deps.publicKey(keyId);
    if (key === null) return response(503, "key unavailable");
    const signature = derEcdsaToP1363(base64Url(parsed.get("signature")!));
    const valid = await crypto.subtle.verify(
      { name: "ECDSA", hash: "SHA-256" },
      key,
      signature.slice().buffer,
      new TextEncoder().encode(signed),
    );
    if (!valid) return response(403, "invalid signature");

    // AdMob signs only the numeric unit component here (for example,
    // `2747237135`), not the full ca-app-pub identifier used by the SDK.
    const signedAdUnit = parsed.get("ad_unit")!;
    if (!/^[0-9]{10}$/.test(signedAdUnit)) {
      return response(403, "unknown ad unit");
    }
    const product = deps.products.get(signedAdUnit);
    if (!product) return response(403, "unknown ad unit");
    const rewardAmount = safeInteger(parsed.get("reward_amount")!);
    const rewardItem = parsed.get("reward_item")!;
    if (rewardAmount !== product.amount || rewardItem !== product.item) {
      return response(403, "invalid reward");
    }
    const customData = parsed.get("custom_data")!;
    const transactionId = parsed.get("transaction_id")!;
    const adNetwork = parsed.get("ad_network")!;
    const timestampMs = safeInteger(parsed.get("timestamp")!);
    if (
      !/^[0-9a-f]{64}$/.test(customData) ||
      !/^[A-Za-z0-9._~-]{1,256}$/.test(transactionId) ||
      adNetwork.length < 1 ||
      adNetwork.length > 128 ||
      /[\u0000-\u001f\u007f-\u009f]/.test(adNetwork) ||
      timestampMs > 253402300799999
    ) return response(400, "invalid callback");
    const userId = parsed.get("user_id");
    const usesSetupCustomData = customData === deps.setupProbeCustomData;
    if (userId !== undefined || usesSetupCustomData) {
      if (userId !== setupProbeUserId || !usesSetupCustomData) {
        return response(403, "invalid setup probe");
      }
      // AdMob's Verify URL action has no player claim to settle. It reaches
      // this branch only after Google's signature, product and exact reward
      // have been verified, and must never call the persistence/reward RPC.
      return response(200, "setup ok");
    }
    const result = await deps.record({
      customData,
      currency: product.currency,
      adUnitId: product.canonicalAdUnitId,
      rewardItem,
      rewardAmount,
      transactionId,
      adNetwork,
      timestampMs,
      keyId,
      callbackSha256: await sha256Hex(raw),
    });
    return response(200, result === "replayed" ? "replayed" : "ok");
  } catch (error) {
    if (error instanceof InfrastructureFailure) {
      return response(503, "temporarily unavailable");
    }
    return response(400, "invalid callback");
  }
}

export class InfrastructureFailure extends Error {}
