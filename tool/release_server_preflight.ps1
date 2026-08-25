[CmdletBinding()]
param(
    [string]$SupabaseCli = 'supabase'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $repoRoot 'lib\config\online_config.dart'
$migrationPath = Join-Path $repoRoot 'supabase\migrations'
$projectRefPath = Join-Path $repoRoot 'supabase\.temp\project-ref'

if (Test-Path -LiteralPath $SupabaseCli) {
    $resolvedCli = (Resolve-Path -LiteralPath $SupabaseCli).Path
}
else {
    $command = Get-Command $SupabaseCli -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        throw 'Supabase CLI was not found. Pass its path with -SupabaseCli.'
    }
    $resolvedCli = $command.Source
}

if (-not (Test-Path -LiteralPath $projectRefPath)) {
    throw 'The Supabase project is not linked in this checkout.'
}
if ((Get-Content -LiteralPath $projectRefPath -Raw).Trim() -ne 'tnzathhutuwmohmjfrlo') {
    throw 'This checkout is linked to an unexpected Supabase project.'
}

$configText = Get-Content -LiteralPath $configPath -Raw
$urlMatch = [regex]::Match(
    $configText,
    "defaultValue:\s*'(https://[^']+)'",
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
)
$keyMatch = [regex]::Match(
    $configText,
    "defaultValue:\s*'(sb_publishable_[^']+)'",
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
)
if (-not $urlMatch.Success -or -not $keyMatch.Success) {
    throw 'The bundled public Supabase configuration could not be parsed.'
}

Push-Location $repoRoot
try {
    $migrationJson = & $resolvedCli migration list --linked --output-format json
    if ($LASTEXITCODE -ne 0) {
        throw 'The linked migration check failed.'
    }
    $migrationResult = ($migrationJson | Out-String) | ConvertFrom-Json
    $localVersions = @(
        Get-ChildItem -LiteralPath $migrationPath -File -Filter '*.sql' |
            ForEach-Object {
                if ($_.BaseName -notmatch '^(\d+)_') {
                    throw "Migration '$($_.Name)' has no numeric version prefix."
                }
                $Matches[1]
            }
    )
    $remoteVersions = @($migrationResult.migrations | ForEach-Object { $_.remote })
    $differences = @(Compare-Object $localVersions $remoteVersions)
    if ($differences.Count -ne 0) {
        throw 'Local and remote Supabase migrations do not match exactly.'
    }

    $lintJson = & $resolvedCli db lint --linked --level error --fail-on error --output-format json
    if ($LASTEXITCODE -ne 0) {
        throw 'The linked database lint failed.'
    }
    $lintResult = ($lintJson | Out-String) | ConvertFrom-Json
    if (@($lintResult.results).Count -ne 0) {
        throw 'The linked database contains schema lint errors.'
    }

    $baseUrl = $urlMatch.Groups[1].Value
    $publicKey = $keyMatch.Groups[1].Value
    $headers = @{ apikey = $publicKey }
    $health = Invoke-WebRequest -Uri "$baseUrl/auth/v1/health" -Headers $headers -UseBasicParsing
    $settings = Invoke-WebRequest -Uri "$baseUrl/auth/v1/settings" -Headers $headers -UseBasicParsing
    if ($health.StatusCode -ne 200 -or $settings.StatusCode -ne 200) {
        throw 'The public Supabase Auth endpoints are not healthy.'
    }
    if ($settings.Content -notmatch '"email"') {
        throw 'The public Supabase Auth settings do not expose e-mail authentication.'
    }

    [pscustomobject]@{
        ProjectRef = 'tnzathhutuwmohmjfrlo'
        MigrationCount = $localVersions.Count
        DatabaseLintErrors = 0
        AuthHealthStatus = $health.StatusCode
        AuthSettingsStatus = $settings.StatusCode
        EmailAuthConfigured = $true
    }
}
finally {
    Pop-Location
}
