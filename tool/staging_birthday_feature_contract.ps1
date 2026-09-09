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
$query = Get-Content -LiteralPath 'tool/birthday_trial_contract.sql' -Raw
if ($RehearseMigrations) {
  $query = "begin;`n" + (Get-Content -LiteralPath 'supabase/migrations/202609090063_birthday_trial.sql' -Raw) + "`n" +
    [regex]::Replace($query, '(?m)^begin;\r?\n', '', 1)
}
$result = Invoke-RestMethod -Method Post -Uri "https://api.supabase.com/v1/projects/$ProjectRef/database/query" `
  -Headers @{Authorization = "Bearer $ManagementAccessToken"} -ContentType 'application/json' `
  -Body (ConvertTo-Json @{query=$query; read_only=$false} -Compress)
if ($result.birthday_contract_passed -ne $true) { throw 'Birthday contract did not confirm rollback.' }
Write-Output "PASS: birthday_contract_passed; migrations_rehearsed=$RehearseMigrations; synthetic_changes_rolled_back=true"
