"""Synthetic single-keeper Beacon lifecycle phase of the guarded staging drill."""
import json
import os
import re
import secrets
import subprocess
import uuid


def run_beacon_probe(*, root, project, base, public_key, run, fixture, admin_headers, call, query, require):
    sessions = []
    owners = []
    for ordinal in range(1):
        password = secrets.token_urlsafe(32) + "Dh7!"
        email = f"beacon-{run}-{ordinal}@dragonhaven-probe.invalid"
        status, created = call(base + '/auth/v1/admin/users', admin_headers, {
            'email': email, 'password': password, 'email_confirm': True,
            'app_metadata': {'dragonhaven_game_probe': run},
        })
        require(status in (200, 201) and created.get('email') == email, 'beacon_probe_account_create')
        owner = str(uuid.UUID(created['id']))
        status, signed = call(base + '/auth/v1/token?grant_type=password', {'apikey': public_key},
                              {'email': email, 'password': password})
        require(status == 200 and signed.get('user', {}).get('id') == owner, 'beacon_probe_account_signin')
        owners.append(owner)
        sessions.append(signed)
        state = json.loads(json.dumps(fixture))
        state['pet'].update({'id': f'beacon-dragon-{ordinal}', 'name': f'Beacon {ordinal + 1}',
            'stage': 'ascended', 'xp': 3400, 'coins': 1000, 'gems': 10, 'evolutionPath': 'might',
            'training': {'might': 300, 'arcana': 300, 'spirit': 300}, 'favorite': True,
            'activeAdventureId': None, 'firstEgg': False, 'spectral': False, 'sinister': False})
        state.update({'sanctuaryDragons': [], 'eggStash': [], 'releasedDragons': [],
                      'pendingPresentations': [], 'adventureRuns': []})
        state['eggAltar']['ownerId'] = owner
        state['eggAltar']['wallet'] = {'fragments': 200, 'essence': 7, 'hearts': 2}
        encoded = json.dumps(state, separators=(',', ':')).encode('utf-8').hex()
        query(f"""begin;
          select set_config('request.jwt.claim.role','authenticated',true);
          select set_config('request.jwt.claim.sub','{owner}',true);
          select public.ensure_my_online_account();
          insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
            values('{owner}',1,convert_from(decode('{encoded}','hex'),'utf8')::jsonb,'synthetic-beacon-probe','0.5.30',54);
          select set_config('request.jwt.claim.role','service_role',true);
          select public.stage_canonical_game_copy('{owner}',1,
            (select private.game_json_sha256(state) from public.cloud_game_saves where user_id='{owner}'));
          update private.canonical_game_states set is_prepared=true where owner_id='{owner}';
          commit;""")
    owner_array = "array[" + ','.join("'" + owner + "'::uuid" for owner in owners) + "]"
    conclave = str(uuid.uuid4())
    query(f"""begin;
      select set_config('request.jwt.claim.role','service_role',true);
      update private.game_engine_runtime set shadow_projection_enabled=true,shadow_lifecycle_enabled=true where singleton;
      update private.canonical_game_states set is_prepared=true where owner_id=any({owner_array});
      insert into public.conclaves(id,name,emblem_key,language,visibility,member_limit,created_by,description)
        values('{conclave}','Probe '||left('{conclave}',18),'conclave_emblem_01','en','invite',4,'{owners[0]}','{run}');
      insert into public.conclave_members(conclave_id,user_id,role) values('{conclave}','{owners[0]}','flightmaster');
      insert into private.conclave_weave_beacons(conclave_id,fragments) values('{conclave}',490);
      commit;""")
    child = {key: value for key, value in os.environ.items()
        if not any(part in key.upper() for part in ('SECRET','TOKEN','PASSWORD','SUPABASE','KEY'))}
    child.update({'STAGING_SUPABASE_PROJECT_REF': project, 'STAGING_SUPABASE_URL': base,
      'STAGING_SUPABASE_PUBLISHABLE_KEY': public_key, 'STAGING_BEACON_SESSIONS': json.dumps(sessions),
      'STAGING_GAME_PROBE_RUN': run, 'STAGING_BEACON_ID': conclave})
    result = subprocess.run(['flutter','test','--no-pub','tool/canonical_beacon_session_probe.dart'],
        cwd=root,env=child,capture_output=True,text=True,timeout=360)
    del child['STAGING_BEACON_SESSIONS']
    if result.returncode:
        for phase in re.findall(r'PROBE: ([a-z_]+)',result.stdout): print('PROBE: '+phase,flush=True)
        failure = re.search(r'client_probe_[a-z_]+',result.stdout+result.stderr)
        require(False, failure.group(0) if failure else 'client_probe_beacon_failed')
    require('PASS: real Beacon UI;' in result.stdout, 'client_probe_beacon_proof_missing')
    facts=query(f"""select
      (select fragments=515 from private.conclave_weave_beacons where conclave_id='{conclave}') as shared_total,
      (select count(*)=1 from public.conclave_messages where conclave_id='{conclave}') as one_stage_message,
      (select state->'eggAltar'->'wallet'=jsonb_build_object('fragments',175,'essence',7,'hearts',2)
        and (state->'pet'->>'xp')::integer=3400 and (state->'pet'->>'coins')::integer=1000
        from private.canonical_game_states where owner_id='{owners[0]}') as one_debit,
      (select count(*)=1 from private.canonical_game_intents where owner_id='{owners[0]}' and status='succeeded') as one_receipt,
      (select count(*)=0 from private.canonical_game_intents where owner_id='{owners[0]}' and status='processing') as no_pending;
    """,True)[0]
    require(facts == dict.fromkeys(['shared_total','one_stage_message','one_debit','one_receipt','no_pending'],True),
      'client_probe_beacon_atomicity')
    print('PASS: actual Beacon UI; one voluntary debit, one shared stage message and recovery of a lost reply.',flush=True)
