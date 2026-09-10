#requires -Version 7.0
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$ProjectRef,
  [Parameter(Mandatory = $true)][string]$ManagementAccessToken
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($ProjectRef -cne 'vtmjkhzalalozpfnbvsd') {
  throw 'The canonical game rehearsal only targets registered DragonHaven staging.'
}
if ([string]::IsNullOrWhiteSpace($ManagementAccessToken)) {
  throw 'Protected staging management configuration is missing.'
}
$headers = @{ Authorization = "Bearer $ManagementAccessToken" }
$endpoint = "https://api.supabase.com/v1/projects/$ProjectRef/database/query"
try {
  $history = Invoke-RestMethod -Method Post -Uri $endpoint -Headers $headers -TimeoutSec 45 `
    -ContentType 'application/json' -Body (ConvertTo-Json @{
      query = 'select version from supabase_migrations.schema_migrations order by version'; read_only = $true
    } -Compress)
  $expected = @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot '../supabase/migrations') -Filter '*.sql' |
    ForEach-Object { $_.BaseName.Split('_')[0] } | Where-Object { [long]$_ -le 202609070051 } | Sort-Object)
  $actual = @($history | ForEach-Object { [string]$_.version } | Sort-Object)
  . (Join-Path $PSScriptRoot 'canonical_contract_history.ps1')
  $applied = Test-CanonicalContractHistory -Actual $actual `
    -FirstAppliedVersion '202609070052' -LastReviewedVersion '202609100079'
  if (-not $applied -and @(Compare-Object $actual $expected).Count -ne 0) {
    throw 'game_contract_baseline_mismatch'
  }
  $migration = Get-Content -LiteralPath (Join-Path $PSScriptRoot '../supabase/migrations/202609070052_canonical_game_commands.sql') -Raw -Encoding utf8
  $contract = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'canonical_game_contract.sql') -Raw -Encoding utf8
  $query = if ($applied) { $contract } else {
    "begin;`n" + $migration + "`n" + [regex]::Replace($contract, '(?m)^begin;\r?\n', '', 1)
  }
  $result = Invoke-RestMethod -Method Post -Uri $endpoint -Headers $headers -TimeoutSec 90 `
    -ContentType 'application/json' -Body (ConvertTo-Json @{query = $query; read_only = $false} -Compress)
} catch {
  $detail = if ($null -ne $_.ErrorDetails) { [string]$_.ErrorDetails.Message } else { [string]$_.Exception.Message }
  if ($detail -match '\b(game_contract_[a-z_]+)\b') {
    Write-Output "Failed assertion: $($Matches[1])"
  }
  # Query data is synthetic; never include request headers or a service secret.
  throw 'Staging canonical game rehearsal failed; its transaction must roll back.'
}
if (($result | ConvertTo-Json -Depth 5) -notmatch '"canonical_game_contract_passed"\s*:\s*true') {
  throw 'Staging did not confirm the canonical game rollback.'
}
Write-Output 'PASS: canonical game migration 52; full-copy, lease/replay, owner and wallet guards; all changes rolled back.'
