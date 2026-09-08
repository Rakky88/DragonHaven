-- Forward-only catalog parity for the four unique equipable brooches.
-- No runtime, authority, wallet or existing-item changes.
create or replace function private.economy_chest_catalog()
returns jsonb language sql immutable set search_path = '' as $$
  select $catalog${"version":2,"portrait":["portrait_001","portrait_002","portrait_003","portrait_004","portrait_005","portrait_006","portrait_007","portrait_008","portrait_009","portrait_010","portrait_011","portrait_012","portrait_013","portrait_014","portrait_015","portrait_016","portrait_017","portrait_018","portrait_019","portrait_020","portrait_021","portrait_022","portrait_023","portrait_024","portrait_025","portrait_026","portrait_027","portrait_028","portrait_029","portrait_030","portrait_031","portrait_032","portrait_033","portrait_034","portrait_035","portrait_036","portrait_037","portrait_038","portrait_039","portrait_040","portrait_041","portrait_042","portrait_043","portrait_044","portrait_045","portrait_046","portrait_047","portrait_048","portrait_049","portrait_050","portrait_051","portrait_052","portrait_053","portrait_054","portrait_055","portrait_056","portrait_057","portrait_058","portrait_059","portrait_060","portrait_061","portrait_062","portrait_063","portrait_064","portrait_065","portrait_066","portrait_067","portrait_068","portrait_069","portrait_070","portrait_071","portrait_072","portrait_073","portrait_074","portrait_075","portrait_076","portrait_077","portrait_078","portrait_079","portrait_080","portrait_081","portrait_082","portrait_083","portrait_084","portrait_085","portrait_086","portrait_087","portrait_088","portrait_089","portrait_090","portrait_091","portrait_092","portrait_093","portrait_094","portrait_095","portrait_096","portrait_097","portrait_098","portrait_099","portrait_100"],"title":["title_001","title_002","title_003","title_004","title_005","title_006","title_007","title_008","title_009","title_010","title_011","title_012","title_013","title_014","title_015","title_016","title_017","title_018","title_019","title_020","title_021","title_022","title_023","title_024","title_025","title_026","title_027","title_028","title_029","title_030","title_031","title_032","title_033","title_034","title_035","title_036","title_037","title_038","title_039","title_040","title_041","title_042","title_043","title_044","title_045","title_046","title_047","title_048","title_049","title_050","title_051","title_052","title_053","title_054","title_055","title_056","title_057","title_058","title_059","title_060","title_061","title_062","title_063","title_064","title_065","title_066","title_067","title_068","title_069","title_070","title_071","title_072","title_073","title_074","title_075","title_076","title_077","title_078","title_079","title_080","title_081","title_082","title_083","title_084","title_085","title_086","title_087","title_088","title_089","title_090","title_091","title_092","title_093","title_094","title_095","title_096","title_097","title_098","title_099","title_100","title_101","title_102","title_103","title_104","title_105","title_106","title_107","title_108","title_109","title_110","title_111","title_112","title_113","title_114","title_115","title_116","title_117","title_118","title_119","title_120","title_121","title_122","title_123","title_124","title_125","title_126","title_127","title_128","title_129","title_130","title_131","title_132","title_133","title_134","title_135","title_136","title_137","title_138","title_139","title_140","title_141","title_142","title_143","title_144","title_145","title_146","title_147","title_148","title_149","title_150","title_151","title_152","title_153","title_154","title_155","title_156","title_157","title_158","title_159","title_160","title_161","title_162","title_163","title_164","title_165","title_166","title_167","title_168","title_169","title_170","title_171","title_172","title_173","title_174","title_175","title_176","title_177","title_178","title_179","title_180","title_181","title_182","title_183","title_184","title_185","title_186","title_187","title_188","title_189","title_190","title_191","title_192","title_193","title_194","title_195","title_196","title_197","title_198","title_199","title_200","title_201","title_202","title_203","title_204","title_205","title_206","title_207","title_208","title_209","title_210","title_211","title_212","title_213","title_214","title_215","title_216","title_217","title_218","title_219","title_220","title_221","title_222","title_223","title_224","title_225","title_226","title_227","title_228","title_229","title_230","title_231","title_232","title_233","title_234","title_235","title_236","title_237","title_238","title_239","title_240","title_241","title_242","title_243","title_244","title_245","title_246","title_247","title_248","title_249","title_250","title_251","title_252","title_253","title_254","title_255","title_256","title_257","title_258","title_259","title_260","title_261","title_262","title_263","title_264","title_265","title_266","title_267","title_268","title_269","title_270","title_271","title_272","title_273","title_274","title_275","title_276","title_277","title_278","title_279","title_280","title_281","title_282","title_283","title_284","title_285","title_286","title_287","title_288","title_289","title_290","title_291","title_292","title_293","title_294","title_295","title_296","title_297","title_298","title_299","title_300","title_301","title_302","title_303","title_304","title_305","title_306","title_307","title_308","title_309","title_310","title_311","title_312","title_313","title_314","title_315","title_316","title_317","title_318","title_319","title_320","title_321","title_322","title_323","title_324","title_325","title_326","title_327","title_328","title_329","title_330","title_331","title_332","title_333","title_334","title_335","title_336","title_337","title_338","title_339","title_340","title_341","title_342","title_343","title_344","title_345","title_346","title_347","title_348","title_349","title_350","title_351","title_352","title_353","title_354","title_355","title_356","title_357","title_358","title_359","title_360","title_361","title_362","title_363","title_364","title_365","title_366","title_367","title_368","title_369","title_370","title_371","title_372","title_373","title_374","title_375","title_376","title_377","title_378","title_379","title_380","title_381","title_382","title_383","title_384","title_385","title_386","title_387","title_388","title_389","title_390","title_391","title_392","title_393","title_394","title_395","title_396","title_397","title_398","title_399","title_400","title_401","title_402","title_403","title_404","title_405","title_406","title_407","title_408","title_409","title_410","title_411","title_412","title_413","title_414","title_415","title_416","title_417","title_418","title_419","title_420","title_421","title_422","title_423","title_424","title_425","title_426","title_427","title_428","title_429","title_430","title_431","title_432","title_433","title_434","title_435","title_436","title_437","title_438","title_439","title_440","title_441","title_442","title_443","title_444","title_445","title_446","title_447","title_448","title_449","title_450","title_451","title_452","title_453","title_454","title_455","title_456","title_457","title_458","title_459","title_460","title_461","title_462","title_463","title_464","title_465","title_466","title_467","title_468","title_469","title_470","title_471","title_472","title_473","title_474","title_475","title_476","title_477","title_478","title_479","title_480","title_481","title_482","title_483","title_484","title_485","title_486","title_487","title_488","title_489","title_490","title_491","title_492","title_493","title_494","title_495","title_496","title_497","title_498","title_499","title_500"],"music":["clair_de_lune","arabesque_1","reverie","flaxen_hair","golliwoggs_cakewalk","gymnopedie_1","gymnopedie_2","gymnopedie_3","gnossienne_1","gnossienne_3","je_te_veux","fur_elise","moonlight_1","moonlight_3","pathetique_2","ode_to_joy","symphony_5_1","symphony_7_2","eine_kleine_nachtmusik","rondo_alla_turca","symphony_40_1","sonata_k545_1","lacrimosa","dies_irae","ave_verum","canon_in_d","air_g_string","prelude_c_major","toccata_fugue_d_minor","cello_suite_1_prelude","jesu_joy","badinerie","minuet_g_major","spring","summer_presto","autumn_1","winter_1","winter_2","sugar_plum","waltz_flowers","trepak","swan_lake_scene","sleeping_beauty_waltz","1812_finale","mountain_king","morning_mood","anitras_dance","solveigs_song","nocturne_9_2","prelude_28_4","raindrop_prelude","minute_waltz","funeral_march","fantaisie_impromptu","hungarian_dance_5","hungarian_dance_6","lullaby","blue_danube","tritsch_tratsch","radetzky_march","can_can","barcarolle","ride_valkyries","bridal_chorus","bumblebee","scheherazade_prince_princess","procession_nobles","entertainer","maple_leaf_rag","easy_winners","solace","elite_syncopations","greensleeves","scarborough_fair","drunken_sailor","irish_washerwoman","korobeiniki","house_rising_sun","amazing_grace","auld_lang_syne"],"emote":["chest_treasure_hello","chest_coin_eyes","chest_sleepy_hoard","chest_surprise_egg","chest_lucky_gem","chest_chest_peek","chest_gem_tears","chest_golden_laugh","chest_map_confused","chest_key_found","chest_mimic_shock","chest_coin_rain","chest_tiny_hoard","chest_pearl_proud","chest_treasure_sleep","chest_locked_out","chest_crown_try","chest_dusty_sneeze","chest_potion_find","chest_silver_bell","chest_scroll_wow","chest_ruby_blush","chest_sapphire_cool","chest_jackpot","chest_dragon_detective","chest_adored","chest_nervous","chest_terrified","chest_furious","chest_sulking","chest_jealous","chest_guilty","chest_embarrassed","chest_shy","chest_skeptical","chest_disgusted","chest_curious","chest_awestruck","chest_hopeful","chest_relieved","chest_grateful","chest_lonely","chest_homesick","chest_protective","chest_generous","chest_mischievous","chest_impatient","chest_overwhelmed","chest_content","chest_bored","chest_misty_eyes","chest_single_tear","chest_happy_tears","chest_heartbroken_sob","chest_dramatic_bawl"],"relic":["moralPrism","orderCompass","soulMirror","astralLens","chronoshard","wayfinderSigil","twinstarBrooch","emberheartBrooch","moonweaveBrooch","soulbloomBrooch"],"relic_weights":{"moralPrism":10,"orderCompass":10,"soulMirror":10,"astralLens":10,"chronoshard":10,"wayfinderSigil":10,"twinstarBrooch":1,"emberheartBrooch":1,"moonweaveBrooch":1,"soulbloomBrooch":1},"unique_relics":["twinstarBrooch","emberheartBrooch","moonweaveBrooch","soulbloomBrooch"],"lineages":{"common":["mossprout","crystalwhisk","dustglimmer","gleamclaw","emberbun","copperflame","spicewing","bubblefin","linencloud","tidescale","clockskip","galeear","thunderpuff","dreammoth","dewhorn","quietstar","heartwing","twinflare","rainbowruff","harmonytail"],"uncommon":["bramblequill","cinderlynx","mistmantle","runehopper","petaldrift","ironwhistle","frostfable","sunmuzzle","echofern","velvetvolt"],"rare":["auroracrown","voidbloom","coraloracle","meteorhide","temporalark","opalchimera"],"veryRare":["eclipseantler","worldroot","seraphscale"],"legendary":["starforged","leviathanecho"],"mythical":["everwyrm"],"specialEvent":[]},"spectral_chance":0.05,"special_eggs":{"golden_wings_egg_v1":{"lineage":"cluckatrice","incubation_seconds":75600,"moral":null,"moral_known_at_hatch":false,"spectral_chance":0.05},"witchlight_egg_v1":{"lineage":"gloamgourd","incubation_seconds":47593,"moral":null,"moral_known_at_hatch":false,"spectral_chance":0.05},"starlit_evergreen_egg_v1":{"lineage":"hollyfrost","incubation_seconds":90000,"moral":"good","moral_known_at_hatch":true,"spectral_chance":0.05},"turning_year_egg_v1":{"lineage":"dawnchime","incubation_seconds":86400,"moral":"neutral","moral_known_at_hatch":true,"spectral_chance":0.05},"rosebound_egg_v1":{"lineage":"rosevow","incubation_seconds":50400,"moral":"good","moral_known_at_hatch":true,"spectral_chance":0.05},"truecolor_egg_v1":{"lineage":"spectrumplume","incubation_seconds":64800,"moral":"good","moral_known_at_hatch":true,"spectral_chance":0.05}},"special_chests":{"golden_wings_chest_v1":{"coins":269,"gems":10,"egg":"golden_wings_egg_v1"},"witchlight_chest_v1":{"coins":313,"gems":13,"egg":"witchlight_egg_v1"},"starlight_gift_chest_v1":{"coins":250,"gems":12,"egg":"starlit_evergreen_egg_v1"},"firstlight_celebration_chest_v1":{"coins":365,"gems":12,"egg":"turning_year_egg_v1"},"twinheart_keepsake_chest_v1":{"coins":214,"gems":14,"egg":"rosebound_egg_v1"},"radiant_festival_chest_v1":{"coins":300,"gems":15,"egg":"truecolor_egg_v1"}},"tiers":{"wooden":{"coins_min":20,"coins_max":40,"gem_chance":0.0,"gems_min":0,"gems_max":0,"egg_chance":0.01,"relic_chance":0.0,"emote_chance":0.005,"rarity":[0.75,0.95,0.995,0.9995,0.99999]},"silver":{"coins_min":45,"coins_max":80,"gem_chance":0.5,"gems_min":1,"gems_max":2,"egg_chance":0.04,"relic_chance":0.0,"emote_chance":0.01,"rarity":[0.65,0.9,0.98,0.997,0.9998]},"gold":{"coins_min":90,"coins_max":160,"gem_chance":0.72,"gems_min":2,"gems_max":4,"egg_chance":0.12,"relic_chance":0.01,"emote_chance":0.02,"rarity":[0.5,0.8,0.94,0.99,0.999]},"dragon":{"coins_min":180,"coins_max":300,"gem_chance":0.9,"gems_min":4,"gems_max":7,"egg_chance":1.0,"relic_chance":0.02,"emote_chance":0.04,"rarity":[0.25,0.55,0.8,0.95,0.995]},"mythical":{"coins_min":400,"coins_max":650,"gem_chance":1.0,"gems_min":8,"gems_max":13,"egg_chance":1.0,"relic_chance":0.04,"emote_chance":0.08,"rarity":[0.1,0.3,0.55,0.8,0.97]},"sinister":{"coins_min":400,"coins_max":650,"gem_chance":1.0,"gems_min":8,"gems_max":13,"egg_chance":1.0,"relic_chance":1.0,"emote_chance":0.12,"rarity":[0.1,0.3,0.55,0.8,0.97]}}}$catalog$::jsonb;
$$;

create or replace function private.economy_relic_drop_pool(p_owner uuid)
returns jsonb language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(relic.value order by relic.ordinality, ticket), '[]'::jsonb)
  from jsonb_array_elements_text(private.economy_chest_catalog()->'relic')
    with ordinality relic(value, ordinality)
  cross join lateral generate_series(1,
    (private.economy_chest_catalog()->'relic_weights'->>relic.value)::integer) ticket
  where not (private.economy_chest_catalog()->'unique_relics' ? relic.value)
    or jsonb_array_length(private.economy_remaining_pool(p_owner, 'relic',
      jsonb_build_array(relic.value))) = 1;
$$;
revoke all on function private.economy_relic_drop_pool(uuid) from public, anon, authenticated;

create or replace function private.economy_grant_chest_item(
  p_owner uuid, p_request uuid, p_chest uuid, p_kind text, p_catalog_id text
) returns jsonb language plpgsql set search_path = '' as $$
declare instance_id uuid; details jsonb := '{}'::jsonb;
  unique_item boolean := p_kind <> 'relic' or p_catalog_id in ('twinstarBrooch','emberheartBrooch','moonweaveBrooch','soulbloomBrooch');
begin
  if unique_item then
    insert into private.economy_unique_acquisitions(owner_id, item_kind, catalog_id)
      values(p_owner, p_kind, p_catalog_id) on conflict do nothing;
    if not found then raise exception 'economy_collectible_already_acquired'; end if;
  end if;
  if p_catalog_id = 'chronoshard' then
    details := jsonb_build_object('reduction_percent', 10 + private.economy_random_int(81));
  end if;
  insert into public.player_item_instances(owner_id, item_kind, catalog_id,
    tradeable, source_type, source_reference, metadata)
  values(p_owner, p_kind, p_catalog_id, p_kind = 'relic' and not unique_item,
    'chest', p_chest::text, details) returning id into instance_id;
  details := details || jsonb_build_object('instance_id', instance_id, 'kind', p_kind, 'catalog_id', p_catalog_id);
  perform private.append_economy_ledger_entry(p_owner, p_request, 'item', p_catalog_id,
    'grant', 'chest', 1, null, p_chest::text, details);
  return details;
end;
$$;

create or replace function public.open_chest_instances(
  p_request_id uuid, p_chest_ids uuid[], p_protocol_version integer, p_client_build integer
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare keeper uuid := auth.uid(); started jsonb; response jsonb; chest_id uuid;
  chest public.player_chest_instances%rowtype; wallet public.player_wallets%rowtype;
  catalog jsonb := private.economy_chest_catalog(); rules jsonb; rolled jsonb; pool jsonb;
  receipt jsonb; receipts jsonb := '[]'::jsonb; items jsonb; egg jsonb;
  coin_reward integer; gem_reward integer; pity boolean; special_id text;
  version bigint; opened_count integer := 0;
begin
  perform private.assert_economy_client(p_protocol_version, p_client_build);
  if p_chest_ids is null or coalesce(array_length(p_chest_ids, 1), 0) not between 1 and 10
    or array_ndims(p_chest_ids) <> 1 or array_lower(p_chest_ids, 1) <> 1
    or exists(select 1 from unnest(p_chest_ids) id where id is null)
    or (select count(distinct id) from unnest(p_chest_ids) id) <> cardinality(p_chest_ids) then
    raise exception 'economy_chest_request_invalid';
  end if;
  -- Same order as trade/Altar operations, then authority, wallet, chest rows.
  perform pg_advisory_xact_lock(hashtextextended(keeper::text, 0));
  started := private.begin_economy_mutation(p_request_id, 'chest.open',
    p_protocol_version, p_client_build, jsonb_build_object('chest_ids', p_chest_ids), 30, 60);
  if (started->>'replayed')::boolean then
    if started->>'status' <> 'succeeded' then raise exception 'economy_request_state_invalid'; end if;
    return started->'response';
  end if;
  perform 1 from public.player_economy_authority where user_id = keeper for update;
  select * into wallet from public.player_wallets where user_id = keeper for update;
  if not found then raise exception 'economy_wallet_missing'; end if;
  foreach chest_id in array p_chest_ids loop
    select * into chest from public.player_chest_instances where id = chest_id and owner_id = keeper for update;
    if not found then raise exception 'economy_chest_not_owned'; end if;
    if chest.state = 'opened' then
      if chest.opening_receipt is null then raise exception 'economy_chest_receipt_missing'; end if;
      receipts := receipts || jsonb_build_array(chest.opening_receipt); continue;
    end if;
    if chest.state <> 'owned' then raise exception 'economy_chest_reserved'; end if;
    items := '[]'::jsonb; egg := null; coin_reward := 0; gem_reward := 0;
    if chest.tier in ('portrait', 'title', 'music') then
      pool := private.economy_remaining_pool(keeper, chest.tier, catalog->chest.tier);
      if jsonb_array_length(pool) = 0 then
        receipts := receipts || jsonb_build_array(jsonb_build_object('outcome', 'collection_complete',
          'chest_instance_id', chest_id, 'tier', chest.tier, 'coins', 0, 'gems', 0, 'items', items));
        continue;
      end if;
      items := jsonb_build_array(private.economy_grant_chest_item(keeper, p_request_id,
        chest_id, chest.tier, pool->>private.economy_random_int(jsonb_array_length(pool))));
    elsif chest.tier = 'special' then
      -- No guessing the event identity for imported chests. Import must supply it.
      rules := catalog->'special_chests'->chest.special_chest_id;
      if rules is null then raise exception 'economy_special_chest_unknown'; end if;
      coin_reward := (rules->>'coins')::integer; gem_reward := (rules->>'gems')::integer;
      special_id := rules->>'egg';
      egg := private.economy_grant_chest_egg(keeper, p_request_id, chest_id, null, false, special_id);
      rolled := jsonb_build_object('emote', private.economy_random_unit() < .10);
    else
      rules := catalog->'tiers'->chest.tier;
      pity := not exists(select 1 from public.player_eggs where owner_id = keeper)
        and not exists(select 1 from private.egg_altar_eggs where owner_id = keeper and in_nest and not returned);
      rolled := private.economy_chest_roll(chest.tier, pity, array[
        private.economy_random_unit(), private.economy_random_unit(), private.economy_random_unit(),
        private.economy_random_unit(), private.economy_random_unit(), private.economy_random_unit()]);
      coin_reward := (rules->>'coins_min')::integer + private.economy_random_int(
        (rules->>'coins_max')::integer - (rules->>'coins_min')::integer + 1);
      if (rolled->>'gems')::boolean then
        gem_reward := (rules->>'gems_min')::integer + private.economy_random_int(
          (rules->>'gems_max')::integer - (rules->>'gems_min')::integer + 1);
      end if;
      if (rolled->>'egg')::boolean then
        egg := private.economy_grant_chest_egg(keeper, p_request_id, chest_id,
          rolled->>'rarity', (rolled->>'sinister')::boolean);
      end if;
      if (rolled->>'relic')::boolean then
        pool := private.economy_relic_drop_pool(keeper);
        items := items || jsonb_build_array(private.economy_grant_chest_item(keeper,
          p_request_id, chest_id, 'relic', pool->>private.economy_random_int(jsonb_array_length(pool))));
      end if;
    end if;
    if chest.tier not in ('portrait', 'title', 'music') and (rolled->>'emote')::boolean then
      pool := private.economy_remaining_pool(keeper, 'emote', catalog->'emote');
      if jsonb_array_length(pool) > 0 then
        items := items || jsonb_build_array(private.economy_grant_chest_item(keeper,
          p_request_id, chest_id, 'emote', pool->>private.economy_random_int(jsonb_array_length(pool))));
      end if;
    end if;
    if coin_reward > 0 or gem_reward > 0 then
      update public.player_wallets set coins = coins + coin_reward, gems = gems + gem_reward,
        revision = revision + 1, updated_at = clock_timestamp()
        where user_id = keeper returning * into wallet;
      if coin_reward > 0 then
        perform private.append_economy_ledger_entry(keeper, p_request_id, 'coins', 'coins',
          'credit', 'chest', coin_reward, wallet.coins, chest_id::text);
      end if;
      if gem_reward > 0 then
        perform private.append_economy_ledger_entry(keeper, p_request_id, 'gems', 'gems',
          'credit', 'chest', gem_reward, wallet.gems, chest_id::text);
      end if;
    end if;
    receipt := jsonb_build_object('outcome', 'opened', 'chest_instance_id', chest_id,
      'tier', chest.tier, 'coins', coin_reward, 'gems', gem_reward, 'egg', egg, 'items', items,
      'catalog_version', catalog->'version');
    update public.player_chest_instances set state = 'opened', opened_at = clock_timestamp(),
      opened_request_id = p_request_id, opening_receipt = receipt where id = chest_id;
    perform private.append_economy_ledger_entry(keeper, p_request_id, 'chest', chest.tier,
      'consume', 'chest', -1, null, chest_id::text, jsonb_build_object('chest_instance_id', chest_id));
    receipts := receipts || jsonb_build_array(receipt); opened_count := opened_count + 1;
  end loop;
  update public.player_economy_authority set server_revision = server_revision +
    case when opened_count > 0 then 1 else 0 end where user_id = keeper returning server_revision into version;
  response := jsonb_build_object('chests', receipts, 'coins', wallet.coins, 'gems', wallet.gems,
    'wallet_revision', wallet.revision, 'server_revision', version);
  perform private.complete_economy_mutation(keeper, p_request_id, response);
  return response;
end;
$$;
