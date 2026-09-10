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
$query = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'canonical_social_projection_contract.sql') -Raw -Encoding utf8
try {
  if ($RehearseMigrations) {
    $history = Invoke-RestMethod -Method Post -Uri "https://api.supabase.com/v1/projects/$ProjectRef/database/query" `
      -Headers @{Authorization = "Bearer $ManagementAccessToken"} -ContentType 'application/json' -TimeoutSec 45 `
      -Body (ConvertTo-Json @{query='select version from supabase_migrations.schema_migrations order by version';read_only=$true} -Compress)
    $remote = @($history | ForEach-Object { [string]$_.version } | Sort-Object)
    $files = @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot '../supabase/migrations') -Filter '*.sql' | Sort-Object Name)
    $expected = @($files | ForEach-Object { $_.BaseName.Split('_')[0] } | Where-Object { [long]$_ -le [long]$remote[-1] })
    if ($remote[-1] -notin @('202609090065','202609100066','202609100067','202609100068') -or
        @(Compare-Object $remote $expected).Count -ne 0) { throw 'social_projection_contract_schema'; }
    $pending = @($files | Where-Object { [long]$_.BaseName.Split('_')[0] -gt [long]$remote[-1] -and
        [long]$_.BaseName.Split('_')[0] -le 202609100068 } | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding utf8 })
    $query = "begin;`n" + ($pending -join "`n") + "`n" + [regex]::Replace($query, '(?m)^begin;\r?\n', '', 1)
  }
  $result = Invoke-RestMethod -Method Post -Uri "https://api.supabase.com/v1/projects/$ProjectRef/database/query" `
    -Headers @{Authorization = "Bearer $ManagementAccessToken"} -ContentType 'application/json' -TimeoutSec 90 `
    -Body (ConvertTo-Json @{query=$query; read_only=$false} -Compress)
} catch {
  $detail = if ($null -ne $_.ErrorDetails) { [string]$_.ErrorDetails.Message } else { [string]$_.Exception.Message }
  if ($detail -match '\b(social_projection_contract_[a-z_]+)\b') { Write-Output "Failed assertion: $($Matches[1])" }
  throw 'Staging social projection rehearsal failed; its transaction must roll back.'
}
if ($result.canonical_social_projection_contract_passed -ne $true) { throw 'Social projection contract did not confirm rollback.' }
Write-Output "PASS: canonical social projection contract; atomic wallet/dragon/showcase projection and old-client fences; migrations_rehearsed=$RehearseMigrations; synthetic_changes_rolled_back=true"
