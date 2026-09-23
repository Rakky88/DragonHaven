import {
  configuredRewardProducts,
  handleSsv,
  InfrastructureFailure,
  rewardedAdHealth,
  VerificationRecord,
} from "./core.ts";
import { CachedVerifierKeys } from "./verifier_keys.ts";

const base = Deno.env.get("SUPABASE_URL") ?? "";
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const gemsUnit = Deno.env.get("ADMOB_REWARDED_GEMS_AD_UNIT_ID") ?? "";
const coinsUnit = Deno.env.get("ADMOB_REWARDED_COINS_AD_UNIT_ID") ?? "";
const setupProbeCustomData =
  Deno.env.get("REWARDED_AD_SSV_SETUP_CUSTOM_DATA") ?? "";
const sourceRevision = Deno.env.get("REWARDED_AD_SSV_SOURCE_REVISION") ?? "";
const unitPattern = /^ca-app-pub-[0-9]{16}\/[0-9]{10}$/;
if (
  !/^https:\/\/[a-z0-9]{20}\.supabase\.co$/.test(base) ||
  serviceKey.length < 32 ||
  !unitPattern.test(gemsUnit) || !unitPattern.test(coinsUnit) ||
  gemsUnit === coinsUnit ||
  !/^[0-9a-f]{64}$/.test(setupProbeCustomData) ||
  !/^[0-9a-f]{40}$/.test(sourceRevision)
) {
  throw new Error("rewarded_ad_configuration_missing");
}

const products = configuredRewardProducts(gemsUnit, coinsUnit);

function bytesFromBase64(value: string): Uint8Array {
  const raw = atob(value);
  return Uint8Array.from(raw, (character) => character.charCodeAt(0));
}

async function loadGoogleVerifierKeys(): Promise<Map<number, CryptoKey>> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 8000);
  try {
    const response = await fetch(
      "https://www.gstatic.com/admob/reward/verifier-keys.json",
      { signal: controller.signal, headers: { accept: "application/json" } },
    );
    const body = await response.text();
    if (!response.ok || body.length > 65536) {
      throw new InfrastructureFailure();
    }
    const decoded = JSON.parse(body);
    if (!decoded || !Array.isArray(decoded.keys)) {
      throw new InfrastructureFailure();
    }
    const next = new Map<number, CryptoKey>();
    for (const entry of decoded.keys) {
      if (
        !entry || !Number.isSafeInteger(entry.keyId) ||
        typeof entry.pem !== "string"
      ) continue;
      const match = entry.pem.match(
        /^-----BEGIN PUBLIC KEY-----\s*([A-Za-z0-9+/=\s]+)\s*-----END PUBLIC KEY-----$/,
      );
      if (!match) continue;
      const spki = bytesFromBase64(match[1].replaceAll(/\s/g, ""));
      const key = await crypto.subtle.importKey(
        "spki",
        spki.slice().buffer,
        { name: "ECDSA", namedCurve: "P-256" },
        false,
        ["verify"],
      );
      next.set(entry.keyId, key);
    }
    if (next.size === 0) throw new InfrastructureFailure();
    return next;
  } catch (error) {
    if (error instanceof InfrastructureFailure) throw error;
    throw new InfrastructureFailure();
  } finally {
    clearTimeout(timeout);
  }
}

const verifierKeys = new CachedVerifierKeys(loadGoogleVerifierKeys);

async function record(
  value: VerificationRecord,
): Promise<"verified" | "replayed"> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 8000);
  try {
    const response = await fetch(
      `${base}/rest/v1/rpc/record_rewarded_ad_verification`,
      {
        method: "POST",
        signal: controller.signal,
        headers: {
          "content-type": "application/json",
          apikey: serviceKey,
          authorization: `Bearer ${serviceKey}`,
        },
        body: JSON.stringify({
          p_custom_data: value.customData,
          p_currency: value.currency,
          p_ad_unit_id: value.adUnitId,
          p_reward_item: value.rewardItem,
          p_reward_amount: value.rewardAmount,
          p_transaction_id: value.transactionId,
          p_ad_network: value.adNetwork,
          p_timestamp_ms: value.timestampMs,
          p_key_id: value.keyId,
          p_callback_sha256: value.callbackSha256,
        }),
      },
    );
    const body = await response.text();
    if (!response.ok || body.length > 4096) throw new InfrastructureFailure();
    const result = JSON.parse(body);
    if (result !== "verified" && result !== "replayed") {
      throw new InfrastructureFailure();
    }
    return result;
  } catch (error) {
    if (error instanceof InfrastructureFailure) throw error;
    throw new InfrastructureFailure();
  } finally {
    clearTimeout(timeout);
  }
}

Deno.serve((request) => {
  const url = new URL(request.url);
  if (request.method === "GET" && url.search === "?health=1") {
    return rewardedAdHealth(
      sourceRevision,
      gemsUnit,
      coinsUnit,
    );
  }
  return handleSsv(request, {
    products,
    setupProbeCustomData,
    publicKey: (keyId) => verifierKeys.get(keyId),
    record,
  });
});
