"""One bounded, real Auth -> Edge -> Dart -> Postgres probe on isolated staging.

Only synthetic, auto-confirmed .invalid accounts are created; no email is sent.
Tokens and service keys stay in memory. No player save or secret is logged.
The worker operates exclusively on detached shadow copies, not live inventory.
"""
import concurrent.futures
import gzip
import json
import os
import pathlib
import re
import secrets
import subprocess
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
    request = urllib.request.Request(url, headers={"Content-Type": "application/json", "Accept": "application/json",
                                     "User-Agent": "DragonHaven-Staging-Probe/1.0", **headers},
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
        if response.headers.get("Content-Encoding") == "gzip":
            raw = gzip.decompress(raw)
            require(len(raw) <= 10 * 1024 * 1024, "probe_response_too_large")
        try:
            value = json.loads(raw) if raw else None
        except (ValueError, UnicodeError):
            # Safe transport diagnostics only: never include a response body,
            # URL query, header, email or request data.
            raise ProbeError(f"probe_response_invalid_http_{response.status}_bytes_{len(raw)}") from None
        return response.status, value


def query(sql, read_only=False):
    status, value = call("https://api.supabase.com/v1/projects/" + PROJECT + "/database/query",
                         {"Authorization": "Bearer " + MANAGEMENT}, {"query": sql, "read_only": read_only})
    code = value.get("code", "unknown") if isinstance(value, dict) else "unknown"
    if not isinstance(code, str) or re.fullmatch(r"[A-Z0-9]{5}", code) is None:
        code = "unknown"
    require(status in (200, 201) and isinstance(value, list), f"probe_database_failed_http_{status}_sql_{code}_type_{type(value).__name__}")
    return value


def main():
    prepare_import = sys.argv[1:] == ['--prepare-import']
    require(not sys.argv[1:] or prepare_import, "probe_arguments_invalid")
    require(PROJECT == "vtmjkhzalalozpfnbvsd" and BASE == "https://" + PROJECT + ".supabase.co"
            and MANAGEMENT and PUBLIC_KEY, "registered_staging_required")
    bridge = (ROOT / "supabase/functions/execute-game-command/bundle.generated.ts").read_text(encoding="utf-8")
    match = re.search(r"export const ruleset = '([a-f0-9]{64})'", bridge)
    require(match is not None, "compiled_ruleset_missing")
    ruleset = match.group(1)
    fixture = json.loads((ROOT / "staging/game-fixture.json").read_text(encoding="utf-8"))["state"]
    fixture["eggAltar"]["wallet"] = {"fragments": 20, "essence": 2, "hearts": 0}
    # Explicit synthetic test stock; never grant through a live player/drop path.
    brooches = ('twinstarBrooch', 'emberheartBrooch', 'moonweaveBrooch', 'soulbloomBrooch')
    for relic in brooches:
        fixture.setdefault('relicInventory', {})[relic] = 1
        fixture.setdefault('untradeableRelicInventory', {})[relic] = 1
    fixture['uniqueRelicsEverObtained'] = sorted(set(fixture.get('uniqueRelicsEverObtained', [])) | set(brooches))
    fixture['twinstarBroochEverObtained'] = True
    fixture['pet']['training'] = {'might': 60, 'arcana': 60, 'spirit': 60}
    fixture['pet']['highlightedExpertises'] = []
    fixture['ownedPortraitIds'] = ['portrait_001', 'portrait_002']
    fixture['selectedPortraitId'] = 'portrait_001'
    preference_dragon = json.loads(json.dumps(fixture['pet']))
    preference_dragon.update({'id': '77777777-7777-4777-8777-777777777777',
                             'name': 'Preference Probe', 'favorite': False})
    fixture['sanctuaryDragons'] = [preference_dragon]
    fixture['pet']['coins'] = 50000
    fixture['towerFloorRoomIds'] = ['hearth']
    fixture['dragonWardLevel'] = 0
    fixture['damagedTowerFloors'] = [0]
    # Match the valid post-damage state; never rely on read-time repair.
    for dragon in [fixture['pet'], *fixture['sanctuaryDragons']]:
        dragon['roamsTower'] = False
    fixture['damagedTowerRepairFactors'] = {'0': 0.60}
    fixture.setdefault('adventureOptionIds', {})['mini'] = ['mini_1']
    fixture['relicInventory']['wayfinderSigil'] = 1
    fixture['trialOffers'] = [{'id': 'staging-verified-ruin', 'kind': 'ruinBreaker',
                               'appearedAt': '2026-09-10T00:00:00.000Z',
                               'specialEventKey': None, 'startedAt': None}]
    fixture_hex = json.dumps(fixture, separators=(",", ":")).encode("utf-8").hex()
    original_coins = fixture["pet"]["coins"]
    original_title_chests = fixture["chestInventory"].get("title", 0)
    sinister_egg = next((egg for egg in fixture["eggStash"] if egg["lineageId"] == "sinisterra"), None)
    require(sinister_egg is not None, "fixture_sinister_egg_missing")
    egg_id = sinister_egg["id"]
    require(re.fullmatch(r"[a-zA-Z0-9_-]{1,100}", egg_id) is not None, "fixture_identity_invalid")
    baseline = query("""select r.enabled, r.shadow_social_enabled, r.ruleset_sha256,
        (select count(*) from private.canonical_game_states) as copies,
        (select mutations_enabled from private.economy_contract where singleton) as mutations,
        (select count(*) from public.player_economy_authority where authority_mode <> 'legacy_client') as promoted
        from private.game_engine_runtime r where singleton""", True)[0]
    require(not baseline["enabled"] and not baseline["shadow_social_enabled"] and baseline["copies"] == 0 and not baseline["mutations"]
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
    client_sessions = {}
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
            client_sessions[owner] = signed_in
        owner, token = owners[0]
        outsider, outsider_token = owners[1]
        source_expression = f"convert_from(decode('{fixture_hex}','hex'),'utf8')::jsonb"
        altar_fixture = ""
        if prepare_import:
            source_expression = f"jsonb_set({source_expression},'{{eggAltar,ownerId}}',to_jsonb('{owner}'::text))"
            altar_fixture = f"insert into private.egg_altar_accounts(owner_id,fragments,essence) values('{owner}',20,2);"
        prepared = query(f"""begin;
          select set_config('request.jwt.claim.sub','{owner}',true);
          select set_config('request.jwt.claim.role','authenticated',true);
          select public.ensure_my_online_account();
          select set_config('request.jwt.claim.sub','{outsider}',true);
          select public.ensure_my_online_account();
          insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
            values('{owner}',1,{source_expression},'synthetic-game-worker','0.5.18',54);
          {altar_fixture}
          select set_config('request.jwt.claim.role','service_role',true);
          select public.stage_canonical_game_copy('{owner}',1,
            (select private.game_json_sha256(state) from public.cloud_game_saves where user_id='{owner}'));
          update private.game_engine_runtime set enabled=true, ruleset_sha256='{ruleset}' where singleton;
          commit;
          select private.game_json_sha256(c.state) as source_hash, to_jsonb(w) as wallet
            from public.cloud_game_saves c join public.player_wallets w on w.user_id=c.user_id where c.user_id='{owner}';""")[0]
        if prepare_import:
            child_environment = {key: value for key, value in os.environ.items() if key not in (
                'STAGING_SUPABASE_ACCESS_TOKEN', 'SUPABASE_ACCESS_TOKEN', 'SUPABASE_DB_PASSWORD',
                'GITHUB_TOKEN', 'GH_TOKEN', 'STAGING_SUPABASE_DB_PASSWORD')}
            child_environment['STAGING_SUPABASE_SERVICE_ROLE_KEY'] = admin_key
            for replayed in (False, True):
                result = subprocess.run(['deno', 'run',
                    '--allow-env=STAGING_SUPABASE_URL,STAGING_SUPABASE_SERVICE_ROLE_KEY',
                    '--allow-net=vtmjkhzalalozpfnbvsd.supabase.co',
                    'tool/prepare_staging_game_import.ts', owner],
                    cwd=ROOT, env=child_environment, capture_output=True, text=True, timeout=45)
                if result.returncode != 0:
                    code = result.stderr.strip()
                    if re.fullmatch(r'game_[a-z_]+', code) is None:
                        code = 'game_import_unavailable'
                    raise ProbeError('probe_preparation_' + code)
                receipt = json.loads(result.stdout)
                require(receipt.get('prepared') and receipt.get('authority') == 'shadow'
                        and receipt.get('serverRevision') == 2 and receipt.get('replayed') is replayed,
                        'probe_preparation_receipt_failed')
            del child_environment['STAGING_SUPABASE_SERVICE_ROLE_KEY']
        revision_offset = 1 if prepare_import else 0
        observed_revision = 1 + revision_offset
        request_revisions = {}

        def command(action, payload=None, request_id=None, bearer=token, extra=None):
            nonlocal observed_revision
            request_id = request_id or str(uuid.uuid4())
            request_body = {"protocol": 2, "clientBuild": 10069, "requestId": request_id,
                            "expectedRevision": request_revisions.setdefault(request_id, observed_revision),
                            "action": action, "payload": payload or {}}
            request_body.update(extra or {})
            headers = {"apikey": PUBLIC_KEY}
            if bearer:
                headers["Authorization"] = "Bearer " + bearer
            status, result = call(BASE + "/functions/v1/execute-game-command", headers, request_body)
            if status == 200:
                observed_revision = max(observed_revision, result.get('server_revision', 0))
            return status, result

        def read_state(bearer=token, extra=None):
            request_body = {"protocol": 2, "clientBuild": 10068, "action": "read_state"}
            request_body.update(extra or {})
            return call(BASE + "/functions/v1/execute-game-command",
                        {"apikey": PUBLIC_KEY, "Authorization": "Bearer " + bearer}, request_body)

        require(read_state(outsider_token)[0] == 409, "probe_read_outsider_accepted")
        require(read_state(extra={"ownerId": outsider})[0] == 400, "probe_read_owner_injection_accepted")
        status, initial_view = read_state()
        require(status == 200 and initial_view.get("server_revision") == 1 + revision_offset
                and initial_view.get("authority_mode") == "shadow", "probe_initial_read_failed")
        require(type(initial_view.get('ruleset_revision')) is int and initial_view['ruleset_revision'] > 0,
                'probe_ruleset_revision_missing')
        for egg in initial_view['data']['eggs']:
            require(egg.get('lineageId') is None and 'hatchSeed' not in egg and 'spectral' not in egg,
                    'probe_read_hidden_egg_exposed')
        require('hatchSeed' not in json.dumps(initial_view['data']), 'probe_read_seed_exposed')

        require(command("refresh", bearer="")[0] == 401, "probe_anonymous_accepted")
        status, denied = command("refresh", bearer=outsider_token)
        require(status == 409 and denied.get("error") == "game_import_required", "probe_outsider_accepted")
        require(command("refresh", extra={"ownerId": outsider})[0] == 400, "probe_owner_injection_accepted")
        require(command("complete_trial", {"score": 999999})[0] == 400, "probe_score_injection_accepted")
        purchase_id = str(uuid.uuid4())
        status, purchased = command("purchase_title_chest", request_id=purchase_id)
        require(status == 200 and purchased.get("result") == "purchased" and purchased.get("server_revision") == 2 + revision_offset,
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
        require(status == 200 and opened.get("replayed") and opened.get("server_revision") == 3 + revision_offset, "probe_chest_replay_failed")
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
        query("update private.game_engine_runtime set enabled=false where singleton")
        status, paused_view = read_state()
        require(status == 200 and paused_view.get('mutations_enabled') is False
                and paused_view.get('server_revision') == renamed['server_revision'], 'probe_paused_read_failed')
        require(paused_view.get('ruleset_revision') == initial_view['ruleset_revision'], 'probe_pause_changed_ruleset')
        require(all(e['id'] != egg_id for e in paused_view['data']['eggs']), 'probe_read_resurrected_egg')
        require(next(d for d in paused_view['data']['dragons'] if d['id'] == fixture['pet']['id'])['name']
                == 'Probe Weaver', 'probe_read_rename_missing')
        status, paused_purchase = command('purchase_title_chest', request_id=purchase_id)
        require(status == 200 and paused_purchase.get('replayed') is True and
                {k: v for k, v in paused_purchase.items() if k != 'replayed'} ==
                {k: v for k, v in purchased.items() if k != 'replayed'}, 'probe_paused_receipt_failed')
        status, paused_refusal = command('return_egg', {'eggId': egg_id, 'sinisterConfirmed': True},
                                         request_id=protected['request_id'])
        require(status == 422 and paused_refusal.get('error') == 'egg_tagged'
                and paused_refusal.get('replayed') is True, 'probe_paused_refusal_failed')
        status, paused_new = command('purchase_title_chest')
        require(status == 503 and paused_new.get('error') == 'game_engine_disabled', 'probe_paused_new_command_accepted')
        def recover(request_id, bearer=token, extra=None):
            request_body = {'protocol': 2, 'clientBuild': 10069, 'action': 'recover_commands',
                            'requestId': request_id}
            request_body.update(extra or {})
            return call(BASE + '/functions/v1/execute-game-command',
                        {'apikey': PUBLIC_KEY, 'Authorization': 'Bearer ' + bearer}, request_body)

        recovery_id = str(uuid.uuid4())
        require(recover(recovery_id, outsider_token)[0] == 409, 'probe_recovery_outsider_accepted')
        require(recover(recovery_id, extra={'ownerId': outsider})[0] == 400, 'probe_recovery_owner_injection')
        status, recovered = recover(recovery_id)
        require(status == 200 and recovered['barrier_revision'] == observed_revision + 1
                and recovered['cancelled_commands'] == 0 and recovered['replayed'] is False,
                'probe_recovery_failed')
        status, repeated_recovery = recover(recovery_id)
        require(status == 200 and repeated_recovery['replayed'] is True and
                {k: v for k, v in recovered.items() if k != 'replayed'} ==
                {k: v for k, v in repeated_recovery.items() if k != 'replayed'}, 'probe_recovery_replay')
        query('update private.game_engine_runtime set enabled=true where singleton')
        status, stale = command('purchase_title_chest')
        require(status == 422 and stale.get('error') == 'game_state_changed', 'probe_late_request_accepted')
        pending_id = str(uuid.uuid4())
        boundary = recovered['barrier_revision']
        # Create an interrupted private worker lease for this synthetic account.
        # Only its status is returned; no state, seed or token leaves the query.
        require(query(f"""select set_config('request.jwt.claim.role','service_role',true);
          select public.begin_revisioned_game_command('{owner}','{pending_id}',
            'purchase_title_chest','{{}}',10069,'{ruleset}',{boundary})->>'status' as pending_status""")[-1]
            ['pending_status'] == 'processing', 'probe_pending_lease_failed')
        query('update private.game_engine_runtime set enabled=false where singleton')
        status, cancelled = recover(str(uuid.uuid4()))
        require(status == 200 and cancelled['cancelled_commands'] == 1
                and cancelled['barrier_revision'] == boundary + 1, 'probe_pending_recovery_failed')
        request_revisions[pending_id] = boundary
        status, cancelled_replay = command('purchase_title_chest', request_id=pending_id)
        require(status == 422 and cancelled_replay.get('error') == 'game_command_recovered'
                and cancelled_replay.get('replayed') is True, 'probe_cancelled_replay_failed')
        status, recovered_view = read_state()
        require(status == 200 and recovered_view['server_revision'] == boundary + 1
                and recovered_view['state_sha256'] == paused_view['state_sha256'], 'probe_recovery_changed_assets')
        status, committed_replay = command('purchase_title_chest', request_id=purchase_id)
        require(status == 200 and committed_replay.get('replayed') is True
                and committed_replay['server_revision'] == purchased['server_revision'], 'probe_recovery_lost_receipt')
        print('PASS: real authenticated recovery, idempotent barrier, stale request refusal and paused pending cancellation; assets unchanged.', flush=True)
        final = query(f"""select c.state->'pet'->>'coins' as coins, c.state->'chestInventory'->>'title' as titles,
          c.state->'chestInventory'->>'wooden' as wooden,
          c.state->'eggAltar'->'wallet' as altar_wallet, c.state->'eggAltar'->'crafted' as crafted,
          c.state->'pet'->>'name' as dragon_name,
          (select count(*) from jsonb_array_elements(c.state->'eggStash') e where e->>'id'='{egg_id}') as egg_count,
          (select count(*) from private.canonical_game_intents where owner_id='{owner}' and status='processing') as pending,
          (select count(*) from private.canonical_game_intents where owner_id='{owner}' and status='succeeded') as successes,
          (select s.state=i.source_state and s.revision=i.source_revision
            from public.cloud_game_saves s join private.canonical_game_imports i on i.owner_id=s.user_id
            where s.user_id='{owner}') as source_matches_import,
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
        require(final["source_matches_import"] and final["wallet"] == prepared["wallet"]
                and final["live_authority"] == "legacy_client" and not final["mutations"], "probe_live_state_changed")
        print("PASS: real Auth/Edge/Dart/Postgres; purchases, concurrent chest replay, tags, Sinister return and quill; live save/wallet unchanged.", flush=True)
        if prepare_import:
            print("PASS: captured authoritative Altar prepared and replayed before game commands; no migration reward grant.", flush=True)
        print("PASS: authenticated public projection hides egg genetics, reflects committed actions and reads while mutations are paused.", flush=True)
        print("PASS: paused worker recovers original success/failure receipts and refuses new mutations.", flush=True)
        # Separate server-owned, synthetic social sources. They are visible to
        # this account but are not paid until the final UI claim section.
        social_dragon = str(uuid.uuid4())
        partner_dragon = str(uuid.uuid4())
        group_source, pair_source, podium_source = (str(uuid.uuid4()) for _ in range(3))
        query(f"""begin;
          insert into public.player_dragons(id,owner_id,legacy_client_id,name,lineage_id,stage)
            select '{social_dragon}','{owner}',state->'pet'->>'id','Social Probe',
              state->'pet'->>'lineageId',state->'pet'->>'stage'
              from private.canonical_game_states where owner_id='{owner}';
          insert into public.player_dragons(id,owner_id,legacy_client_id,name,lineage_id,stage)
            values('{partner_dragon}','{outsider}','synthetic-partner','Partner Probe','copperflame','hatchling');
          insert into public.group_adventure_lobbies(id,slot,adventure_id,owner_id,status,required_players,
            focus,base_duration_minutes,xp,stat_points,started_at,ends_at,chest_tier)
            values('{group_source}',0,'group_1','{owner}','running',2,'spirit',60,400,5,
              now()-interval '2 hours',now()-interval '1 hour','dragon');
          insert into public.group_adventure_participants(lobby_id,user_id,dragon_id)
            values('{group_source}','{owner}','{social_dragon}'),('{group_source}','{outsider}','{partner_dragon}');
          insert into public.seasonal_pair_adventures(id,occurrence_key,creator_id,partner_id,
            creator_dragon_id,partner_dragon_id,creator_might,creator_arcana,creator_spirit,
            partner_might,partner_arcana,partner_spirit,status,started_at,ends_at)
            select '{pair_source}','valentine_two_heartlights:synthetic:{RUN}','{owner}','{outsider}',
              state->'pet'->>'id','synthetic-partner',10,10,10,10,10,10,'running',
              now()-interval '2 hours',now()-interval '1 hour' from private.canonical_game_states where owner_id='{owner}';
          insert into public.seasonal_event_prizes(id,event_id,occurrence_key,user_id,ranking_position,score,podium_emote_id)
            values('{podium_source}','sunwake_summer_sea','sunwake_summer_sea:synthetic:{RUN}','{owner}',1,30000,'seasonal_sunwake_gold');
          update private.game_engine_runtime set shadow_social_enabled=true where singleton;
          commit;""")
        # Exercise the actual Flutter SDK transport/session and filesystem
        # journals. This child receives no management/service/database secrets.
        query('update private.game_engine_runtime set enabled=true where singleton')
        child_environment = {key: value for key, value in os.environ.items()
            if not any(part in key.upper() for part in ('SECRET', 'TOKEN', 'PASSWORD', 'SUPABASE', 'KEY'))}
        child_environment.update({
            'STAGING_SUPABASE_PROJECT_REF': PROJECT, 'STAGING_SUPABASE_URL': BASE,
            'STAGING_SUPABASE_PUBLISHABLE_KEY': PUBLIC_KEY,
            'STAGING_GAME_CLIENT_SESSION': json.dumps(client_sessions[owner]),
            'STAGING_GAME_PROBE_RUN': RUN,
        })
        client_result = subprocess.run(['flutter', 'test', '--no-pub',
            'tool/canonical_game_session_probe.dart'], cwd=ROOT, env=child_environment,
            capture_output=True, text=True, timeout=600)
        del child_environment['STAGING_GAME_CLIENT_SESSION']
        if client_result.returncode != 0:
            # Only fixed phase markers and timeout status may leave the child.
            # Never print arbitrary SDK exceptions, state or session tokens.
            for phase in re.findall(r'PROBE: ([a-z_]+)', client_result.stdout):
                print('PROBE: ' + phase, flush=True)
            if 'TimeoutException' in client_result.stdout + client_result.stderr:
                print('PROBE: client_test_timeout', flush=True)
            match = re.search(r'client_probe_[a-z_]+', client_result.stdout + client_result.stderr)
            raise ProbeError(match.group(0) if match else 'client_probe_failed')
        require('PASS: real SDK/session/journals;' in client_result.stdout, 'client_probe_proof_missing')
        require('PASS: real shop UI purchase,' in client_result.stdout, 'client_probe_ui_proof_missing')
        require('PASS: real lifecycle UI;' in client_result.stdout, 'client_probe_lifecycle_proof_missing')
        require('PASS: real adventure UI;' in client_result.stdout, 'client_probe_adventure_proof_missing')
        require('PASS: real house UI;' in client_result.stdout, 'client_probe_house_proof_missing')
        require('PASS: real room editor;' in client_result.stdout, 'client_probe_room_editor_proof_missing')
        require('PASS: real roaming UI;' in client_result.stdout, 'client_probe_roaming_proof_missing')
        require('PASS: real care UI;' in client_result.stdout, 'client_probe_care_proof_missing')
        require('PASS: real profile and room UI;' in client_result.stdout, 'client_probe_cosmetic_proof_missing')
        require('PASS: real milestone UI;' in client_result.stdout, 'client_probe_milestone_proof_missing')
        require('PASS: real Academy UI;' in client_result.stdout, 'client_probe_school_proof_missing')
        require('PASS: real Trial selection' in client_result.stdout, 'client_probe_trial_proof_missing')
        require('PASS: real social claim UI;' in client_result.stdout, 'client_probe_social_proof_missing')
        social_ack = query(f"""select
          (select reward_acknowledged_at is not null from public.group_adventure_participants
            where lobby_id='{group_source}' and user_id='{owner}') as own_group,
          (select reward_acknowledged_at is null from public.group_adventure_participants
            where lobby_id='{group_source}' and user_id='{outsider}') as partner_group,
          (select creator_reward_claimed_at is not null and partner_reward_claimed_at is null and status='reward_ready'
            from public.seasonal_pair_adventures where id='{pair_source}') as pair,
          (select claimed_at is not null from public.seasonal_event_prizes where id='{podium_source}') as podium,
          (select count(*) from public.social_notifications where entity_id='{pair_source}' and kind='seasonal_pair_ready') as notifications
        """, True)[0]
        require(social_ack == {'own_group': True, 'partner_group': True, 'pair': True, 'podium': True, 'notifications': 2},
                'client_probe_social_ack_failed')
        print('PASS: actual social reward UI; group, partner and podium rewards committed once with their source acknowledgments.', flush=True)
        require('PASS: real preferences UI;' in client_result.stdout, 'client_probe_preferences_proof_missing')
        unchanged = query(f"""select
          (select s.state=i.source_state and s.revision=i.source_revision
            from public.cloud_game_saves s join private.canonical_game_imports i on i.owner_id=s.user_id
            where s.user_id='{owner}') as source_matches_import,
          (select to_jsonb(w) from public.player_wallets w where user_id='{owner}') as wallet,
          (select authority_mode from public.player_economy_authority where user_id='{owner}') as authority,
          (select mutations_enabled from private.economy_contract where singleton) as mutations
        """, True)[0]
        require(unchanged['source_matches_import'] and unchanged['wallet'] == prepared['wallet']
                and unchanged['authority'] == 'legacy_client' and not unchanged['mutations'],
                'client_probe_ui_changed_live_state')
        print('PASS: actual shop UI purchase and chest reveal; one debit and one earned title.', flush=True)
        print('PASS: actual lifecycle UI; Sinister return, crafting, discovery, tags, incubation, rename and equipment.', flush=True)
        print('PASS: actual adventure UI; server deadline, lost claim recovery, one reward, abort and Wayfinder.', flush=True)
        print('PASS: actual house UI; stored repair price, ward upgrade, floor purchase and free room selection.', flush=True)
        print('PASS: actual preferences UI; expertise highlights, adventure information and one favorite.', flush=True)
        print('PASS: actual house editor, roaming and care UI; layout and needs preserved, one treat debit.', flush=True)
        print('PASS: actual Flutter client, Supabase Auth, filesystem journals and server; one charge after lost reply; corrupt request recovery without another purchase.', flush=True)
        from staging_group_probe import run_group_probe
        run_group_probe(root=ROOT, project=PROJECT, base=BASE, public_key=PUBLIC_KEY,
            run=RUN, fixture=fixture, admin_headers=admin_headers, call=call, query=query, require=require)
        from staging_pair_probe import run_pair_probe
        run_pair_probe(root=ROOT, project=PROJECT, base=BASE, public_key=PUBLIC_KEY,
            run=RUN, fixture=fixture, admin_headers=admin_headers, call=call, query=query, require=require)
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
          update private.game_engine_runtime set enabled=false, shadow_social_enabled=false, shadow_projection_enabled=false, shadow_lifecycle_enabled=false, ruleset_sha256={restore} where singleton;
          select set_config('request.jwt.claim.role','service_role',true);
          delete from auth.users where raw_app_meta_data->>'dragonhaven_game_probe'='{RUN}'
            and email like '%@dragonhaven-probe.invalid';
          commit;
          select (select count(*) from auth.users where raw_app_meta_data->>'dragonhaven_game_probe'='{RUN}') as accounts,
            (select count(*) from private.canonical_game_states) as copies,
            (select count(*) from private.canonical_game_intents) as intents,
            (select count(*) from private.canonical_game_recoveries) as recoveries,
            (select enabled or shadow_social_enabled or shadow_projection_enabled or shadow_lifecycle_enabled from private.game_engine_runtime where singleton) as enabled;
        """)[0]
        require(cleaned == {"accounts": 0, "copies": 0, "intents": 0, "recoveries": 0, "enabled": False}, "probe_cleanup_incomplete")
        print("CLEANUP: all synthetic accounts and shadow commands removed; all four worker/social switches disabled.", flush=True)


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
