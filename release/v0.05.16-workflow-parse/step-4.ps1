$sql = "begin;`n"
foreach ($version in @('202609070042', '202609070043', '202609070044')) {
  $file = Get-ChildItem supabase/migrations -File -Filter "$($version)_*.sql"
  if (@($file).Count -ne 1) { throw 'The migration set is ambiguous.' }
  $sql += (Get-Content -LiteralPath $file.FullName -Raw) + "`n"
}
$contract = Get-Content -LiteralPath tool/egg_altar_contract.sql -Raw
$sql += $contract.Replace('begin;', '').Replace('rollback;', '') + "`nrollback;`nselect true as egg_altar_contract_passed;"
$response = Invoke-RestMethod -Method Post `
  -Uri 'https://api.supabase.com/v1/projects/tnzathhutuwmohmjfrlo/database/query' `
  -Headers @{ Authorization = "Bearer $env:SUPABASE_ACCESS_TOKEN" } `
  -ContentType 'application/json' `
  -Body (ConvertTo-Json @{ query = $sql; read_only = $false } -Compress)
if (($response | ConvertTo-Json -Depth 5) -notmatch '"egg_altar_contract_passed"\s*:\s*true') {
  throw 'Rolled-back production rehearsal failed; migrations will not be applied.'
}
'PASS: all three migrations and the Altar contract rolled back before applying.' |
  Set-Content production-migration/rehearsal.txt
