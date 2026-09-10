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
foreach ($contract in @('summer_event_contract', 'endless_sunwake_contract')) {
  $query = Get-Content -LiteralPath "tool/$contract.sql" -Raw
  if ($RehearseMigrations) {
    $query = "begin;`n" + (Get-Content -LiteralPath 'supabase/migrations/202609100066_endless_sunwake.sql' -Raw) + "`n" +
      [regex]::Replace($query, '(?m)^begin;\r?\n', '', 1)
  }
  $result = Invoke-RestMethod -Method Post -Uri "https://api.supabase.com/v1/projects/$ProjectRef/database/query" `
    -Headers @{Authorization = "Bearer $ManagementAccessToken"} -ContentType 'application/json' `
    -Body (ConvertTo-Json @{query=$query; read_only=$false} -Compress)
  $field = if ($contract -ceq 'summer_event_contract') { 'summer_contract_passed' } else { 'endless_contract_passed' }
  if ($result.$field -ne $true) { throw 'Endless Sunwake contract did not confirm rollback.' }
  Write-Output "PASS: $field; migrations_rehearsed=$RehearseMigrations; synthetic_changes_rolled_back=true"
}
