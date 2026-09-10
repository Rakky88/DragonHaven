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
$query = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'canonical_beacon_contract.sql') -Raw -Encoding utf8
$phase = 'history'
try {
  if ($RehearseMigrations) {
    $history = Invoke-RestMethod -Method Post -Uri "https://api.supabase.com/v1/projects/$ProjectRef/database/query" `
      -Headers @{Authorization = "Bearer $ManagementAccessToken"} -ContentType 'application/json' -TimeoutSec 45 `
      -Body (ConvertTo-Json @{query='select version from supabase_migrations.schema_migrations order by version';read_only=$true} -Compress)
    $remote = @($history | ForEach-Object { [string]$_.version } | Sort-Object)
    $files = @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot '../supabase/migrations') -Filter '*.sql' | Sort-Object Name)
    $expected = @($files | ForEach-Object { $_.BaseName.Split('_')[0] } | Where-Object { [long]$_ -le [long]$remote[-1] })
    if ($remote[-1] -notin @('202609090065','202609100066','202609100067','202609100068','202609100069','202609100070','202609100071','202609100072','202609100073','202609100074','202609100075','202609100076') -or
        @(Compare-Object $remote $expected).Count -ne 0) { throw 'beacon_contract_schema'; }
    $pending = @($files | Where-Object { [long]$_.BaseName.Split('_')[0] -gt [long]$remote[-1] -and
        [long]$_.BaseName.Split('_')[0] -le 202609100073 } | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding utf8 })
    $query = "begin;`n" + ($pending -join "`n") + "`n" + [regex]::Replace($query, '(?m)^begin;\r?\n', '', 1)
  }
  $phase = 'rollback_query'
  $result = Invoke-RestMethod -Method Post -Uri "https://api.supabase.com/v1/projects/$ProjectRef/database/query" `
    -Headers @{Authorization = "Bearer $ManagementAccessToken"} -ContentType 'application/json' -TimeoutSec 90 `
    -Body (ConvertTo-Json @{query=$query; read_only=$false} -Compress)
} catch {
  $detail = if ($null -ne $_.ErrorDetails) { [string]$_.ErrorDetails.Message } else { [string]$_.Exception.Message }
  if ($detail -match '\b(beacon_contract_[a-z_]+)\b') { Write-Output "Failed assertion: $($Matches[1])" }
  Write-Output "Failed phase: $phase"
  if ($null -ne $_.Exception.Response) { Write-Output "HTTP status: $([int]$_.Exception.Response.StatusCode)" }
  if ($detail -match 'ERROR:\s+([0-9A-Z]{5}):') { Write-Output "SQL state: $($Matches[1])" }
  if ($detail -match '\b(game_[a-z_]+|invalid_profile|invalid_group_dragon|economy_server_inventory_required)\b') {
    Write-Output "Fixed database error: $($Matches[1])"
  }
  if ($detail -match 'column reference [\\]*"([a-z_][a-z_0-9]{0,62})[\\]*" is ambiguous') {
    Write-Output "Ambiguous SQL identifier: $($Matches[1])"
  }
  if ($detail -match 'violates (?:check|unique|foreign key|not-null) constraint [\\]*"([a-z_][a-z_0-9]{0,62})[\\]*"') {
    Write-Output "SQL constraint: $($Matches[1])"
  }
  foreach ($classification in @('does not exist','ambiguous','violates not-null','violates check','syntax error','permission denied','timeout','deadlock')) {
    if ($detail.Contains($classification)) { Write-Output "SQL classification: $classification" }
  }

  throw 'Staging Beacon rehearsal failed; its transaction must roll back.'
}
if ($result.canonical_beacon_contract_passed -ne $true) { throw 'Beacon contract did not confirm rollback.' }
Write-Output "PASS: canonical Beacon contract; one debit and shared progress, replay, changed capacity rollback, membership and legacy fences; migrations_rehearsed=$RehearseMigrations; synthetic_changes_rolled_back=true"
