[CmdletBinding()]
param(
    [string]$SupabaseCli = 'supabase',
    [string]$ExpectedProjectRef = 'tnzathhutuwmohmjfrlo',
    [string]$ExpectedUrl = '',
    [string]$ExpectedPublishableKey = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $repoRoot 'lib\config\online_config.dart'
$migrationPath = Join-Path $repoRoot 'supabase\migrations'
$projectRefPath = Join-Path $repoRoot 'supabase\.temp\project-ref'
. (Join-Path $PSScriptRoot 'lib\public_auth_health.ps1')

if (Test-Path -LiteralPath $SupabaseCli -PathType Leaf) {
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
if ([string]::IsNullOrWhiteSpace($ExpectedProjectRef)) {
    throw 'The expected Supabase project reference is empty.'
}
if ((Get-Content -LiteralPath $projectRefPath -Raw).Trim() -ne $ExpectedProjectRef.Trim()) {
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
if ([string]::IsNullOrWhiteSpace($ExpectedUrl) -and -not $urlMatch.Success) {
    throw 'The bundled public Supabase configuration could not be parsed.'
}
if ([string]::IsNullOrWhiteSpace($ExpectedPublishableKey) -and -not $keyMatch.Success) {
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
        # The CLI result contains only schema object names and lint messages;
        # surface it so a failed CI gate can be diagnosed without database
        # credentials or user data.
        $lintJson | ForEach-Object { Write-Output $_ }
        throw 'The linked database lint failed.'
    }
    $lintResult = ($lintJson | Out-String) | ConvertFrom-Json
    if (@($lintResult.results).Count -ne 0) {
        throw 'The linked database contains schema lint errors.'
    }

    $baseUrl = if ([string]::IsNullOrWhiteSpace($ExpectedUrl)) {
        $urlMatch.Groups[1].Value
    } else {
        $ExpectedUrl.TrimEnd('/')
    }
    $publicKey = if ([string]::IsNullOrWhiteSpace($ExpectedPublishableKey)) {
        $keyMatch.Groups[1].Value
    } else {
        $ExpectedPublishableKey.Trim()
    }
    if ($baseUrl -notmatch '^https://[^/]+$') {
        throw 'The expected Supabase URL is invalid.'
    }
    if ($publicKey -notmatch '^sb_publishable_') {
        throw 'The expected Supabase publishable key is invalid.'
    }
    $health = Invoke-DragonHavenPublicRequest `
        -BaseUrl $baseUrl `
        -Path '/auth/v1/health' `
        -PublishableKey $publicKey
    $settings = Invoke-DragonHavenPublicRequest `
        -BaseUrl $baseUrl `
        -Path '/auth/v1/settings' `
        -PublishableKey $publicKey
    if ($health.Status -ne 200 -or $settings.Status -ne 200) {
        throw 'The public Supabase Auth endpoints are not healthy.'
    }
    if ($settings.Content -notmatch '"email"') {
        throw 'The public Supabase Auth settings do not expose e-mail authentication.'
    }
    $applicationResponse = Invoke-DragonHavenPublicRequest `
        -BaseUrl $baseUrl `
        -Path '/rest/v1/rpc/dragonhaven_public_health' `
        -PublishableKey $publicKey `
        -Method POST `
        -JsonBody '{}'
    if ($applicationResponse.Status -ne 200) {
        throw 'The public DragonHaven application endpoint is not healthy.'
    }
    $application = ConvertFrom-DragonHavenApplicationHealth `
        -Content $applicationResponse.Content

    [pscustomobject]@{
        ProjectRef = $ExpectedProjectRef.Trim()
        MigrationCount = $localVersions.Count
        DatabaseLintErrors = 0
        AuthHealthStatus = $health.Status
        AuthHealthDurationMs = $health.DurationMs
        AuthSettingsStatus = $settings.Status
        AuthSettingsDurationMs = $settings.DurationMs
        EmailAuthConfigured = $true
        ApplicationHealthStatus = $applicationResponse.Status
        ApplicationHealthDurationMs = $applicationResponse.DurationMs
        ApplicationService = $application.Service
        ApplicationContractVersion = $application.ContractVersion
        ApplicationServerTimeUtc = $application.ServerTimeUtc
        ApplicationClockSkewMs = $application.ClockSkewMs
    }
}
finally {
    Pop-Location
}
