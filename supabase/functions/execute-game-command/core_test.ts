import { boundedJson, Dependencies, handleCommand, JsonObject, RpcFailure } from "./core.ts";

const owner = "11111111-1111-4111-8111-111111111111";
const other = "22222222-2222-4222-8222-222222222222";
const requestId = "33333333-3333-4333-8333-333333333333";
const lease = "44444444-4444-4444-8444-444444444444";
const hash = "a5".repeat(32);
const token = "Bearer " + "synthetic-token-".repeat(4);
const body = { protocol: 2, requestId, clientBuild: 10068, action: "open_chests", payload: { tier: "wooden", count: 1 } };
const saved = { owner_id: owner, request_id: requestId, server_revision: 3,
  state_sha256: hash, authority_mode: "shadow", result: { coins: 5 } };
const leased = { status: "processing", owner_id: owner, request_id: requestId,
  base_revision: 2, lease_token: lease, secret_seed: hash, now: "2026-09-07T12:00:00Z",
  authority_mode: "shadow", state: { private: "hidden egg identity" } };
function assert(condition: unknown, message = "assertion failed"): asserts condition {
  if (!condition) throw new Error(message);
}
function equal(actual: unknown, expected: unknown) {
  assert(JSON.stringify(actual) === JSON.stringify(expected));
}
function request(value: unknown = body, authorization = token) {
  return new Request("https://staging.invalid/functions/v1/execute-game-command", {
    method: "POST", headers: { authorization, "content-type": "application/json" }, body: JSON.stringify(value),
  });
}
function setup(overrides: Partial<Dependencies> = {}) {
  const calls: { name: string; payload: JsonObject }[] = [];
  const inputs: JsonObject[] = [];
  const deps: Dependencies = {
    ruleset: hash,
    authenticate: async (value) => value === token ? owner : null,
    rpc: async (name, payload) => {
      calls.push({ name, payload });
      if (name === "begin_canonical_game_command") return leased;
      if (name === "commit_canonical_game_command") return saved;
      if (name === "fail_canonical_game_command") return true;
      throw new Error("unexpected RPC");
    },
    evaluate: async (input) => {
      inputs.push(input);
      return { protocol: 2, state: { private: "new hidden egg identity" }, result: { coins: 5 } };
    },
    ...overrides,
  };
  return { deps, calls, inputs };
}

const readBody = { protocol: 2, clientBuild: 10068, action: "read_state" };
const readSnapshot = { owner_id: owner, server_revision: 3, state_sha256: hash,
  authority_mode: "shadow", server_time: "2026-09-07T12:00:00Z", mutations_enabled: false,
  state: { private: "hidden egg identity", seed: "NEVER_RETURN" } };
const publicData = { projectionVersion: 1, activeDragonId: null, wallet: { coins: 25, gems: 3 },
  eggs: [], dragons: [], inventory: {}, collection: {}, house: {}, progress: {},
  adventures: {}, trials: {}, presentations: [], activities: [] };

Deno.test("read uses Auth owner and public projection while mutations are disabled", async () => {
  const calls: string[] = [];
  const { deps } = setup({
    rpc: async (name, payload) => {
      calls.push(name);
      equal(payload, { p_owner_id: owner, p_client_build: 10068, p_ruleset_sha256: hash });
      return readSnapshot;
    },
    project: (input) => {
      equal(input, { state: readSnapshot.state, ownerId: owner, now: readSnapshot.server_time });
      return publicData;
    },
    evaluate: () => { throw new Error("a read cannot evaluate commands"); },
  });
  const result = await handleCommand(request(readBody), deps);
  assert(result.status === 200 && result.headers.get("cache-control") === "no-store");
  const text = await result.text();
  assert(!text.includes("NEVER_RETURN") && !text.includes("hidden egg identity"));
  const value = JSON.parse(text);
  equal(value.data, publicData);
  assert(value.mutations_enabled === false && value.authority_mode === "shadow");
  equal(calls, ["read_canonical_game_state"]);
});

Deno.test("read rejects client state, owner, time, entropy and a cross-owner snapshot", async () => {
  for (const extra of [{ ownerId: other }, { state: {} }, { now: leased.now }, { secretSeed: hash }]) {
    const { deps, calls } = setup();
    assert((await handleCommand(request({ ...readBody, ...extra }), deps)).status === 400);
    equal(calls, []);
  }
  let projections = 0;
  const { deps } = setup({ rpc: async () => ({ ...readSnapshot, owner_id: other }),
    project: () => { projections++; return publicData; } });
  assert((await handleCommand(request(readBody), deps)).status === 503);
  assert(projections === 0);
});

Deno.test("read cannot pass through raw saves or unclassified projection failures", async () => {
  for (const projection of [{ ...publicData, private: "NEVER_RETURN" }, readSnapshot.state,
    { error: "NEVER_RETURN" }]) {
    const { deps } = setup({ rpc: async () => readSnapshot, project: () => projection });
    const result = await handleCommand(request(readBody), deps);
    assert(result.status === 503 && !(await result.text()).includes("NEVER_RETURN"));
  }
  const { deps } = setup({ rpc: async () => readSnapshot,
    project: () => ({ error: "game_state_reconciliation_required" }) });
  assert((await handleCommand(request(readBody), deps)).status === 409);
});

Deno.test("a command uses authenticated owner and private lease inputs, and returns only the receipt", async () => {
  const { deps, calls, inputs } = setup();
  const result = await handleCommand(request(), deps);
  assert(result.status === 200 && result.headers.get("cache-control") === "no-store");
  const text = await result.text();
  assert(!text.includes("private") && !text.includes("secret_seed") && !text.includes("lease_token"));
  equal(inputs, [{ state: leased.state, action: body.action, payload: body.payload,
    secretSeed: hash, now: leased.now, keeperId: owner }]);
  equal(calls.map((call) => call.name), ["begin_canonical_game_command", "commit_canonical_game_command"]);
  assert(calls.every((call) => call.payload.p_owner_id === owner));
  assert(calls[1].payload.p_lease_token === lease);
  assert(JSON.parse(text).authority_mode === "shadow");
});

Deno.test("missing, forged and unavailable authentication never reaches a game RPC", async () => {
  for (const mode of ["missing", "forged", "unavailable"]) {
    const { deps, calls } = setup({ authenticate: async () => {
      if (mode === "unavailable") throw new Error("private provider details");
      return null;
    } });
    const result = await handleCommand(request(body, mode === "missing" ? "" : token), deps);
    assert(result.status === (mode === "unavailable" ? 503 : 401));
    equal(calls, []);
    assert(!(await result.text()).includes("private provider details"));
  }
});

Deno.test("caller-supplied owner, state, clock, entropy, grants and nested arguments are rejected before reserving", async () => {
  for (const candidate of [
    { ...body, ownerId: other }, { ...body, state: { coins: 999999 } },
    { ...body, secretSeed: hash }, { ...body, now: "2099-01-01" },
    { ...body, action: "complete_trial", payload: { score: 999999 } },
    { ...body, action: "__proto__", payload: {} },
    { ...body, payload: { tier: "wooden", count: { amount: 1 } } },
    { ...body, payload: { tier: "wooden", count: 1, coins: 999999 } },
    { ...body, payload: { tier: "x".repeat(5000), count: 1 } },
    { ...body, clientBuild: 2 ** 53 },
  ]) {
    const { deps, calls } = setup();
    assert((await handleCommand(request(candidate), deps)).status === 400);
    equal(calls, []);
  }
});

Deno.test("replay returns the stored receipt without a second evaluation or commit", async () => {
  const { deps, inputs } = setup({ rpc: async (name) => {
    assert(name === "begin_canonical_game_command");
    return { status: "succeeded", response: { ...saved, state: leased.state, secret_seed: hash } };
  } });
  const result = await handleCommand(request(), deps);
  assert(result.status === 200);
  equal(inputs, []);
  const value = await result.json();
  assert(value.replayed && !Object.hasOwn(value, "state") && !Object.hasOwn(value, "secret_seed"));
});

Deno.test("cross-owner lease and receipt, live authority and wrong revision are refused", async () => {
  for (const [begin, end] of [
    [{ ...leased, owner_id: other }, saved],
    [leased, { ...saved, owner_id: other }],
    [{ ...leased, authority_mode: "server" }, saved],
    [leased, { ...saved, server_revision: 2 }],
  ]) {
    const { deps } = setup({ rpc: async (name) => name === "begin_canonical_game_command" ? begin : end });
    const result = await handleCommand(request(), deps);
    assert(result.status === 503);
    assert(!(await result.text()).includes("hidden egg"));
  }
});

Deno.test("a lost commit response retains the original intent for receipt recovery", async () => {
  const calls: string[] = [];
  let committed = false;
  const { deps, inputs } = setup({ rpc: async (name) => {
    calls.push(name);
    if (name === "begin_canonical_game_command") return committed ? { status: "succeeded", response: saved } : leased;
    if (name === "commit_canonical_game_command") { committed = true; throw new Error("connection lost after commit"); }
    throw new Error("must not fail an ambiguously committed intent");
  } });
  assert((await handleCommand(request(), deps)).status === 503);
  const retried = await handleCommand(request(), deps);
  assert(retried.status === 200 && (await retried.json()).replayed);
  assert(inputs.length === 1);
  equal(calls, ["begin_canonical_game_command", "commit_canonical_game_command", "begin_canonical_game_command"]);
});

Deno.test("known domain refusal is durably fenced before it is reported", async () => {
  const { deps, calls } = setup({ evaluate: async () => ({ error: "egg_tagged" }) });
  const result = await handleCommand(request(), deps);
  assert(result.status === 422 && (await result.json()).error === "egg_tagged");
  equal(calls.map((call) => call.name), ["begin_canonical_game_command", "fail_canonical_game_command"]);
  assert(calls[1].payload.p_failure_code === "egg_tagged" && calls[1].payload.p_lease_token === lease);
  deps.rpc = async (name) => name === "begin_canonical_game_command" ? leased : false;
  assert((await handleCommand(request(), deps)).status === 409);
});

Deno.test("unknown errors remain private and transient without changing an intent", async () => {
  const { deps, calls } = setup({ evaluate: async () => { throw new Error("secret save and token"); } });
  const result = await handleCommand(request(), deps);
  assert(result.status === 503);
  equal(await result.json(), { error: "game_command_unavailable" });
  assert(calls.length === 1);
  for (const [code, expected] of [["game_command_busy", 409], ["economy_rate_limited", 429],
    ["game_client_upgrade_required", 426], ["private server details", 503]] as const) {
    deps.rpc = async () => { throw new RpcFailure(code); };
    assert((await handleCommand(request(), deps)).status === expected);
  }
});

Deno.test("body reading enforces bytes and elapsed time even on streamed requests", async () => {
  for (const body of [
    new Response("x".repeat(100)).body,
    new ReadableStream<Uint8Array>({ start(controller) { controller.enqueue(new Uint8Array([32])); } }),
  ]) {
    let rejected = false;
    try { await boundedJson(body, 64, 10); } catch { rejected = true; }
    assert(rejected);
  }
});
