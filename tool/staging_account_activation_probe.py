"""One disposable legacy keeper; real server account activation and receipt recovery."""
import json
import os
import re
import secrets
import subprocess
import uuid


def run_account_activation_probe(*, root, project, base, public_key, run, fixture, admin_headers, call, query, require):
    password = secrets.token_urlsafe(32) + 'Dh7!'
    email = f'activation-{run}@dragonhaven-probe.invalid'
    status, created = call(base + '/auth/v1/admin/users', admin_headers, {
        'email': email, 'password': password, 'email_confirm': True,
        'app_metadata': {'dragonhaven_game_probe': run}})
    require(status in (200, 201) and created.get('email') == email, 'activation_probe_create')
    owner = str(uuid.UUID(created['id']))
    status, signed = call(base + '/auth/v1/token?grant_type=password', {'apikey': public_key},
        {'email': email, 'password': password})
    require(status == 200 and signed.get('user', {}).get('id') == owner, 'activation_probe_signin')
    state = json.loads(json.dumps(fixture))
    state['pet'].update({'id': 'activation-probe-dragon', 'name': 'Seasonal Keeper', 'stage': 'ascended',
        'xp': 3400, 'coins': 1000, 'gems': 10, 'evolutionPath': 'might',
        'training': {'might': 300, 'arcana': 300, 'spirit': 300}, 'favorite': True,
        'activeAdventureId': None, 'firstEgg': False, 'spectral': False, 'sinister': False})
    state.update({'sanctuaryDragons': [], 'eggStash': [], 'releasedDragons': [],
        'pendingPresentations': [], 'adventureRuns': [], 'eggRarityRevealedIds': [],
        'chestInventory': {}, 'relicInventory': {}, 'untradeableRelicInventory': {},
        'chronoshardReductions': [], 'trialOffers': [], 'trialRefilledAt': None,
        'uniqueRelicsEverObtained': [], 'twinstarBroochEverObtained': False,
        'twinstarBroochDragonId': None, 'equippedRelicDragonIds': {},
        'seasonalEventPreviewExpiresAt': {}, 'seasonalEventDismissedUntil': {}})
    state['eggAltar']['ownerId'] = owner
    state['eggAltar']['wallet'] = {'fragments': 0, 'essence': 0, 'hearts': 0}
    state['futureMigrationMetadata'] = {'preserved': True}
    state.pop('_activeGameAttempt', None)
    state.pop('_lastGameResult', None)
    encoded = json.dumps(state, separators=(',', ':')).encode('utf-8').hex()
    query(f"""begin;
      select set_config('request.jwt.claim.role','authenticated',true);
      select set_config('request.jwt.claim.sub','{owner}',true);
      select public.ensure_my_online_account();
      insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
        values('{owner}',1,convert_from(decode('{encoded}','hex'),'utf8')::jsonb,'synthetic-activation-probe','0.5.30',54);
      select set_config('request.jwt.claim.role','service_role',true);
      insert into private.egg_altar_accounts(owner_id) values('{owner}');
      update private.game_engine_runtime set migration_enabled=true,shadow_projection_enabled=false where singleton;
      commit;""")
    child = {key: value for key, value in os.environ.items()
        if not any(part in key.upper() for part in ('SECRET', 'TOKEN', 'PASSWORD', 'SUPABASE', 'KEY'))}
    child.update({'STAGING_SUPABASE_PROJECT_REF': project, 'STAGING_SUPABASE_URL': base,
        'STAGING_SUPABASE_PUBLISHABLE_KEY': public_key, 'STAGING_ACTIVATION_SESSION': json.dumps(signed),
        'STAGING_GAME_PROBE_RUN': run})
    result = subprocess.run(['flutter', 'test', '--no-pub', 'tool/canonical_account_activation_session_probe.dart'],
        cwd=root, env=child, capture_output=True, text=True, timeout=240)
    del child['STAGING_ACTIVATION_SESSION']
    for phase in re.findall(r'PROBE: ([a-z_]+)', result.stdout):
        print('PROBE: ' + phase, flush=True)
    if result.returncode:
        failure = re.search(r'client_probe_activation_[a-z_]+', result.stdout + result.stderr)
        require(False, failure.group(0) if failure else 'client_probe_activation_failed')
    require('PASS: real account activation;' in result.stdout, 'client_probe_activation_proof_missing')
    facts = query(f"""select
      (select count(*)=1 from private.canonical_account_migrations where owner_id='{owner}' and activated_at is not null
        and activated_revision=3) as one_activation,
      (select authority_mode='server' and protocol_version=2 from public.player_economy_authority where user_id='{owner}') as authority,
      (select g.state#>>'{{pet,coins}}'='900' and g.state#>>'{{pet,gems}}'='10' and
        g.state#>>'{{chestInventory,title}}'='1' and g.state#>>'{{futureMigrationMetadata,preserved}}'='true'
        from private.canonical_game_states g where owner_id='{owner}') as exact_inventory,
      (select count(*)=1 from private.canonical_game_intents where owner_id='{owner}'
        and action='purchase_title_chest' and status='succeeded') as one_purchase,
      (select revision=1 and state#>>'{{pet,coins}}'='1000' from public.cloud_game_saves where user_id='{owner}') as source_preserved,
      (select count(*)=0 from private.canonical_game_intents where owner_id='{owner}' and status='processing') as no_pending
      """, True)[0]
    expected = ['one_activation', 'authority', 'exact_inventory', 'one_purchase', 'source_preserved', 'no_pending']
    require(set(facts) == set(expected), 'client_probe_activation_facts_shape')
    for check in expected:
        require(facts[check] is True, 'client_probe_activation_' + check)
    print('PASS: actual account activation; immutable legacy source, one activation, preserved metadata and one purchase after lost replies.', flush=True)
