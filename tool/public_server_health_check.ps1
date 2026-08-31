[CmdletBinding()]
param(
    [string]$BaseUrl = '',
    [string]$PublishableKey = '',
    [string]$Environment = 'production',
    [string]$OutputPath = '',
    [switch]$SkipApplicationHealth,
    [int]$TimeoutSeconds = 60
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $repoRoot 'lib\config\online_config.dart'
. (Join-Path $PSScriptRoot 'lib\public_auth_health.ps1')

if ($TimeoutSeconds -lt 1 -or $TimeoutSeconds -gt 60) {
    throw 'TimeoutSeconds must be between 1 and 60.'
}

if ([string]::IsNullOrWhiteSpace($BaseUrl) -or
    [string]::IsNullOrWhiteSpace($PublishableKey)) {
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
    if ([string]::IsNullOrWhiteSpace($BaseUrl)) {
        if (-not $urlMatch.Success) {
            throw 'The bundled public Supabase URL could not be parsed.'
        }
        $BaseUrl = $urlMatch.Groups[1].Value
    }
    if ([string]::IsNullOrWhiteSpace($PublishableKey)) {
        if (-not $keyMatch.Success) {
            throw 'The bundled public Supabase key could not be parsed.'
        }
        $PublishableKey = $keyMatch.Groups[1].Value
    }
}

$BaseUrl = $BaseUrl.TrimEnd('/')
if ($BaseUrl -notmatch '^https://[^/]+$') {
    throw 'The public health URL is invalid.'
}
if ($PublishableKey -notmatch '^sb_publishable_') {
    throw 'The public health publishable key is invalid.'
}

$health = Invoke-DragonHavenPublicRequest `
    -BaseUrl $BaseUrl `
    -Path '/auth/v1/health' `
    -PublishableKey $PublishableKey `
    -TimeoutSeconds $TimeoutSeconds
$settings = Invoke-DragonHavenPublicRequest `
    -BaseUrl $BaseUrl `
    -Path '/auth/v1/settings' `
    -PublishableKey $PublishableKey `
    -TimeoutSeconds $TimeoutSeconds
if ($health.Status -ne 200 -or $settings.Status -ne 200) {
    throw 'One or more public Auth endpoints are unhealthy.'
}
if ($settings.Content -notmatch '"email"') {
    throw 'Public Auth settings do not expose e-mail authentication.'
}

$application = $null
$applicationResponse = $null
if (-not $SkipApplicationHealth) {
    $applicationResponse = Invoke-DragonHavenPublicRequest `
        -BaseUrl $BaseUrl `
        -Path '/rest/v1/rpc/dragonhaven_public_health' `
        -PublishableKey $PublishableKey `
        -Method POST `
        -JsonBody '{}' `
        -TimeoutSeconds $TimeoutSeconds
    if ($applicationResponse.Status -ne 200) {
        throw 'The public application health endpoint is unhealthy.'
    }
    $application = ConvertFrom-DragonHavenApplicationHealth `
        -Content $applicationResponse.Content
}

$report = [ordered]@{
    CheckedAtUtc = [DateTime]::UtcNow.ToString('o')
    Environment = $Environment
    Host = ([Uri]$BaseUrl).Host
    AuthHealthStatus = $health.Status
    AuthHealthDurationMs = $health.DurationMs
    AuthSettingsStatus = $settings.Status
    AuthSettingsDurationMs = $settings.DurationMs
    EmailAuthConfigured = $true
    ApplicationHealthChecked = -not $SkipApplicationHealth
}
if ($null -ne $application) {
    $report.ApplicationHealthStatus = $applicationResponse.Status
    $report.ApplicationHealthDurationMs = $applicationResponse.DurationMs
    $report.ApplicationService = $application.Service
    $report.ApplicationContractVersion = $application.ContractVersion
    $report.ApplicationServerTimeUtc = $application.ServerTimeUtc
    $report.ApplicationClockSkewMs = $application.ClockSkewMs
}

if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $resolvedOutput = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
        $OutputPath
    } else {
        Join-Path $repoRoot $OutputPath
    }
    $parent = Split-Path -Parent $resolvedOutput
    if (-not [string]::IsNullOrWhiteSpace($parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $report | ConvertTo-Json | Set-Content -LiteralPath $resolvedOutput -Encoding utf8
}

[pscustomobject]$report
