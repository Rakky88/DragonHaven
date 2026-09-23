import { InfrastructureFailure } from "./core.ts";
import { CachedVerifierKeys } from "./verifier_keys.ts";

function assert(value: unknown, message = "assertion failed"): asserts value {
  if (!value) throw new Error(message);
}

const fakeKey = (name: string) => ({ name }) as unknown as CryptoKey;

Deno.test("unknown verifier key IDs share a bounded refresh cooldown", async () => {
  let now = 1_000_000;
  let loads = 0;
  const known = fakeKey("known");
  const cache = new CachedVerifierKeys(async () => {
    loads++;
    return new Map([[7, known]]);
  }, {
    now: () => now,
    missCooldownMs: 1000,
    cacheDurationMs: 10_000,
    maximumNegativeEntries: 2,
  });

  assert(await cache.get(7) === known);
  assert(loads === 1);
  assert(await cache.get(100) === null);
  assert(await cache.get(101) === null);
  assert(await cache.get(102) === null);
  assert(await cache.get(100) === null);
  assert(loads === 1, "misses during cooldown must not refetch");

  now += 1001;
  assert(await cache.get(100) === null);
  assert(Number(loads) === 2, "one miss may refresh after the cooldown");
  assert(await cache.get(101) === null);
  assert(Number(loads) === 2, "the new cooldown also applies globally");
});

Deno.test("a rotated verifier key becomes available after one miss refresh", async () => {
  let now = 2_000_000;
  let loads = 0;
  const first = fakeKey("first");
  const rotated = fakeKey("rotated");
  const cache = new CachedVerifierKeys(async () => {
    loads++;
    return loads === 1
      ? new Map([[1, first]])
      : new Map([[1, first], [2, rotated]]);
  }, { now: () => now, missCooldownMs: 1000, cacheDurationMs: 10_000 });

  assert(await cache.get(1) === first);
  assert(await cache.get(2) === null);
  now += 1001;
  assert(await cache.get(2) === rotated);
  assert(Number(loads) === 2);
});

Deno.test("key endpoint failures are briefly negatively cached", async () => {
  let now = 3_000_000;
  let loads = 0;
  const cache = new CachedVerifierKeys(async () => {
    loads++;
    throw new InfrastructureFailure();
  }, { now: () => now, failureCooldownMs: 1000 });

  for (var attempt = 0; attempt < 2; attempt++) {
    let failed = false;
    try {
      await cache.get(9);
    } catch (error) {
      failed = error instanceof InfrastructureFailure;
    }
    assert(failed);
  }
  assert(loads === 1, "failure cooldown must prevent repeated egress");

  now += 1001;
  try {
    await cache.get(9);
  } catch {
    // Expected: the loader still fails after the cooldown.
  }
  assert(Number(loads) === 2);
});
