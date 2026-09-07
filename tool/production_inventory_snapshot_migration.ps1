#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ProjectRef,
    [Parameter(Mandatory = $true)][string]$BaseUrl,
    [Parameter(Mandatory = $true)][string]$PublishableKey,
    [Parameter(Mandatory = $true)][string]$Confirmation
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$production = 'tnzathhutuwmohmjfrlo'
if ($ProjectRef -notmatch '^[a-z0-9]{20}$' -or $BaseUrl.TrimEnd('/') -ne "https://$ProjectRef.supabase.co" -or
    $ProjectRef -ne $production) {
    throw 'The environment and exact project do not match.'
}
if ($Confirmation -cne 'APPLY_PRODUCTION_INVENTORY_SNAPSHOT_49') {
    throw 'The exact bounded inventory-snapshot confirmation is missing.'
}
foreach ($name in @('SUPABASE_ACCESS_TOKEN','SUPABASE_DB_PASSWORD')) {
    if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) { throw "Missing protected $name." }
}
$folder = 'production-migration'
New-Item -ItemType Directory -Path $folder -Force | Out-Null
$local = @(Get-ChildItem supabase/migrations -File -Filter '*.sql' | ForEach-Object { $_.BaseName.Split('_')[0] } | Sort-Object)
if ($local.Count -ne 49 -or $local[-1] -ne '202609070049') { throw 'This checkout must contain exactly migrations 1-49.' }
supabase link --project-ref $ProjectRef --password $env:SUPABASE_DB_PASSWORD
if ($LASTEXITCODE -ne 0) { throw 'Project link failed.' }
$listing = ((supabase migration list --linked --output-format json) | Out-String) | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Migration history could not be read.' }
$remote = @($listing.migrations | ForEach-Object { [string]$_.remote } | Where-Object { $_ } | Sort-Object)
if ($remote.Count -notin @(48,49) -or $remote[-1] -notin @('202609070048','202609070049') -or
    @(Compare-Object @($local | Select-Object -First $remote.Count) $remote).Count -ne 0) {
    throw 'The complete remote history is not exactly the expected 48/49 baseline.'
}
function Invoke-PrivateQuery([string]$Query) {
    Invoke-RestMethod -Method Post -TimeoutSec 90 `
        -Uri "https://api.supabase.com/v1/projects/$ProjectRef/database/query" `
        -Headers @{ Authorization = "Bearer $env:SUPABASE_ACCESS_TOKEN" } `
        -ContentType 'application/json' `
        -Body (ConvertTo-Json @{ query = $Query; read_only = $false } -Compress)
}
function Get-AuthorityEvidence {
    $rows = @(Invoke-PrivateQuery "select mutations_enabled, (select count(*) from public.player_economy_authority where authority_mode <> 'legacy_client') as nonlegacy_accounts from private.economy_contract where singleton;")
    if ($rows.Count -ne 1 -or $rows[0].mutations_enabled -isnot [bool] -or $rows[0].nonlegacy_accounts -ne 0 -or $rows[0].mutations_enabled) {
        throw 'Unexpected economy authority state; stop before changing inventory snapshot.'
    }
    $rows[0]
}
function Test-SnapshotContract([bool]$Rehearse) {
    $sql = Get-Content -LiteralPath tool/economy_inventory_snapshot_contract.sql -Raw
    if ($Rehearse) {
        $migration = Get-Content -LiteralPath supabase/migrations/202609070049_economy_inventory_snapshot.sql -Raw
        $sql = "begin;`n" + $migration + "`n" + [regex]::Replace($sql, '(?m)^begin;\r?\n', '', 1)
    }
    $rows = @(Invoke-PrivateQuery $sql)
    if ($rows.Count -ne 1 -or $rows[0].economy_inventory_snapshot_contract_passed -ne $true) {
        throw 'Rolled-back inventory-snapshot contract failed.'
    }
    "PASS: inventory snapshot; rehearsal=$Rehearse; synthetic_records_rolled_back=true"
}
Get-AuthorityEvidence | ConvertTo-Json | Set-Content "$folder/snapshot-authority-before.json"
./tool/public_server_health_check.ps1 -BaseUrl $BaseUrl -PublishableKey $PublishableKey `
    -Environment production -OutputPath "$folder/snapshot-health-before.json"
supabase db lint --linked --level error --fail-on error --output-format json | Set-Content "$folder/snapshot-lint-before.json"
if ($LASTEXITCODE -ne 0) { throw 'Pre-migration database lint failed.' }
supabase db push --linked --include-all --dry-run | Tee-Object "$folder/snapshot-dry-run.txt"
if ($LASTEXITCODE -ne 0) { throw 'Inventory-snapshot dry run failed.' }
if ($remote.Count -eq 48) {
    Test-SnapshotContract $true | Set-Content "$folder/snapshot-rehearsal.txt"
    supabase db push --linked --include-all --yes | Tee-Object "$folder/snapshot-apply.txt"
    if ($LASTEXITCODE -ne 0) { throw 'Inventory-snapshot migration failed.' }
}
Test-SnapshotContract $false | Set-Content "$folder/snapshot-contract.txt"
./tool/release_server_preflight.ps1 -ExpectedProjectRef $ProjectRef -ExpectedUrl $BaseUrl `
    -ExpectedPublishableKey $PublishableKey | Tee-Object "$folder/snapshot-preflight-after.txt"
Get-AuthorityEvidence | ConvertTo-Json | Set-Content "$folder/snapshot-authority-after.json"
