#requires -Version 7.0
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
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
$baseline = @($local | Where-Object { [long]$_ -le 202609090065 })
if ($local[-1] -cne '202609100067' -or
    (@(Compare-Object $remote $baseline).Count -ne 0 -and
     @(Compare-Object $remote @($baseline + '202609100066')).Count -ne 0 -and
     @(Compare-Object $remote $local).Count -ne 0)) {
  throw 'Requires exact registered staging schema 65/66/67 and only the reviewed Sunwake/social migrations.'
}
./tool/staging_endless_sunwake_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN `
  -RehearseMigrations:($remote[-1] -ceq '202609090065')
./tool/staging_canonical_social_claim_contract.ps1 -ProjectRef $projectRef `
  -ManagementAccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN `
  -RehearseMigrations:($remote[-1] -cne '202609100067')
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
supabase db lint --linked --level error --fail-on error --output-format json
if ($LASTEXITCODE -ne 0) { throw 'Pre-apply lint failed.' }
if (@(Compare-Object $remote $local).Count -ne 0) {
  supabase db push --linked --include-all --dry-run
  if ($LASTEXITCODE -ne 0) { throw 'Migration dry run failed.' }
  supabase db push --linked --include-all --yes
  if ($LASTEXITCODE -ne 0) { throw 'Detached game migration apply failed.' }
}
./tool/staging_canonical_social_claim_contract.ps1 -ProjectRef $projectRef `
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
supabase functions deploy execute-game-command --project-ref $projectRef --no-verify-jwt --use-api
if ($LASTEXITCODE -ne 0) { throw 'Staging game worker deployment failed.' }
./tool/release_server_preflight.ps1 -ExpectedProjectRef $projectRef `
  -ExpectedUrl $env:STAGING_SUPABASE_URL -ExpectedPublishableKey $env:STAGING_SUPABASE_PUBLISHABLE_KEY
'PASS: detached staging game schema and worker deployed; live economy activation remains disabled.'
