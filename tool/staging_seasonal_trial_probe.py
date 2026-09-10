"""One disposable keeper; real event activation, Trial UI and public ranking."""
import json
import os
import re
import secrets
import subprocess
import uuid


def run_seasonal_trial_probe(*, root, project, base, public_key, run, fixture, admin_headers, call, query, require):
    password = secrets.token_urlsafe(32) + 'Dh7!'
    email = f'seasonal-{run}@dragonhaven-probe.invalid'
    status, created = call(base + '/auth/v1/admin/users', admin_headers, {
        'email': email, 'password': password, 'email_confirm': True,
        'app_metadata': {'dragonhaven_game_probe': run}})
    require(status in (200, 201) and created.get('email') == email, 'seasonal_probe_create')
    owner = str(uuid.UUID(created['id']))
    status, signed = call(base + '/auth/v1/token?grant_type=password', {'apikey': public_key},
        {'email': email, 'password': password})
    require(status == 200 and signed.get('user', {}).get('id') == owner, 'seasonal_probe_signin')
    state = json.loads(json.dumps(fixture))
    state['pet'].update({'id': 'seasonal-probe-dragon', 'name': 'Seasonal Keeper', 'stage': 'ascended',
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
    encoded = json.dumps(state, separators=(',', ':')).encode('utf-8').hex()
    query(f"""begin;
      select set_config('request.jwt.claim.role','authenticated',true);
      select set_config('request.jwt.claim.sub','{owner}',true);
      select public.ensure_my_online_account();
      insert into public.cloud_game_saves(user_id,revision,state,device_id,client_version,schema_version)
        values('{owner}',1,convert_from(decode('{encoded}','hex'),'utf8')::jsonb,'synthetic-seasonal-probe','0.5.30',54);
      select set_config('request.jwt.claim.role','service_role',true);
      select public.stage_canonical_game_copy('{owner}',1,
        (select private.game_json_sha256(state) from public.cloud_game_saves where user_id='{owner}'));
      update private.game_engine_runtime set shadow_projection_enabled=true where singleton;
      update private.canonical_game_states set is_prepared=true where owner_id='{owner}';
      commit;""")
    child = {key: value for key, value in os.environ.items()
        if not any(part in key.upper() for part in ('SECRET', 'TOKEN', 'PASSWORD', 'SUPABASE', 'KEY'))}
    child.update({'STAGING_SUPABASE_PROJECT_REF': project, 'STAGING_SUPABASE_URL': base,
        'STAGING_SUPABASE_PUBLISHABLE_KEY': public_key, 'STAGING_SEASONAL_SESSION': json.dumps(signed),
        'STAGING_GAME_PROBE_RUN': run})
    result = subprocess.run(['flutter', 'test', '--no-pub', 'tool/canonical_seasonal_session_probe.dart'],
        cwd=root, env=child, capture_output=True, text=True, timeout=240)
    del child['STAGING_SEASONAL_SESSION']
    for phase in re.findall(r'PROBE: ([a-z_]+)', result.stdout):
        print('PROBE: ' + phase, flush=True)
    if result.returncode:
        failure = re.search(r'client_probe_seasonal_[a-z_]+', result.stdout + result.stderr)
        require(False, failure.group(0) if failure else 'client_probe_seasonal_failed')
    require('PASS: real seasonal UI;' in result.stdout, 'client_probe_seasonal_proof_missing')
    facts = query(f"""select
      (select count(*)=1 from public.seasonal_trial_attempts where user_id='{owner}' and canonical_owned
        and simulated and ranking_eligible and completed_at is not null and total_actions-correct_actions=3) as one_attempt,
      (select count(*)=1 from public.seasonal_trial_bests b join public.seasonal_trial_attempts a
        on a.user_id=b.user_id and a.occurrence_key=b.occurrence_key and a.event_id=b.event_id
        where a.user_id='{owner}' and b.preview and b.score=a.score and b.duration_ms=a.duration_ms) as exact_ranking,
      (select count(*)=0 from public.seasonal_event_previews where user_id='{owner}') as preview_ended,
      (select g.state->'pet'->>'xp'=(3400+(g.state->'_lastGameResult'->'result'->>'xp')::integer)::text and
        g.state->'_activeGameAttempt'='null'::jsonb from private.canonical_game_states g where owner_id='{owner}') as exact_reward,
      (select count(*)=0 from private.canonical_game_intents where owner_id='{owner}' and status='processing') as no_pending
      """, True)[0]
    expected = ['one_attempt', 'exact_ranking', 'preview_ended', 'exact_reward', 'no_pending']
    require(set(facts) == set(expected), 'client_probe_seasonal_facts_shape')
    for check in expected:
        require(facts[check] is True, 'client_probe_seasonal_' + check)
    print('PASS: actual Sunwake UI; one verified three-mistake attempt, exact preview ranking/reward, activation and event end.', flush=True)
