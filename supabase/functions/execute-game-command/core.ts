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
  prepareImport?: (input: JsonObject) => unknown;
}

const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;
const hash = /^[0-9a-f]{64}$/;
const encoder = new TextEncoder();
const commandKeys: Record<string, readonly string[]> = {

  offer_trade: ["keeperCode", "kind", "key", "variant"],
  reply_trade: ["tradeId", "kind", "key", "variant"],
  confirm_trade: ["tradeId"], cancel_trade: ["tradeId"], reject_trade: ["tradeId"],
  claim_event_reward: ["eventKey"],
  donate_beacon: ["conclaveId", "amount"],
  invite_pair_adventure: ["keeperCode", "dragonId"],
  accept_pair_adventure: ["adventureId", "dragonId"],
  decline_pair_adventure: ["adventureId"],
  start_pair_adventure: ["adventureId"],
  cancel_pair_adventure: ["adventureId"],
  create_group_adventure: ["adventureId", "dragonId"],
  join_group_adventure: ["lobbyId", "dragonId"],
  leave_group_adventure: ["lobbyId"],
  remove_group_adventure_member: ["lobbyId", "memberId"],
  start_trial: ["offerId", "dragonId"],
  claim_group_reward: ["lobbyId"], claim_pair_reward: ["adventureId"], claim_podium_prize: ["prizeId"],
  checkpoint_trial: ["attemptId", "inputs", "elapsedMs", "finish"],
  cancel_trial: ["attemptId"],
  resume_trial: ["attemptId"],
  start_school: ["gameId", "dragonIds", "mentorId"],
  finish_school: ["attemptId", "inputs"], cancel_school: ["attemptId"],
  graduate_school: ["dragonId"],
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
  select_portrait: ["catalogId"], select_title: ["catalogId"],
  select_badge: ["catalogId"], select_frame: ["catalogId"],
  complete_presentation: ["presentationId"],
  call_dragon_to_floor: ["roomId", "index"], visit_tower_floor: ["roomId", "index"],
  place_house_item: ["itemId", "roomId", "x", "y"], move_house_item: ["itemId", "x", "y"],
  change_tower_floor_room: ["index", "roomId"],
  remove_house_item: ["itemId"], reorder_tower_floor: ["oldIndex", "newIndex"],
  set_dragon_roaming: ["dragonId", "enabled"], clear_tower_floor: ["index"],
};

export const domainErrors = new Set([
  "game_action_unavailable", "game_social_claim_unavailable", "game_social_state_changed",
  "game_attempt_unavailable", "game_attempt_time_invalid",
  "game_attempt_state_changed", "game_attempt_in_progress",
  "game_attempt_input_limit", "game_attempt_incomplete",
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
  ["game_migration_disabled", 503], ["game_migration_in_progress", 409],
  ["game_migration_authority_conflict", 409], ["game_migration_trade_pending", 409],
  ["game_migration_capture_changed", 409], ["game_migration_preparation_changed", 409],
  ["game_migration_social_changed", 409], ["game_import_source_changed", 409],
  ["game_import_altar_changed", 409], ["game_import_generation_changed", 409],
  ["game_import_device_clock_required", 409], ["game_import_pending_altar", 409],
  ["game_import_altar_invalid", 409], ["game_import_altar_snapshot_missing", 409],
  ["game_import_altar_snapshot_stale", 409], ["game_import_foreign_altar", 409],
  ["game_import_offline_altar_review", 409], ["game_import_owner_invalid", 409],
  ["game_import_protected_return_conflict", 409], ["game_import_return_history_conflict", 409],
  ["game_import_returned_dragon_conflict", 409], ["game_import_returned_nest_conflict", 409],
  ["game_import_server_metadata_untrusted", 409],
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

function validAuthority(value: unknown): boolean {
  return value === "shadow" || value === "server";
}

function receipt(value: unknown, owner: string, command: Command): JsonObject {
  if (!object(value) || value.owner_id !== owner || value.request_id !== command.requestId ||
    !positiveInteger(value.server_revision) || typeof value.state_sha256 !== "string" ||
    !hash.test(value.state_sha256) || !validAuthority(value.authority_mode) ||
    !Object.hasOwn(value, "result") || encoder.encode(JSON.stringify(value.result)).length > 30000) {
    throw new Error("invalid_receipt");
  }
  // Preserve the database authority; clients must explicitly require their mode.
  return { protocol: 2, owner_id: owner, request_id: command.requestId,
    server_revision: value.server_revision, state_sha256: value.state_sha256,
    authority_mode: value.authority_mode, result: value.result };
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
  if (object(input) && input.action === "migrate_account") {
    if (!exactKeys(input, ["protocol", "clientBuild", "action", "requestId", "sourceRevision"]) ||
      input.protocol !== 2 || !positiveInteger(input.clientBuild) || input.clientBuild > 2147483647 ||
      !positiveInteger(input.sourceRevision) || typeof input.requestId !== "string" || !uuid.test(input.requestId)) {
      return error("game_request_invalid", 400);
    }
    return migrateAccount(owner, input.requestId, input.sourceRevision, input.clientBuild, deps);
  }
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
      !validAuthority(leased.authority_mode) || !positiveInteger(leased.base_revision) ||
      typeof leased.lease_token !== "string" || !uuid.test(leased.lease_token) ||
      typeof leased.secret_seed !== "string" || !hash.test(leased.secret_seed) ||
      typeof leased.now !== "string" || !Number.isFinite(Date.parse(leased.now)) || !object(leased.state)) {
      throw new Error("invalid_lease");
    }
    const counterpart = leased.trade_counterparty;
    if (command.action === "confirm_trade") {
      if (!object(counterpart) || !exactKeys(counterpart, ["owner_id", "base_revision", "state_sha256",
        "authority_mode", "state", "secret_seed", "social_context", "social_reservations", "trade_reservations"]) ||
        typeof counterpart.owner_id !== "string" || !uuid.test(counterpart.owner_id) || counterpart.owner_id === owner ||
        !positiveInteger(counterpart.base_revision) || typeof counterpart.state_sha256 !== "string" || !hash.test(counterpart.state_sha256) ||
        counterpart.authority_mode !== leased.authority_mode || !object(counterpart.state) ||
        typeof counterpart.secret_seed !== "string" || !hash.test(counterpart.secret_seed) ||
        !object(counterpart.social_context) || counterpart.social_context.ownerId !== counterpart.owner_id ||
        counterpart.social_context.sourceId !== command.payload.tradeId) throw new Error("invalid_counterparty_lease");
    } else if (counterpart !== undefined && counterpart !== null) throw new Error("unexpected_counterparty_lease");
    // These inputs come exclusively from Auth and the private database lease.
    const evaluated = await deps.evaluate({ state: leased.state, action: command.action,
      payload: command.payload, secretSeed: leased.secret_seed, now: leased.now, keeperId: owner,
      verifiedSocialContext: leased.social_context ?? null,
      verifiedEventProgress: leased.event_progress ?? null,
      verifiedSocialClaims: leased.social_claims ?? [],
      verifiedSocialReservations: leased.social_reservations ?? null,
      verifiedTradeReservations: leased.trade_reservations ?? null });
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
    let otherEvaluation: JsonObject | null = null;
    if (command.action === "confirm_trade" && object(counterpart)) {
      const result = await deps.evaluate({state: counterpart.state, action: command.action, payload: command.payload,
        secretSeed: counterpart.secret_seed, now: leased.now, keeperId: counterpart.owner_id,
        verifiedSocialContext: counterpart.social_context, verifiedSocialReservations: counterpart.social_reservations,
        verifiedTradeReservations: counterpart.trade_reservations});
      if (!object(result)) throw new Error("invalid_counterparty_evaluation");
      if (typeof result.error === "string" && domainErrors.has(result.error)) {
        const recorded = await deps.rpc("fail_canonical_game_command", {p_owner_id: owner,
          p_request_id: command.requestId, p_lease_token: leased.lease_token, p_failure_code: result.error});
        if (recorded !== true) throw new RpcFailure("game_lease_lost");
        return response({error: result.error, request_id: command.requestId, replayed: false}, 422);
      }
      if (result.protocol !== 2 || !object(result.state) || !Object.hasOwn(result,"result")) throw new Error("invalid_counterparty_evaluation");
      otherEvaluation = result;
    }
    let committed;
    try {
      committed = await deps.rpc(otherEvaluation ? "commit_canonical_trade_command" : "commit_canonical_game_command", {
        p_owner_id: owner, p_request_id: command.requestId, p_lease_token: leased.lease_token,
        p_state: evaluated.state, p_result: evaluated.result,
        ...(otherEvaluation ? {p_counterparty_state: otherEvaluation.state, p_counterparty_result: otherEvaluation.result} : {}),
      });
    } catch (failure) {
      // This exact SQL refusal rolls the entire commit back. Unlike a timeout,
      // it proves no reward was granted; fence the now-obsolete social claim.
      if (!(failure instanceof RpcFailure) || failure.code !== "game_social_state_changed") throw failure;
      const recorded = await deps.rpc("fail_canonical_game_command", {
        p_owner_id: owner, p_request_id: command.requestId, p_lease_token: leased.lease_token,
        p_failure_code: failure.code,
      });
      if (recorded !== true) throw new RpcFailure("game_lease_lost");
      return response({error: failure.code, request_id: command.requestId, replayed: false}, 422);
    }
    const saved = receipt(committed, owner, command);
    if (saved.authority_mode !== leased.authority_mode || saved.server_revision !== leased.base_revision + 1) throw new Error("invalid_committed_revision");
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
      result.owner_id !== owner || result.request_id !== requestId || !validAuthority(result.authority_mode) ||
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
      !hash.test(snapshot.state_sha256) || !validAuthority(snapshot.authority_mode) ||
      typeof snapshot.mutations_enabled !== "boolean" || !object(snapshot.state) ||
      typeof snapshot.server_time !== "string" || !Number.isFinite(Date.parse(snapshot.server_time))) {
      throw new Error("invalid_snapshot");
    }
    const data = deps.project({ state: snapshot.state, ownerId: owner, now: snapshot.server_time,
      verifiedSocialClaims: snapshot.social_claims ?? [],
      verifiedTradeOffers: snapshot.trade_offers ?? {completedToday: 0, offers: []},
      verifiedEventProgress: snapshot.event_progress ?? null,
      verifiedSocialReservations: snapshot.social_reservations ?? null,
      verifiedTradeReservations: snapshot.trade_reservations ?? null });
    if (object(data) && data.error === "game_state_reconciliation_required") {
      return error("game_state_reconciliation_required", 409);
    }
    if (!object(data) || data.projectionVersion !== 1 ||
      !exactKeys(data, ["projectionVersion", "activeDragonId", "wallet", "eggs", "dragons", "inventory",
        "collection", "house", "progress", "adventures", "trials", "presentations", "activities", "trades"]) ||
      encoder.encode(JSON.stringify(data)).length > 8 * 1024 * 1024) {
      throw new Error("invalid_projection");
    }
    return response({ protocol: 2, owner_id: owner, server_revision: snapshot.server_revision,
      state_sha256: snapshot.state_sha256, ruleset_sha256: deps.ruleset,
      ruleset_revision: snapshot.ruleset_revision,
      authority_mode: snapshot.authority_mode, mutations_enabled: snapshot.mutations_enabled,
      server_time: snapshot.server_time, data });
  } catch (failure) {
    if (failure instanceof RpcFailure && databaseErrors.has(failure.code)) {
      return error(failure.code, databaseErrors.get(failure.code)!);
    }
    return error("game_snapshot_unavailable", 503);
  }
}

// Auth supplies the owner. Only a database-captured immutable save and Altar
// ledger enter the importer; the caller supplies a revision, never inventory.
async function migrateAccount(owner: string, requestId: string, sourceRevision: number,
  clientBuild: number, deps: Dependencies): Promise<Response> {
  try {
    if (!deps.prepareImport) throw new Error("preparation_missing");
    const captured = await deps.rpc("begin_canonical_account_migration", {
      p_owner_id:owner, p_request_id:requestId, p_source_revision:sourceRevision,
      p_client_build:clientBuild, p_ruleset_sha256:deps.ruleset,
    });
    if (!object(captured) || captured.owner_id !== owner) throw new Error("invalid_capture");
    if (captured.phase === "active" && positiveInteger(captured.server_revision)) {
      return response({protocol:2, owner_id:owner, request_id:requestId, authority_mode:"server",
        server_revision:captured.server_revision, phase:"active", replayed:true});
    }
    if (captured.phase !== "captured" || typeof captured.import_id !== "string" ||
      !uuid.test(captured.import_id)) throw new Error("invalid_capture");
    const input = await deps.rpc("get_canonical_game_import", {p_owner_id:owner});
    if (!object(input) || input.owner_id !== owner || input.import_id !== captured.import_id ||
      !positiveInteger(input.base_revision) || input.source_revision !== sourceRevision ||
      typeof input.source_sha256 !== "string" || !hash.test(input.source_sha256) ||
      typeof input.altar_sha256 !== "string" || !hash.test(input.altar_sha256) ||
      typeof input.secret_seed !== "string" || !hash.test(input.secret_seed) ||
      typeof input.now !== "string" || !Number.isFinite(Date.parse(input.now)) || !object(input.source) ||
      (input.authoritative_altar !== null && !object(input.authoritative_altar))) throw new Error("invalid_import");
    const prepared = deps.prepareImport({ownerId:owner, source:input.source, authoritativeAltar:input.authoritative_altar,
      now:input.now, secretSeed:input.secret_seed});
    if (object(prepared) && typeof prepared.error === "string" && databaseErrors.has(prepared.error)) {
      throw new RpcFailure(prepared.error);
    }
    if (!object(prepared) || prepared.protocol !== 2 || !object(prepared.state) ||
      !Array.isArray(prepared.changed_asset_kinds) || prepared.changed_asset_kinds.length > 100 ||
      !prepared.changed_asset_kinds.every((kind) => typeof kind === "string" && /^[a-zA-Z][a-zA-Z0-9_]{0,79}$/.test(kind))) {
      throw new Error("invalid_preparation");
    }
    const receipt = await deps.rpc("commit_canonical_game_preparation", {
      p_owner_id:owner, p_import_id:input.import_id, p_expected_revision:input.base_revision,
      p_ruleset_sha256:deps.ruleset, p_state:prepared.state, p_changed_asset_kinds:prepared.changed_asset_kinds,
    });
    if (!object(receipt) || receipt.owner_id !== owner || receipt.import_id !== input.import_id ||
      receipt.authority_mode !== "shadow" || !positiveInteger(receipt.server_revision) ||
      typeof receipt.state_sha256 !== "string" || !hash.test(receipt.state_sha256) ||
      typeof receipt.replayed !== "boolean") throw new Error("invalid_preparation_receipt");
    const activated = await deps.rpc("activate_canonical_account", {
      p_owner_id:owner, p_request_id:requestId, p_import_id:input.import_id,
      p_prepared_revision:receipt.server_revision, p_ruleset_sha256:deps.ruleset,
    });
    if (!object(activated) || activated.owner_id !== owner || activated.phase !== "active" ||
      !positiveInteger(activated.server_revision) || activated.server_revision !== receipt.server_revision + 1 ||
      typeof activated.replayed !== "boolean") throw new Error("invalid_activation");
    return response({protocol:2, owner_id:owner, request_id:requestId, authority_mode:"server",
      server_revision:activated.server_revision, phase:"active", replayed:activated.replayed});
  } catch (failure) {
    if (failure instanceof RpcFailure && databaseErrors.has(failure.code)) {
      return error(failure.code, databaseErrors.get(failure.code)!);
    }
    // An activation may have committed before the connection was lost. A retry
    // reads the durable active status and never repeats preparation or spending.
    return error("game_migration_unavailable", 503);
  }
}
