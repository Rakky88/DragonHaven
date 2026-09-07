"""Bounded production rollout of the exact staging-proven dormant migrations.

Rehearses every contract in a rollback-only transaction before db push.
Never enables push, game mutations, or changes any account's authority mode.
Uses the authenticated Supabase CLI without extracting its credentials.
"""
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CLI = ROOT / '.tools/supabase-2.115.0/supabase.exe'
PROJECT = 'tnzathhutuwmohmjfrlo'
GH = 'C:/Program Files/GitHub CLI/gh.exe'
EVIDENCE = '34153525465'
CONTRACTS = ['social_push', 'canonical_game', 'canonical_import',
             'canonical_game_read', 'canonical_receipt', 'canonical_ruleset']


def run(args, parse=True):
    result = subprocess.run(args, cwd=ROOT, capture_output=True, text=True, encoding='utf-8')
    if result.returncode:
        # CLI diagnostics might include SQL or auth state; store no raw output.
        raise RuntimeError('Bounded operator command failed: ' + pathlib.Path(args[0]).name)
    return json.loads(result.stdout) if parse else result.stdout


def query(sql):
    path = ROOT / '.tools/production-dormant-query.sql'
    path.write_text(sql, encoding='utf-8')
    return run([str(CLI), 'db', 'query', '--linked', '--project-ref', PROJECT,
                '--file', str(path), '--output', 'json'])['rows']


def history():
    rows = run([str(CLI), 'migration', 'list', '--linked', '--output-format', 'json'])
    return sorted(row['remote'] for row in rows['migrations'] if row.get('remote'))


def authority(with_dormant):
    extra = '' if not with_dormant else """,
        (select enabled from private.push_runtime where singleton) as push_enabled,
        (select enabled from private.game_engine_runtime where singleton) as game_enabled,
        (select count(*) from private.canonical_game_states) as shadow_copies"""
    row = query("""select mutations_enabled,
        (select count(*) from public.player_economy_authority where authority_mode<>'legacy_client') as promoted
        """ + extra + ' from private.economy_contract where singleton')[0]
    if any(row.values()):
        raise RuntimeError('Production must remain legacy with all mutations disabled and zero shadow copies.')
    print('PASS: dormant authority ' + json.dumps(row))


def main():
    if sys.argv[1:] not in (['--rehearse'], ['--apply']):
        raise RuntimeError('Expected --rehearse or --apply.')
    if (ROOT / 'supabase/.temp/project-ref').read_text().strip() != PROJECT:
        raise RuntimeError('Production project link mismatch.')
    proof = run([GH, 'api', 'repos/Rakky88/DragonHaven/actions/runs/' + EVIDENCE])
    if proof['conclusion'] != 'success' or proof['path'] != '.github/workflows/staging-economy-contract-drill.yml':
        raise RuntimeError('Missing successful exact staging proof.')
    run(['git', 'diff', '--exit-code', proof['head_sha'], '--', 'supabase/migrations',
         *['tool/' + name + '_contract.sql' for name in CONTRACTS]], False)
    files = sorted((ROOT / 'supabase/migrations').glob('*.sql'))
    versions = [file.name.split('_')[0] for file in files]
    before = history()
    if len(versions) != 56 or versions[-1] != '202609070056' or before not in (versions[:49], versions):
        raise RuntimeError('Requires exact schema 49 or 56, and local schema 56.')
    authority(len(before) == 56)
    # SAVEPOINT isolates synthetic contracts from each other, while retaining
    # the prospective schema within the outer rollback-only transaction.
    migrations = '\n'.join(p.read_text(encoding='utf-8') for p in files[49:]) if len(before) == 49 else ''
    sql = 'begin;\nset local statement_timeout=\'90s\';\n' + migrations
    for name in CONTRACTS:
        content = (ROOT / ('tool/' + name + '_contract.sql')).read_text(encoding='utf-8')
        body = content.split('begin;', 1)[1].rsplit('rollback;', 1)[0]
        sql += '\nsavepoint probe;\n' + body + '\nrollback to savepoint probe;\n'
    sql += '\nrollback;\nselect true as all_dormant_contracts_passed;'
    if query(sql) != [{'all_dormant_contracts_passed': True}]:
        raise RuntimeError('Rollback-only rehearsal did not pass.')
    print('PASS: contracts 50-56 rehearsed; all synthetic changes rolled back; staging proof ' + EVIDENCE)
    if history() != before:
        raise RuntimeError('Rehearsal unexpectedly changed migration history.')
    if sys.argv[1] == '--apply' and len(before) == 49:
        run([str(CLI), 'db', 'push', '--linked', '--include-all', '--dry-run'], False)
        print('PASS: migration dry run; applying exactly 50-56 dormant.')
        run([str(CLI), 'db', 'push', '--linked', '--include-all', '--yes'], False)
        if history() != versions:
            raise RuntimeError('Post-apply migration parity failed.')
        authority(True)
        print('PASS: production schema 56; all gameplay remains legacy; push and game workers disabled.')


if __name__ == '__main__':
    main()
