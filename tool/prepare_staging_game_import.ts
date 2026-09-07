import { boundedJson, object } from "../supabase/functions/execute-game-command/core.ts";
import { ruleset } from "../supabase/functions/execute-game-command/bundle.generated.ts";

// An operator-only tool for an already captured staging source. It cannot
// upload arbitrary client state or promote live account authority. The private
// service key, full source and preparation seed never leave process memory.
const base = Deno.env.get("STAGING_SUPABASE_URL") ?? "";
const service = Deno.env.get("STAGING_SUPABASE_SERVICE_ROLE_KEY") ?? "";
const owner = Deno.args[0] ?? "";
const uuid = /^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/;
const hash = /^[0-9a-f]{64}$/;

function require(condition: unknown, code: string): asserts condition {
  if (!condition) throw new Error(code);
}
async function rpc(name: string, payload: unknown) {
  const result = await fetch(`${base}/rest/v1/rpc/${name}`, {
    method: "POST", signal: AbortSignal.timeout(15000),
    headers: { "content-type": "application/json", apikey: service, authorization: `Bearer ${service}` },
    body: JSON.stringify(payload),
  });
  const value = await boundedJson(result.body, 10 * 1024 * 1024);
  if (!result.ok) {
    // Return only documented fixed domain codes, never PostgREST details.
    const safe = object(value) && typeof value.message === "string" &&
      /^game_(?:import_[a-z_]+|revision_conflict|pending_command_required|ruleset_mismatch|idempotency_conflict)$/.test(value.message);
    throw new Error(safe ? value.message as string : "game_import_rpc_failed");
  }
  return value;
}

try {
  require(base === "https://vtmjkhzalalozpfnbvsd.supabase.co" && service.length >= 32 &&
    Deno.args.length === 1 && uuid.test(owner), "game_import_staging_configuration_required");
  const input = await rpc("get_canonical_game_import", { p_owner_id: owner });
  require(object(input) && input.owner_id === owner && typeof input.import_id === "string" &&
    uuid.test(input.import_id) && Number.isSafeInteger(input.base_revision) && (input.base_revision as number) > 0 &&
    typeof input.source_sha256 === "string" && hash.test(input.source_sha256) &&
    typeof input.altar_sha256 === "string" && hash.test(input.altar_sha256) &&
    typeof input.secret_seed === "string" && hash.test(input.secret_seed) &&
    typeof input.now === "string" && Number.isFinite(Date.parse(input.now)) && object(input.source) &&
    (input.authoritative_altar === null || object(input.authoritative_altar)), "game_import_source_invalid");
  const domain = globalThis as unknown as { dragonhavenPrepareGameImport: (input: string) => string };
  const prepared: unknown = JSON.parse(domain.dragonhavenPrepareGameImport(JSON.stringify({
    ownerId: owner, source: input.source, authoritativeAltar: input.authoritative_altar,
    now: input.now, secretSeed: input.secret_seed,
  })));
  require(object(prepared), "game_import_preparation_invalid");
  if (typeof prepared.error === "string" && /^game_import_[a-z_]+$/.test(prepared.error)) throw new Error(prepared.error);
  require(prepared.protocol === 2 && object(prepared.state) && Array.isArray(prepared.changed_asset_kinds) &&
    prepared.changed_asset_kinds.length <= 100 && prepared.changed_asset_kinds.every((kind) =>
      typeof kind === "string" && /^[a-zA-Z][a-zA-Z0-9_]{0,79}$/.test(kind)), "game_import_preparation_invalid");
  const result = await rpc("commit_canonical_game_preparation", {
    p_owner_id: owner, p_import_id: input.import_id, p_expected_revision: input.base_revision,
    p_ruleset_sha256: ruleset, p_state: prepared.state, p_changed_asset_kinds: prepared.changed_asset_kinds,
  });
  require(object(result) && result.owner_id === owner && result.import_id === input.import_id &&
    result.authority_mode === "shadow" && Number.isSafeInteger(result.server_revision) &&
    typeof result.state_sha256 === "string" && hash.test(result.state_sha256) && typeof result.replayed === "boolean",
    "game_import_receipt_invalid");
  console.log(JSON.stringify({ prepared: true, authority: "shadow", serverRevision: result.server_revision,
    replayed: result.replayed, changedAssetKinds: result.changed_asset_kinds }));
} catch (error) {
  const code = error instanceof Error && /^game_[a-z_]+$/.test(error.message)
    ? error.message : "game_import_unavailable";
  console.error(code);
  Deno.exitCode = 1;
}
