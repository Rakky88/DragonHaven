#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ProjectRef,
    [Parameter(Mandatory = $true)][string]$ManagementAccessToken,
    [switch]$RehearseMigrations
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($ProjectRef -notmatch '^[a-z0-9]{20}$' -or $ProjectRef -eq 'tnzathhutuwmohmjfrlo') {
    throw 'Inventory snapshot contract tests require staging; production is forbidden.'
}
if ([string]::IsNullOrWhiteSpace($ManagementAccessToken)) {
    throw 'Protected staging management configuration is missing.'
}
$contract = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'economy_inventory_snapshot_contract.sql') -Raw
$query = $contract
if ($RehearseMigrations) {
    $migration = Get-Content -LiteralPath 'supabase/migrations/202609070049_economy_inventory_snapshot.sql' -Raw
    $query = "begin;`n" + $migration + "`n" + [regex]::Replace($contract, '(?m)^begin;\r?\n', '', 1)
}
try {
    $result = Invoke-RestMethod -Method Post -TimeoutSec 90 `
        -Uri "https://api.supabase.com/v1/projects/$ProjectRef/database/query" `
        -Headers @{ Authorization = "Bearer $ManagementAccessToken" } `
        -ContentType 'application/json' `
        -Body (ConvertTo-Json @{ query = $query; read_only = $false } -Compress)
} catch {
    # The body contains only synthetic records. Never print the request/headers.
    $detail = [string]$_.ErrorDetails.Message
    if ($detail -match '\b(snapshot_contract_[a-z_]+)\b') { Write-Output "Failed assertion: $($Matches[1])" }
    throw 'Staging inventory snapshot contract failed; changes must roll back.'
}
if (($result | ConvertTo-Json -Depth 5) -notmatch '"economy_inventory_snapshot_contract_passed"\s*:\s*true') {
    throw 'Staging did not confirm the inventory snapshot rollback.'
}
"PASS: inventory snapshot; migrations_rehearsed=$RehearseMigrations; all_synthetic_changes_rolled_back=true"
