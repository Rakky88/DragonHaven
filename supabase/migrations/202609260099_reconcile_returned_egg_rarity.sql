-- A returned egg can no longer have inspectable rarity metadata. Older
-- canonical workers removed the egg but retained its id in the derived rarity
-- collection, so the next exact restore correctly required reconciliation.
-- Normalize only that derived collection, advance the affected revision, and
-- let the existing canonical projection triggers rebuild public display data.
do $reconcile_returned_egg_rarity$
declare
  previous_role text := current_setting('request.jwt.claim.role', true);
  keeper uuid;
begin
  perform set_config('request.jwt.claim.role', 'service_role', true);

  -- Serialize with the command path before inspecting or repairing a keeper.
  for keeper in
    select g.owner_id
    from private.canonical_game_states g
    where g.is_prepared
      and g.authority_mode = 'server'
      and jsonb_typeof(g.state->'eggRarityRevealedIds') = 'array'
      and exists (
        select 1
        from jsonb_array_elements_text(
          g.state->'eggRarityRevealedIds'
        ) as revealed(id)
        where not (
          (g.state#>>'{pet,stage}' = 'egg'
            and g.state#>>'{pet,id}' = revealed.id)
          or g.state#>>'{incubatingEgg,id}' = revealed.id
          or exists (
            select 1
            from jsonb_array_elements(
              coalesce(g.state->'eggStash', '[]'::jsonb)
            ) as egg
            where egg->>'id' = revealed.id
          )
        )
      )
    order by g.owner_id
  loop
    perform pg_advisory_xact_lock(hashtextextended(keeper::text, 0));
    if exists (
      select 1
      from private.canonical_game_intents i
      where i.owner_id = keeper and i.status = 'processing'
    ) then
      raise exception 'canonical_rarity_reconciliation_busy';
    end if;
  end loop;

  with normalized as (
    select g.owner_id,
      jsonb_set(
        g.state,
        '{eggRarityRevealedIds}',
        coalesce((
          select jsonb_agg(revealed.id order by revealed.ordinality)
          from jsonb_array_elements_text(
            coalesce(g.state->'eggRarityRevealedIds', '[]'::jsonb)
          ) with ordinality as revealed(id, ordinality)
          where
            (g.state#>>'{pet,stage}' = 'egg'
              and g.state#>>'{pet,id}' = revealed.id)
            or g.state#>>'{incubatingEgg,id}' = revealed.id
            or exists (
              select 1
              from jsonb_array_elements(
                coalesce(g.state->'eggStash', '[]'::jsonb)
              ) as egg
              where egg->>'id' = revealed.id
            )
        ), '[]'::jsonb),
        true
      ) as next_state
    from private.canonical_game_states g
    where g.is_prepared
      and g.authority_mode = 'server'
      and jsonb_typeof(g.state->'eggRarityRevealedIds') = 'array'
  ), changed as (
    select n.owner_id, n.next_state
    from normalized n
    join private.canonical_game_states g using (owner_id)
    where n.next_state is distinct from g.state
  )
  update private.canonical_game_states g
  set state = changed.next_state,
      state_sha256 = private.game_json_sha256(changed.next_state),
      revision = g.revision + 1,
      updated_at = clock_timestamp()
  from changed
  where g.owner_id = changed.owner_id;

  perform set_config(
    'request.jwt.claim.role',
    coalesce(previous_role, ''),
    true
  );
exception when others then
  perform set_config(
    'request.jwt.claim.role',
    coalesce(previous_role, ''),
    true
  );
  raise;
end
$reconcile_returned_egg_rarity$;
