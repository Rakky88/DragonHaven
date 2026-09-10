#requires -Version 7.0
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'canonical_contract_history_test.ps1')
$projectRef = $env:STAGING_SUPABASE_PROJECT_REF
if ($projectRef -cne 'vtmjkhzalalozpfnbvsd' -or
    $env:STAGING_SUPABASE_URL.TrimEnd('/') -cne "https://$projectRef.supabase.co") {
  throw 'This worker apply only targets registered DragonHaven staging.'
}
foreach ($name in @('SUPABASE_ACCESS_TOKEN','SUPABASE_DB_PASSWORD','STAGING_SUPABASE_ACCESS_TOKEN')) {
  if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) {
    throw "Missing protected staging configuration: $name."
  }
}
if (-not (Test-Path -LiteralPath 'supabase/functions/execute-game-command/bundle.generated.ts')) {
  throw 'Compile the server game from this checkout before deploying.'
}
supabase link --project-ref $projectRef --password $env:SUPABASE_DB_PASSWORD
if ($LASTEXITCODE -ne 0) { throw 'Staging link failed.' }
$state = (supabase migration list --linked --output-format json | Out-String) | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Migration history unavailable.' }
$remote = @($state.migrations | ForEach-Object { [string]$_.remote } | Where-Object { $_ } | Sort-Object)
$local = @(Get-ChildItem supabase/migrations -Filter '*.sql' | ForEach-Object { $_.BaseName.Split('_')[0] } | Sort-Object)
$expectedRemote = @($local | Where-Object { [long]$_ -le [long]$remote[-1] })
if ($local[-1] -cne '202609100079' -or $local.Count -ne 79 -or
    $remote[-1] -notin @('202609090065','202609100066','202609100067','202609100068','202609100069','202609100070','202609100071','202609100072','202609100073','202609100074','202609100075','202609100076','202609100077','202609100078','202609100079') -or
    @(Compare-Object $remote $expectedRemote).Count -ne 0) {
  throw 'Requires exact registered staging schema 65 through 79 and the reviewed canonical migrations.'
}
./tool/staging_endless_sunwake_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN `
  -RehearseMigrations:($remote[-1] -ceq '202609090065')
./tool/staging_canonical_social_claim_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN `
  -RehearseMigrations:([long]$remote[-1] -lt 202609100067)
./tool/staging_canonical_social_projection_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN `
  -RehearseMigrations:([long]$remote[-1] -lt 202609100068)
./tool/staging_canonical_social_reservation_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN `
  -RehearseMigrations:([long]$remote[-1] -lt 202609100070)
./tool/staging_canonical_group_lifecycle_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN `
  -RehearseMigrations:([long]$remote[-1] -lt 202609100071)
./tool/staging_canonical_pair_lifecycle_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN `
  -RehearseMigrations:([long]$remote[-1] -lt 202609100072)
./tool/staging_canonical_beacon_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN `
  -RehearseMigrations:([long]$remote[-1] -lt 202609100073)
./tool/staging_canonical_trade_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN `
  -RehearseMigrations:([long]$remote[-1] -lt 202609100074)
./tool/staging_wide_trial_score_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN `
  -RehearseMigrations:([long]$remote[-1] -lt 202609100078)
./tool/staging_canonical_seasonal_trial_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN `
  -RehearseMigrations:([long]$remote[-1] -lt 202609100076)
./tool/staging_canonical_group_cleanup_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN `
  -RehearseMigrations:([long]$remote[-1] -lt 202609100077)
./tool/staging_canonical_account_activation_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN `
  -RehearseMigrations:([long]$remote[-1] -lt 202609100079)
# Schema 69's internal-entry grant is the known, dormant staging defect.
# The reservation rollback contract above rehearses the exact 70 repair and
# checks that grant before any DDL is applied. All compatibility contracts run
# after apply below; on other baselines they also run before apply as usual.
if ($remote[-1] -cne '202609100069') {
  ./tool/staging_canonical_game_contract.ps1 -ProjectRef $projectRef `
    -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
  ./tool/staging_canonical_import_contract.ps1 -ProjectRef $projectRef `
    -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
  ./tool/staging_canonical_game_read_contract.ps1 -ProjectRef $projectRef `
    -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
  ./tool/staging_canonical_receipt_contract.ps1 -ProjectRef $projectRef `
    -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
  ./tool/staging_canonical_ruleset_contract.ps1 -ProjectRef $projectRef `
    -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
  ./tool/staging_canonical_command_recovery_contract.ps1 -ProjectRef $projectRef `
    -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
}
$lintText = supabase db lint --linked --level error --fail-on error --output-format json | Out-String
$lintExit = $LASTEXITCODE
if ($lintExit -ne 0) {
  # Only the two revoked v74 bodies exposed by schema 75 are repairable here.
  # The wide-score rollback above must first prove all seven drops with RESTRICT
  # and every current wide RPC. Any other lint error still blocks deployment.
  $lint = $lintText | ConvertFrom-Json
  $expected = @('public.finalize_my_seasonal_event_prizes_v74','public.get_trial_rankings_v74')
  $known = $remote[-1] -in @('202609100075','202609100076','202609100077') -and
    @($lint.results).Count -eq 2 -and
    @(Compare-Object @($lint.results.function | Sort-Object) @($expected | Sort-Object)).Count -eq 0
  foreach ($finding in $lint.results) {
    $known = $known -and @($finding.issues).Count -eq 1 -and
      $finding.issues[0].level -ceq 'error' -and
      $finding.issues[0].sqlState -ceq '42804' -and
      $finding.issues[0].message -ceq 'structure of query does not match function result type' -and
      $finding.issues[0].detail -match '^Returned type bigint does not match expected type integer in column (5|8)\.$'
  }
  if (-not $known) { throw 'Pre-apply lint failed outside the rehearsed narrow-function repair.' }
  Write-Output 'Known schema-75 revoked narrow bodies confirmed; rehearsed migration 78 retires them.'
} else { Write-Output $lintText.Trim() }
if (@(Compare-Object $remote $local).Count -ne 0) {
  supabase db push --linked --include-all --dry-run
  if ($LASTEXITCODE -ne 0) { throw 'Migration dry run failed.' }
  supabase db push --linked --include-all --yes
  if ($LASTEXITCODE -ne 0) { throw 'Detached game migration apply failed.' }
}
./tool/staging_canonical_social_claim_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
./tool/staging_canonical_social_projection_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
./tool/staging_canonical_social_reservation_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
./tool/staging_canonical_group_lifecycle_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
./tool/staging_canonical_pair_lifecycle_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
./tool/staging_canonical_beacon_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
./tool/staging_canonical_trade_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
./tool/staging_canonical_game_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
./tool/staging_canonical_import_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
./tool/staging_canonical_game_read_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
./tool/staging_canonical_receipt_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
./tool/staging_canonical_ruleset_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
./tool/staging_canonical_command_recovery_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
./tool/staging_podium_feature_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
./tool/staging_endless_sunwake_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
./tool/staging_wide_trial_score_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
./tool/staging_canonical_seasonal_trial_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
./tool/staging_canonical_group_cleanup_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
./tool/staging_canonical_account_activation_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN
supabase functions deploy execute-game-command --project-ref $projectRef --no-verify-jwt --use-api
if ($LASTEXITCODE -ne 0) { throw 'Staging game worker deployment failed.' }
./tool/release_server_preflight.ps1 -ExpectedProjectRef $projectRef `
  -ExpectedUrl $env:STAGING_SUPABASE_URL -ExpectedPublishableKey $env:STAGING_SUPABASE_PUBLISHABLE_KEY
'PASS: detached staging game schema and worker deployed; live economy activation remains disabled.'
