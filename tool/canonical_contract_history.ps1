# Exact local migration prefixes only. A new reviewed version extends the range
# without accidentally dropping the preceding staging baseline.
function Test-CanonicalContractHistory {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Actual,
    [Parameter(Mandatory = $true)][string]$FirstAppliedVersion,
    [Parameter(Mandatory = $true)][string]$LastReviewedVersion
  )
  if ($Actual.Count -eq 0) { return $false }
  $ordered = @($Actual | Sort-Object)
  if ($ordered[-1] -clt $FirstAppliedVersion -or
      $ordered[-1] -cgt $LastReviewedVersion) { return $false }
  $prefix = @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot '../supabase/migrations') -Filter '*.sql' |
    ForEach-Object { $_.BaseName.Split('_')[0] } |
    Where-Object { $_ -cle $ordered[-1] } | Sort-Object)
  return $ordered.Count -eq $prefix.Count -and
    @(Compare-Object $ordered $prefix).Count -eq 0
}
