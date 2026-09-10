"""Synthetic four-keeper group lifecycle phase of the guarded staging drill."""
import json
import os
import re
import secrets
import subprocess
import uuid


def run_group_probe(*, root, project, base, public_key, run, fixture, admin_headers, call, query, require):
    sessions = []
    owners = []
    for ordinal in range(4):
        password = secrets.token_urlsafe(32) + "Dh7!"
        email = f"group-{run}-{ordinal}@dragonhaven-probe.invalid"
        status, created = call(base + '/auth/v1/admin/users', admin_headers, {
            'email': email, 'password': password, 'email_confirm': True,
            'app_metadata': {'dragonhaven_game_probe': run},
        })
        require(status in (200, 201) and created.get('email') == email, 'group_probe_account_create')
        owner = str(uuid.UUID(created['id']))
        status, signed = call(base + '/auth/v1/token?grant_type=password', {'apikey': public_key},
                              {'email': email, 'password': password})
        require(status == 200 and signed.get('user', {}).get('id') == owner, 'group_probe_account_signin')
        owners.append(owner)
        sessions.append(signed)
        state = json.loads(json.dumps(fixture))
        state['pet'].update({'id': f'group-dragon-{ordinal}', 'name': f'Crew {ordinal + 1}',
            'stage': 'ascended', 'xp': 3400, 'coins': 1000, 'gems': 10, 'evolutionPath': 'might',
            'training': {'might': 300, 'arcana': 300, 'spirit': 300}, 'favorite': True,
            'activeAdventureId': None, 'firstEgg': False, 'spectral': False, 'sinister': False})
        state.update({'sanctuaryDragons': [], 'eggStash': [], 'releasedDragons': [],
                      'pendingPresentations': [], 'adventureRuns': []})
        state['eggAltar']['ownerId'] = owner
        encoded = json.dumps(state, separators=(',', ':')).encode('utf-8').hex()
        query(f"""begin;
          select set_config('request.jwt.claim.role','authenticated',true);
          select set_config('request.jwt.claim.sub','{owner}',true);
          select public.ensure_my_online_account();
          insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
            values('{owner}',1,convert_from(decode('{encoded}','hex'),'utf8')::jsonb,'synthetic-group-probe','0.5.30',54);
          select set_config('request.jwt.claim.role','service_role',true);
          select public.stage_canonical_game_copy('{owner}',1,
            (select private.game_json_sha256(state) from public.cloud_game_saves where user_id='{owner}'));
          update private.canonical_game_states set is_prepared=true where owner_id='{owner}';
          commit;""")
    owner_array = "array[" + ','.join("'" + owner + "'::uuid" for owner in owners) + "]"
    friendships = ','.join(f"('{owners[0]}','{owner}','accepted')" for owner in owners[1:])
    query(f"""begin;
      select set_config('request.jwt.claim.role','service_role',true);
      insert into public.friendships(requester_id,addressee_id,status) values {friendships};
      update private.game_engine_runtime set shadow_projection_enabled=true,shadow_lifecycle_enabled=true where singleton;
      update private.canonical_game_states set is_prepared=true where owner_id=any({owner_array});
      commit;""")
    child = {key: value for key, value in os.environ.items()
        if not any(part in key.upper() for part in ('SECRET','TOKEN','PASSWORD','SUPABASE','KEY'))}
    child.update({'STAGING_SUPABASE_PROJECT_REF': project, 'STAGING_SUPABASE_URL': base,
      'STAGING_SUPABASE_PUBLISHABLE_KEY': public_key, 'STAGING_GROUP_SESSIONS': json.dumps(sessions),
      'STAGING_GAME_PROBE_RUN': run})
    result = subprocess.run(['flutter','test','--no-pub','tool/canonical_group_session_probe.dart'],
        cwd=root,env=child,capture_output=True,text=True,timeout=360)
    del child['STAGING_GROUP_SESSIONS']
    if result.returncode:
        for phase in re.findall(r'PROBE: ([a-z_]+)',result.stdout): print('PROBE: '+phase,flush=True)
        failure = re.search(r'client_probe_[a-z_]+',result.stdout+result.stderr)
        require(False, failure.group(0) if failure else 'client_probe_group_failed')
    require('PASS: real group UI;' in result.stdout, 'client_probe_group_proof_missing')
    facts=query(f"""select
      (select count(*)=1 from public.group_adventure_lobbies where owner_id='{owners[0]}') as one_lobby,
      (select bool_and(l.canonical_owned and l.status='running' and l.ends_at-l.started_at=interval '24 hours'
        and l.chest_tier in ('gold','dragon','mythical') and l.required_players=(select count(*) from public.group_adventure_participants p where p.lobby_id=l.id))
        from public.group_adventure_lobbies l where l.owner_id='{owners[0]}') as one_shared_start,
      (select bool_and((state->'pet'->>'xp')::integer=3400 and (state->'pet'->>'coins')::integer=1000)
        from private.canonical_game_states where owner_id=any({owner_array})) as no_unearned_rewards,
      (select count(*)=0 from private.canonical_game_intents where owner_id=any({owner_array}) and status='processing') as no_pending;
    """,True)[0]
    require(facts == {'one_lobby':True,'one_shared_start':True,'no_unearned_rewards':True,'no_pending':True},
      'client_probe_group_atomicity')
    print('PASS: actual four-keeper group UI; lost create recovery, leave, join, removal, released dragon and one shared start.',flush=True)
