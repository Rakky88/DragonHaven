$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'canonical_contract_history.ps1')
$versions = @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot '../supabase/migrations') -Filter '*.sql' |
  ForEach-Object { $_.BaseName.Split('_')[0] } | Sort-Object)
foreach ($first in @('202609070052','202609070053','202609070054','202609070055','202609070056','202609070057')) {
  foreach ($last in @('202609100070','202609100071','202609100072','202609100073','202609100074','202609100075','202609100076','202609100077','202609100078','202609100079')) {
    $prefix = @($versions | Where-Object { $_ -cle $last })
    if (-not (Test-CanonicalContractHistory $prefix $first '202609100079')) {
      throw "Reviewed baseline rejected: $first through $last."
    }
    $gap = @($prefix | Where-Object { $_ -cne '202609090065' })
    foreach ($invalid in @($gap, @($prefix + $first), @($prefix + '202609100080'))) {
      if (Test-CanonicalContractHistory $invalid $first '202609100079') {
        throw 'Incomplete, duplicate or unreviewed history was accepted.'
      }
    }
  }
}
if (Test-CanonicalContractHistory @() '202609070052' '202609100079') {
  throw 'Empty history was accepted.'
}
'PASS: reviewed staging prefixes including 72/73/74/75/76/77/78/79; gaps, duplicates, future and empty histories rejected.'
