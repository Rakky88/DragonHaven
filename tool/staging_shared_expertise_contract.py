"""Rehearse pending expertise schema and synthetic rows in one rolled-back transaction."""
import json
import os
from pathlib import Path
import re
import urllib.error
import urllib.request


def main():
    project = os.environ.get('STAGING_SUPABASE_PROJECT_REF')
    token = os.environ.get('STAGING_SUPABASE_ACCESS_TOKEN')
    if project != 'vtmjkhzalalozpfnbvsd' or not token:
        raise RuntimeError('staging_configuration_required')

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
            match = re.search(r'\bexpertise_contract_[a-z_]+\b', body)
            state = re.search(r'ERROR:\s+([0-9A-Z]{5}):', body)
            if match:
                print('Failed assertion:', match[0])
            if state:
                print('SQL state:', state[1])
            raise RuntimeError('staging_expertise_query_failed') from None

    history = query('select version from supabase_migrations.schema_migrations order by version', True)
    versions = [row['version'] for row in history]
    files = sorted(Path('supabase/migrations').glob('*.sql'))
    if not versions or versions[-1] not in ('202609120083', '202609130084', '202609200085'):
        raise RuntimeError('staging_expertise_history_unreviewed')
    if versions != [p.name.split('_')[0] for p in files if p.name.split('_')[0] <= versions[-1]]:
        raise RuntimeError('staging_expertise_history_mismatch')
    pending = [p.read_text(encoding='utf-8') for p in files
               if versions[-1] < p.name.split('_')[0] <= '202609200085']
    contract = Path('tool/shared_expertise_contract.sql').read_text(encoding='utf-8')
    sql = 'begin;\n' + '\n'.join(pending) + '\n' + contract.removeprefix('begin;\n')
    result = query(sql)
    if result != [{'shared_expertise_contract_passed': True}]:
        raise RuntimeError('staging_expertise_rollback_not_confirmed')
    print('PASS: concentrated dragon/showcase/partner scores, negative/oversized refusal, rare Astrolabe pool, hidden bonus and retained RPC fences; synthetic_changes_rolled_back=true')


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        # Never emit management responses or credentials.
        print(str(error) if isinstance(error, RuntimeError) else 'staging_expertise_unavailable')
        raise SystemExit(1) from None
