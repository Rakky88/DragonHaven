-- Store-compliant self-service account deletion. The client reauthenticates
-- with Supabase Auth immediately before this RPC is called.

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'account_delete_reauthentication_failed';
  end if;

  delete from auth.users account
  where account.id = current_user_id;
  if not found then raise exception 'account_delete_failed'; end if;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
