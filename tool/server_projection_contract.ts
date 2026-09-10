// Local integration contract: the real compiled Dart projection must pass the
// HTTP envelope guard. No live server, credentials or player data is used.
import { project, ruleset } from "../supabase/functions/execute-game-command/bundle.generated.ts";
import { handleCommand, type JsonObject } from "../supabase/functions/execute-game-command/core.ts";

function require(value: unknown, code: string): asserts value {
  if (!value) throw new Error("projection_contract_" + code);
}
require(Deno.args.length === 1, "fixture_required");
const fixture = JSON.parse(await Deno.readTextFile(Deno.args[0]));
const owner = "11111111-1111-4111-8111-111111111111";
const state = fixture.state as JsonObject;
require(state && Array.isArray(state.eggStash) && state.eggStash.length > 0, "synthetic_state_required");
const offer = {id: "33333333-3333-4333-8333-333333333333",
  otherOwnerId: "22222222-2222-4222-8222-222222222222", otherName: "Synthetic Keeper",
  otherKeeperCode: "DH-12345678", amInitiator: true, status: "awaiting_initiator",
  createdAt: "2026-09-07T12:00:00Z", expiresAt: "2026-09-07T12:10:00Z",
  sent: {kind: "egg", key: (state.eggStash[0] as JsonObject).id, variant: 0, data: state.eggStash[0]},
  received: {kind: "relic", key: "chronoshard", variant: 60, data: {reductionPercent: 60}}};
for (const offers of [[], [offer]]) {
  let reads = 0;
  const reply = await handleCommand(new Request("https://synthetic.invalid/execute-game-command", {
    method: "POST", headers: {authorization: "Bearer " + "synthetic-".repeat(8), "content-type": "application/json"},
    body: JSON.stringify({protocol: 2, clientBuild: 10080, action: "read_state"})
  }), {ruleset, authenticate: async () => owner, project,
    evaluate: async () => {throw new Error("unexpected_mutation");},
    rpc: async (name, payload) => {
      require(name === "read_canonical_game_state" && payload.p_owner_id === owner, "read_scope");
      reads++;
      return {owner_id: owner, server_revision: 1, ruleset_revision: 1,
        state_sha256: "a5".repeat(32), authority_mode: "shadow", mutations_enabled: false,
        state, server_time: "2026-09-07T12:00:00Z", trade_offers: {completedToday: 0, offers}};
    }});
  require(reply.status === 200 && reads === 1, "compiled_projection_rejected");
  const wire = await reply.json();
  require(wire.data.trades.offers.length === offers.length, "offers_missing");
  require(!JSON.stringify(wire).includes("hatchSeed") && !wire.state, "private_state_exposed");
  if (offers.length) {
    require(wire.data.trades.offers[0].received.reductionPercent === 60, "variant_changed");
    require(!wire.data.trades.offers[0].sent.egg.lineageId, "unknown_identity_exposed");
  }
}
console.log("PASS: actual compiled projection crosses the HTTP guard; empty/populated trade boards, exact variant and masked egg DNA.");
