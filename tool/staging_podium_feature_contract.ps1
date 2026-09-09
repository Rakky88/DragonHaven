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
$query = Get-Content -LiteralPath 'tool/seasonal_podium_chat_contract.sql' -Raw
if ($RehearseMigrations) {
  $query = "begin;`n" + (Get-Content -LiteralPath 'supabase/migrations/202609090065_seasonal_podium_chat.sql' -Raw) + "`n" +
    [regex]::Replace($query, '(?m)^begin;\r?\n', '', 1)
}
$result = Invoke-RestMethod -Method Post -Uri "https://api.supabase.com/v1/projects/$ProjectRef/database/query" `
  -Headers @{Authorization = "Bearer $ManagementAccessToken"} -ContentType 'application/json' `
  -Body (ConvertTo-Json @{query=$query; read_only=$false} -Compress)
if ($result.podium_contract_passed -ne $true) { throw 'Podium contract did not confirm rollback.' }
Write-Output "PASS: podium_contract_passed; migrations_rehearsed=$RehearseMigrations; synthetic_changes_rolled_back=true"
