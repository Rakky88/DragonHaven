#requires -Version 7.0
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$ProjectRef,
  [Parameter(Mandatory = $true)][string]$ManagementAccessToken,
  [switch]$RehearseMigrations
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($ProjectRef -cne 'vtmjkhzalalozpfnbvsd') { throw 'Only registered staging is allowed.' }
if ([string]::IsNullOrWhiteSpace($ManagementAccessToken)) { throw 'Missing protected management configuration.' }
$query = Get-Content -LiteralPath 'tool/seasonal_preview_access_contract.sql' -Raw
if ($RehearseMigrations) {
  $query = "begin;`n" + (Get-Content -LiteralPath 'supabase/migrations/202609090062_seasonal_preview_access.sql' -Raw) + "`n" +
    [regex]::Replace($query, '(?m)^begin;\r?\n', '', 1)
}
$result = Invoke-RestMethod -Method Post -Uri "https://api.supabase.com/v1/projects/$ProjectRef/database/query" `
  -Headers @{Authorization = "Bearer $ManagementAccessToken"} -ContentType 'application/json' `
  -Body (ConvertTo-Json @{query=$query; read_only=$false} -Compress)
if ($result.preview_access_contract_passed -ne $true) { throw 'Preview access contract did not confirm rollback.' }
Write-Output "PASS: preview_access_contract_passed; migrations_rehearsed=$RehearseMigrations; synthetic_changes_rolled_back=true"
