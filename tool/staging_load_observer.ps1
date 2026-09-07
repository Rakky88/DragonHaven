#requires -Version 7.0
# One bounded, read-only diagnostic sample. No account IDs, addresses or SQL
# text from running queries are returned. This is not a peak-capacity metric.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRef = $env:STAGING_SUPABASE_PROJECT_REF
if ($projectRef -notmatch '^[a-z0-9]{20}$' -or
    $projectRef -eq 'tnzathhutuwmohmjfrlo' -or
    $env:STAGING_SUPABASE_URL.TrimEnd('/') -ne "https://$projectRef.supabase.co") {
    throw 'Load observation requires the exact isolated staging project.'
}
if ([string]::IsNullOrWhiteSpace($env:STAGING_SUPABASE_ACCESS_TOKEN)) {
    throw 'Protected staging management configuration is missing.'
}
$query = @'
select now() as observed_at_utc,
  (select count(*) from auth.users where email like 'load-%@dragonhaven-load.invalid'
    and raw_app_meta_data ? 'dragonhaven_load_run' and created_at > now() - interval '2 hours') as synthetic_accounts,
  (select count(*) from auth.users where email like 'load-%@dragonhaven-load.invalid'
    and raw_app_meta_data ? 'dragonhaven_load_run' and created_at > now() - interval '2 hours'
    and last_sign_in_at is not null) as synthetic_accounts_signed_in,
  (select min(last_sign_in_at) from auth.users where email like 'load-%@dragonhaven-load.invalid'
    and raw_app_meta_data ? 'dragonhaven_load_run' and created_at > now() - interval '2 hours') as first_synthetic_login,
  (select max(last_sign_in_at) from auth.users where email like 'load-%@dragonhaven-load.invalid'
    and raw_app_meta_data ? 'dragonhaven_load_run' and created_at > now() - interval '2 hours') as last_synthetic_login,
  (select count(*) from pg_stat_activity where backend_type = 'client backend'
    and pid <> pg_backend_pid()) as client_connections_excluding_observer,
  (select count(*) from pg_stat_activity where backend_type = 'client backend'
    and pid <> pg_backend_pid() and state = 'active') as active_client_connections,
  (select count(*) from pg_stat_activity where backend_type = 'client backend'
    and pid <> pg_backend_pid() and wait_event_type = 'Lock') as clients_waiting_for_lock,
  current_setting('max_connections')::integer as configured_max_connections;
'@
try {
    $rows = @(Invoke-RestMethod -Method Post -TimeoutSec 30 `
        -Uri "https://api.supabase.com/v1/projects/$projectRef/database/query" `
        -Headers @{ Authorization = "Bearer $env:STAGING_SUPABASE_ACCESS_TOKEN" } `
        -ContentType 'application/json' `
        -Body (ConvertTo-Json @{ query = $query; read_only = $true } -Compress))
} catch {
    throw 'The read-only staging load observation was unavailable.'
}
if ($rows.Count -ne 1) { throw 'Staging returned an unexpected observation.' }
# Emit only known aggregate fields, even if the provider response changes.
$evidence = [ordered]@{
    environment = 'staging'; readOnly = $true; peakMeasurement = $false
    observedAtUtc = [DateTime]::Parse($rows[0].observed_at_utc).ToUniversalTime().ToString('o')
}
foreach ($name in @('first_synthetic_login', 'last_synthetic_login')) {
    $value = $rows[0].$name
    $evidence[$name] = if ($null -eq $value) { $null } else {
        [DateTime]::Parse($value).ToUniversalTime().ToString('o')
    }
}
foreach ($name in @('synthetic_accounts', 'synthetic_accounts_signed_in',
    'client_connections_excluding_observer', 'active_client_connections',
    'clients_waiting_for_lock', 'configured_max_connections')) {
    $value = [long]$rows[0].$name
    if ($value -lt 0) { throw 'Staging returned an invalid aggregate count.' }
    $evidence[$name] = $value
}
$evidence | ConvertTo-Json
