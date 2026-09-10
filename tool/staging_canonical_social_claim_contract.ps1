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
$query = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'canonical_social_claim_contract.sql') -Raw -Encoding utf8
if ($RehearseMigrations) {
  $migration = Get-Content -LiteralPath (Join-Path $PSScriptRoot '../supabase/migrations/202609100067_canonical_social_claims.sql') -Raw -Encoding utf8
  $query = "begin;`n" + $migration + "`n" + [regex]::Replace($query, '(?m)^begin;\r?\n', '', 1)
}
try {
  $result = Invoke-RestMethod -Method Post -Uri "https://api.supabase.com/v1/projects/$ProjectRef/database/query" `
    -Headers @{Authorization = "Bearer $ManagementAccessToken"} -ContentType 'application/json' -TimeoutSec 90 `
    -Body (ConvertTo-Json @{query=$query; read_only=$false} -Compress)
} catch {
  $detail = if ($null -ne $_.ErrorDetails) { [string]$_.ErrorDetails.Message } else { [string]$_.Exception.Message }
  if ($detail -match '\b(social_claim_contract_[a-z_]+)\b') { Write-Output "Failed assertion: $($Matches[1])" }
  throw 'Staging social claim rehearsal failed; its transaction must roll back.'
}
if ($result.canonical_social_claim_contract_passed -ne $true) { throw 'Social claim contract did not confirm rollback.' }
Write-Output "PASS: canonical social claim contract; sealed facts, owner/deadline/retry/atomic acknowledgment; migrations_rehearsed=$RehearseMigrations; synthetic_changes_rolled_back=true"
