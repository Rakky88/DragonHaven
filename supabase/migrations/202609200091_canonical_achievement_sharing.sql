-- Social publication follows confirmed achievements for migrated accounts.
-- Legacy accounts retain their existing sharing API until their own cutover.
create or replace function public.synchronize_conclave_achievements(p_achievement_ids text[])
returns integer language plpgsql security definer set search_path='' as $$
declare cid uuid; achievement text; inserted_count integer:=0;
  allowed_ids text[]:=coalesce(p_achievement_ids,array[]::text[]); confirmed jsonb;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,0));
  if exists(select 1 from public.player_economy_authority where user_id=auth.uid() and authority_mode='server') then
    select state->'achievements' into confirmed from private.canonical_game_states
      where owner_id=auth.uid() and authority_mode='server' and is_prepared;
    if confirmed is null then raise exception 'game_state_reconciliation_required'; end if;
    allowed_ids:=array(select value from jsonb_array_elements_text(confirmed)
      where value=any(allowed_ids));
  end if;
  select cm.conclave_id into cid from public.conclave_members cm join public.profiles p on p.user_id=cm.user_id
    where cm.user_id=auth.uid() and p.share_achievements_with_conclave;
  if cid is null then return 0; end if;
  foreach achievement in array allowed_ids loop
    if char_length(achievement) between 1 and 80 then
      insert into public.conclave_achievement_shares(conclave_id,user_id,achievement_id) values(cid,auth.uid(),achievement) on conflict do nothing;
      if found then
        insert into public.conclave_messages(conclave_id,sender_id,kind,body,payload) values(cid,auth.uid(),'achievement','Achievement unlocked!',jsonb_build_object('achievement_id',achievement));
        insert into public.conclave_chronicle(conclave_id,actor_id,kind,body) values(cid,auth.uid(),'achievement','A Keeper shared a new achievement.');
        inserted_count:=inserted_count+1;
      end if;
    end if;
  end loop;
  return inserted_count;
end $$;

revoke all on function public.synchronize_conclave_achievements(text[]) from public,anon;
grant execute on function public.synchronize_conclave_achievements(text[]) to authenticated;
