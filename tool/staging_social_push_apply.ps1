#requires -Version 7.0
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRef = $env:STAGING_SUPABASE_PROJECT_REF
if ($projectRef -cne 'vtmjkhzalalozpfnbvsd' -or
    $env:STAGING_SUPABASE_URL.TrimEnd('/') -cne "https://$projectRef.supabase.co") {
  throw 'This apply script only targets the registered staging project.'
}
$required = @('SUPABASE_ACCESS_TOKEN','SUPABASE_DB_PASSWORD',
  'STAGING_SUPABASE_ACCESS_TOKEN','FIREBASE_MESSAGING_SERVICE_ACCOUNT','PUSH_DISPATCH_SECRET')
foreach ($name in $required) {
  if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) {
    throw "Missing protected configuration: $name."
  }
}
$account = $env:FIREBASE_MESSAGING_SERVICE_ACCOUNT | ConvertFrom-Json
if ($account.project_id -cne 'dragonhaven-prod-rakky88' -or
    $env:PUSH_DISPATCH_SECRET -cnotmatch '^[a-f0-9]{64}$') {
  throw 'The staging sender identity or dispatch secret is invalid.'
}
supabase link --project-ref $projectRef --password $env:SUPABASE_DB_PASSWORD
if ($LASTEXITCODE -ne 0) { throw 'Staging link failed.' }
$state = (supabase migration list --linked --output-format json | Out-String) | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Migration history unavailable.' }
$remote = @($state.migrations | ForEach-Object { [string]$_.remote } | Where-Object { $_ } | Sort-Object)
$local = @(Get-ChildItem supabase/migrations -Filter '*.sql' | ForEach-Object { $_.BaseName.Split('_')[0] } | Sort-Object)
$baseline = @($local | Where-Object { [long]$_ -le 202609070049 })
$pending = @($local | Where-Object { [long]$_ -gt 202609070049 })
if (@(Compare-Object $remote $baseline).Count -ne 0 -or
    @(Compare-Object $pending @('202609070050','202609070051')).Count -ne 0) {
  throw 'Requires exact schema 49 and only pending migrations 50-51.'
}
./tool/staging_social_push_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN -RehearseMigrations
supabase db lint --linked --level error --fail-on error --output-format json
if ($LASTEXITCODE -ne 0) { throw 'Pre-apply lint failed.' }
supabase db push --linked --include-all --dry-run
if ($LASTEXITCODE -ne 0) { throw 'Migration dry run failed.' }
supabase db push --linked --include-all --yes
if ($LASTEXITCODE -ne 0) { throw 'Dormant push migration apply failed.' }
./tool/staging_social_push_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
$secretPath = Join-Path ([IO.Path]::GetTempPath()) ('dragonhaven-push-' + [guid]::NewGuid() + '.env')
try {
  $compactAccount = $account | ConvertTo-Json -Depth 8 -Compress
  if ($compactAccount.Contains("'")) { throw 'Unexpected sender key encoding.' }
  [IO.File]::WriteAllText($secretPath, "FIREBASE_PROJECT_ID=dragonhaven-prod-rakky88`nFIREBASE_MESSAGING_SERVICE_ACCOUNT='$compactAccount'`nPUSH_DISPATCH_SECRET=$env:PUSH_DISPATCH_SECRET`n")
  supabase secrets set --project-ref $projectRef --env-file $secretPath
  if ($LASTEXITCODE -ne 0) { throw 'Protected worker configuration failed.' }
} finally { Remove-Item -LiteralPath $secretPath -Force -ErrorAction SilentlyContinue }
supabase functions deploy dispatch-social-push --project-ref $projectRef --no-verify-jwt --use-api
if ($LASTEXITCODE -ne 0) { throw 'Push worker deployment failed.' }
# Secret format was validated above. Never print the query or provider response.
$query = @"
begin;
do `$`$ begin
  if (select enabled from private.push_runtime) then raise exception 'push_must_remain_dormant'; end if;
  if exists(select 1 from vault.secrets where name='dragonhaven_push_dispatch_secret') then
    perform vault.update_secret((select id from vault.secrets where name='dragonhaven_push_dispatch_secret'), '$env:PUSH_DISPATCH_SECRET');
  else
    perform vault.create_secret('$env:PUSH_DISPATCH_SECRET','dragonhaven_push_dispatch_secret','DragonHaven staging worker authentication');
  end if;
end; `$`$;
update private.push_runtime set endpoint='https://$projectRef.supabase.co/functions/v1/dispatch-social-push' where singleton;
commit;
select true as push_configuration_saved;
"@
try {
  $result = Invoke-RestMethod -Method Post -TimeoutSec 45 `
    -Uri "https://api.supabase.com/v1/projects/$projectRef/database/query" `
    -Headers @{ Authorization = "Bearer $env:STAGING_SUPABASE_ACCESS_TOKEN" } `
    -ContentType 'application/json' -Body (ConvertTo-Json @{ query=$query; read_only=$false } -Compress)
  if (($result | ConvertTo-Json) -notmatch '"push_configuration_saved"\s*:\s*true') { throw 'Missing proof.' }
} catch { throw 'Protected staging Vault configuration failed.' }
./tool/release_server_preflight.ps1 -ExpectedProjectRef $projectRef `
  -ExpectedUrl $env:STAGING_SUPABASE_URL -ExpectedPublishableKey $env:STAGING_SUPABASE_PUBLISHABLE_KEY
'PASS: staging schema 51, worker configured, push remains disabled; production untouched.'
