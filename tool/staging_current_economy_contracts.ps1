#requires -Version 7.0
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$ProjectRef,
  [Parameter(Mandatory = $true)][string]$ManagementAccessToken
)
$ErrorActionPreference = 'Stop'
if ($ProjectRef -cne 'vtmjkhzalalozpfnbvsd') { throw 'Only registered staging is allowed.' }
$contracts = @(
  'staging_birthday_feature_contract',
  'staging_endless_sunwake_contract',
  'staging_canonical_social_claim_contract',
  'staging_canonical_social_projection_contract',
  'staging_canonical_social_reservation_contract',
  'staging_canonical_group_lifecycle_contract',
  'staging_canonical_pair_lifecycle_contract',
  'staging_canonical_beacon_contract',
  'staging_canonical_trade_contract',
  'staging_canonical_game_contract',
  'staging_canonical_import_contract',
  'staging_canonical_game_read_contract',
  'staging_canonical_receipt_contract',
  'staging_canonical_ruleset_contract',
  'staging_canonical_command_recovery_contract',
  'staging_podium_feature_contract',
  'staging_wide_trial_score_contract',
  'staging_canonical_seasonal_trial_contract',
  'staging_canonical_group_cleanup_contract',
  'staging_canonical_account_activation_contract'
)
foreach ($contract in $contracts) {
  & (Join-Path $PSScriptRoot "$contract.ps1") -ProjectRef $ProjectRef `
    -ManagementAccessToken $ManagementAccessToken
}
foreach ($case in @(
    @{ File = 'extended_event_windows_contract'; Result = 'extended_event_windows_passed' },
    @{ File = 'single_event_preview_contract'; Result = 'single_event_preview_contract_passed' },
    @{ File = 'end_event_contract'; Result = 'end_event_contract_passed' }
)) {
  $query = Get-Content -LiteralPath (Join-Path $PSScriptRoot ($case.File + '.sql')) -Raw -Encoding utf8
  $result = Invoke-RestMethod -Method Post `
    -Uri "https://api.supabase.com/v1/projects/$ProjectRef/database/query" `
    -Headers @{Authorization = "Bearer $ManagementAccessToken"} -ContentType 'application/json' -TimeoutSec 90 `
    -Body (ConvertTo-Json @{query = $query; read_only = $false} -Compress)
  if ($result.($case.Result) -ne $true) { throw "Calendar contract did not confirm rollback: $($case.File)." }
  Write-Output "PASS: $($case.File); synthetic_changes_rolled_back=true"
}
'PASS: all current economy contracts passed with rollback; no migration or worker deployed.'
