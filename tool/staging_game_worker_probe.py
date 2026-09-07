"""One bounded, real Auth -> Edge -> Dart -> Postgres probe on isolated staging.

Only synthetic, auto-confirmed .invalid accounts are created; no email is sent.
Tokens and service keys stay in memory. No player save or secret is logged.
The worker operates exclusively on detached shadow copies, not live inventory.
"""
import concurrent.futures
import json
import os
import pathlib
import re
import secrets
import sys
import urllib.error
import urllib.request
import uuid

ROOT = pathlib.Path(__file__).resolve().parent.parent
PROJECT = os.environ.get("STAGING_SUPABASE_PROJECT_REF", "")
BASE = os.environ.get("STAGING_SUPABASE_URL", "").rstrip("/")
MANAGEMENT = os.environ.get("STAGING_SUPABASE_ACCESS_TOKEN", "")
PUBLIC_KEY = os.environ.get("STAGING_SUPABASE_PUBLISHABLE_KEY", "")
RUN = str(uuid.uuid4())


class ProbeError(Exception):
    pass


def require(condition, code):
    if not condition:
        raise ProbeError(code)


def call(url, headers, body=None, method=None):
    require(url.startswith(BASE + "/") or url.startswith("https://api.supabase.com/v1/projects/" + PROJECT + "/"),
            "probe_endpoint_invalid")
    request = urllib.request.Request(url, headers={"Content-Type": "application/json", **headers},
                                     method=method or ("GET" if body is None else "POST"),
                                     data=None if body is None else json.dumps(body).encode("utf-8"))
    try:
        response = urllib.request.urlopen(request, timeout=30)
    except urllib.error.HTTPError as error:
        response = error
    except (OSError, TimeoutError):
        raise ProbeError("probe_transport_unavailable") from None
    with response:
        raw = response.read(10 * 1024 * 1024 + 1)
        require(len(raw) <= 10 * 1024 * 1024, "probe_response_too_large")
        try:
            value = json.loads(raw) if raw else None
        except (ValueError, UnicodeError):
            raise ProbeError("probe_response_invalid") from None
        return response.status, value


def query(sql, read_only=False):
    status, value = call("https://api.supabase.com/v1/projects/" + PROJECT + "/database/query",
                         {"Authorization": "Bearer " + MANAGEMENT}, {"query": sql, "read_only": read_only})
    require(status == 200 and isinstance(value, list), "probe_database_failed")
    return value


def main():
    require(PROJECT == "vtmjkhzalalozpfnbvsd" and BASE == "https://" + PROJECT + ".supabase.co"
            and MANAGEMENT and PUBLIC_KEY, "registered_staging_required")
    bridge = (ROOT / "supabase/functions/execute-game-command/bundle.generated.ts").read_text(encoding="utf-8")
    match = re.search(r"export const ruleset = '([a-f0-9]{64})'", bridge)
    require(match is not None, "compiled_ruleset_missing")
    ruleset = match.group(1)
    fixture = json.loads((ROOT / "staging/game-fixture.json").read_text(encoding="utf-8"))["state"]
    fixture["eggAltar"]["wallet"] = {"fragments": 20, "essence": 2, "hearts": 0}
    fixture_hex = json.dumps(fixture, separators=(",", ":")).encode("utf-8").hex()
    original_coins = fixture["pet"]["coins"]
    original_title_chests = fixture["chestInventory"].get("title", 0)
    egg_id = fixture["eggStash"][0]["id"]
    require(re.fullmatch(r"[a-zA-Z0-9_-]{1,100}", egg_id) is not None, "fixture_identity_invalid")
    baseline = query("""select r.enabled, r.ruleset_sha256,
        (select count(*) from private.canonical_game_states) as copies,
        (select mutations_enabled from private.economy_contract where singleton) as mutations,
        (select count(*) from public.player_economy_authority where authority_mode <> 'legacy_client') as promoted
        from private.game_engine_runtime r where singleton""", True)[0]
    require(not baseline["enabled"] and baseline["copies"] == 0 and not baseline["mutations"]
            and baseline["promoted"] == 0, "probe_requires_empty_dormant_staging")
    old_ruleset = baseline["ruleset_sha256"]
    require(old_ruleset is None or re.fullmatch(r"[a-f0-9]{64}", old_ruleset), "probe_baseline_invalid")
    status, keys = call("https://api.supabase.com/v1/projects/" + PROJECT + "/api-keys?reveal=true",
                        {"Authorization": "Bearer " + MANAGEMENT})
    require(status == 200 and isinstance(keys, list), "probe_admin_configuration_missing")
    admin_key = next((key["api_key"] for key in keys if key.get("name") == "service_role"), None)
    require(isinstance(admin_key, str), "probe_admin_configuration_missing")
    admin_headers = {"Authorization": "Bearer " + admin_key, "apikey": admin_key}
    owners = []
    try:
        for ordinal in range(2):
            password = secrets.token_urlsafe(32) + "Dh7!"
            address = f"game-{RUN}-{ordinal}@dragonhaven-probe.invalid"
            status, created = call(BASE + "/auth/v1/admin/users", admin_headers, {
                "email": address, "password": password, "email_confirm": True,
                "app_metadata": {"dragonhaven_game_probe": RUN},
            })
            require(status in (200, 201) and created.get("email") == address
                    and created.get("email_confirmed_at"), "probe_account_creation_failed")
            owner = str(uuid.UUID(created["id"]))
            status, signed_in = call(BASE + "/auth/v1/token?grant_type=password", {"apikey": PUBLIC_KEY},
                                     {"email": address, "password": password})
            require(status == 200 and signed_in.get("user", {}).get("id") == owner
                    and isinstance(signed_in.get("access_token"), str), "probe_sign_in_failed")
            owners.append((owner, signed_in["access_token"]))
        owner, token = owners[0]
        outsider, outsider_token = owners[1]
        prepared = query(f"""begin;
          select set_config('request.jwt.claim.sub','{owner}',true);
          select set_config('request.jwt.claim.role','authenticated',true);
          select public.ensure_my_online_account();
          select set_config('request.jwt.claim.sub','{outsider}',true);
          select public.ensure_my_online_account();
          insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
            values('{owner}',1,convert_from(decode('{fixture_hex}','hex'),'utf8')::jsonb,'synthetic-game-worker','0.5.18',54);
          select set_config('request.jwt.claim.role','service_role',true);
          select public.stage_canonical_game_copy('{owner}',1,
            (select private.game_json_sha256(state) from public.cloud_game_saves where user_id='{owner}'));
          update private.game_engine_runtime set enabled=true, ruleset_sha256='{ruleset}' where singleton;
          commit;
          select private.game_json_sha256(c.state) as source_hash, to_jsonb(w) as wallet
            from public.cloud_game_saves c join public.player_wallets w on w.user_id=c.user_id where c.user_id='{owner}';""")[0]

        def command(action, payload=None, request_id=None, bearer=token, extra=None):
            request_body = {"protocol": 2, "clientBuild": 10068, "requestId": request_id or str(uuid.uuid4()),
                            "action": action, "payload": payload or {}}
            request_body.update(extra or {})
            headers = {"apikey": PUBLIC_KEY}
            if bearer:
                headers["Authorization"] = "Bearer " + bearer
            return call(BASE + "/functions/v1/execute-game-command", headers, request_body)

        require(command("refresh", bearer="")[0] == 401, "probe_anonymous_accepted")
        status, denied = command("refresh", bearer=outsider_token)
        require(status == 409 and denied.get("error") == "game_import_required", "probe_outsider_accepted")
        require(command("refresh", extra={"ownerId": outsider})[0] == 400, "probe_owner_injection_accepted")
        require(command("complete_trial", {"score": 999999})[0] == 400, "probe_score_injection_accepted")
        purchase_id = str(uuid.uuid4())
        status, purchased = command("purchase_title_chest", request_id=purchase_id)
        require(status == 200 and purchased.get("result") == "purchased" and purchased.get("server_revision") == 2,
                "probe_purchase_failed")
        status, replay = command("purchase_title_chest", request_id=purchase_id)
        require(status == 200 and replay.get("replayed") and
                {k: v for k, v in replay.items() if k != "replayed"} ==
                {k: v for k, v in purchased.items() if k != "replayed"}, "probe_replay_changed")
        require(command("purchase_portrait_chest", request_id=purchase_id)[0] == 409, "probe_conflict_accepted")
        opening_id = str(uuid.uuid4())
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
            futures = [pool.submit(command, "open_chests", {"tier": "wooden", "count": 2}, opening_id) for _ in range(2)]
            outcomes = [future.result() for future in futures]
        require(all(status in (200, 409) for status, _ in outcomes) and any(status == 200 for status, _ in outcomes),
                "probe_double_submit_failed")
        status, opened = command("open_chests", {"tier": "wooden", "count": 2}, opening_id)
        require(status == 200 and opened.get("replayed") and opened.get("server_revision") == 3, "probe_chest_replay_failed")
        encoded_receipt = json.dumps(opened)
        require(not any(key in encoded_receipt for key in ("lineageId", "hatchSeed", "secret_seed", "lease_token")),
                "probe_hidden_identity_exposed")
        require(command("tag_egg", {"eggId": egg_id, "tagged": True})[0] == 200, "probe_tag_failed")
        status, protected = command("return_egg", {"eggId": egg_id, "sinisterConfirmed": True})
        require(status == 422 and protected.get("error") == "egg_tagged", "probe_tag_did_not_protect")
        require(command("tag_egg", {"eggId": egg_id, "tagged": False})[0] == 200, "probe_untag_failed")
        status, unconfirmed = command("return_egg", {"eggId": egg_id, "sinisterConfirmed": False})
        require(status == 422 and unconfirmed.get("error") == "sinister_confirmation_required", "probe_sinister_confirmation_missing")
        require(command("return_egg", {"eggId": egg_id, "sinisterConfirmed": True})[0] == 200, "probe_return_failed")
        require(command("craft_altar_relic", {"relic": "nameweaversQuill"})[0] == 200, "probe_craft_failed")
        status, renamed = command("name_dragon", {"dragonId": fixture["pet"]["id"], "name": "Probe Weaver"})
        require(status == 200 and renamed.get("result") is True, "probe_rename_failed")
        final = query(f"""select c.state->'pet'->>'coins' as coins, c.state->'chestInventory'->>'title' as titles,
          c.state->'chestInventory'->>'wooden' as wooden,
          c.state->'eggAltar'->'wallet' as altar_wallet, c.state->'eggAltar'->'crafted' as crafted,
          c.state->'pet'->>'name' as dragon_name,
          (select count(*) from jsonb_array_elements(c.state->'eggStash') e where e->>'id'='{egg_id}') as egg_count,
          (select count(*) from private.canonical_game_intents where owner_id='{owner}' and status='processing') as pending,
          (select count(*) from private.canonical_game_intents where owner_id='{owner}' and status='succeeded') as successes,
          (select private.game_json_sha256(state) from public.cloud_game_saves where user_id='{owner}') as source_hash,
          (select to_jsonb(w) from public.player_wallets w where user_id='{owner}') as wallet,
          (select authority_mode from public.player_economy_authority where user_id='{owner}') as live_authority,
          (select mutations_enabled from private.economy_contract where singleton) as mutations
          from private.canonical_game_states c where owner_id='{owner}'""", True)[0]
        reward_coins = sum(reward["coins"] for reward in opened["result"]["rewards"])
        require(int(final["coins"]) == original_coins - 100 + reward_coins and
                int(final["titles"]) == original_title_chests + 1 and int(final["wooden"]) == 0,
                "probe_wallet_or_stock_changed_twice")
        require(final["altar_wallet"]["fragments"] == 35 and 4 <= final["altar_wallet"]["essence"] <= 6
                and 0 <= final["altar_wallet"]["hearts"] <= 1 and final["crafted"].get("nameweaversQuill") == 0
                and final["dragon_name"] == "Probe Weaver",
                "probe_altar_cost_or_reward_changed")
        require(final["egg_count"] == 0 and final["pending"] == 0 and final["successes"] == 7,
                "probe_intent_accounting_failed")
        require(final["source_hash"] == prepared["source_hash"] and final["wallet"] == prepared["wallet"]
                and final["live_authority"] == "legacy_client" and not final["mutations"], "probe_live_state_changed")
        print("PASS: real Auth/Edge/Dart/Postgres; purchases, concurrent chest replay, tags, Sinister return and quill; live save/wallet unchanged.", flush=True)
    finally:
        restore = "null" if old_ruleset is None else "'" + old_ruleset + "'"
        # The immutable run marker also finds an account whose admin-create
        # response was lost. Never delete a real account or another probe run.
        cleaned = query(f"""begin;
          do $$ begin
            if exists(select 1 from private.canonical_game_states c join auth.users u on u.id=c.owner_id
                where u.raw_app_meta_data->>'dragonhaven_game_probe' is distinct from '{RUN}') then
              raise exception 'probe_cleanup_other_owner';
            end if;
            if (select enabled and ruleset_sha256 is distinct from '{ruleset}' from private.game_engine_runtime where singleton) then
              raise exception 'probe_cleanup_runtime_changed';
            end if;
          end $$;
          update private.game_engine_runtime set enabled=false, ruleset_sha256={restore} where singleton;
          delete from auth.users where raw_app_meta_data->>'dragonhaven_game_probe'='{RUN}'
            and email like '%@dragonhaven-probe.invalid';
          commit;
          select (select count(*) from auth.users where raw_app_meta_data->>'dragonhaven_game_probe'='{RUN}') as accounts,
            (select count(*) from private.canonical_game_states) as copies,
            (select count(*) from private.canonical_game_intents) as intents,
            (select enabled from private.game_engine_runtime where singleton) as enabled;
        """)[0]
        require(cleaned == {"accounts": 0, "copies": 0, "intents": 0, "enabled": False}, "probe_cleanup_incomplete")
        print("CLEANUP: both synthetic accounts and shadow commands removed; game worker disabled.", flush=True)


if __name__ == "__main__":
    try:
        main()
    except ProbeError as error:
        print("FAIL: " + str(error), file=sys.stderr)
        sys.exit(1)
    except Exception:
        # Do not leak provider bodies, bearer tokens or synthetic passwords.
        print("FAIL: unexpected_game_probe_error", file=sys.stderr)
        sys.exit(1)
