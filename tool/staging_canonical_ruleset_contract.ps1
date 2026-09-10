#requires -Version 7.0
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$ProjectRef,
  [Parameter(Mandatory = $true)][string]$ManagementAccessToken
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($ProjectRef -cne 'vtmjkhzalalozpfnbvsd' -or [string]::IsNullOrWhiteSpace($ManagementAccessToken)) {
  throw 'The ruleset rehearsal requires registered staging and protected management configuration.'
}
$headers = @{ Authorization = "Bearer $ManagementAccessToken" }
$endpoint = "https://api.supabase.com/v1/projects/$ProjectRef/database/query"
try {
  $history = Invoke-RestMethod -Method Post -Uri $endpoint -Headers $headers -TimeoutSec 45 `
    -ContentType 'application/json' -Body (ConvertTo-Json @{
      query = 'select version from supabase_migrations.schema_migrations order by version'; read_only = $true
    } -Compress)
  $expected = @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot '../supabase/migrations') -Filter '*.sql' |
    ForEach-Object { $_.BaseName.Split('_')[0] } | Where-Object { [long]$_ -le 202609070055 } | Sort-Object)
  $actual = @($history | ForEach-Object { [string]$_.version } | Sort-Object)
  $applied = @(Compare-Object $actual @($expected + '202609070056')).Count -eq 0 -or
    @(Compare-Object $actual @($expected + @('202609070056','202609070057'))).Count -eq 0 -or
    @(Compare-Object $actual @($expected + @('202609070056','202609070057','202609080058','202609080059'))).Count -eq 0 -or
    @(Compare-Object $actual @($expected + @('202609070056','202609070057','202609080058','202609080059','202609090060'))).Count -eq 0 -or
    @(Compare-Object $actual @($expected + @('202609070056','202609070057','202609080058','202609080059','202609090060','202609090061'))).Count -eq 0 -or
    @(Compare-Object $actual @($expected + @('202609070056','202609070057','202609080058','202609080059','202609090060','202609090061','202609090062'))).Count -eq 0 -or
    @(Compare-Object $actual @($expected + @('202609070056','202609070057','202609080058','202609080059','202609090060','202609090061','202609090062','202609090063','202609090064','202609090065'))).Count -eq 0 -or
    @(Compare-Object $actual @($expected + @('202609070056','202609070057','202609080058','202609080059','202609090060','202609090061','202609090062','202609090063','202609090064','202609090065','202609100066'))).Count -eq 0 -or
    @(Compare-Object $actual @($expected + @('202609070056','202609070057','202609080058','202609080059','202609090060','202609090061','202609090062','202609090063','202609090064','202609090065','202609100066','202609100067'))).Count -eq 0 -or
    @(Compare-Object $actual @($expected + @('202609070056','202609070057','202609080058','202609080059','202609090060','202609090061','202609090062','202609090063','202609090064','202609090065','202609100066','202609100067','202609100068'))).Count -eq 0 -or
    @(Compare-Object $actual @($expected + @('202609070056','202609070057','202609080058','202609080059','202609090060','202609090061','202609090062','202609090063','202609090064','202609090065','202609100066','202609100067','202609100068','202609100069'))).Count -eq 0
  if (-not $applied -and @(Compare-Object $actual $expected).Count -ne 0) { throw 'ruleset_contract_baseline_mismatch' }
  $migration = Get-Content -LiteralPath (Join-Path $PSScriptRoot '../supabase/migrations/202609070056_canonical_ruleset_revision.sql') -Raw -Encoding utf8
  $contract = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'canonical_ruleset_contract.sql') -Raw -Encoding utf8
  $query = if ($applied) { $contract } else {
    "begin;`n" + $migration + "`n" + [regex]::Replace($contract, '(?m)^begin;\r?\n', '', 1)
  }
  $result = Invoke-RestMethod -Method Post -Uri $endpoint -Headers $headers -TimeoutSec 90 `
    -ContentType 'application/json' -Body (ConvertTo-Json @{query = $query; read_only = $false} -Compress)
} catch {
  $detail = if ($null -ne $_.ErrorDetails) { [string]$_.ErrorDetails.Message } else { [string]$_.Exception.Message }
  if ($detail -match '\b(ruleset_contract_[a-z_]+)\b') { Write-Output "Failed assertion: $($Matches[1])" }
  throw 'Staging canonical ruleset rehearsal failed; its transaction must roll back.'
}
if (($result | ConvertTo-Json -Depth 5) -notmatch '"canonical_ruleset_contract_passed"\s*:\s*true') {
  throw 'Staging did not confirm the canonical ruleset rollback.'
}
'PASS: canonical ruleset migration 56; monotonic ruleset generation, no-op/pause stability, prepared reads and zero game mutations; all changes rolled back.'
