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
    throw 'Social push contract tests require staging; production is forbidden.'
}
if ([string]::IsNullOrWhiteSpace($ManagementAccessToken)) {
    throw 'Protected staging management configuration is missing.'
}
$contract = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'social_push_contract.sql') -Raw
$query = $contract
if ($RehearseMigrations) {
    $migration = @('202609070050_social_push_outbox.sql','202609070051_social_push_dispatch_schedule.sql') | ForEach-Object { Get-Content -LiteralPath (Join-Path 'supabase/migrations' $_) -Raw }; $migration = $migration -join "`n"
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
    if ($detail -match '\b(push_contract_[a-z_]+)\b') { Write-Output "Failed assertion: $($Matches[1])" }
    throw 'Staging social push contract failed; changes must roll back.'
}
if (($result | ConvertTo-Json -Depth 5) -notmatch '"social_push_contract_passed"\s*:\s*true') {
    throw 'Staging did not confirm the social push rollback.'
}
"PASS: social push; migrations_rehearsed=$RehearseMigrations; all_synthetic_changes_rolled_back=true"
