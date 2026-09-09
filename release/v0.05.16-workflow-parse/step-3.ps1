$expectedRemote = '202609070041'
$expectedPending = @(
  '202609070042', '202609070043', '202609070044')
supabase link --project-ref tnzathhutuwmohmjfrlo `
  --password $env:SUPABASE_DB_PASSWORD
New-Item -ItemType Directory -Path production-migration -Force |
  Out-Null
$migrationResult = ((supabase migration list --linked `
  --output-format json) | Out-String) | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Could not read production migrations.' }
$remoteVersions = @($migrationResult.migrations |
  ForEach-Object { [string]$_.remote } |
  Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
  Sort-Object)
if ($remoteVersions.Count -eq 0 -or
    $remoteVersions[-1] -ne $expectedRemote) {
  throw 'Production is not exactly at migration 41.'
}
$pendingLocal = @(Get-ChildItem supabase/migrations -File -Filter '*.sql' |
  ForEach-Object {
    if ($_.BaseName -notmatch '^(\d+)_') {
      throw "Invalid migration filename: $($_.Name)."
    }
    $Matches[1]
  } | Where-Object { [long]$_ -gt [long]$expectedRemote } | Sort-Object)
if (@(Compare-Object $expectedPending $pendingLocal).Count -ne 0) {
  throw 'The pending production set is not exactly migrations 42 through 44.'
}
./tool/public_server_health_check.ps1 `
  -Environment production `
  -OutputPath production-migration/health-before.json
supabase db lint --linked --level error --fail-on error `
  --output-format json | Tee-Object production-migration/lint-before.json
if ($LASTEXITCODE -ne 0) { throw 'Pre-migration lint failed.' }
supabase db push --linked --include-all --dry-run |
  Tee-Object production-migration/dry-run.txt
if ($LASTEXITCODE -ne 0) { throw 'Production dry run failed.' }
