"""Focused client proof against the already-deployed schema-74 worker.

The pinned ruleset was built by full staging run 34486928336 on 9e2d4f9.
This runner deploys no code and applies no migration; all state is synthetic.
"""
import json
import re
import sys
import staging_game_worker_probe as probe
from staging_group_probe import run_group_probe
from staging_pair_probe import run_pair_probe
from staging_beacon_probe import run_beacon_probe
from staging_trade_probe import run_trade_probe

RULESET = '8f1bec0ba7f96cafc8fcce85c35ce29821e9ed24c2387ed6883e39b6d3be786c'

def main():
    p = probe
    p.require(p.PROJECT == 'vtmjkhzalalozpfnbvsd' and p.BASE == 'https://'+p.PROJECT+'.supabase.co'
      and p.MANAGEMENT and p.PUBLIC_KEY, 'group_probe_registered_staging_required')
    versions = p.query('select version from supabase_migrations.schema_migrations order by version', True)
    expected = sorted(path.name.split('_')[0] for path in (p.ROOT/'supabase/migrations').glob('*.sql')
      if path.name.split('_')[0] <= '202609100074')
    p.require([row['version'] for row in versions] == expected and len(expected) == 74, 'group_probe_schema_mismatch')
    baseline=p.query("""select enabled or shadow_social_enabled or shadow_projection_enabled or shadow_lifecycle_enabled as enabled,
      ruleset_sha256,(select count(*) from private.canonical_game_states) as copies,
      (select mutations_enabled from private.economy_contract where singleton) as mutations
      from private.game_engine_runtime where singleton""",True)[0]
    p.require(not baseline['enabled'] and baseline['copies']==0 and not baseline['mutations'],'group_probe_requires_dormant')
    old=baseline['ruleset_sha256'];p.require(old is None or re.fullmatch(r'[0-9a-f]{64}',old),'group_probe_ruleset_invalid')
    status,keys=p.call('https://api.supabase.com/v1/projects/'+p.PROJECT+'/api-keys?reveal=true',{'Authorization':'Bearer '+p.MANAGEMENT})
    p.require(status==200 and isinstance(keys,list),'group_probe_admin_missing')
    admin=next((row['api_key'] for row in keys if row.get('name')=='service_role'),None)
    p.require(isinstance(admin,str),'group_probe_admin_missing')
    fixture=json.loads((p.ROOT/'staging/game-fixture.json').read_text(encoding='utf-8'))['state']
    try:
      p.query(f"update private.game_engine_runtime set enabled=true,ruleset_sha256='{RULESET}' where singleton")
      mode=p.os.environ.get('STAGING_SOCIAL_PROBE','group')
      p.require(mode in ('group','pair','beacon','trade'),'social_probe_mode_invalid')
      run_probe={'group':run_group_probe,'pair':run_pair_probe,'beacon':run_beacon_probe,'trade':run_trade_probe}[mode]
      run_probe(root=p.ROOT,project=p.PROJECT,base=p.BASE,public_key=p.PUBLIC_KEY,run=p.RUN,
        fixture=fixture,admin_headers={'Authorization':'Bearer '+admin,'apikey':admin},call=p.call,query=p.query,require=p.require)
    finally:
      restore='null' if old is None else "'"+old+"'"
      cleaned=p.query(f"""begin;
        do $$ begin
          if exists(select 1 from private.canonical_game_states c join auth.users u on u.id=c.owner_id
            where u.raw_app_meta_data->>'dragonhaven_game_probe' is distinct from '{p.RUN}') then
            raise exception 'group_probe_cleanup_other_owner'; end if;
          if (select enabled and ruleset_sha256 is distinct from '{RULESET}' from private.game_engine_runtime where singleton) then
            raise exception 'group_probe_runtime_changed'; end if;
        end $$;
        update private.game_engine_runtime set enabled=false,shadow_social_enabled=false,shadow_projection_enabled=false,
          shadow_lifecycle_enabled=false,ruleset_sha256={restore} where singleton;
        select set_config('request.jwt.claim.role','service_role',true);
        delete from public.conclaves where description='{p.RUN}' and created_by in
          (select id from auth.users where raw_app_meta_data->>'dragonhaven_game_probe'='{p.RUN}' and email like '%@dragonhaven-probe.invalid');
        delete from auth.users where raw_app_meta_data->>'dragonhaven_game_probe'='{p.RUN}' and email like '%@dragonhaven-probe.invalid';
        commit;
        select (select count(*) from auth.users where raw_app_meta_data->>'dragonhaven_game_probe'='{p.RUN}') as accounts,
          (select count(*) from private.canonical_game_states) as copies,(select count(*) from private.canonical_game_intents) as intents,
          (select enabled or shadow_social_enabled or shadow_projection_enabled or shadow_lifecycle_enabled from private.game_engine_runtime where singleton) as enabled
      """)[0]
      p.require(cleaned=={'accounts':0,'copies':0,'intents':0,'enabled':False},'group_probe_cleanup_incomplete')
      print('CLEANUP: all synthetic group accounts and commands removed; all four switches disabled.',flush=True)

if __name__=='__main__':
  try:main()
  except probe.ProbeError as error:print('FAIL: '+str(error),file=sys.stderr);sys.exit(1)
  except Exception:print('FAIL: unexpected_group_probe_error',file=sys.stderr);sys.exit(1)
