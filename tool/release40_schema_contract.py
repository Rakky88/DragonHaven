"""Bounded release-40 rehearsal. Every synthetic fixture is rolled back."""
import argparse
import json
import os
from pathlib import Path
import re
import urllib.error
import urllib.request


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--phase', choices=['before', 'after'], required=True)
    args = parser.parse_args()
    environment = os.environ.get('RELEASE_ENVIRONMENT')
    project = os.environ.get('RELEASE_PROJECT_REF')
    expected = {'staging': 'vtmjkhzalalozpfnbvsd', 'production': 'tnzathhutuwmohmjfrlo'}
    token = os.environ.get('SUPABASE_ACCESS_TOKEN')
    if environment not in expected or project != expected[environment] or not token:
        raise RuntimeError('release40_configuration_invalid')

    def query(sql, readonly=False):
        request = urllib.request.Request(
            f'https://api.supabase.com/v1/projects/{project}/database/query',
            data=json.dumps({'query': sql, 'read_only': readonly}).encode(),
            headers={'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'},
            method='POST')
        try:
            with urllib.request.urlopen(request, timeout=90) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            body = error.read().decode('utf-8', errors='replace')
            assertion = re.search(r'\b(?:expertise|chime|uncapped|event_points)_contract_[a-z_]+\b', body)
            state = re.search(r'ERROR:\s+([0-9A-Z]{5}):', body)
            if assertion:
                print('Failed assertion:', assertion[0])
            if state:
                print('SQL state:', state[1])
            raise RuntimeError('release40_contract_query_failed') from None

    files = sorted(Path('supabase/migrations').glob('*.sql'))
    local = [p.name.split('_')[0] for p in files]
    if len(local) != 87 or local[-1:] != ['202609200087']:
        raise RuntimeError('release40_local_history_invalid')
    versions = [r['version'] for r in query(
        'select version from supabase_migrations.schema_migrations order by version', True)]
    if len(versions) not in range(86, 88) or versions != local[:len(versions)]:
        raise RuntimeError('release40_remote_history_invalid')
    if args.phase == 'after' and versions != local:
        raise RuntimeError('release40_apply_incomplete')
    authority = query('''select r.enabled, r.migration_enabled,
        r.shadow_social_enabled, r.shadow_projection_enabled, r.shadow_lifecycle_enabled,
        e.mutations_enabled,
        (select count(*) from private.canonical_game_states where authority_mode='server') as server_accounts
        from private.game_engine_runtime r cross join private.economy_contract e
        where r.singleton and e.singleton''', True)
    if len(authority) != 1 or any(authority[0].values()):
        raise RuntimeError('release40_requires_dormant_authority')
    folder = Path('release40-schema')
    folder.mkdir(exist_ok=True)
    if args.phase == 'before':
        (folder / 'authority-before.json').write_text(json.dumps(authority), encoding='utf-8')
    elif json.loads((folder / 'authority-before.json').read_text(encoding='utf-8')) != authority:
        raise RuntimeError('release40_authority_changed')
    migrations = '\n'.join(p.read_text(encoding='utf-8') for p in files[len(versions):])
    for name, field in [
        ('shared_expertise_contract', 'shared_expertise_contract_passed'),
        ('uncapped_seasonal_contract', 'uncapped_contract_passed'),
        ('endless_chime_contract', 'chime_contract_passed'),
        ('canonical_event_points_contract', 'canonical_event_points_passed'),
    ]:
        contract = Path(f'tool/{name}.sql').read_text(encoding='utf-8')
        contract = re.sub(r'(?m)^begin;\s*\n', '', contract, count=1)
        result = query("begin; set local statement_timeout='45s';\n" + migrations + '\n' + contract)
        if result != [{field: True}]:
            raise RuntimeError('release40_rollback_not_confirmed')
        print(f'PASS {environment} {args.phase}: {name}; synthetic_changes_rolled_back=true')
    if query('select version from supabase_migrations.schema_migrations order by version', True) != [
            {'version': v} for v in versions]:
        raise RuntimeError('release40_rehearsal_changed_history')
    report = {'environment': environment, 'phase': args.phase,
              'migrationCount': len(versions), 'authorityUnchanged': True,
              'syntheticChangesRolledBack': True}
    (folder / f'{args.phase}.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps(report))


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print(str(error) if isinstance(error, RuntimeError) else 'release40_contract_unavailable')
        raise SystemExit(1) from None
