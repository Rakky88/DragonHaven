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
foreach ($entry in @(
  @('202609080058_equipment_relic_pool.sql', 'chest_opening_contract.sql', 'chest_opening_contract_passed'),
  @('202609080059_single_active_event_preview.sql', 'single_event_preview_contract.sql', 'single_event_preview_contract_passed')
)) {
  $query = Get-Content -LiteralPath (Join-Path 'tool' $entry[1]) -Raw
  if ($RehearseMigrations) {
    $query = "begin;`n" + (Get-Content -LiteralPath (Join-Path 'supabase/migrations' $entry[0]) -Raw) + "`n" +
      [regex]::Replace($query, '(?m)^begin;\r?\n', '', 1)
  }
  $result = Invoke-RestMethod -Method Post -Uri "https://api.supabase.com/v1/projects/$ProjectRef/database/query" `
    -Headers @{Authorization = "Bearer $ManagementAccessToken"} -ContentType 'application/json' `
    -Body (ConvertTo-Json @{query=$query; read_only=$false} -Compress)
  if ($result.($entry[2]) -ne $true) { throw 'Feature contract did not confirm rollback.' }
  Write-Output "PASS: $($entry[2]); migrations_rehearsed=$RehearseMigrations; synthetic_changes_rolled_back=true"
}
