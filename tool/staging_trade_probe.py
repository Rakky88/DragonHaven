"""Real two-keeper trade UI, restricted to the guarded drill's synthetic users."""
import json
import os
import re
import secrets
import subprocess
import uuid


def run_trade_probe(*, root, project, base, public_key, run, fixture, admin_headers, call, query, require):
    sessions, owners = [], []
    egg_id = 'trade-probe-special-egg'
    for ordinal in range(2):
        password = secrets.token_urlsafe(32) + 'Dh7!'
        email = f'trade-{run}-{ordinal}@dragonhaven-probe.invalid'
        status, created = call(base + '/auth/v1/admin/users', admin_headers, {
            'email': email, 'password': password, 'email_confirm': True,
            'app_metadata': {'dragonhaven_game_probe': run}})
        require(status in (200, 201) and created.get('email') == email, 'trade_probe_account_create')
        owner = str(uuid.UUID(created['id']))
        status, signed = call(base + '/auth/v1/token?grant_type=password', {'apikey': public_key},
                              {'email': email, 'password': password})
        require(status == 200 and signed.get('user', {}).get('id') == owner, 'trade_probe_account_signin')
        owners.append(owner)
        sessions.append(signed)
        state = json.loads(json.dumps(fixture))
        state['pet'].update({'id': f'trade-dragon-{ordinal}', 'name': f'Trader {ordinal+1}',
            'stage': 'ascended', 'xp': 3400, 'coins': 1000, 'gems': 10, 'evolutionPath': 'might',
            'training': {'might': 300, 'arcana': 300, 'spirit': 300}, 'favorite': True,
            'activeAdventureId': None, 'firstEgg': False, 'spectral': False, 'sinister': False})
        egg = json.loads(json.dumps(fixture['eggStash'][0]))
        egg.update({'id': egg_id, 'lineageId': 'solmanta', 'specialEggId': 'sunwake_egg_v1',
            'incubationMinutes': 1200, 'hatchSeed': 8675309, 'sex': 'female', 'prismatic': True,
            'moralAxisKnown': False, 'altarKnowledge': {'tagged': True, 'tagRevision': 3,
                'rarity': True, 'order': True, 'moral': True, 'lineage': False,
                'futureClue': 'retained'}, 'futureMetadata': {'fixedRoll': 'unchanged'}})
        state.update({'sanctuaryDragons': [], 'eggStash': [egg] if ordinal == 0 else [],
            'releasedDragons': [], 'pendingPresentations': [], 'adventureRuns': [],
            'eggRarityRevealedIds': [egg_id] if ordinal == 0 else [],
            'reservedOnlineTradeEggIds': [], 'reservedOnlineTradeChests': {},
            'reservedOnlineTradeRelics': {}, 'appliedOnlineTradeIds': [],
            'chestInventory': {'gold': 2}, 'relicInventory': {'chronoshard': 2} if ordinal == 1 else {},
            'untradeableRelicInventory': {}, 'chronoshardReductions': [25, 60] if ordinal == 1 else [],
            'trialOffers': [], 'uniqueRelicsEverObtained': [], 'twinstarBroochEverObtained': False,
            'twinstarBroochDragonId': None, 'equippedRelicDragonIds': {}})
        state['eggAltar']['ownerId'] = owner
        encoded = json.dumps(state, separators=(',', ':')).encode('utf-8').hex()
        query(f"""begin;
          select set_config('request.jwt.claim.role','authenticated',true);
          select set_config('request.jwt.claim.sub','{owner}',true);
          select public.ensure_my_online_account();
          insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
            values('{owner}',1,convert_from(decode('{encoded}','hex'),'utf8')::jsonb,'synthetic-trade-probe','0.5.30',54);
          select set_config('request.jwt.claim.role','service_role',true);
          select public.stage_canonical_game_copy('{owner}',1,
            (select private.game_json_sha256(state) from public.cloud_game_saves where user_id='{owner}'));
          update private.canonical_game_states set is_prepared=true where owner_id='{owner}';
          commit;""")
    owner_array = 'array[' + ','.join("'" + owner + "'::uuid" for owner in owners) + ']'
    query(f"""begin;
      select set_config('request.jwt.claim.role','service_role',true);
      update private.game_engine_runtime set shadow_projection_enabled=true,shadow_lifecycle_enabled=true where singleton;
      update private.canonical_game_states set is_prepared=true where owner_id=any({owner_array});
      insert into public.friendships(requester_id,addressee_id,status) values('{owners[0]}','{owners[1]}','accepted');
      commit;""")
    code = query(f"select keeper_code from public.profiles where user_id='{owners[1]}'", True)[0]['keeper_code']
    require(re.fullmatch(r'DH-[0-9A-F]{8}', code) is not None, 'trade_probe_keeper_code')
    child = {key: value for key, value in os.environ.items()
        if not any(part in key.upper() for part in ('SECRET','TOKEN','PASSWORD','SUPABASE','KEY'))}
    child.update({'STAGING_SUPABASE_PROJECT_REF': project, 'STAGING_SUPABASE_URL': base,
        'STAGING_SUPABASE_PUBLISHABLE_KEY': public_key, 'STAGING_TRADE_SESSIONS': json.dumps(sessions),
        'STAGING_GAME_PROBE_RUN': run, 'STAGING_TRADE_TARGET_CODE': code})
    result = subprocess.run(['flutter', 'test', '--no-pub', 'tool/canonical_trade_session_probe.dart'],
        cwd=root, env=child, capture_output=True, text=True, timeout=360)
    del child['STAGING_TRADE_SESSIONS']
    for phase in re.findall(r'PROBE: ([a-z_]+)', result.stdout):
        print('PROBE: ' + phase, flush=True)
    if result.returncode:
        failure = re.search(r'client_probe_trade_[a-z_]+', result.stdout + result.stderr)
        require(False, failure.group(0) if failure else 'client_probe_trade_failed')
    require('PASS: real trade UI;' in result.stdout, 'client_probe_trade_proof_missing')
    facts = query(f"""select
      (select count(*)=3 from public.trades where initiator_id='{owners[0]}') as three_offers,
      (select count(*)=1 from public.trades where initiator_id='{owners[0]}' and status='rejected') as one_rejected,
      (select count(*)=1 from public.trades where initiator_id='{owners[0]}' and status='cancelled') as one_cancelled,
      (select count(*)=1 from public.trades where initiator_id='{owners[0]}' and status='completed' and canonical_owned) as one_completed,
      (select count(*)=2 from private.canonical_trade_settlements where owner_id=any({owner_array})) as two_settlements,
      (select count(*)=0 from public.trade_reservations where owner_id=any({owner_array})) as none_reserved,
      (select state->'eggStash'='[]'::jsonb and state->'chronoshardReductions'='[60]'::jsonb and
        state->'eggRarityRevealedIds'='[]'::jsonb from private.canonical_game_states where owner_id='{owners[0]}') as sender_exact,
      (select state->'chronoshardReductions'='[25]'::jsonb and state->'eggStash'->0->>'id'='{egg_id}' and
        state->'eggStash'->0->>'hatchSeed'='8675309' and state->'eggStash'->0->>'sex'='female' and
        state->'eggStash'->0->>'lineageId'='solmanta' and state->'eggStash'->0->>'specialEggId'='sunwake_egg_v1' and
        state->'eggStash'->0->'futureMetadata'->>'fixedRoll'='unchanged' and
        state->'eggStash'->0->'altarKnowledge'->>'futureClue'='retained' and
        state->'eggRarityRevealedIds' ? '{egg_id}'
        from private.canonical_game_states where owner_id='{owners[1]}') as receiver_exact,
      (select bool_and((state->'pet'->>'xp')::integer=3400 and (state->'pet'->>'coins')::integer=1000 and
        (state->'chestInventory'->>'gold')::integer=2 and
        not exists(select 1 from jsonb_each_text(state->'chestInventory') c where c.key<>'gold' and c.value::integer<>0) and state->'pendingPresentations'='[]'::jsonb)
        from private.canonical_game_states where owner_id=any({owner_array})) as no_unearned_rewards,
      (select count(*)=0 from private.canonical_game_intents where owner_id=any({owner_array}) and status='processing') as no_pending;
    """, True)[0]
    expected = ['three_offers','one_rejected','one_cancelled','one_completed',
        'two_settlements','none_reserved','sender_exact','receiver_exact','no_unearned_rewards','no_pending']
    require(set(facts) == set(expected), 'client_probe_trade_atomicity_shape')
    for check in expected:
        require(facts[check] is True, 'client_probe_trade_atomicity_' + check)
    print('PASS: actual two-keeper trade UI; cancellation, rejection, Special egg/knowledge/sex retention, exact Chronoshard, lost reply and both reveals.', flush=True)
