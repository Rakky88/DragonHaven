-- DragonHaven server-authoritative economy foundation.
--
-- This migration is deliberately dormant. It creates the transaction,
-- ownership and compatibility boundaries needed by future economy RPCs, but
-- does not redirect any current gameplay action and does not enable server
-- mutations for any keeper.

create table private.economy_contract (
  singleton boolean primary key default true check (singleton),
  protocol_version integer not null default 1 check (protocol_version > 0),
  minimum_client_build integer not null default 10061
    check (minimum_client_build > 0),
  mutations_enabled boolean not null default false,
  updated_at timestamptz not null default now()
);

insert into private.economy_contract(singleton)
values (true);

create table public.player_economy_authority (
  user_id uuid primary key references public.profiles(user_id)
    on delete cascade,
  authority_mode text not null default 'legacy_client'
    check (authority_mode in ('legacy_client', 'shadow', 'server')),
  protocol_version integer not null default 1 check (protocol_version > 0),
  server_revision bigint not null default 0 check (server_revision >= 0),
  activated_at timestamptz,
  updated_at timestamptz not null default now(),
  check (
    (authority_mode = 'server' and activated_at is not null)
    or authority_mode <> 'server'
  )
);

insert into public.player_economy_authority(user_id)
select profile.user_id
from public.profiles profile
on conflict (user_id) do nothing;

create table public.economy_mutation_requests (
  owner_id uuid not null references public.profiles(user_id)
    on delete cascade,
  request_id uuid not null,
  operation text not null
    check (operation ~ '^[a-z][a-z0-9_.]{2,79}$'),
  protocol_version integer not null check (protocol_version > 0),
  client_build integer not null check (client_build > 0),
  request_sha256 text not null
    check (request_sha256 ~ '^[0-9a-f]{64}$'),
  status text not null default 'processing'
    check (status in ('processing', 'succeeded', 'failed')),
  response jsonb,
  failure_code text,
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  expires_at timestamptz not null default (now() + interval '30 days'),
  primary key (owner_id, request_id),
  check (response is null or jsonb_typeof(response) = 'object'),
  check (response is null or octet_length(response::text) <= 32768),
  check (failure_code is null or failure_code ~ '^[a-z][a-z0-9_]{2,79}$'),
  check (
    (status = 'processing' and completed_at is null and response is null
      and failure_code is null)
    or (status = 'succeeded' and completed_at is not null
      and response is not null and failure_code is null)
    or (status = 'failed' and completed_at is not null
      and response is null and failure_code is not null)
  )
);

create index economy_mutation_requests_owner_created_idx
  on public.economy_mutation_requests(owner_id, created_at desc);
create index economy_mutation_requests_expiry_idx
  on public.economy_mutation_requests(expires_at);

create table public.player_item_instances (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(user_id)
    on delete cascade,
  item_kind text not null check (item_kind in (
    'relic', 'furniture', 'portrait', 'title', 'music', 'emote',
    'badge', 'portrait_frame', 'consumable'
  )),
  catalog_id text not null check (catalog_id ~ '^[A-Za-z0-9_.-]{1,100}$'),
  state text not null default 'owned'
    check (state in ('owned', 'reserved', 'equipped', 'consumed')),
  tradeable boolean not null default false,
  source_type text not null check (source_type in (
    'legacy_import', 'adventure', 'trial', 'chest', 'shop', 'trade',
    'achievement', 'daily', 'special_event', 'purchase', 'support', 'system'
  )),
  source_reference text,
  metadata jsonb not null default '{}'::jsonb,
  acquired_at timestamptz not null default now(),
  consumed_at timestamptz,
  updated_at timestamptz not null default now(),
  check (source_reference is null or char_length(source_reference) <= 160),
  check (jsonb_typeof(metadata) = 'object'),
  check (octet_length(metadata::text) <= 8192),
  check (
    (state = 'consumed' and consumed_at is not null)
    or (state <> 'consumed' and consumed_at is null)
  )
);

create index player_item_instances_owner_active_idx
  on public.player_item_instances(owner_id, item_kind, catalog_id)
  where state <> 'consumed';

create table public.player_chest_instances (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(user_id)
    on delete cascade,
  tier text not null check (tier in (
    'wooden', 'silver', 'gold', 'dragon', 'mythical', 'sinister',
    'special', 'portrait', 'title', 'music'
  )),
  state text not null default 'owned'
    check (state in ('owned', 'reserved', 'opened')),
  tradeable boolean not null default false,
  source_type text not null check (source_type in (
    'legacy_import', 'adventure', 'trial', 'chest', 'shop', 'trade',
    'achievement', 'daily', 'special_event', 'purchase', 'support', 'system'
  )),
  source_reference text,
  acquired_at timestamptz not null default now(),
  opened_at timestamptz,
  opened_request_id uuid,
  updated_at timestamptz not null default now(),
  check (source_reference is null or char_length(source_reference) <= 160),
  check (
    (state = 'opened' and opened_at is not null and opened_request_id is not null)
    or (state <> 'opened' and opened_at is null and opened_request_id is null)
  ),
  foreign key (owner_id, opened_request_id)
    references public.economy_mutation_requests(owner_id, request_id)
);

create index player_chest_instances_owner_active_idx
  on public.player_chest_instances(owner_id, tier, acquired_at)
  where state <> 'opened';

create table public.economy_reward_claims (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(user_id)
    on delete cascade,
  claim_type text not null check (claim_type ~ '^[a-z][a-z0-9_.]{2,79}$'),
  claim_key text not null check (char_length(claim_key) between 1 and 160),
  status text not null default 'available'
    check (status in ('available', 'claimed', 'expired', 'cancelled')),
  reward_plan jsonb not null default '{}'::jsonb,
  result jsonb,
  available_at timestamptz not null default now(),
  expires_at timestamptz,
  claimed_at timestamptz,
  claimed_request_id uuid,
  updated_at timestamptz not null default now(),
  unique (owner_id, claim_type, claim_key),
  check (jsonb_typeof(reward_plan) = 'object'),
  check (octet_length(reward_plan::text) <= 16384),
  check (result is null or jsonb_typeof(result) = 'object'),
  check (result is null or octet_length(result::text) <= 32768),
  check (expires_at is null or expires_at > available_at),
  check (
    (status = 'claimed' and claimed_at is not null
      and claimed_request_id is not null and result is not null)
    or (status <> 'claimed' and claimed_at is null
      and claimed_request_id is null and result is null)
  ),
  foreign key (owner_id, claimed_request_id)
    references public.economy_mutation_requests(owner_id, request_id)
);

create index economy_reward_claims_owner_status_idx
  on public.economy_reward_claims(owner_id, status, available_at);

create table public.economy_ledger_entries (
  id bigint generated always as identity primary key,
  owner_id uuid not null references public.profiles(user_id)
    on delete cascade,
  request_id uuid,
  asset_kind text not null check (asset_kind in (
    'coins', 'gems', 'item', 'chest', 'egg', 'dragon', 'reward'
  )),
  asset_key text not null check (char_length(asset_key) between 1 and 160),
  mutation_type text not null check (mutation_type in (
    'opening_balance', 'credit', 'debit', 'reserve', 'release', 'grant',
    'consume', 'transfer_in', 'transfer_out', 'refund', 'adjustment'
  )),
  source_type text not null check (source_type in (
    'legacy_import', 'adventure', 'trial', 'chest', 'shop', 'trade',
    'achievement', 'daily', 'special_event', 'purchase', 'refund',
    'support', 'system'
  )),
  quantity_delta bigint not null check (quantity_delta <> 0),
  balance_after bigint,
  source_reference text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  check (source_reference is null or char_length(source_reference) <= 160),
  check (jsonb_typeof(metadata) = 'object'),
  check (octet_length(metadata::text) <= 8192),
  check (
    (asset_kind in ('coins', 'gems') and balance_after is not null
      and balance_after >= 0)
    or (asset_kind not in ('coins', 'gems') and balance_after is null)
  ),
  check (
    request_id is not null
    or mutation_type = 'opening_balance'
    or source_type in ('legacy_import', 'support')
  ),
  foreign key (owner_id, request_id)
    references public.economy_mutation_requests(owner_id, request_id)
);

create index economy_ledger_entries_owner_created_idx
  on public.economy_ledger_entries(owner_id, created_at desc, id desc);
create index economy_ledger_entries_request_idx
  on public.economy_ledger_entries(owner_id, request_id)
  where request_id is not null;

create table private.economy_rate_limit_buckets (
  owner_id uuid not null references public.profiles(user_id)
    on delete cascade,
  operation text not null check (operation ~ '^[a-z][a-z0-9_.]{2,79}$'),
  request_count integer not null default 0 check (request_count >= 0),
  reset_at timestamptz not null,
  updated_at timestamptz not null default now(),
  primary key (owner_id, operation)
);

alter table public.player_economy_authority enable row level security;
alter table public.economy_mutation_requests enable row level security;
alter table public.player_item_instances enable row level security;
alter table public.player_chest_instances enable row level security;
alter table public.economy_reward_claims enable row level security;
alter table public.economy_ledger_entries enable row level security;

revoke all on table private.economy_contract
  from public, anon, authenticated;
revoke all on table private.economy_rate_limit_buckets
  from public, anon, authenticated;
revoke all on table public.player_economy_authority
  from public, anon, authenticated;
revoke all on table public.economy_mutation_requests
  from public, anon, authenticated;
revoke all on table public.player_item_instances
  from public, anon, authenticated;
revoke all on table public.player_chest_instances
  from public, anon, authenticated;
revoke all on table public.economy_reward_claims
  from public, anon, authenticated;
revoke all on table public.economy_ledger_entries
  from public, anon, authenticated;

create or replace function private.bootstrap_player_economy_authority()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.player_economy_authority(user_id)
  values (new.user_id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

create trigger profiles_bootstrap_player_economy_authority
after insert on public.profiles
for each row execute function private.bootstrap_player_economy_authority();

create trigger player_economy_authority_touch_updated_at
before update on public.player_economy_authority
for each row execute function private.touch_updated_at();
create trigger player_item_instances_touch_updated_at
before update on public.player_item_instances
for each row execute function private.touch_updated_at();
create trigger player_chest_instances_touch_updated_at
before update on public.player_chest_instances
for each row execute function private.touch_updated_at();
create trigger economy_reward_claims_touch_updated_at
before update on public.economy_reward_claims
for each row execute function private.touch_updated_at();

create or replace function private.reject_economy_ledger_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- The only destructive exception is the nested foreign-key cascade caused
  -- by deleting the owning profile/account. Direct ledger updates/deletes and
  -- ordinary administrative cleanup remain forbidden.
  if tg_op = 'DELETE' and pg_trigger_depth() > 1
    and not exists (
      select 1 from public.profiles where user_id = old.owner_id
    ) then
    return old;
  end if;
  raise exception 'economy_ledger_is_append_only';
end;
$$;

create trigger economy_ledger_entries_reject_change
before update or delete on public.economy_ledger_entries
for each row execute function private.reject_economy_ledger_change();

create or replace function private.assert_economy_client(
  p_protocol_version integer,
  p_client_build integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  contract private.economy_contract%rowtype;
  authority public.player_economy_authority%rowtype;
begin
  if current_user_id is null then
    raise exception 'economy_login_required';
  end if;
  if p_protocol_version is null or p_client_build is null then
    raise exception 'economy_client_upgrade_required';
  end if;
  select * into contract
  from private.economy_contract
  where singleton = true;
  if not found then
    raise exception 'economy_contract_unavailable';
  end if;
  select * into authority
  from public.player_economy_authority
  where user_id = current_user_id;
  if not found or authority.authority_mode <> 'server'
    or not contract.mutations_enabled then
    raise exception 'economy_mutations_disabled';
  end if;
  if p_protocol_version <> contract.protocol_version
    or p_protocol_version <> authority.protocol_version
    or p_client_build < contract.minimum_client_build then
    raise exception 'economy_client_upgrade_required';
  end if;
end;
$$;

create or replace function private.consume_economy_rate_limit(
  p_owner_id uuid,
  p_operation text,
  p_limit integer,
  p_window_seconds integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  bucket private.economy_rate_limit_buckets%rowtype;
  current_time timestamptz := clock_timestamp();
begin
  if p_owner_id is null or p_operation is null
    or p_operation !~ '^[a-z][a-z0-9_.]{2,79}$'
    or p_limit is null or p_window_seconds is null
    or p_limit not between 1 and 300
    or p_window_seconds not between 1 and 86400 then
    raise exception 'economy_rate_limit_invalid';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(
    p_owner_id::text || ':' || p_operation, 0
  ));
  select * into bucket
  from private.economy_rate_limit_buckets
  where owner_id = p_owner_id and operation = p_operation
  for update;
  if not found then
    insert into private.economy_rate_limit_buckets(
      owner_id, operation, request_count, reset_at
    ) values (
      p_owner_id, p_operation, 1,
      current_time + make_interval(secs => p_window_seconds)
    );
  elsif bucket.reset_at <= current_time then
    update private.economy_rate_limit_buckets
    set request_count = 1,
        reset_at = current_time + make_interval(secs => p_window_seconds),
        updated_at = current_time
    where owner_id = p_owner_id and operation = p_operation;
  elsif bucket.request_count >= p_limit then
    raise exception 'economy_rate_limited';
  else
    update private.economy_rate_limit_buckets
    set request_count = request_count + 1,
        updated_at = current_time
    where owner_id = p_owner_id and operation = p_operation;
  end if;
end;
$$;

create or replace function private.begin_economy_mutation(
  p_request_id uuid,
  p_operation text,
  p_protocol_version integer,
  p_client_build integer,
  p_payload jsonb,
  p_rate_limit integer default 30,
  p_rate_window_seconds integer default 60
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  request_hash text;
  existing public.economy_mutation_requests%rowtype;
begin
  perform private.assert_economy_client(p_protocol_version, p_client_build);
  if p_request_id is null
    or p_operation is null
    or p_operation !~ '^[a-z][a-z0-9_.]{2,79}$'
    or p_payload is null
    or jsonb_typeof(p_payload) <> 'object'
    or octet_length(p_payload::text) > 32768 then
    raise exception 'economy_request_invalid';
  end if;
  request_hash := encode(
    extensions.digest(convert_to(p_payload::text, 'utf8'), 'sha256'),
    'hex'
  );
  perform pg_advisory_xact_lock(hashtextextended(
    current_user_id::text || ':' || p_request_id::text, 0
  ));
  select * into existing
  from public.economy_mutation_requests
  where owner_id = current_user_id and request_id = p_request_id
  for update;
  if found then
    if existing.operation <> p_operation
      or existing.request_sha256 <> request_hash then
      raise exception 'economy_idempotency_conflict';
    end if;
    return jsonb_build_object(
      'replayed', true,
      'status', existing.status,
      'response', existing.response,
      'failure_code', existing.failure_code
    );
  end if;
  perform private.consume_economy_rate_limit(
    current_user_id, p_operation, p_rate_limit, p_rate_window_seconds
  );
  insert into public.economy_mutation_requests(
    owner_id, request_id, operation, protocol_version, client_build,
    request_sha256
  ) values (
    current_user_id, p_request_id, p_operation, p_protocol_version,
    p_client_build, request_hash
  );
  return jsonb_build_object('replayed', false, 'status', 'processing');
end;
$$;

create or replace function private.complete_economy_mutation(
  p_owner_id uuid,
  p_request_id uuid,
  p_response jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_owner_id is null or p_request_id is null
    or p_response is null
    or jsonb_typeof(p_response) <> 'object'
    or octet_length(p_response::text) > 32768 then
    raise exception 'economy_response_invalid';
  end if;
  update public.economy_mutation_requests
  set status = 'succeeded', response = p_response, completed_at = now()
  where owner_id = p_owner_id and request_id = p_request_id
    and status = 'processing';
  if not found then
    raise exception 'economy_request_not_processing';
  end if;
end;
$$;

create or replace function private.fail_economy_mutation(
  p_owner_id uuid,
  p_request_id uuid,
  p_failure_code text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_owner_id is null or p_request_id is null
    or p_failure_code is null
    or p_failure_code !~ '^[a-z][a-z0-9_]{2,79}$' then
    raise exception 'economy_failure_invalid';
  end if;
  update public.economy_mutation_requests
  set status = 'failed', failure_code = p_failure_code, completed_at = now()
  where owner_id = p_owner_id and request_id = p_request_id
    and status = 'processing';
  if not found then
    raise exception 'economy_request_not_processing';
  end if;
end;
$$;

create or replace function private.append_economy_ledger_entry(
  p_owner_id uuid,
  p_request_id uuid,
  p_asset_kind text,
  p_asset_key text,
  p_mutation_type text,
  p_source_type text,
  p_quantity_delta bigint,
  p_balance_after bigint,
  p_source_reference text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  result_id bigint;
begin
  insert into public.economy_ledger_entries(
    owner_id, request_id, asset_kind, asset_key, mutation_type,
    source_type, quantity_delta, balance_after, source_reference, metadata
  ) values (
    p_owner_id, p_request_id, p_asset_kind, p_asset_key, p_mutation_type,
    p_source_type, p_quantity_delta, p_balance_after, p_source_reference,
    coalesce(p_metadata, '{}'::jsonb)
  )
  returning id into result_id;
  return result_id;
end;
$$;

create or replace function public.get_my_economy_contract()
returns table (
  authority_mode text,
  protocol_version integer,
  minimum_client_build integer,
  mutations_enabled boolean,
  server_revision bigint,
  wallet_revision bigint
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    coalesce(authority.authority_mode, 'legacy_client'),
    contract.protocol_version,
    contract.minimum_client_build,
    contract.mutations_enabled and
      coalesce(authority.authority_mode = 'server', false),
    coalesce(authority.server_revision, 0),
    coalesce(wallet.revision, 0)
  from private.economy_contract contract
  left join public.player_economy_authority authority
    on authority.user_id = auth.uid()
  left join public.player_wallets wallet
    on wallet.user_id = auth.uid()
  where contract.singleton = true and auth.uid() is not null
$$;

revoke all on function private.bootstrap_player_economy_authority()
  from public, anon, authenticated;
revoke all on function private.reject_economy_ledger_change()
  from public, anon, authenticated;
revoke all on function private.assert_economy_client(integer, integer)
  from public, anon, authenticated;
revoke all on function private.consume_economy_rate_limit(uuid, text, integer, integer)
  from public, anon, authenticated;
revoke all on function private.begin_economy_mutation(
  uuid, text, integer, integer, jsonb, integer, integer
) from public, anon, authenticated;
revoke all on function private.complete_economy_mutation(uuid, uuid, jsonb)
  from public, anon, authenticated;
revoke all on function private.fail_economy_mutation(uuid, uuid, text)
  from public, anon, authenticated;
revoke all on function private.append_economy_ledger_entry(
  uuid, uuid, text, text, text, text, bigint, bigint, text, jsonb
) from public, anon, authenticated;
revoke all on function public.get_my_economy_contract()
  from public, anon;
grant execute on function public.get_my_economy_contract()
  to authenticated;

comment on table private.economy_contract is
  'Dormant global contract for future server-authoritative economy RPCs.';
comment on table public.economy_ledger_entries is
  'Append-only audit trail; only an owning profile deletion may cascade rows.';
comment on function public.get_my_economy_contract() is
  'Read-only compatibility projection. It never enables or performs a mutation.';
