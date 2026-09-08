export type JsonObject = Record<string, unknown>;
export type Command = {
  protocol: 2;
  requestId: string;
  clientBuild: number;
  expectedRevision: number;
  action: string;
  payload: JsonObject;
};

export interface Dependencies {
  ruleset: string;
  authenticate: (authorization: string) => Promise<string | null>;
  rpc: (name: string, payload: JsonObject) => Promise<unknown>;
  evaluate: (input: JsonObject) => Promise<unknown>;
  project?: (input: JsonObject) => unknown;
}

const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const hash = /^[0-9a-f]{64}$/;
const encoder = new TextEncoder();
const commandKeys: Record<string, readonly string[]> = {
  refresh: [], purchase_portrait_chest: [], purchase_title_chest: [], purchase_music_chest: [],
  purchase_furniture: ["catalogId"], purchase_relic: ["relic"],
  open_chests: ["tier", "count"], open_special_chests: ["catalogId", "count"],
  use_relic: ["relic", "dragonId"], use_astral_lens: ["eggId"],
  tag_egg: ["eggId", "tagged"], return_egg: ["eggId", "sinisterConfirmed"],
  craft_altar_relic: ["relic"], use_altar_relic: ["relic", "eggId"],
  use_chronoshard: ["reductionPercent"], use_wayfinder: ["kind", "replaceAdventureId"],
  equip_twinstar: ["dragonId"], equip_relic: ["relic", "dragonId"], activate_egg: ["eggId"], hatch_egg: ["eggId"],
  name_dragon: ["dragonId", "name"], evolve_dragon: ["dragonId"],
  set_dragon_highlight: ["dragonId", "focus", "highlighted"], set_favorite_dragon: ["dragonId"],
  buy_starlight_treat: ["dragonId"], release_dragon: ["dragonId"],
  start_adventure: ["adventureId", "dragonId"], dismiss_adventure: ["adventureId"],
  claim_adventure: ["runId"], abort_adventure: ["runId"], dismiss_trial: ["offerId"],
  claim_constellation: [], unlock_room: ["roomId"], build_floor: ["roomId"],
  repair_floor: ["index"], upgrade_ward: [], complete_tutorial: ["fullyViewed"],
  redeem_code: ["code"],
};

export const domainErrors = new Set([
  "invalid_command", "invalid_argument", "unknown_item", "special_chest_id_required",
  "unknown_adventure", "unknown_room", "game_state_reconciliation_required",
  "game_state_owner_mismatch",
  "altar_busy", "altar_sign_in_required", "altar_pending", "egg_not_found",
  "sinister_confirmation_required", "invalid_relic", "insufficient_materials",
  "already_known", "egg_reserved", "relic_not_owned", "invalid_name", "invalid_action",
  "egg_tagged", "special_egg", "egg_in_nest", "already_returned",
  "game_state_changed", "game_command_recovered",
]);
const databaseErrors = new Map<string, number>([
  ["game_engine_disabled", 503], ["game_client_upgrade_required", 426],
  ["game_ruleset_mismatch", 503], ["game_import_required", 409],
  ["game_import_preparation_required", 409],
  ["game_idempotency_conflict", 409], ["game_pending_ruleset_changed", 409],
  ["game_command_busy", 409], ["game_revision_conflict", 409],
  ["game_pending_command_required", 409], ["game_lease_lost", 409],
  ["economy_rate_limited", 429],
]);

// Only exact known SQL exception messages are surfaced. Request bodies, saves,
// authorization headers and PostgREST details are never logged or returned.
export class RpcFailure extends Error {
  constructor(readonly code: string) { super("game_rpc_failed"); }
}

export function object(value: unknown): value is JsonObject {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
function exactKeys(value: JsonObject, keys: readonly string[]) {
  return Object.keys(value).length === keys.length && keys.every((key) => Object.hasOwn(value, key));
}
function positiveInteger(value: unknown): value is number {
  return Number.isSafeInteger(value) && (value as number) > 0;
}
export function parseCommand(value: unknown): Command | null {
  if (!object(value) || !exactKeys(value, ["protocol", "requestId", "clientBuild", "action", "payload", "expectedRevision"]) ||
    value.protocol !== 2 || typeof value.requestId !== "string" || !uuid.test(value.requestId) ||
    !positiveInteger(value.clientBuild) || value.clientBuild > 2147483647 ||
    !positiveInteger(value.expectedRevision) ||
    typeof value.action !== "string" || !Object.hasOwn(commandKeys, value.action) ||
    !object(value.payload) || !exactKeys(value.payload, commandKeys[value.action]) ||
    encoder.encode(JSON.stringify(value.payload)).length > 4096 ||
    Object.values(value.payload).some((item) => item !== null &&
      typeof item !== "string" && typeof item !== "boolean" && typeof item !== "number")) return null;
  return value as Command;
}

const headers = {
  "cache-control": "no-store", "content-type": "application/json",
  "access-control-allow-origin": "*", "access-control-allow-headers": "authorization, apikey, content-type, x-client-info",
  "access-control-allow-methods": "POST, OPTIONS", "x-content-type-options": "nosniff",
};
function response(value: unknown, status = 200) {
  return new Response(JSON.stringify(value), { status, headers });
}
function error(code: string, status: number) { return response({ error: code }, status); }

export async function boundedJson(body: ReadableStream<Uint8Array> | null,
  maximum: number, timeoutMs = 8000): Promise<unknown> {
  if (!body) throw new Error("missing_body");
  const reader = body.getReader();
  let timeout: ReturnType<typeof setTimeout> | undefined;
  const expiry = new Promise<never>((_, reject) => {
    timeout = setTimeout(() => reject(new Error("body_timeout")), timeoutMs);
  });
  try {
    const chunks: Uint8Array[] = [];
    let length = 0;
    while (true) {
      const part = await Promise.race([reader.read(), expiry]);
      if (part.done) break;
      length += part.value.length;
      if (length > maximum) throw new Error("body_too_large");
      chunks.push(part.value);
    }
    const bytes = new Uint8Array(length);
    let offset = 0;
    for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
    return JSON.parse(new TextDecoder("utf-8", { fatal: true }).decode(bytes));
  } finally {
    clearTimeout(timeout);
    void reader.cancel().catch(() => {});
  }
}

function receipt(value: unknown, owner: string, command: Command): JsonObject {
  if (!object(value) || value.owner_id !== owner || value.request_id !== command.requestId ||
    !positiveInteger(value.server_revision) || typeof value.state_sha256 !== "string" ||
    !hash.test(value.state_sha256) || value.authority_mode !== "shadow" ||
    !Object.hasOwn(value, "result") || encoder.encode(JSON.stringify(value.result)).length > 30000) {
    throw new Error("invalid_receipt");
  }
  // Shadow results and projections must never be applied to a live game.
  return { protocol: 2, owner_id: owner, request_id: command.requestId,
    server_revision: value.server_revision, state_sha256: value.state_sha256,
    authority_mode: "shadow", result: value.result };
}

export async function handleCommand(request: Request, deps: Dependencies): Promise<Response> {
  if (request.method === "OPTIONS") return new Response(null, { status: 204, headers });
  if (request.method !== "POST") return error("game_method_not_allowed", 405);
  const authorization = request.headers.get("authorization") ?? "";
  if (!/^Bearer [A-Za-z0-9._~-]{32,8192}$/.test(authorization)) return error("game_login_required", 401);
  if (!hash.test(deps.ruleset)) return error("game_configuration_missing", 503);
  let owner: string | null;
  try { owner = await deps.authenticate(authorization); }
  catch { return error("game_auth_unavailable", 503); }
  if (owner === null || !uuid.test(owner)) return error("game_login_required", 401);
  let command: Command | null;
  let input: unknown;
  try { input = await boundedJson(request.body, 8192); }
  catch { return error("game_request_invalid", 400); }
  if (object(input) && input.action === "read_state") {
    if (!exactKeys(input, ["protocol", "clientBuild", "action"]) || input.protocol !== 2 ||
      !positiveInteger(input.clientBuild) || input.clientBuild > 2147483647) {
      return error("game_request_invalid", 400);
    }
    return readState(owner, input.clientBuild, deps);
  }
  if (object(input) && input.action === "recover_commands") {
    if (!exactKeys(input, ["protocol", "clientBuild", "action", "requestId"]) || input.protocol !== 2 ||
      !positiveInteger(input.clientBuild) || input.clientBuild > 2147483647 ||
      typeof input.requestId !== "string" || !uuid.test(input.requestId)) {
      return error("game_request_invalid", 400);
    }
    return recoverCommands(owner, input.requestId, input.clientBuild, deps);
  }
  command = parseCommand(input);
  if (!command) return error("game_request_invalid", 400);

  try {
    const leased = await deps.rpc("begin_revisioned_game_command", {
      p_owner_id: owner, p_request_id: command.requestId, p_action: command.action,
      p_payload: command.payload, p_client_build: command.clientBuild, p_ruleset_sha256: deps.ruleset,
      p_expected_revision: command.expectedRevision,
    });
    if (!object(leased)) throw new Error("invalid_lease");
    if (leased.status === "succeeded") return response({ ...receipt(leased.response, owner, command), replayed: true });
    if (leased.status === "failed" && typeof leased.failure_code === "string" && domainErrors.has(leased.failure_code)) {
      return response({ error: leased.failure_code, request_id: command.requestId, replayed: leased.replayed !== false }, 422);
    }
    if (leased.status !== "processing" || leased.owner_id !== owner || leased.request_id !== command.requestId ||
      leased.authority_mode !== "shadow" || !positiveInteger(leased.base_revision) ||
      typeof leased.lease_token !== "string" || !uuid.test(leased.lease_token) ||
      typeof leased.secret_seed !== "string" || !hash.test(leased.secret_seed) ||
      typeof leased.now !== "string" || !Number.isFinite(Date.parse(leased.now)) || !object(leased.state)) {
      throw new Error("invalid_lease");
    }
    // These inputs come exclusively from Auth and the private database lease.
    const evaluated = await deps.evaluate({ state: leased.state, action: command.action,
      payload: command.payload, secretSeed: leased.secret_seed, now: leased.now, keeperId: owner });
    if (!object(evaluated)) throw new Error("invalid_evaluation");
    if (typeof evaluated.error === "string" && domainErrors.has(evaluated.error)) {
      const recorded = await deps.rpc("fail_canonical_game_command", {
        p_owner_id: owner, p_request_id: command.requestId, p_lease_token: leased.lease_token,
        p_failure_code: evaluated.error,
      });
      if (recorded !== true) throw new RpcFailure("game_lease_lost");
      return response({ error: evaluated.error, request_id: command.requestId, replayed: false }, 422);
    }
    if (evaluated.protocol !== 2 || !object(evaluated.state) || !Object.hasOwn(evaluated, "result")) {
      throw new Error("invalid_evaluation");
    }
    const committed = await deps.rpc("commit_canonical_game_command", {
      p_owner_id: owner, p_request_id: command.requestId, p_lease_token: leased.lease_token,
      p_state: evaluated.state, p_result: evaluated.result,
    });
    const saved = receipt(committed, owner, command);
    if (saved.server_revision !== leased.base_revision + 1) throw new Error("invalid_committed_revision");
    return response({ ...saved, replayed: false });
  } catch (failure) {
    if (failure instanceof RpcFailure && databaseErrors.has(failure.code)) {
      return error(failure.code, databaseErrors.get(failure.code)!);
    }
    // A timeout may have happened after commit. Never mark that intent failed
    // or invent a new request; retrying the same UUID recovers its receipt.
    return error("game_command_unavailable", 503);
  }
}

async function recoverCommands(owner: string, requestId: string, clientBuild: number,
  deps: Dependencies): Promise<Response> {
  try {
    const result = await deps.rpc("recover_canonical_game_commands", {
      p_owner_id: owner, p_request_id: requestId, p_client_build: clientBuild, p_ruleset_sha256: deps.ruleset,
    });
    if (!object(result) || !exactKeys(result, ["protocol", "owner_id", "request_id", "authority_mode",
      "barrier_revision", "cancelled_commands", "replayed"]) || result.protocol !== 2 ||
      result.owner_id !== owner || result.request_id !== requestId || result.authority_mode !== "shadow" ||
      !positiveInteger(result.barrier_revision) || ![0, 1].includes(result.cancelled_commands as number) ||
      typeof result.replayed !== "boolean") throw new Error("invalid_recovery");
    return response(result);
  } catch (failure) {
    if (failure instanceof RpcFailure && databaseErrors.has(failure.code)) {
      return error(failure.code, databaseErrors.get(failure.code)!);
    }
    return error("game_recovery_unavailable", 503);
  }
}

async function readState(owner: string, clientBuild: number, deps: Dependencies): Promise<Response> {
  try {
    if (!deps.project) throw new Error("projection_missing");
    const snapshot = await deps.rpc("read_canonical_game_state", {
      p_owner_id: owner, p_client_build: clientBuild, p_ruleset_sha256: deps.ruleset,
    });
    if (!object(snapshot) || snapshot.owner_id !== owner ||
      !positiveInteger(snapshot.server_revision) || typeof snapshot.state_sha256 !== "string" ||
      !positiveInteger(snapshot.ruleset_revision) ||
      !hash.test(snapshot.state_sha256) || snapshot.authority_mode !== "shadow" ||
      typeof snapshot.mutations_enabled !== "boolean" || !object(snapshot.state) ||
      typeof snapshot.server_time !== "string" || !Number.isFinite(Date.parse(snapshot.server_time))) {
      throw new Error("invalid_snapshot");
    }
    const data = deps.project({ state: snapshot.state, ownerId: owner, now: snapshot.server_time });
    if (object(data) && data.error === "game_state_reconciliation_required") {
      return error("game_state_reconciliation_required", 409);
    }
    if (!object(data) || data.projectionVersion !== 1 ||
      !exactKeys(data, ["projectionVersion", "activeDragonId", "wallet", "eggs", "dragons", "inventory",
        "collection", "house", "progress", "adventures", "trials", "presentations", "activities"]) ||
      encoder.encode(JSON.stringify(data)).length > 8 * 1024 * 1024) {
      throw new Error("invalid_projection");
    }
    return response({ protocol: 2, owner_id: owner, server_revision: snapshot.server_revision,
      state_sha256: snapshot.state_sha256, ruleset_sha256: deps.ruleset,
      ruleset_revision: snapshot.ruleset_revision,
      authority_mode: "shadow", mutations_enabled: snapshot.mutations_enabled,
      server_time: snapshot.server_time, data });
  } catch (failure) {
    if (failure instanceof RpcFailure && databaseErrors.has(failure.code)) {
      return error(failure.code, databaseErrors.get(failure.code)!);
    }
    return error("game_snapshot_unavailable", 503);
  }
}
