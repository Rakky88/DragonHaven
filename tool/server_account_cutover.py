"""Bounded schema rehearsal/apply for server-owned account restoration.

Uses a management token from the environment; never prints player state or keys.
Schema apply keeps all authority switches unchanged. Activation is a separate
operator step after client, worker and restoration verification.
"""
import argparse
import json
import os
from pathlib import Path
import re
import urllib.error
import urllib.request


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--environment', choices=['staging', 'production'], required=True)
    parser.add_argument('--phase', choices=['rehearse', 'apply', 'verify'], required=True)
    args = parser.parse_args()
    project = {'staging': 'vtmjkhzalalozpfnbvsd', 'production': 'tnzathhutuwmohmjfrlo'}[args.environment]
    token = os.environ['SUPABASE_ACCESS_TOKEN']
    root = Path(__file__).resolve().parent.parent

    def query(sql):
        request = urllib.request.Request(f'https://api.supabase.com/v1/projects/{project}/database/query',
            data=json.dumps({'query': sql, 'read_only': False}).encode(),
            headers={'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'})
        try:
            with urllib.request.urlopen(request, timeout=55) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            message = error.read().decode('utf-8', errors='replace')
            label = re.search(r'\b(?:profile|read|achievement|account_start|server_start)_contract_[a-z_]+\b', message)
            raise RuntimeError(label[0] if label else 'schema_query_failed') from None

    files = sorted((root / 'supabase/migrations').glob('*.sql'))
    local = [p.name.split('_')[0] for p in files]
    if len(local) != 92 or local[-1] != '202609200092':
        raise RuntimeError('local_history_not_reviewed')
    remote = [r['version'] for r in query('select version from supabase_migrations.schema_migrations order by version')]
    if len(remote) not in range(88, 93) or remote != local[:len(remote)]:
        raise RuntimeError('remote_history_not_reviewed')
    runtime_sql = "select to_jsonb(r) as runtime, (select count(*) from private.canonical_game_states where authority_mode='server') as players from private.game_engine_runtime r where singleton"
    before = query(runtime_sql)
    pending = files[len(remote):]
    migrations = '\n'.join(p.read_text(encoding='utf-8') for p in pending)
    contracts = ['server_account_start_contract', 'canonical_profile_identity_contract',
        'canonical_achievement_sharing_contract', 'account_conclave_reads_contract']

    def verify(prefix):
        for name in contracts:
            sql = (root / 'tool' / (name + '.sql')).read_text(encoding='utf-8').removeprefix('begin;')
            result = query("begin; set local lock_timeout='5s';\n" + prefix + '\n' + sql)
            if len(result) != 1 or list(result[0].values()) != [True]:
                raise RuntimeError('contract_result_invalid')
        # Trigger checks need their relation context as well as the function OID.
        names = set()
        for p in files[-4:]:
            names.update(re.findall(r'create (?:or replace )?function ((?:public|private)\.[a-z_]+)', p.read_text()))
        predicates = ' or '.join("(n.nspname='" + n.split('.')[0] + "' and p.proname='" + n.split('.')[1] + "')" for n in sorted(names))
        lint = """begin; set local statement_timeout='45s';
create extension if not exists plpgsql_check with schema extensions;
""" + prefix + """
do $lint$ declare fn record; issue record; begin
for fn in select p.oid,coalesce(t.tgrelid,0)::regclass as rel from pg_proc p
join pg_namespace n on n.oid=p.pronamespace left join pg_trigger t on t.tgfoid=p.oid
where """ + predicates + """ loop
for issue in select * from extensions.plpgsql_check_function_tb(fn.oid,fn.rel) where level='error' loop
raise exception 'server_start_contract_lint'; end loop; end loop; end $lint$;
rollback; select true as lint_passed;"""
        if query(lint) != [{'lint_passed': True}]:
            raise RuntimeError('lint_result_invalid')

    if args.phase == 'verify' and pending:
        raise RuntimeError('schema_apply_incomplete')
    verify(migrations)
    if args.phase == 'apply' and pending:
        if any(before[0]['runtime'][key] for key in ['enabled', 'migration_enabled',
            'shadow_social_enabled', 'shadow_projection_enabled', 'shadow_lifecycle_enabled']):
            raise RuntimeError('schema_apply_requires_dormant_runtime')
        quote = lambda s: "'" + s.replace("'", "''") + "'"
        records = []
        for path in pending:
            version, name = path.stem.split('_', 1)
            records.append('insert into supabase_migrations.schema_migrations(version,name,statements) values(' +
                ','.join([quote(version), quote(name), 'ARRAY[' + quote(path.read_text(encoding='utf-8')) + ']']) + ');')
        query("begin; set local lock_timeout='5s'; set local statement_timeout='45s';\n" + migrations + '\n' + '\n'.join(records) + '\ncommit;')
        verify('')
    if query(runtime_sql) != before:
        raise RuntimeError('authority_changed')
    count = query('select count(*)::int as count from supabase_migrations.schema_migrations')[0]['count']
    print(json.dumps({'environment': args.environment, 'phase': args.phase,
        'migrations': count, 'contracts': len(contracts), 'lint_errors': 0, 'authority_unchanged': True}))


if __name__ == '__main__':
    main()
