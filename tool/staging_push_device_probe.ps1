#requires -Version 7.0
# One synthetic notification to the operator's explicitly supplied staging device.
# The device token is a protected environment secret, never an artifact.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$project = $env:STAGING_SUPABASE_PROJECT_REF
if ($project -cne 'vtmjkhzalalozpfnbvsd' -or
    $env:STAGING_PUSH_PROBE_TOKEN -cnotmatch '^[A-Za-z0-9_:.-]{20,4096}$') {
  throw 'Registered staging project and a protected test-device token are required.'
}
function Invoke-ProbeQuery([string]$Query) {
  try {
    Invoke-RestMethod -Method Post -TimeoutSec 30 `
      -Uri "https://api.supabase.com/v1/projects/$project/database/query" `
      -Headers @{ Authorization = "Bearer $env:STAGING_SUPABASE_ACCESS_TOKEN" } `
      -ContentType 'application/json' -Body (ConvertTo-Json @{ query=$Query; read_only=$false } -Compress)
  } catch { throw 'Staging push probe database request failed.' }
}
$owner = [guid]::NewGuid().ToString()
$installation = [guid]::NewGuid().ToString()
$notice = [guid]::NewGuid().ToString()
try {
  $query = @"
begin;
do `$`$ begin
  if (select enabled from private.push_runtime) or exists(select 1 from private.push_devices) then
    raise exception 'requires_isolated_dormant_staging_push';
  end if;
end; `$`$;
insert into auth.users(id,email,email_confirmed_at) values('$owner','$owner@push-probe.invalid',now());
select set_config('request.jwt.claim.sub','$owner',true);
select public.ensure_my_online_account();
select public.register_my_push_device('$owner','$installation','$env:STAGING_PUSH_PROBE_TOKEN','nl',array['friend_request']);
update private.push_runtime set enabled=true, next_dispatch_at=now() where singleton;
insert into public.social_notifications(id,user_id,kind,entity_id) values('$notice','$owner','friend_request',gen_random_uuid());
select private.dispatch_social_push_tick();
commit;
select true as probe_enqueued;
"@
  $null = Invoke-ProbeQuery $query
  $accepted = $false
  for ($attempt = 0; $attempt -lt 24; $attempt++) {
    Start-Sleep -Seconds 5
    $result = Invoke-ProbeQuery "select count(*) filter(where o.state='accepted') as accepted, count(*) filter(where n.acknowledged_at is not null) as read_count from private.social_push_outbox o join public.social_notifications n on n.id=o.notification_id where o.notification_id='$notice';"
    if ([int]$result.accepted -eq 1) {
      if ([int]$result.read_count -ne 0) { throw 'Push acceptance incorrectly acknowledged the inbox.' }
      $accepted = $true
      break
    }
  }
  if (-not $accepted) { throw 'FCM did not accept the test push within the bounded device probe.' }
  'PASS: real staging FCM acceptance; inbox remains unread; confirm OS display separately.'
} finally {
  $cleanup = @"
begin;
do `$`$ begin
  if exists(select 1 from auth.users where id='$owner') then
    update private.push_runtime set enabled=false where singleton;
    delete from auth.users where id='$owner';
  end if;
end; `$`$;
commit;
select true as probe_cleanup_completed;
"@
  $null = Invoke-ProbeQuery $cleanup
  'CLEANUP: synthetic account/device/inbox/outbox removed; staging push disabled.'
}
