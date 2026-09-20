begin;
set local statement_timeout='45s';
do $$
declare keeper uuid:=gen_random_uuid(); partner uuid:=gen_random_uuid(); dragon_id uuid;
  pool jsonb; relic_count integer; pair_id uuid; result jsonb;
begin
  if private.dragon_expertise_maximum('ascended','mastery',true,'might')<>1200
      or private.dragon_expertise_maximum('hatchling',null,false,'arcana')<>1000 then
    raise exception 'expertise_contract_transport_limits'; end if;
  if has_function_privilege('authenticated','public.invite_seasonal_pair_adventure_v68(text,text,integer,integer,integer)','execute')
      or has_function_privilege('authenticated','public.respond_seasonal_pair_adventure_v68(uuid,boolean,text,integer,integer,integer)','execute') then
    raise exception 'expertise_contract_legacy_wrappers_exposed'; end if;
  insert into auth.users(id,email,email_confirmed_at) values
    (keeper,keeper::text||'@expertise-contract.invalid',now()),
    (partner,partner::text||'@expertise-contract.invalid',now());
  perform set_config('request.jwt.claim.role','authenticated',true);
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  perform public.ensure_my_online_account();
  perform set_config('request.jwt.claim.sub',partner::text,true);
  perform public.ensure_my_online_account();
  perform set_config('request.jwt.claim.sub',keeper::text,true);
  dragon_id:=private.upsert_group_dragon(keeper,jsonb_build_object(
    'client_id','concentrated','name','Concentrated','lineage_id','sinisterra',
    'stage','ascended','xp',3400,'might',1200,'arcana',0,'spirit',0,
    'evolution_path','mastery','sinister',true));
  if (select might from public.player_dragons where id=dragon_id)<>1200 then
    raise exception 'expertise_contract_concentrated_dragon'; end if;
  insert into public.social_showcases(user_id,favorite_dragon_might,
    favorite_dragon_arcana,favorite_dragon_spirit) values(keeper,1200,0,0);
  insert into public.seasonal_pair_adventures(occurrence_key,creator_id,partner_id,
    creator_dragon_id,creator_might,creator_arcana,creator_spirit,simulated)
    values('expertise-contract',keeper,partner,'concentrated',1200,0,0,true)
    returning id into pair_id;
  perform set_config('request.jwt.claim.sub',partner::text,true);
  perform public.respond_seasonal_pair_adventure_v68(pair_id,true,'second',0,1200,0);
  if (select partner_arcana from public.seasonal_pair_adventures where id=pair_id)<>1200 then
    raise exception 'expertise_contract_pair_concentration'; end if;
  begin
    update public.player_dragons set spirit=-1 where id=dragon_id;
    raise exception 'expertise_contract_negative_accepted';
  exception when check_violation then null; end;
  begin
    update public.player_dragons set might=1201 where id=dragon_id;
    raise exception 'expertise_contract_oversized_accepted';
  exception when check_violation then null; end;
  pool:=private.economy_relic_drop_pool(keeper);
  select count(*) into relic_count from jsonb_array_elements_text(pool) r where r='sparkAstrolabe';
  if jsonb_array_length(pool)<>65 or relic_count<>1
      or (private.economy_chest_catalog()->>'version')::integer<>4
      or private.economy_chest_catalog()->'unique_relics' ? 'sparkAstrolabe' then
    raise exception 'expertise_contract_drop_pool'; end if;
  if exists(select 1 from information_schema.columns where table_schema='public'
      and column_name in ('dragon_spark','dragonSpark')) then
    raise exception 'expertise_contract_hidden_value_exposed'; end if;
end $$;
select true as shared_expertise_contract_passed;
rollback;
