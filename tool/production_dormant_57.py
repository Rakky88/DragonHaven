"""Apply only staging-proven recovery migration 57, preserving live switches.

Every contract is rehearsed and rolled back before the forward-only migration.
No live game copies are imported and no economic authority is enabled.
"""
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CLI = ROOT / '.tools/supabase-2.115.0/supabase.exe'
PROJECT = 'tnzathhutuwmohmjfrlo'
GH = 'C:/Program Files/GitHub CLI/gh.exe'
EVIDENCE = '34254991384'
CONTRACTS = ['canonical_game', 'canonical_import', 'canonical_game_read',
             'canonical_receipt', 'canonical_ruleset', 'canonical_command_recovery']


def run(args, parse=True):
    result = subprocess.run(args, cwd=ROOT, capture_output=True, text=True, encoding='utf-8')
    if result.returncode:
        raise RuntimeError('Bounded operator command failed: ' + pathlib.Path(args[0]).name)
    return json.loads(result.stdout) if parse else result.stdout


def query(sql):
    path = ROOT / '.tools/production-recovery57-query.sql'
    path.write_text(sql, encoding='utf-8')
    return run([str(CLI), 'db', 'query', '--linked', '--project-ref', PROJECT,
                '--file', str(path), '--output', 'json'])['rows']


def history():
    rows = run([str(CLI), 'migration', 'list', '--linked', '--output-format', 'json'])
    return sorted(row['remote'] for row in rows['migrations'] if row.get('remote'))


def authority():
    row = query("""select mutations_enabled,
      (select count(*) from public.player_economy_authority where authority_mode<>'legacy_client') as promoted,
      (select enabled from private.push_runtime where singleton) as push_enabled,
      (select to_jsonb(r) from private.game_engine_runtime r where singleton) as game_runtime,
      (select count(*) from private.canonical_game_states) as shadow_copies
      from private.economy_contract where singleton""")[0]
    if row['mutations_enabled'] or row['promoted'] or row['shadow_copies'] or row['game_runtime']['enabled']:
        raise RuntimeError('Requires legacy accounts, disabled economics/game worker and zero shadow copies.')
    print('PASS: legacy accounts, economic/game mutations off, zero copies; push=' + str(row['push_enabled']))
    return row


def rehearse(files, before):
    migration = files[-1].read_text(encoding='utf-8') if len(before) == 56 else ''
    sql = "begin;\nset local lock_timeout='5s';\nset local statement_timeout='90s';\n" + migration
    for name in CONTRACTS:
        content = (ROOT / ('tool/' + name + '_contract.sql')).read_text(encoding='utf-8')
        body = content.split('begin;', 1)[1].rsplit('rollback;', 1)[0]
        sql += '\nsavepoint probe;\n' + body + '\nrollback to savepoint probe;\n'
    sql += '\nrollback;\nselect true as recovery_contracts_passed;'
    if query(sql) != [{'recovery_contracts_passed': True}]:
        raise RuntimeError('Rollback-only rehearsal did not pass.')
    if history() != before:
        raise RuntimeError('Rehearsal changed migration history.')
    print('PASS: six recovery/game contracts; all synthetic changes rolled back.')


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
    if len(versions) != 57 or versions[-1] != '202609070057' or before not in (versions[:56], versions):
        raise RuntimeError('Requires exact production 56 or 57 and local 57.')
    original = authority()
    rehearse(files, before)
    if authority() != original:
        raise RuntimeError('Rehearsal changed runtime or authority state.')
    if sys.argv[1] == '--apply' and len(before) == 56:
        run([str(CLI), 'db', 'push', '--linked', '--include-all', '--dry-run'], False)
        print('PASS: exact staging source ' + EVIDENCE + '; applying only migration 57.')
        run([str(CLI), 'db', 'push', '--linked', '--include-all', '--yes'], False)
        if history() != versions:
            raise RuntimeError('Post-apply migration parity failed.')
        rehearse(files, versions)
    if authority() != original:
        raise RuntimeError('Runtime or authority changed; inspect before further release work.')
    print('PASS: final schema ' + str(len(history())) + '; live switches and legacy authority preserved.')


if __name__ == '__main__':
    main()
