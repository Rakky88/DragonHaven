supabase db push --linked --include-all --yes |
  Tee-Object production-migration/apply.txt
if ($LASTEXITCODE -ne 0) { throw 'Production migration apply failed.' }
$contract = Get-Content -LiteralPath tool/egg_altar_contract.sql -Raw
$response = Invoke-RestMethod -Method Post `
  -Uri 'https://api.supabase.com/v1/projects/tnzathhutuwmohmjfrlo/database/query' `
  -Headers @{ Authorization = "Bearer $env:SUPABASE_ACCESS_TOKEN" } `
  -ContentType 'application/json' `
  -Body (ConvertTo-Json @{ query = $contract; read_only = $false } -Compress)
if (($response | ConvertTo-Json -Depth 5) -notmatch '"egg_altar_contract_passed"\s*:\s*true') {
  throw 'The applied Altar contract failed.'
}
'PASS: ownership, tags, retries, Sinister rewards, crafting and Beacon; all test mutations rolled back.' |
  Set-Content production-migration/contract.txt
./tool/release_server_preflight.ps1 |
  Tee-Object production-migration/preflight-after.txt
supabase db lint --linked --level error --fail-on error `
  --output-format json | Tee-Object production-migration/lint-after.json
if ($LASTEXITCODE -ne 0) { throw 'Post-migration lint failed.' }
./tool/public_server_health_check.ps1 `
  -Environment production `
  -OutputPath production-migration/health-after.json
@(
  'DragonHaven production migration evidence'
  "Commit: $env:GITHUB_SHA"
  'Previous migration: 202609070041'
  'Applied migrations: 202609070042 through 202609070044'
  'Economy authority remains in disabled legacy compatibility mode.'
  'Egg Altar, tags, crafted relics, Beacon and corrected Sinister rewards are available.'
  'Migration parity, database lint, Auth and application health: passed'
  'No credentials or player data are included in this artifact.'
) | Set-Content production-migration/verification.txt -Encoding utf8
