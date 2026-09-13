"""Verify retired event-Adventure starts cannot return after the schema-80 cutover.
Existing reward claims are exercised by the full canonical client probe.
"""
import json
import secrets
import uuid


def run_pair_probe(*, root, project, base, public_key, run, fixture, admin_headers, call, query, require):
    sessions = []
    owners = []
    preview_expiry = query("select now()+interval '2 days' as expires_at", True)[0]['expires_at']
    for ordinal in range(2):
        password = secrets.token_urlsafe(32) + "Dh7!"
        email = f"pair-{run}-{ordinal}@dragonhaven-probe.invalid"
        status, created = call(base + '/auth/v1/admin/users', admin_headers, {
            'email': email, 'password': password, 'email_confirm': True,
            'app_metadata': {'dragonhaven_game_probe': run},
        })
        require(status in (200, 201) and created.get('email') == email, 'pair_probe_account_create')
        owner = str(uuid.UUID(created['id']))
        status, signed = call(base + '/auth/v1/token?grant_type=password', {'apikey': public_key},
                              {'email': email, 'password': password})
        require(status == 200 and signed.get('user', {}).get('id') == owner, 'pair_probe_account_signin')
        owners.append(owner)
        sessions.append(signed)
        state = json.loads(json.dumps(fixture))
        state['pet'].update({'id': f'pair-dragon-{ordinal}', 'name': f'Partner {ordinal + 1}',
            'stage': 'ascended', 'xp': 3400, 'coins': 1000, 'gems': 10, 'evolutionPath': 'might',
            'training': {'might': 300, 'arcana': 300, 'spirit': 300}, 'favorite': True,
            'activeAdventureId': None, 'firstEgg': False, 'spectral': False, 'sinister': False})
        state.update({'sanctuaryDragons': [], 'eggStash': [], 'releasedDragons': [],
                      'pendingPresentations': [], 'adventureRuns': [],
                      'seasonalEventPreviewExpiresAt': {'valentine_two_heartlights': preview_expiry} if ordinal == 0 else {}})
        state['eggAltar']['ownerId'] = owner
        encoded = json.dumps(state, separators=(',', ':')).encode('utf-8').hex()
        query(f"""begin;
          select set_config('request.jwt.claim.role','authenticated',true);
          select set_config('request.jwt.claim.sub','{owner}',true);
          select public.ensure_my_online_account();
          insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
            values('{owner}',1,convert_from(decode('{encoded}','hex'),'utf8')::jsonb,'synthetic-pair-probe','0.5.30',54);
          select set_config('request.jwt.claim.role','service_role',true);
          select public.stage_canonical_game_copy('{owner}',1,
            (select private.game_json_sha256(state) from public.cloud_game_saves where user_id='{owner}'));
          update private.canonical_game_states set is_prepared=true where owner_id='{owner}';
          commit;""")
    owner_array = "array[" + ','.join("'" + owner + "'::uuid" for owner in owners) + "]"
    query(f"""begin;
      select set_config('request.jwt.claim.role','service_role',true);
      update private.game_engine_runtime set shadow_projection_enabled=true,shadow_lifecycle_enabled=true where singleton;
      update private.canonical_game_states set is_prepared=true where owner_id=any({owner_array});
      commit;""")
    facts = query(f"""begin;
      select set_config('request.jwt.claim.role','service_role',true);
      do $$
      declare before_state jsonb; after_state jsonb; action_name text; rules text;
      begin
        select jsonb_agg(to_jsonb(g) order by owner_id) into before_state
          from private.canonical_game_states g where owner_id=any({owner_array});
        select ruleset_sha256 into rules from private.game_engine_runtime where singleton;
        foreach action_name in array array['invite_pair_adventure','accept_pair_adventure','start_pair_adventure'] loop
          begin
            perform public.begin_revisioned_game_command('{owners[0]}',gen_random_uuid(),action_name,
              '{{}}',10085,rules,1);
            raise exception 'retired_pair_probe_action_accepted';
          exception when others then if sqlerrm<>'game_action_unavailable' then raise; end if; end;
        end loop;
        select jsonb_agg(to_jsonb(g) order by owner_id) into after_state
          from private.canonical_game_states g where owner_id=any({owner_array});
        if before_state is distinct from after_state or
          exists(select 1 from private.canonical_game_intents where owner_id=any({owner_array})) or
          exists(select 1 from public.seasonal_pair_adventures where creator_id=any({owner_array})) then
          raise exception 'retired_pair_probe_state_changed'; end if;
      end $$;
      rollback;
      select true as retired_pair_actions_refused;
    """)
    require(facts == [{'retired_pair_actions_refused': True}], 'retired_pair_probe_failed')
    print('PASS: retired event Adventure invite/accept/start refused; both inventories unchanged, no command or invitation created.', flush=True)
