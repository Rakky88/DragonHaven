$stagingSha = '174fd3ab71e03bf30d271cce1beed81b6951e189'
$run = gh api repos/Rakky88/DragonHaven/actions/runs/34106264418 | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or $run.conclusion -ne 'success' -or $run.head_sha -ne $stagingSha) {
  throw 'The exact staging evidence is missing or failed.'
}
git fetch --depth=1 origin $stagingSha
if ($LASTEXITCODE -ne 0) { throw 'Could not resolve the tested staging commit.' }
git diff --exit-code $stagingSha -- supabase/migrations tool/egg_altar_contract.sql
if ($LASTEXITCODE -ne 0) { throw 'The production server content differs from tested staging.' }
