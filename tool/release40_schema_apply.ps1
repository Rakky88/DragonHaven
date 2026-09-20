#requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Confirmation)
if ($env:RELEASE_ENVIRONMENT -notin @('staging','production') -or
    $Confirmation -cne "APPLY_$($env:RELEASE_ENVIRONMENT.ToUpperInvariant())_RELEASE40_SCHEMA_87") {
  throw 'The exact release-40 migration scope is required.'
}
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force release40-schema | Out-Null
python3 tool/release40_schema_contract.py --phase before | Tee-Object release40-schema/rehearsal.txt
if ($LASTEXITCODE -ne 0) { throw 'Release-40 rehearsal failed.' }
supabase link --project-ref $env:RELEASE_PROJECT_REF --password $env:SUPABASE_DB_PASSWORD
if ($LASTEXITCODE -ne 0) { throw 'Project link failed.' }
supabase db lint --linked --level error --fail-on error --output-format json | Tee-Object release40-schema/lint-before.json
if ($LASTEXITCODE -ne 0) { throw 'Pre-apply database lint failed.' }
supabase db push --linked --include-all --dry-run | Tee-Object release40-schema/dry-run.txt
if ($LASTEXITCODE -ne 0) { throw 'Release-40 dry run failed.' }
supabase db push --linked --include-all --yes | Tee-Object release40-schema/apply.txt
if ($LASTEXITCODE -ne 0) { throw 'Release-40 apply failed.' }
python3 tool/release40_schema_contract.py --phase after | Tee-Object release40-schema/contract.txt
if ($LASTEXITCODE -ne 0) { throw 'Post-apply contract failed.' }
$key = if ($env:RELEASE_ENVIRONMENT -ceq 'production') {
  [regex]::Match((Get-Content lib/config/online_config.dart -Raw), 'sb_publishable_[A-Za-z0-9_-]+').Value
} else { $env:STAGING_PUBLISHABLE_KEY }
./tool/release_server_preflight.ps1 -ExpectedProjectRef $env:RELEASE_PROJECT_REF `
  -ExpectedUrl "https://$($env:RELEASE_PROJECT_REF).supabase.co" -ExpectedPublishableKey $key |
  ConvertTo-Json | Tee-Object release40-schema/preflight.json
