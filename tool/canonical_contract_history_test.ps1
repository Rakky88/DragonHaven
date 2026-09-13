$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'canonical_contract_history.ps1')
$versions = @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot '../supabase/migrations') -Filter '*.sql' |
  ForEach-Object { $_.BaseName.Split('_')[0] } | Sort-Object)
foreach ($first in @('202609070052','202609070053','202609070054','202609070055','202609070056','202609070057')) {
  foreach ($last in @('202609100070','202609100071','202609100072','202609100073','202609100074','202609100075','202609100076','202609100077','202609100078','202609100079','202609120080','202609120081','202609120082','202609120083')) {
    $prefix = @($versions | Where-Object { $_ -cle $last })
    if (-not (Test-CanonicalContractHistory $prefix $first '202609120083')) {
      throw "Reviewed baseline rejected: $first through $last."
    }
    $gap = @($prefix | Where-Object { $_ -cne '202609090065' })
    foreach ($invalid in @($gap, @($prefix + $first), @($prefix + '202609120084'))) {
      if (Test-CanonicalContractHistory $invalid $first '202609120083') {
        throw 'Incomplete, duplicate or unreviewed history was accepted.'
      }
    }
  }
}
if (Test-CanonicalContractHistory @() '202609070052' '202609120083') {
  throw 'Empty history was accepted.'
}
'PASS: reviewed staging prefixes through schema 83; gaps, duplicates, future and empty histories rejected.'
