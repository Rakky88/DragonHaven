[CmdletBinding()]
param(
    [string]$SupabaseCli = 'supabase',
    [string]$ExpectedProjectRef = 'tnzathhutuwmohmjfrlo',
    [string]$ExpectedUrl = '',
    [string]$ExpectedPublishableKey = '',
    [switch]$RequireRewardedAds,
    [string]$ExpectedRewardedGemsAdUnitId = '',
    [string]$ExpectedRewardedCoinsAdUnitId = '',
    [string]$ExpectedRewardedSsvSourceRevision = ''
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

if ($RequireRewardedAds) {
    $rewardedUnitPattern = '^ca-app-pub-([0-9]{16})/([0-9]{10})$'
    $gemsUnitMatch = [regex]::Match(
        $ExpectedRewardedGemsAdUnitId.Trim(),
        $rewardedUnitPattern
    )
    $coinsUnitMatch = [regex]::Match(
        $ExpectedRewardedCoinsAdUnitId.Trim(),
        $rewardedUnitPattern
    )
    if (-not $gemsUnitMatch.Success -or -not $coinsUnitMatch.Success) {
        throw 'Rewarded-ad preflight requires two valid production ad-unit IDs.'
    }
    if ($ExpectedRewardedGemsAdUnitId.Trim() -eq
        $ExpectedRewardedCoinsAdUnitId.Trim()) {
        throw 'Rewarded-ad preflight requires two distinct ad-unit IDs.'
    }
    if ($gemsUnitMatch.Groups[1].Value -ne $coinsUnitMatch.Groups[1].Value) {
        throw 'Rewarded-ad preflight requires ad units from one publisher account.'
    }
    if ($gemsUnitMatch.Groups[1].Value -eq '3940256099942544') {
        throw 'Rewarded-ad preflight refuses Google test ad-unit IDs.'
    }
    if ($ExpectedRewardedSsvSourceRevision -notmatch '^[0-9a-f]{40}$') {
        throw 'Rewarded-ad preflight requires the exact deployed Git revision.'
    }
    if ([string]::IsNullOrWhiteSpace($env:SUPABASE_ACCESS_TOKEN)) {
        throw 'Rewarded-ad preflight requires SUPABASE_ACCESS_TOKEN.'
    }
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

    $rewardedHealthStatus = $null
    $rewardedHealthDurationMs = $null
    $rewardedFunctionVersion = $null
    $rewardedFunctionBundleSha256 = $null
    if ($RequireRewardedAds) {
        $managementHeaders = @{
            Accept = 'application/json'
            Authorization = "Bearer $($env:SUPABASE_ACCESS_TOKEN)"
            'User-Agent' = 'DragonHaven-Release-Preflight/1'
        }
        try {
            # Windows PowerShell can preserve a top-level JSON array returned
            # directly by Invoke-RestMethod as one nested value inside @(...).
            # Assign first so the array expression enumerates every function
            # consistently on Windows PowerShell and PowerShell 7.
            $functionResponse = Invoke-RestMethod `
                -Method GET `
                -Uri "https://api.supabase.com/v1/projects/$($ExpectedProjectRef.Trim())/functions" `
                -Headers $managementHeaders `
                -TimeoutSec 30
            $functions = @($functionResponse)
        }
        catch {
            throw 'The deployed Supabase Edge Function metadata could not be verified.'
        }
        $rewardedFunctions = @(
            $functions | Where-Object { [string]$_.slug -ceq 'rewarded-ad-ssv' }
        )
        if ($rewardedFunctions.Count -ne 1) {
            throw 'The rewarded-ad-ssv Edge Function is not deployed exactly once.'
        }
        $rewardedFunction = $rewardedFunctions[0]
        $verifyJwtProperty = $rewardedFunction.PSObject.Properties['verify_jwt']
        if ([string]$rewardedFunction.status -cne 'ACTIVE' -or
            $null -eq $verifyJwtProperty -or
            $verifyJwtProperty.Value -isnot [bool] -or
            [bool]$verifyJwtProperty.Value -ne $false -or
            [string]::IsNullOrWhiteSpace([string]$rewardedFunction.ezbr_sha256)) {
            throw 'The deployed rewarded-ad-ssv Edge Function configuration is unsafe.'
        }

        $rewardedResponse = Invoke-DragonHavenPublicRequest `
            -BaseUrl $baseUrl `
            -Path '/functions/v1/rewarded-ad-ssv?health=1' `
            -PublishableKey $publicKey
        if ($rewardedResponse.Status -ne 200) {
            throw 'The deployed rewarded-ad-ssv health contract is unavailable.'
        }
        try {
            $rewarded = $rewardedResponse.Content | ConvertFrom-Json
        }
        catch {
            throw 'The deployed rewarded-ad-ssv health response is not valid JSON.'
        }
        if ($null -eq $rewarded -or $rewarded -is [System.Array] -or
            [string]$rewarded.service -cne 'rewarded-ad-ssv' -or
            [int]$rewarded.contractVersion -ne 1 -or
            [string]$rewarded.sourceRevision -cne
                $ExpectedRewardedSsvSourceRevision -or
            [string]$rewarded.gemsAdUnitId -cne
                $ExpectedRewardedGemsAdUnitId.Trim() -or
            [string]$rewarded.coinsAdUnitId -cne
                $ExpectedRewardedCoinsAdUnitId.Trim()) {
            throw 'The deployed rewarded-ad-ssv source or ad-unit configuration differs from this release.'
        }
        $rewardedHealthStatus = $rewardedResponse.Status
        $rewardedHealthDurationMs = $rewardedResponse.DurationMs
        $rewardedFunctionVersion = [int64]$rewardedFunction.version
        $rewardedFunctionBundleSha256 = [string]$rewardedFunction.ezbr_sha256
    }

    $result = [ordered]@{
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
    if ($RequireRewardedAds) {
        $result['RewardedAdsVerified'] = $true
        $result['RewardedSsvHealthStatus'] = $rewardedHealthStatus
        $result['RewardedSsvHealthDurationMs'] = $rewardedHealthDurationMs
        $result['RewardedSsvSourceRevision'] = $ExpectedRewardedSsvSourceRevision
        $result['RewardedSsvFunctionVersion'] = $rewardedFunctionVersion
        $result['RewardedSsvBundleSha256'] = $rewardedFunctionBundleSha256
    }
    [pscustomobject]$result
}
finally {
    Pop-Location
}
