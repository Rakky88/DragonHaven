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
    throw 'Item-shop contract tests require staging and must never target production.'
}
if ([string]::IsNullOrWhiteSpace($ManagementAccessToken)) {
    throw 'Protected staging management configuration is missing.'
}
$contract = Get-Content -LiteralPath tool/item_shop_contract.sql -Raw
$query = $contract
if ($RehearseMigrations) {
    $query = "begin;`n"
    foreach ($path in @(
        'supabase/migrations/202609070047_dormant_item_shop.sql'
    )) {
        $query += (Get-Content -LiteralPath $path -Raw) + "`n"
    }
    # Only remove the top-level BEGIN, preserving all exception subtransactions.
    $query += [regex]::Replace($contract, '(?m)^begin;\r?\n', '', 1)
}
try {
    $result = Invoke-RestMethod -Method Post `
        -Uri "https://api.supabase.com/v1/projects/$ProjectRef/database/query" `
        -Headers @{ Authorization = "Bearer $ManagementAccessToken" } `
        -ContentType 'application/json' `
        -Body (ConvertTo-Json @{ query = $query; read_only = $false } -Compress)
} catch {
    # SQL contains only synthetic records. Keep credentials/request bodies out
    # of logs; server error text identifies the failed assertion or SQL line.
    $detail = $_.ErrorDetails.Message
    if ($detail) { Write-Error "Staging item-shop contract failed: $detail" }
    throw 'Staging item-shop contract request failed.'
}
if (($result | ConvertTo-Json -Depth 5) -notmatch '"item_shop_contract_passed"\s*:\s*true') {
    throw 'Staging did not confirm the item-shop contract rollback.'
}
Write-Output "PASS: item-shop contract; migrations_rehearsed=$RehearseMigrations; all_synthetic_changes_rolled_back=true"
