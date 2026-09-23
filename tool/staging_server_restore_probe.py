"""Fresh server account + empty second device, using disposable staging users.

Never prints credentials, account saves, emails, or private egg properties.
Requires a dormant staging runtime; restores it and deletes only this run's users.
"""
import json
import os
from pathlib import Path
import re
import secrets
import sys
import urllib.request
import urllib.error
import uuid

PROJECT = 'vtmjkhzalalozpfnbvsd'
BASE = f'https://{PROJECT}.supabase.co'
ROOT = Path(__file__).resolve().parent.parent


def require(value, label):
    if not value:
        raise RuntimeError(label)


def call(url, headers, body=None):
    request = urllib.request.Request(url, headers={'Content-Type': 'application/json', **headers},
        data=None if body is None else json.dumps(body).encode())
    try:
        response = urllib.request.urlopen(request, timeout=55)
    except urllib.error.HTTPError as error:
        response = error
    with response:
        raw = response.read()
        return response.status, json.loads(raw) if raw else None


def main():
    token = os.environ.get('STAGING_SUPABASE_ACCESS_TOKEN')
    require(token and os.environ.get('STAGING_SUPABASE_PROJECT_REF') == PROJECT, 'registered_staging_required')
    management = {'Authorization': f'Bearer {token}'}

    def query(sql):
        code, result = call(f'https://api.supabase.com/v1/projects/{PROJECT}/database/query', management,
            {'query': sql, 'read_only': False})
        require(code in (200, 201) and isinstance(result, list), 'staging_query_failed')
        return result

    old = query('select to_jsonb(r) as runtime from private.game_engine_runtime r where singleton')[0]['runtime']
    switches = ['enabled', 'shadow_social_enabled', 'shadow_projection_enabled', 'shadow_lifecycle_enabled', 'migration_enabled']
    require(not any(old[k] for k in switches), 'staging_runtime_not_dormant')
    require(query('select count(*)::int as n from private.canonical_game_states')[0]['n'] == 0,
        'staging_has_existing_canonical_accounts')
    code, keys = call(f'https://api.supabase.com/v1/projects/{PROJECT}/api-keys?reveal=true', management)
    require(code == 200, 'staging_keys_unavailable')
    admin_key = next(k['api_key'] for k in keys if k['name'] == 'service_role')
    public_key = next(k['api_key'] for k in keys if k['name'] == 'anon')
    admin = {'Authorization': f'Bearer {admin_key}', 'apikey': admin_key}
    rules = re.search(r"ruleset = '([a-f0-9]{64})'", (ROOT / 'supabase/functions/execute-game-command/bundle.generated.ts').read_text()).group(1)
    run = uuid.uuid4().hex
    build = 10092
    checks = []
    conclaves = []

    def login(email, password):
        code, signed = call(BASE + '/auth/v1/token?grant_type=password', {'apikey': public_key},
            {'email': email, 'password': password})
        require(code == 200, 'staging_login_failed')
        return {'apikey': public_key, 'Authorization': 'Bearer ' + signed['access_token']}

    def rpc(headers, name, data, expected=200):
        code, result = call(BASE + '/rest/v1/rpc/' + name, headers, data)
        require(code == expected or (expected == 200 and code == 204), 'rpc_' + name + '_failed')
        return result

    def edge(headers, action, **data):
        code, result = call(BASE + '/functions/v1/execute-game-command', headers,
            {'protocol': 2, 'clientBuild': build, 'action': action, **data})
        if code != 200:
            error = result.get('error', '') if isinstance(result, dict) else ''
            safe = error if re.fullmatch(r'[a-z_]+', error) else 'unknown'
            raise RuntimeError('edge_' + action + '_' + safe)
        return result

    def command(headers, view, action, payload, request=None):
        return edge(headers, action, expectedRevision=view['server_revision'],
            requestId=request or str(uuid.uuid4()), payload=payload)

    try:
        # Shadow writes must stay disabled during capture/preparation. Active
        # server accounts project and settle through their authority instead.
        query("update private.game_engine_runtime set enabled=true,migration_enabled=true" +
            f",ruleset_sha256='{rules}',minimum_client_build={build} where singleton")
        for kind in ['fresh', 'legacy']:
            email = f'{kind}-{run}@dragonhaven-restore.invalid'
            password = secrets.token_urlsafe(36) + 'Dh7!'
            code, created = call(BASE + '/auth/v1/admin/users', admin, {'email': email,
                'password': password, 'email_confirm': True, 'app_metadata': {'dragonhaven_restore_probe': run}})
            require(code in (200, 201), 'staging_user_create_failed')
            owner = str(uuid.UUID(created['id']))
            phone = login(email, password)
            rpc(phone, 'ensure_my_online_account', {})
            rpc(phone, 'acknowledge_my_privacy_notice', {'p_version': '2026-09-23', 'p_age_16_confirmed': True})
            if kind == 'legacy':
                fixture = json.loads((ROOT / 'staging/game-fixture.json').read_text())['state']
                fixture['onboardingComplete'] = True
                fixture['accountName'] = 'Migration Keeper'
                fixture['eggAltar']['ownerId'] = owner
                fixture['eggAltar']['wallet'] = {'fragments': 817, 'essence': 36, 'hearts': 4}
                fixture['relicInventory']['astralLens'] = 5
                fixture['untradeableRelicInventory']['astralLens'] = 2
                fixture['futureRestorationMetadata'] = {'retained': True}
                fixture['pet']['trialHighScores'] = {'ruinBreaker': 12770, 'cavernFlight': 8138}
                raw = json.dumps(fixture).encode().hex()
                query(f"""begin;
                  insert into private.egg_altar_accounts(owner_id,fragments,essence,hearts) values('{owner}',817,36,4);
                  insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
                    values('{owner}',1,convert_from(decode('{raw}','hex'),'utf8')::jsonb,'synthetic-restore','0.05.41',54);
                  commit;""")
                request = str(uuid.uuid4())
                activated = edge(phone, 'migrate_account', requestId=request, sourceRevision=1)
                replay = edge(phone, 'migrate_account', requestId=request, sourceRevision=1)
            else:
                request = str(uuid.uuid4())
                activated = edge(phone, 'initialize_account', requestId=request)
                replay = edge(phone, 'initialize_account', requestId=request)
            require(activated['phase'] == 'active' and replay['server_revision'] == activated['server_revision'], kind + '_activation_replayed')
            view = edge(phone, 'read_state')
            require(view['authority_mode'] == 'server', kind + '_authority')
            if kind == 'fresh':
                egg_id = view['data']['eggs'][0]['id']
                require(view['data']['collection']['onboardingComplete'] is False, 'fresh_onboarding')
                command(phone, view, 'complete_onboarding', {'name': 'Restore Keeper'})
                view = edge(phone, 'read_state')
                require(view['data']['eggs'][0]['id'] == egg_id, 'fresh_egg_changed')
                require(view['data']['collection']['accountName'] == 'Restore Keeper', 'fresh_name')
            else:
                inventory = view['data']['inventory']
                require(inventory['altar']['wallet'] == {'fragments': 817, 'essence': 36, 'hearts': 4}, 'altar_materials')
                require(inventory['relicInventory']['astralLens'] == 5 and inventory['untradeableRelicInventory']['astralLens'] == 2,
                    'relic_tradeability')
                command(phone, view, 'refresh', {})
                view = edge(phone, 'read_state')
                egg = next(e for e in view['data']['eggs'] if e['location'] == 'stash')
                command(phone, view, 'tag_egg', {'eggId': egg['id'], 'tagged': True})
                view = edge(phone, 'read_state')
                dragon = next(d for d in view['data']['dragons'] if d['location'] != 'released' and d['activeAdventureId'] is None)
                offer = view['data']['adventures']['adventureOptionIds']['mini'][0]
                command(phone, view, 'start_adventure', {'adventureId': offer, 'dragonId': dragon['id']})
                view = edge(phone, 'read_state')
                require(any(r['dragonId'] == dragon['id'] for r in view['data']['adventures']['runs']), 'active_adventure_started')
            request = str(uuid.uuid4())
            receipt = command(phone, view, 'set_preferences', {'changes': json.dumps({'languageCode': 'nl', 'musicEnabled': False})}, request)
            replay = command(phone, view, 'set_preferences', {'changes': json.dumps({'languageCode': 'nl', 'musicEnabled': False})}, request)
            require(receipt['server_revision'] == replay['server_revision'], kind + '_lost_reply_duplicate')
            first = edge(phone, 'read_state')
            # Only this run's isolated Conclave: confirmed achievement sharing
            # and read receipts must survive a completely new login too.
            cid = str(uuid.uuid4())
            mid = str(uuid.uuid4())
            conclaves.append(cid)
            query(f"begin; insert into public.conclaves(id,name,emblem_key,language,visibility,member_limit,created_by) values('{cid}','Restore {cid[:20]}','conclave_emblem_01','en','invite',4,'{owner}'); "
                f"insert into public.conclave_members(conclave_id,user_id,role) values('{cid}','{owner}','flightmaster'); "
                f"update public.profiles set share_achievements_with_conclave=true where user_id='{owner}'; "
                f"insert into public.conclave_messages(id,conclave_id,sender_id,kind,body) values('{mid}','{cid}','{owner}','text','Synthetic restore probe'); commit;")
            achievements = first['data']['collection']['achievements']
            shared = rpc(phone, 'synchronize_conclave_achievements', {'p_achievement_ids': [*achievements, 'invented_probe_achievement']})
            require(shared == len(achievements), kind + '_unconfirmed_achievement_shared')
            rpc(phone, 'mark_my_conclave_messages_read', {'p_message_ids': [mid]})
            second_phone = login(email, password)
            rpc(second_phone, 'ensure_my_online_account', {})
            rpc(second_phone, 'get_online_snapshot', {})
            chat = rpc(second_phone, 'get_my_conclave_snapshot', {})
            require(mid in chat['read_message_ids'], kind + '_read_receipt_not_restored')
            second = edge(second_phone, 'read_state')
            require(first['data'] == second['data'] and first['state_sha256'] == second['state_sha256'], kind + '_reinstall_state')
            require('hatchSeed' not in json.dumps(second['data']), kind + '_private_genetics')
            status = rpc(second_phone, 'get_my_server_gameplay_status', {'p_client_build': build, 'p_gameplay_protocol': 1})
            require(status['phase'] == 'active', kind + '_status')
            social = rpc(second_phone, 'get_my_profile', {})[0]
            collection = second['data']['collection']
            require(social['display_name'] == collection['accountName'], kind + '_social_name')
            require(social['portrait_key'] == collection['selectedPortraitId'] and social['title'] == collection['selectedTitleId'],
                kind + '_social_cosmetics')
            require(social['achievement_count'] == len(collection['achievements']), kind + '_social_achievements')
            code, _ = call(BASE + '/rest/v1/rpc/update_my_profile', second_phone,
                {'p_display_name': 'Old app overwrite', 'p_title': 'title_001', 'p_portrait_key': 'portrait_001'})
            require(code != 200 and code != 204, kind + '_legacy_profile_not_fenced')
            code, _ = call(BASE + '/rest/v1/rpc/get_my_online_session_status', second_phone, {})
            require(code != 200, kind + '_old_client_not_fenced')
            code, stale = call(BASE + '/functions/v1/execute-game-command', phone, {'protocol': 2, 'clientBuild': build,
                'requestId': str(uuid.uuid4()), 'expectedRevision': view['server_revision'],
                'action': 'set_account_name', 'payload': {'name': 'Stale overwrite'}})
            require((code, stale.get('error')) in [(409, 'game_revision_conflict'), (422, 'game_state_changed')],
                kind + '_stale_device_not_fenced')
            checks.append(kind)
            print('PASS: ' + kind + ' creation/migration, materials, ownership, reply retry, second login and stale-device fence.', flush=True)
    finally:
        # Restore precisely the flags/hash/build captured before this bounded run.
        values = {k: old[k] for k in [*switches, 'ruleset_sha256', 'minimum_client_build']}
        def literal(value):
            if value is None: return 'null'
            if isinstance(value, bool): return str(value).lower()
            if isinstance(value, int): return str(value)
            require(bool(re.fullmatch('[a-f0-9]{64}', value)), 'unsafe_runtime_hash')
            return "'" + value + "'"
        conclave_ids = ','.join("'" + str(uuid.UUID(cid)) + "'" for cid in conclaves)
        cleanup_conclaves = f"delete from public.conclaves where id in ({conclave_ids}); " if conclaves else ''
        query('begin; update private.game_engine_runtime set ' + ','.join(k + '=' + literal(v) for k, v in values.items()) +
            f" where singleton; {cleanup_conclaves} delete from auth.users where raw_app_meta_data->>'dragonhaven_restore_probe'='{run}' and email like '%@dragonhaven-restore.invalid'; commit;")
        remaining = query(f"select count(*)::int as n from auth.users where raw_app_meta_data->>'dragonhaven_restore_probe'='{run}'")[0]['n']
        require(remaining == 0, 'staging_cleanup_failed')
        print('CLEANUP: synthetic accounts removed; previous runtime flags restored.', flush=True)
    require(checks == ['fresh', 'legacy'], 'probe_incomplete')


if __name__ == '__main__':
    try:
        main()
    except RuntimeError as error:
        label = str(error)
        print('FAIL: ' + (label if re.fullmatch('[a-z_]+', label) else 'unexpected_restore_probe_failure'))
        sys.exit(1)
    except Exception as error:
        import traceback
        frames = traceback.extract_tb(error.__traceback__)
        print('FAIL: unexpected_restore_probe_failure ' + type(error).__name__ +
            ' at ' + ','.join(str(frame.lineno) for frame in frames if Path(frame.filename).name == Path(__file__).name))
        sys.exit(1)
