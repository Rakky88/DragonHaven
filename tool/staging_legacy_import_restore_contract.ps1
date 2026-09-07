#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ProjectRef,
    [Parameter(Mandatory = $true)][string]$ManagementAccessToken
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($ProjectRef -notmatch '^[a-z0-9]{20}$' -or $ProjectRef -eq 'tnzathhutuwmohmjfrlo') {
    throw 'The import restore rehearsal requires staging; production is forbidden.'
}
if ([string]::IsNullOrWhiteSpace($ManagementAccessToken)) {
    throw 'Protected staging management configuration is missing.'
}
$query = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'legacy_import_restore_contract.sql') -Raw
$started = [DateTime]::UtcNow
try {
    $result = Invoke-RestMethod -Method Post -TimeoutSec 90 `
        -Uri "https://api.supabase.com/v1/projects/$ProjectRef/database/query" `
        -Headers @{ Authorization = "Bearer $ManagementAccessToken" } `
        -ContentType 'application/json' `
        -Body (ConvertTo-Json @{ query = $query; read_only = $false } -Compress)
} catch {
    # Report a stable SQL assertion only, never response/context or account data.
    $detail = [string]$_.ErrorDetails.Message
    if ($detail -match '\b(restore_[a-z_]+)\b') { Write-Output "Failed assertion: $($Matches[1])" }
    throw 'Staging import restore rehearsal failed; all transaction changes must roll back.'
}
if (($result | ConvertTo-Json -Depth 5) -notmatch '"legacy_import_restore_contract_passed"\s*:\s*true') {
    throw 'Staging did not confirm the import restore rollback.'
}
[ordered]@{
    kind = 'dragonhaven-legacy-import-restore-rehearsal'
    environment = 'staging'; production = $false; result = 'passed'
    completedAtUtc = [DateTime]::UtcNow.ToString('o')
    requestDurationMs = [math]::Round(([DateTime]::UtcNow - $started).TotalMilliseconds)
    snapshotEquality = $true; sha256Equality = $true; syntheticRestoreUnder10Seconds = $true
    newerProgressRejected = $true; expiredBackupRejected = $true; foreignOwnerRejected = $true
    serverAuthorityRejected = $true; importRemainsLocked = $true; allChangesRolledBack = $true
    operationalPlayerRestoreImplemented = $false
} | ConvertTo-Json
