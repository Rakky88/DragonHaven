import {
  configuredRewardProducts,
  derEcdsaToP1363,
  handleSsv,
  InfrastructureFailure,
  rewardedAdHealth,
  SsvDependencies,
  VerificationRecord,
} from "./core.ts";

const keyId = 1234567;
const gemsUnit = "ca-app-pub-1234567890123456/1234567890";
const coinsUnit = "ca-app-pub-1234567890123456/0987654321";
const gemsUnitSuffix = "1234567890";
const coinsUnitSuffix = "0987654321";
const customData = "a5".repeat(32);
const products = configuredRewardProducts(gemsUnit, coinsUnit);

function assert(value: unknown, message = "assertion failed"): asserts value {
  if (!value) throw new Error(message);
}

function equal(actual: unknown, expected: unknown, message = "values differ") {
  const left = JSON.stringify(actual);
  const right = JSON.stringify(expected);
  assert(left === right, `${message}: ${left} !== ${right}`);
}

function expectThrow(action: () => unknown) {
  let threw = false;
  try {
    action();
  } catch {
    threw = true;
  }
  assert(threw, "expected action to throw");
}

function concat(...parts: Uint8Array[]) {
  const result = new Uint8Array(
    parts.reduce((sum, part) => sum + part.length, 0),
  );
  let offset = 0;
  for (const part of parts) {
    result.set(part, offset);
    offset += part.length;
  }
  return result;
}

function derInteger(raw: Uint8Array): Uint8Array {
  let first = 0;
  while (first < raw.length - 1 && raw[first] === 0) first++;
  const unsigned = new Uint8Array(raw.slice(first));
  const value = (unsigned[0] & 0x80) !== 0
    ? concat(new Uint8Array([0]), unsigned)
    : unsigned;
  return concat(new Uint8Array([0x02, value.length]), value);
}

function p1363ToDer(raw: Uint8Array): Uint8Array {
  assert(raw.length === 64, "P-256 signature must contain r and s");
  const body = concat(derInteger(raw.slice(0, 32)), derInteger(raw.slice(32)));
  assert(body.length < 128, "P-256 DER signature unexpectedly large");
  return concat(new Uint8Array([0x30, body.length]), body);
}

function base64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replace(
    /=+$/,
    "",
  );
}

type Pair = readonly [name: string, value: string];

const standardPairs = (): Pair[] => [
  ["ad_network", "5450213213286189855"],
  ["ad_unit", gemsUnitSuffix],
  ["custom_data", customData],
  ["reward_amount", "15"],
  ["reward_item", "gems"],
  ["timestamp", "1790157600000"],
  ["transaction_id", "synthetic-transaction_1"],
  ["user_id", "opaque-user-value"],
];

function encodePairs(pairs: readonly Pair[]): string {
  return pairs.map(([name, value]) => `${name}=${encodeURIComponent(value)}`)
    .join("&");
}

interface SigningFixture {
  privateKey: CryptoKey;
  publicKey: CryptoKey;
}

async function signingFixture(): Promise<SigningFixture> {
  const keys = await crypto.subtle.generateKey(
    { name: "ECDSA", namedCurve: "P-256" },
    true,
    ["sign", "verify"],
  );
  return { privateKey: keys.privateKey, publicKey: keys.publicKey };
}

async function signedRequest(
  fixture: SigningFixture,
  pairs = standardPairs(),
  tail: "normal" | "reversed" = "normal",
): Promise<Request> {
  const signed = encodePairs(pairs);
  const p1363 = new Uint8Array(
    await crypto.subtle.sign(
      { name: "ECDSA", hash: "SHA-256" },
      fixture.privateKey,
      new TextEncoder().encode(signed),
    ),
  );
  const signature = encodeURIComponent(base64Url(p1363ToDer(p1363)));
  const suffix = tail === "normal"
    ? `signature=${signature}&key_id=${keyId}`
    : `key_id=${keyId}&signature=${signature}`;
  return new Request(
    `https://example.invalid/rewarded-ad-ssv?${signed}&${suffix}`,
  );
}

function setup(
  publicKey: CryptoKey,
  overrides: Partial<SsvDependencies> = {},
) {
  const records: VerificationRecord[] = [];
  const deps: SsvDependencies = {
    products,
    publicKey: async (value) => value === keyId ? publicKey : null,
    record: async (value) => {
      records.push(value);
      return "verified";
    },
    ...overrides,
  };
  return { deps, records };
}

Deno.test("strict DER conversion round-trips P-256 IEEE-P1363 signatures", () => {
  const raw = new Uint8Array(64);
  raw[0] = 0x80;
  raw[31] = 0x12;
  raw[32] = 0x00;
  raw[62] = 0x80;
  raw[63] = 0x34;
  equal([...derEcdsaToP1363(p1363ToDer(raw))], [...raw]);

  for (
    const malformed of [
      new Uint8Array([]),
      new Uint8Array([0x30, 0x00]),
      new Uint8Array([0x30, 0x81, 0x06, 0x02, 0x01, 1, 0x02, 0x01, 1]),
      new Uint8Array([0x30, 0x82, 0x00, 0x80]),
      new Uint8Array([0x30, 0x06, 0x02, 0x01, 0x80, 0x02, 0x01, 1]),
      new Uint8Array([0x30, 0x07, 0x02, 0x02, 0, 1, 0x02, 0x01, 1]),
      new Uint8Array([0x30, 0x06, 0x02, 0x01, 1, 0x02, 0x01, 1, 0]),
    ]
  ) expectThrow(() => derEcdsaToP1363(malformed));
});

Deno.test("configured products key signed numeric units to canonical IDs", () => {
  assert(products.get(gemsUnitSuffix)?.canonicalAdUnitId === gemsUnit);
  assert(products.get(coinsUnitSuffix)?.canonicalAdUnitId === coinsUnit);
  for (
    const invalid of [
      [gemsUnit, gemsUnit],
      [gemsUnit, "ca-app-pub-0000000000000000/1234567890"],
      ["1234567890", coinsUnit],
    ]
  ) {
    expectThrow(() => configuredRewardProducts(invalid[0], invalid[1]));
  }
});

Deno.test("health exposes only the public deployment contract", async () => {
  const response = rewardedAdHealth("a".repeat(40), gemsUnit, coinsUnit);
  assert(response.status === 200);
  assert(response.headers.get("cache-control") === "no-store");
  equal(await response.json(), {
    service: "rewarded-ad-ssv",
    contractVersion: 1,
    sourceRevision: "a".repeat(40),
    gemsAdUnitId: gemsUnit,
    coinsAdUnitId: coinsUnit,
  });
});

Deno.test("a real P-256 signed callback records only the allowlisted reward", async () => {
  const fixture = await signingFixture();
  const { deps, records } = setup(fixture.publicKey);
  const request = await signedRequest(fixture);
  const rawQuery = request.url.slice(request.url.indexOf("?") + 1);
  const reply = await handleSsv(request, deps);

  assert(reply.status === 200);
  assert(await reply.text() === "ok");
  assert(reply.headers.get("cache-control") === "no-store");
  assert(records.length === 1);
  const record = records[0];
  equal({
    customData: record.customData,
    currency: record.currency,
    adUnitId: record.adUnitId,
    rewardItem: record.rewardItem,
    rewardAmount: record.rewardAmount,
    transactionId: record.transactionId,
    adNetwork: record.adNetwork,
    timestampMs: record.timestampMs,
    keyId: record.keyId,
  }, {
    customData,
    currency: "gems",
    adUnitId: gemsUnit,
    rewardItem: "gems",
    rewardAmount: 15,
    transactionId: "synthetic-transaction_1",
    adNetwork: "5450213213286189855",
    timestampMs: 1790157600000,
    keyId,
  });
  assert(/^[0-9a-f]{64}$/.test(record.callbackSha256));
  const expectedHash = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(rawQuery),
  );
  const expectedHex = [...new Uint8Array(expectedHash)]
    .map((byte) => byte.toString(16).padStart(2, "0")).join("");
  assert(record.callbackSha256 === expectedHex);
});

Deno.test("the numeric coins unit maps to its canonical full identifier", async () => {
  const fixture = await signingFixture();
  const { deps, records } = setup(fixture.publicKey);
  const pairs: Pair[] = standardPairs().map(([name, value]): Pair => [
    name,
    name === "ad_unit"
      ? coinsUnitSuffix
      : name === "reward_amount"
      ? "150"
      : name === "reward_item"
      ? "coins"
      : value,
  ]);
  const reply = await handleSsv(await signedRequest(fixture, pairs), deps);
  assert(reply.status === 200);
  assert(records.length === 1);
  assert(records[0].currency === "coins");
  assert(records[0].adUnitId === coinsUnit);
});

Deno.test("tampering with any signed reward field invalidates the callback", async () => {
  const fixture = await signingFixture();
  const { deps, records } = setup(fixture.publicKey);
  const request = await signedRequest(fixture);
  const tampered = new Request(
    request.url.replace("reward_amount=15", "reward_amount=150"),
  );
  const reply = await handleSsv(tampered, deps);
  assert(reply.status === 403);
  assert(await reply.text() === "invalid signature");
  assert(records.length === 0);
});

Deno.test("duplicates, unknown fields and a reordered or extended unsigned tail are rejected", async () => {
  const fixture = await signingFixture();
  const { deps, records } = setup(fixture.publicKey);
  const valid = await signedRequest(fixture);
  const query = valid.url.slice(valid.url.indexOf("?") + 1);
  const invalid = [
    query.replace(
      "ad_unit=",
      `ad_unit=${gemsUnitSuffix}&ad_unit=`,
    ),
    query.replace("ad_unit=", "unexpected=value&ad_unit="),
    (await signedRequest(fixture, standardPairs(), "reversed")).url.split(
      "?",
    )[1],
    `${query}&unsigned=value`,
  ];
  for (const candidate of invalid) {
    const reply = await handleSsv(
      new Request(`https://example.invalid/rewarded-ad-ssv?${candidate}`),
      deps,
    );
    assert(reply.status === 400);
  }
  assert(records.length === 0);
});

Deno.test("valid signatures cannot claim an unknown unit or altered configured reward", async () => {
  const fixture = await signingFixture();
  const { deps, records } = setup(fixture.publicKey);
  const variants: Pair[][] = [
    standardPairs().map((
      [name, value],
    ) => [
      name,
      name === "ad_unit" ? "1111111111" : value,
    ]),
    standardPairs().map((
      [name, value],
    ) => [name, name === "ad_unit" ? gemsUnit : value]),
    standardPairs().map((
      [name, value],
    ) => [name, name === "reward_amount" ? "150" : value]),
    standardPairs().map((
      [name, value],
    ) => [name, name === "reward_item" ? "coins" : value]),
  ];
  for (const pairs of variants) {
    const reply = await handleSsv(await signedRequest(fixture, pairs), deps);
    assert(reply.status === 403);
  }
  assert(records.length === 0);
});

Deno.test("replays are acknowledged without issuing a different response class", async () => {
  const fixture = await signingFixture();
  let calls = 0;
  const { deps } = setup(fixture.publicKey, {
    record: async () => {
      calls++;
      return calls === 1 ? "verified" : "replayed";
    },
  });
  const first = await handleSsv(await signedRequest(fixture), deps);
  const second = await handleSsv(await signedRequest(fixture), deps);
  assert(first.status === 200 && await first.text() === "ok");
  assert(second.status === 200 && await second.text() === "replayed");
  assert(calls === 2);
});

Deno.test("key and persistence infrastructure failures remain retryable", async () => {
  const fixture = await signingFixture();
  const unavailable = setup(fixture.publicKey, { publicKey: async () => null });
  let reply = await handleSsv(await signedRequest(fixture), unavailable.deps);
  assert(reply.status === 503 && await reply.text() === "key unavailable");
  assert(unavailable.records.length === 0);

  const keyFailure = setup(fixture.publicKey, {
    publicKey: async () => {
      throw new InfrastructureFailure();
    },
  });
  reply = await handleSsv(await signedRequest(fixture), keyFailure.deps);
  assert(
    reply.status === 503 && await reply.text() === "temporarily unavailable",
  );

  const recordFailure = setup(fixture.publicKey, {
    record: async () => {
      throw new InfrastructureFailure();
    },
  });
  reply = await handleSsv(await signedRequest(fixture), recordFailure.deps);
  assert(
    reply.status === 503 && await reply.text() === "temporarily unavailable",
  );
});
