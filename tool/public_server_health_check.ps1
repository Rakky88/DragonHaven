[CmdletBinding()]
param(
    [string]$BaseUrl = '',
    [string]$PublishableKey = '',
    [string]$Environment = 'production',
    [string]$OutputPath = '',
    [switch]$SkipApplicationHealth,
    [int]$TimeoutSeconds = 60,
    [ValidateRange(1, 2)][int]$MaximumAttempts = 1,
    [ValidateRange(0, 30)][int]$RetryDelaySeconds = 15
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $repoRoot 'lib\config\online_config.dart'
. (Join-Path $PSScriptRoot 'lib\public_health_report.ps1')

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

$resolvedOutput = if ([string]::IsNullOrWhiteSpace($OutputPath) -or
    [System.IO.Path]::IsPathRooted($OutputPath)) { $OutputPath }
    else { Join-Path $repoRoot $OutputPath }
$report = Invoke-DragonHavenPublicHealthCheck -BaseUrl $BaseUrl `
    -PublishableKey $PublishableKey -Environment $Environment `
    -OutputPath $resolvedOutput -SkipApplicationHealth:$SkipApplicationHealth `
    -TimeoutSeconds $TimeoutSeconds -MaximumAttempts $MaximumAttempts `
    -RetryDelaySeconds $RetryDelaySeconds
$report
if (-not $report.Succeeded) {
    throw 'Public health checks failed. See the sanitized health report for endpoint statuses and attempts.'
}
