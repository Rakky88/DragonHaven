-- Fetch the complete social dashboard in one authenticated round trip.
-- The existing RPCs remain available for backwards compatibility and writes.

create or replace function public.get_online_snapshot()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  result jsonb;
begin
  if auth.uid() is null then
    raise exception 'group_login_required';
  end if;

  select jsonb_build_object(
    'profile', (
      select to_jsonb(profile_row)
      from public.get_my_profile() as profile_row
      limit 1
    ),
    'friends', coalesce((
      select jsonb_agg(to_jsonb(friend_row))
      from public.list_my_friends() as friend_row
    ), '[]'::jsonb),
    'requests', coalesce((
      select jsonb_agg(to_jsonb(request_row))
      from public.list_friend_requests() as request_row
    ), '[]'::jsonb),
    'blocked_keepers', coalesce((
      select jsonb_agg(to_jsonb(blocked_row))
      from public.list_blocked_keepers() as blocked_row
    ), '[]'::jsonb),
    'group_status', (
      select to_jsonb(status_row)
      from public.get_current_group_adventure_status() as status_row
      limit 1
    ),
    'group_lobbies', coalesce((
      select jsonb_agg(to_jsonb(lobby_row))
      from public.list_group_adventures() as lobby_row
    ), '[]'::jsonb),
    'trades', coalesce((
      select jsonb_agg(to_jsonb(trade_row))
      from public.list_my_trades() as trade_row
    ), '[]'::jsonb),
    'trade_inventory', coalesce((
      select jsonb_agg(to_jsonb(inventory_row))
      from public.list_trade_inventory() as inventory_row
    ), '[]'::jsonb),
    'notifications', coalesce((
      select jsonb_agg(to_jsonb(notification_row))
      from public.list_social_notifications() as notification_row
    ), '[]'::jsonb)
  ) into result;

  if result->'profile' = 'null'::jsonb
    or result->'group_status' = 'null'::jsonb then
    raise exception 'invalid_online_snapshot';
  end if;
  return result;
end;
$$;

revoke all on function public.get_online_snapshot() from public, anon;
grant execute on function public.get_online_snapshot() to authenticated;
