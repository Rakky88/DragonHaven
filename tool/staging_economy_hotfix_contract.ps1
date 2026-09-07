#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ProjectRef,
    [Parameter(Mandatory = $true)][string]$ManagementAccessToken
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($ProjectRef -notmatch '^[a-z0-9]{20}$' -or $ProjectRef -eq 'tnzathhutuwmohmjfrlo') {
    throw 'The SQL hotfix rehearsal requires staging; production is forbidden.'
}
if ([string]::IsNullOrWhiteSpace($ManagementAccessToken)) {
    throw 'Protected staging management configuration is missing.'
}
function Get-SessionLocalRateLimitDefinition([string]$MigrationPath) {
    $source = Get-Content -LiteralPath $MigrationPath -Raw
    $pattern = '(?s)create or replace function private\.consume_economy_rate_limit\(.*?\$\$;'
    $definitions = [regex]::Matches($source, $pattern)
    if ($definitions.Count -ne 1) { throw 'Expected exactly one historical limiter definition.' }
    $definition = $definitions[0].Value.Replace(
        'function private.consume_economy_rate_limit(', 'function pg_temp.consume_economy_rate_limit(')
    return $definition + "`nrevoke all on function pg_temp.consume_economy_rate_limit(uuid,text,integer,integer) from public, anon, authenticated;"
}
$migrationRoot = Join-Path (Split-Path $PSScriptRoot -Parent) 'supabase/migrations'
$historicalPath = Join-Path $migrationRoot '202609050037_economy_authority_foundation.sql'
$correctedPath = Join-Path $migrationRoot '202609050038_economy_rate_limit_timestamp_fix.sql'
$query = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'economy_hotfix_contract.sql') -Raw
$query = $query.Replace('-- INSTALL HISTORICAL FUNCTION', (Get-SessionLocalRateLimitDefinition $historicalPath))
$query = $query.Replace('-- INSTALL CORRECTED FUNCTION', (Get-SessionLocalRateLimitDefinition $correctedPath))
$started = [DateTime]::UtcNow
try {
    $result = Invoke-RestMethod -Method Post -TimeoutSec 90 `
        -Uri "https://api.supabase.com/v1/projects/$ProjectRef/database/query" `
        -Headers @{ Authorization = "Bearer $ManagementAccessToken" } `
        -ContentType 'application/json' `
        -Body (ConvertTo-Json @{ query = $query; read_only = $false } -Compress)
} catch {
    $detail = [string]$_.ErrorDetails.Message
    if ($detail -match '\b(hotfix_[a-z_]+)\b') { Write-Output "Failed assertion: $($Matches[1])" }
    throw 'Staging SQL hotfix rehearsal failed; all transaction changes must roll back.'
}
if (($result | ConvertTo-Json -Depth 5) -notmatch '"economy_hotfix_contract_passed"\s*:\s*true') {
    throw 'Staging did not confirm the SQL hotfix rollback.'
}
[ordered]@{
    kind = 'dragonhaven-sql-hotfix-rehearsal'
    environment = 'staging'; production = $false; result = 'passed'
    completedAtUtc = [DateTime]::UtcNow.ToString('o')
    requestDurationMs = [math]::Round(([DateTime]::UtcNow - $started).TotalMilliseconds)
    historicalMigrationSha256 = (Get-FileHash -LiteralPath $historicalPath -Algorithm SHA256).Hash.ToLowerInvariant()
    correctedMigrationSha256 = (Get-FileHash -LiteralPath $correctedPath -Algorithm SHA256).Hash.ToLowerInvariant()
    historicalFaultReproduced = $true; failedWriteAtomic = $true
    correctedTimestamp = $true; rateLimitEnforced = $true; expiredWindowReset = $true
    installedFunctionUnchanged = $true; grantsUnchanged = $true; activationUnchanged = $true
    allChangesRolledBack = $true; fullOperationalIncidentDrill = $false
} | ConvertTo-Json
