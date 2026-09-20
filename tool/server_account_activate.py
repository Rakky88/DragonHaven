"""Activate the reviewed account cutover only after its APK is publicly ready.

Performs a production smoke test using one auto-confirmed .invalid account,
then removes only that marked synthetic account. No email is sent. A failed
probe pauses migrations and commands; it never rolls a player back to legacy.
"""
import argparse
import json
import os
from pathlib import Path
import re
import secrets
import urllib.error
import urllib.request
import uuid


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--enable-and-probe', action='store_true', required=True)
    parser.add_argument('--apk-sha256', required=True)
    args = parser.parse_args()
    project = 'tnzathhutuwmohmjfrlo'
    base = f'https://{project}.supabase.co'
    root = Path(__file__).resolve().parent.parent
    rules = re.search(r"ruleset = '([a-f0-9]{64})'", (root / 'supabase/functions/execute-game-command/bundle.generated.ts').read_text())[1]
    if not re.fullmatch('[a-f0-9]{64}', args.apk_sha256):
        raise RuntimeError('invalid_artifact_hash')
    token = os.environ['SUPABASE_ACCESS_TOKEN']

    def call(url, headers, data=None, method=None):
        request = urllib.request.Request(url,
            data=None if data is None else json.dumps(data).encode(), method=method,
            headers={'Content-Type': 'application/json', 'User-Agent': 'DragonHaven-Cutover-Verification', **headers})
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                raw = response.read()
                return json.loads(raw) if raw else None
        except urllib.error.HTTPError:
            raise RuntimeError('cutover_http_failure') from None

    management = {'Authorization': 'Bearer ' + token}
    def query(sql):
        return call(f'https://api.supabase.com/v1/projects/{project}/database/query', management,
            {'query': sql, 'read_only': False})

    release = call('https://api.github.com/repos/Rakky88/DragonHaven/releases/latest', {})
    asset = next((a for a in release.get('assets', []) if a['name'] == 'DragonHaven.apk'), {})
    if release.get('tag_name') != 'v0.05.42' or asset.get('digest') != 'sha256:' + args.apk_sha256:
        raise RuntimeError('compatible_public_release_not_verified')
    local = [p.name.split('_')[0] for p in sorted((root / 'supabase/migrations').glob('*.sql'))]
    remote = [r['version'] for r in query('select version from supabase_migrations.schema_migrations order by version')]
    if len(local) != 92 or remote != local:
        raise RuntimeError('cutover_schema_mismatch')
    runtime = query('select to_jsonb(r) as runtime from private.game_engine_runtime r where singleton')[0]['runtime']
    if any(runtime[k] for k in ['shadow_social_enabled', 'shadow_projection_enabled', 'shadow_lifecycle_enabled']):
        raise RuntimeError('cutover_shadow_switch_enabled')
    if runtime['enabled'] or runtime['migration_enabled']:
        if not (runtime['enabled'] and runtime['migration_enabled'] and runtime['ruleset_sha256'] == rules
            and runtime['minimum_client_build'] == 10092):
            raise RuntimeError('cutover_runtime_not_reviewed')
    else:
        query(f"""begin; set local lock_timeout='5s';
update private.game_engine_runtime set enabled=true,migration_enabled=true,
 minimum_client_build=10092,ruleset_revision=case when ruleset_sha256 is null or ruleset_sha256='{rules}' then ruleset_revision else ruleset_revision+1 end,
 ruleset_sha256='{rules}',updated_at=now() where singleton;
commit;""")

    owner = None
    run = uuid.uuid4().hex
    try:
        keys = call(f'https://api.supabase.com/v1/projects/{project}/api-keys?reveal=true', management)
        admin_key = next(k['api_key'] for k in keys if k['name'] == 'service_role')
        public_key = next(k['api_key'] for k in keys if k['name'] == 'anon')
        email = run + '@dragonhaven-cutover.invalid'
        password = secrets.token_urlsafe(30)
        admin = {'apikey': admin_key, 'Authorization': 'Bearer ' + admin_key}
        created = call(base + '/auth/v1/admin/users', admin, {'email': email, 'password': password,
            'email_confirm': True, 'app_metadata': {'dragonhaven_cutover_probe': run}})
        owner = str(uuid.UUID(created['id']))

        def login():
            signed = call(base + '/auth/v1/token?grant_type=password', {'apikey': public_key},
                {'email': email, 'password': password})
            return {'apikey': public_key, 'Authorization': 'Bearer ' + signed['access_token']}
        def rpc(headers, name, payload):
            return call(base + '/rest/v1/rpc/' + name, headers, payload)
        def edge(headers, action, **payload):
            return call(base + '/functions/v1/execute-game-command', headers,
                {'protocol': 2, 'clientBuild': 10092, 'action': action, **payload})
        phone = login()
        rpc(phone, 'ensure_my_online_account', {})
        rpc(phone, 'acknowledge_my_privacy_notice', {'p_version': '2026-09-20', 'p_age_16_confirmed': True})
        request = str(uuid.uuid4())
        first = edge(phone, 'initialize_account', requestId=request)
        retry = edge(phone, 'initialize_account', requestId=request)
        if first['server_revision'] != retry['server_revision']:
            raise RuntimeError('cutover_initialization_replayed_twice')
        before = edge(phone, 'read_state')
        edge(phone, 'complete_onboarding', requestId=str(uuid.uuid4()), expectedRevision=before['server_revision'],
            payload={'name': 'Cutover verification'})
        before = edge(phone, 'read_state')
        other_phone = login()
        rpc(other_phone, 'ensure_my_online_account', {})
        rpc(other_phone, 'get_online_snapshot', {})
        after = edge(other_phone, 'read_state')
        if before['data'] != after['data'] or before['state_sha256'] != after['state_sha256']:
            raise RuntimeError('cutover_restore_mismatch')
        if after['authority_mode'] != 'server' or not after['mutations_enabled']:
            raise RuntimeError('cutover_authority_invalid')
        print(json.dumps({'production_cutover': 'verified', 'minimum_client_build': 10092,
            'ruleset_sha256': rules, 'fresh_account': True, 'reinstall_restore': True,
            'initialization_retry': True}))
    except Exception:
        query('update private.game_engine_runtime set enabled=false,migration_enabled=false,updated_at=now() where singleton')
        print('Production migrations and commands paused after a failed synthetic check; account states retained.')
        raise
    finally:
        # Also covers an Auth creation whose successful reply was lost.
        query(f"begin; select set_config('request.jwt.claim.role','service_role',true); delete from auth.users where raw_app_meta_data->>'dragonhaven_cutover_probe'='{run}' and email like '%@dragonhaven-cutover.invalid'; commit;")
        if query(f"select count(*)::int as n from auth.users where raw_app_meta_data->>'dragonhaven_cutover_probe'='{run}'")[0]['n']:
            raise RuntimeError('cutover_probe_cleanup_failed')
        print('Synthetic production account removed; no player account was edited.')


if __name__ == '__main__':
    main()
