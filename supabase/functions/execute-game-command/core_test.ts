import { boundedJson, Dependencies, handleCommand, JsonObject, RpcFailure } from "./core.ts";

const owner = "11111111-1111-4111-8111-111111111111";
const other = "22222222-2222-4222-8222-222222222222";
const requestId = "33333333-3333-4333-8333-333333333333";
const lease = "44444444-4444-4444-8444-444444444444";
const hash = "a5".repeat(32);
const token = "Bearer " + "synthetic-token-".repeat(4);
const body = { protocol: 2, requestId, clientBuild: 10068, expectedRevision: 2, action: "open_chests", payload: { tier: "wooden", count: 1 } };
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
      if (name === "begin_revisioned_game_command") return leased;
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

Deno.test("dragon preferences use the authenticated lease and reject extra grants", async () => {
  for (const [action, payload] of [
    ["set_dragon_highlight", { dragonId: "owned-dragon", focus: "might", highlighted: true }],
    ["set_favorite_dragon", { dragonId: "owned-dragon" }],
  ] as const) {
    const { deps, inputs, calls } = setup();
    assert((await handleCommand(request({ ...body, action, payload }), deps)).status === 200);
    assert(inputs.length === 1 && inputs[0].keeperId === owner);
    equal(inputs[0].payload, payload);
    assert(calls[0].payload.p_owner_id === owner);
    const denied = setup();
    assert((await handleCommand(request({ ...body, action, payload: { ...payload, xp: 100 } }), denied.deps)).status === 400);
    equal(denied.calls, []);
  }
});
const readSnapshot = { owner_id: owner, server_revision: 3, state_sha256: hash,
  ruleset_revision: 2,
  authority_mode: "shadow", server_time: "2026-09-07T12:00:00Z", mutations_enabled: false,
  state: { private: "hidden egg identity", seed: "NEVER_RETURN" } };
const publicData = { projectionVersion: 1, activeDragonId: null, wallet: { coins: 25, gems: 3 },
  eggs: [], dragons: [], inventory: {}, collection: {}, house: {}, progress: {},
  adventures: {}, trials: {}, presentations: [], activities: [], trades: {completedToday: 0, offers: []} };

Deno.test("read uses Auth owner and public projection while mutations are disabled", async () => {
  const calls: string[] = [];
  const { deps } = setup({
    rpc: async (name, payload) => {
      calls.push(name);
      equal(payload, { p_owner_id: owner, p_client_build: 10068, p_ruleset_sha256: hash });
      return readSnapshot;
    },
    project: (input) => {
      equal(input, { state: readSnapshot.state, ownerId: owner, now: readSnapshot.server_time, verifiedSocialClaims: [], verifiedTradeOffers: {completedToday: 0, offers: []}, verifiedSocialReservations: null, verifiedTradeReservations: null });
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
    secretSeed: hash, now: leased.now, keeperId: owner, verifiedSocialContext: null, verifiedSocialReservations: null, verifiedTradeReservations: null }]);
  equal(calls.map((call) => call.name), ["begin_revisioned_game_command", "commit_canonical_game_command"]);
  assert(calls.every((call) => call.payload.p_owner_id === owner));
  assert(calls[0].payload.p_expected_revision === 2);
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
    { ...body, expectedRevision: undefined }, { ...body, expectedRevision: 0 },
    { ...body, expectedRevision: 2 ** 53 },
  ]) {
    const { deps, calls } = setup();
    assert((await handleCommand(request(candidate), deps)).status === 400);
    equal(calls, []);
  }
});

Deno.test("recovery is owner-scoped, bounded and cannot run game rules or expose history", async () => {
  const recoveryBody = { protocol: 2, clientBuild: 10069, action: "recover_commands", requestId };
  const proof = { protocol: 2, owner_id: owner, request_id: requestId, authority_mode: "shadow",
    barrier_revision: 7, cancelled_commands: 1, replayed: false };
  const { deps, inputs } = setup({rpc: async (name, payload) => {
    assert(name === "recover_canonical_game_commands");
    equal(payload, {p_owner_id: owner, p_request_id: requestId, p_client_build: 10069, p_ruleset_sha256: hash});
    return proof;
  }});
  const response = await handleCommand(request(recoveryBody), deps);
  assert(response.status === 200 && response.headers.get("cache-control") === "no-store");
  equal(await response.json(), proof);
  equal(inputs, []);
  for (const extra of [{ownerId: other}, {state: {}}, {expectedRevision: 7}, {requestId: "bad"}]) {
    assert((await handleCommand(request({...recoveryBody, ...extra}), deps)).status === 400);
  }
  for (const bad of [{...proof, owner_id: other}, {...proof, request_id: other},
    {...proof, barrier_revision: 0}, {...proof, cancelled_commands: 2}, {...proof, secret_seed: hash}]) {
    deps.rpc = async () => bad;
    const rejected = await handleCommand(request(recoveryBody), deps);
    assert(rejected.status === 503 && !(await rejected.text()).includes(hash));
  }
});

Deno.test("stale commands and recovered leases produce durable refusals without evaluation", async () => {
  for (const failure of ["game_state_changed", "game_command_recovered"]) {
    const {deps, inputs} = setup({rpc: async () => ({status: "failed", failure_code: failure, replayed: false})});
    const response = await handleCommand(request(), deps);
    assert(response.status === 422);
    equal(await response.json(), {error: failure, request_id: requestId, replayed: false});
    equal(inputs, []);
  }
});

Deno.test("replay returns the stored receipt without a second evaluation or commit", async () => {
  const { deps, inputs } = setup({ rpc: async (name) => {
    assert(name === "begin_revisioned_game_command");
    return { status: "succeeded", response: { ...saved, state: leased.state, secret_seed: hash } };
  } });
  const result = await handleCommand(request(), deps);
  assert(result.status === 200);
  equal(inputs, []);
  const value = await result.json();
  assert(value.replayed && !Object.hasOwn(value, "state") && !Object.hasOwn(value, "secret_seed"));
});

Deno.test("cross-owner lease and receipt, authority mismatch and wrong revision are refused", async () => {
  for (const [begin, end] of [
    [{ ...leased, owner_id: other }, saved],
    [leased, { ...saved, owner_id: other }],
    [{ ...leased, authority_mode: "server" }, saved],
    [leased, { ...saved, server_revision: 2 }],
  ]) {
    const { deps } = setup({ rpc: async (name) => name === "begin_revisioned_game_command" ? begin : end });
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
    if (name === "begin_revisioned_game_command") return committed ? { status: "succeeded", response: saved } : leased;
    if (name === "commit_canonical_game_command") { committed = true; throw new Error("connection lost after commit"); }
    throw new Error("must not fail an ambiguously committed intent");
  } });
  assert((await handleCommand(request(), deps)).status === 503);
  const retried = await handleCommand(request(), deps);
  assert(retried.status === 200 && (await retried.json()).replayed);
  assert(inputs.length === 1);
  equal(calls, ["begin_revisioned_game_command", "commit_canonical_game_command", "begin_revisioned_game_command"]);
});

Deno.test("known domain refusal is durably fenced before it is reported", async () => {
  const { deps, calls } = setup({ evaluate: async () => ({ error: "egg_tagged" }) });
  const result = await handleCommand(request(), deps);
  assert(result.status === 422 && (await result.json()).error === "egg_tagged");
  equal(calls.map((call) => call.name), ["begin_revisioned_game_command", "fail_canonical_game_command"]);
  assert(calls[1].payload.p_failure_code === "egg_tagged" && calls[1].payload.p_lease_token === lease);
  deps.rpc = async (name) => name === "begin_revisioned_game_command" ? leased : false;
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

Deno.test("house commands bind to Auth and cannot attach inventory or wallet grants", async () => {
  for (const [action, payload] of [
    ["place_house_item", {itemId: "moss_cushion", roomId: "hearth", x: .2, y: .8}],
    ["move_house_item", {itemId: "moss_cushion", x: .6, y: .8}],
    ["remove_house_item", {itemId: "moss_cushion"}],
    ["reorder_tower_floor", {oldIndex: 1, newIndex: 0}],
    ["set_dragon_roaming", {dragonId: "owned-dragon", enabled: false}],
    ["clear_tower_floor", {index: 0}],
  ] as const) {
    const {deps, inputs} = setup();
    assert((await handleCommand(request({...body, action, payload}), deps)).status === 200);
    assert(inputs[0].keeperId === owner);
    equal(inputs[0].payload, payload);
    for (const extra of [{coins: 100}, {ownerId: other}, {inventory: []}]) {
      const denied = setup();
      assert((await handleCommand(request({...body, action, payload: {...payload, ...extra}}), denied.deps)).status === 400);
      equal(denied.calls, []);
    }
  }
});

Deno.test("Trial controls are owner-bound and cannot carry a score or private checkpoint", async () => {
  for (const [action, payload] of [
    ["start_trial", {offerId: "trial-offer", dragonId: "owned-dragon"}],
    ["checkpoint_trial", {attemptId: "attempt", inputs: "AQ==", elapsedMs: 1000, finish: false}],
    ["cancel_trial", {attemptId: "attempt"}],
  ] as const) {
    const {deps, inputs} = setup();
    assert((await handleCommand(request({...body, action, payload}), deps)).status === 200);
    assert(inputs[0].keeperId === owner);
    equal(inputs[0].payload, payload);
    for (const extra of [{score: 100000}, {seed: 1}, {checkpoint: {}}, {ownerId: other}]) {
      const denied = setup();
      assert((await handleCommand(request({...body, action, payload: {...payload, ...extra}}), denied.deps)).status === 400);
      equal(denied.calls, []);
    }
  }
  for (const code of ["game_attempt_incomplete", "game_attempt_input_limit"]) {
    const {deps, calls} = setup({evaluate: async () => ({error: code})});
    const reply = await handleCommand(request({...body, action: "checkpoint_trial",
      payload: {attemptId: "attempt", inputs: "AQ==", elapsedMs: 1000, finish: true}}), deps);
    assert(reply.status === 422 && (await reply.json()).error === code);
    assert(calls[1].name === "fail_canonical_game_command" && calls[1].payload.p_failure_code === code);
  }
});

Deno.test("cosmetic and milestone commands cannot import ownership, cooldowns or rewards", async () => {
  for (const [action, payload] of [
    ["select_portrait", {catalogId: "portrait_002"}],
    ["select_title", {catalogId: "owned-title"}],
    ["select_badge", {catalogId: null}],
    ["select_frame", {catalogId: null}],
    ["complete_presentation", {presentationId: "owned-milestone"}],
    ["call_dragon_to_floor", {roomId: "hearth", index: 0}],
    ["visit_tower_floor", {roomId: "hearth", index: 0}],
  ] as const) {
    const {deps, inputs} = setup();
    assert((await handleCommand(request({...body, action, payload}), deps)).status === 200);
    assert(inputs[0].keeperId === owner);
    equal(inputs[0].payload, payload);
    for (const extra of [{ownedPortraitIds: ["portrait_002"]}, {cooldown: 0},
      {interactionId: "book_surprise"}, {reward: 100}, {ownerId: other}]) {
      const denied = setup();
      assert((await handleCommand(request({...body, action, payload: {...payload, ...extra}}), denied.deps)).status === 400);
      equal(denied.calls, []);
    }
  }
});

Deno.test("social actions use only sealed database facts and reject client grants", async () => {
  for (const [action, payload] of [
    ["invite_pair_adventure", {keeperCode: "DH-1234ABCD", dragonId: "owned-dragon"}],
    ["accept_pair_adventure", {adventureId: other, dragonId: "owned-dragon"}],
    ["decline_pair_adventure", {adventureId: other}],
    ["start_pair_adventure", {adventureId: other}],
    ["cancel_pair_adventure", {adventureId: other}],
    ["create_group_adventure", {adventureId: "group_1", dragonId: "owned-dragon"}],
    ["donate_beacon", {conclaveId: other, amount: 25}],
    ["join_group_adventure", {lobbyId: other, dragonId: "owned-dragon"}],
    ["leave_group_adventure", {lobbyId: other}],
    ["remove_group_adventure_member", {lobbyId: other, memberId: requestId}],
    ["claim_group_reward", {lobbyId: other}], ["claim_pair_reward", {adventureId: other}],
    ["claim_podium_prize", {prizeId: other}],
  ] as const) {
    const context = {version: 1, ownerId: owner, action, sourceId: other, fingerprint: hash, facts: {xp: 400}};
    const {deps, inputs, calls} = setup();
    const original = deps.rpc;
    deps.rpc = async (name, p) => name === "begin_revisioned_game_command"
      ? {...leased, social_context: context} : original(name, p);
    const result = await handleCommand(request({...body, action, payload}), deps);
    assert(result.status === 200);
    equal(inputs[0].verifiedSocialContext, context);
    assert(!(await result.text()).includes("fingerprint"));
    for (const forged of [{...body, action, payload, verifiedSocialContext: context},
      {...body, action, payload: {...payload, context}},
      {...body, action, payload: {...payload, xp: 5000}}]) {
      const before = calls.length;
      assert((await handleCommand(request(forged), deps)).status === 400);
      assert(calls.length === before);
    }
  }
});

Deno.test("changed social sources are terminal only after SQL proves rollback", async () => {
  for (const knownRollback of [true, false]) {
    const {deps, calls} = setup();
    const original = deps.rpc;
    deps.rpc = async (name, p) => {
      if (name === "commit_canonical_game_command") {
        if (knownRollback) throw new RpcFailure("game_social_state_changed");
        throw new Error("network lost after a possible commit");
      }
      return original(name, p);
    };
    const result = await handleCommand(request({...body, action: "claim_group_reward", payload: {lobbyId: other}}), deps);
    assert(result.status === (knownRollback ? 422 : 503));
    assert(calls.some(c => c.name === "fail_canonical_game_command") === knownRollback);
    if (knownRollback) {
      equal(await result.json(), {error: "game_social_state_changed", request_id: requestId, replayed: false});
      assert(calls.at(-1)?.payload.p_lease_token === lease);
    }
  }
});

Deno.test("social reservations originate only in the database lease and owner read", async () => {
  const reservations = {version: 1, ownerId: owner,
    reservations: [{dragonId: "owned-dragon", kind: "group", sourceId: other}]};
  const {deps, inputs, calls} = setup();
  const original = deps.rpc;
  deps.rpc = async (name, payload) => name === "begin_revisioned_game_command"
    ? {...leased, social_reservations: reservations} : original(name, payload);
  const response = await handleCommand(request(), deps);
  assert(response.status === 200);
  equal(inputs[0].verifiedSocialReservations, reservations);
  assert(!(await response.text()).includes("social_reservations"));
  for (const forged of [{...body, verifiedSocialReservations: reservations},
    {...body, payload: {...body.payload, reservations}},
    {...readBody, social_reservations: reservations}]) {
    const before = calls.length;
    assert((await handleCommand(request(forged), deps)).status === 400);
    assert(calls.length === before);
  }
  const reader = setup({
    rpc: async () => ({...readSnapshot, social_reservations: reservations}),
    project: (input) => {equal(input.verifiedSocialReservations, reservations); return publicData;},
  });
  assert((await handleCommand(request(readBody), reader.deps)).status === 200);
});

Deno.test("trade confirmation evaluates both sealed inventories and uses one atomic commit RPC", async () => {
  const result = {tradeId: requestId, status: "completed"};
  const counter = {owner_id: other, base_revision: 8, state_sha256: hash, authority_mode: "shadow",
    state: {private: "counterparty egg DNA"}, secret_seed: "c8".repeat(32),
    social_context: {ownerId: other, sourceId: requestId}, social_reservations: null, trade_reservations: null};
  const inputs: JsonObject[] = []; const calls: string[] = [];
  const {deps} = setup({evaluate: async (input) => {
    inputs.push(input); return {protocol: 2, state: {private: "new state " + input.keeperId}, result};
  }, rpc: async (name,payload) => {
    calls.push(name);
    if(name === "begin_revisioned_game_command") return {...leased, trade_counterparty: counter};
    assert(name === "commit_canonical_trade_command");
    equal(payload.p_state,{private: "new state " + owner});
    equal(payload.p_counterparty_state,{private: "new state " + other});
    return {...saved,result};
  }});
  const reply = await handleCommand(request({...body,action:"confirm_trade",payload:{tradeId:requestId}}),deps);
  assert(reply.status === 200); const output = await reply.text();
  assert(!output.includes("DNA") && !output.includes("new state"));
  equal(inputs.map((i)=>i.keeperId),[owner,other]);
  equal(inputs.map((i)=>i.secretSeed),[hash,counter.secret_seed]);
  equal(calls,["begin_revisioned_game_command","commit_canonical_trade_command"]);
});
Deno.test("trade counterparty failure commits neither inventory and never accepts caller state", async () => {
  for (const failure of ["domain", "timeout", "wrong_owner"]) {
    const calls: string[] = [];
    const {deps} = setup({evaluate: async(input) => {
      if (input.keeperId === other) {
        if(failure === "timeout") throw new Error("timeout");
        return {error:"game_action_unavailable"};
      }
      return {protocol:2,state:{private:true},result:{tradeId:requestId,status:"completed"}};
    },rpc:async(name)=>{
      calls.push(name);
      if(name === "begin_revisioned_game_command") return {...leased,trade_counterparty:{owner_id:failure === "wrong_owner"?owner:other,
        base_revision:8,state_sha256:hash,authority_mode:"shadow",state:{private:true},secret_seed:hash,
        social_context:{ownerId:other,sourceId:requestId},social_reservations:null,trade_reservations:null}};
      assert(name === "fail_canonical_game_command");return true;
    }});
    const response=await handleCommand(request({...body,action:"confirm_trade",payload:{tradeId:requestId}}),deps);
    assert(response.status === (failure === "domain" ? 422 : 503));
    assert(!calls.some((name)=>name.startsWith("commit_")));
    assert(calls.includes("fail_canonical_game_command") === (failure === "domain"));
  }
  const {deps,calls}=setup();
  assert((await handleCommand(request({...body,action:"confirm_trade",payload:{tradeId:requestId,state:{coins:999}}}),deps)).status===400);
  equal(calls,[]);
});

Deno.test("Trial resume accepts only its authenticated attempt ID, never caller state or elapsed time", async () => {
  const accepted = setup();
  const value = {...body, action: "resume_trial", payload: {attemptId: requestId}};
  assert((await handleCommand(request(value), accepted.deps)).status === 200);
  equal(accepted.inputs[0].payload, {attemptId: requestId});
  assert(accepted.inputs[0].keeperId === owner);
  for (const extra of [{checkpoint: {score: 9999}}, {elapsedMs: 50000}, {ownerId: other}, {seed: 7}]) {
    const denied = setup();
    assert((await handleCommand(request({...value, payload: {...value.payload, ...extra}}), denied.deps)).status === 400);
    equal(denied.calls, []);
  }
});

Deno.test("database server authority survives execution, replay, reads and recovery", async () => {
  const liveSaved = {...saved, authority_mode: "server"};
  let executed = false;
  const {deps, inputs} = setup({
    rpc: async (name) => {
      if (name === "begin_revisioned_game_command") return executed
        ? {status: "succeeded", response: liveSaved} : {...leased, authority_mode: "server"};
      if (name === "commit_canonical_game_command") {executed = true; return liveSaved;}
      if (name === "read_canonical_game_state") return {...readSnapshot, authority_mode: "server"};
      if (name === "recover_canonical_game_commands") return {protocol:2, owner_id:owner,
        request_id:requestId, authority_mode:"server", barrier_revision:4,
        cancelled_commands:0, replayed:false};
      throw new Error("unexpected RPC");
    }, project: () => publicData,
  });
  for (const input of [body, body, readBody,
    {protocol:2, clientBuild:10068, action:"recover_commands", requestId}]) {
    const reply = await handleCommand(request(input), deps);
    assert(reply.status === 200);
    const text = await reply.text();
    assert(JSON.parse(text).authority_mode === "server");
    assert(!text.includes("hidden egg") && !text.includes("NEVER_RETURN"));
  }
  assert(inputs.length === 1);
});
