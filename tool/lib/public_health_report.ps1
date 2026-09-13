. (Join-Path $PSScriptRoot 'public_auth_health.ps1')

function Invoke-DragonHavenPublicHealthCheck {
    param(
        [string]$BaseUrl,
        [string]$PublishableKey,
        [string]$Environment = 'production',
        [string]$OutputPath = '',
        [switch]$SkipApplicationHealth,
        [ValidateRange(1, 60)][int]$TimeoutSeconds = 60,
        [ValidateRange(1, 2)][int]$MaximumAttempts = 1,
        [ValidateRange(0, 30)][int]$RetryDelaySeconds = 15
    )
    $attempts = @()
    for ($number = 1; $number -le $MaximumAttempts; $number++) {
        $attempt = [ordered]@{
            CheckedAtUtc = [DateTime]::UtcNow.ToString('o')
            Attempt = $number
            Succeeded = $true
            ApplicationHealthChecked = -not $SkipApplicationHealth
            EmailAuthConfigured = $false
            Errors = @()
        }
        $checks = @(
            @{ Name = 'AuthHealth'; Path = '/auth/v1/health'; Method = 'GET' },
            @{ Name = 'AuthSettings'; Path = '/auth/v1/settings'; Method = 'GET' }
        )
        if (-not $SkipApplicationHealth) {
            $checks += @{ Name = 'ApplicationHealth'; Path = '/rest/v1/rpc/dragonhaven_public_health'; Method = 'POST' }
        }
        foreach ($check in $checks) {
            $name = $check.Name
            $watch = [Diagnostics.Stopwatch]::StartNew()
            try {
                $response = Invoke-DragonHavenPublicRequest -BaseUrl $BaseUrl `
                    -Path $check.Path -PublishableKey $PublishableKey `
                    -Method $check.Method -JsonBody '{}' -TimeoutSeconds $TimeoutSeconds
                $attempt["${name}Status"] = $response.Status
                $attempt["${name}DurationMs"] = $response.DurationMs
            }
            catch {
                # Never serialize an exception or response body: they may contain
                # proxy details, headers or credentials. Zero means no HTTP result.
                $attempt["${name}Status"] = 0
                $attempt["${name}DurationMs"] = $watch.ElapsedMilliseconds
                $attempt.Errors += "${name}:request_failed"
                continue
            }
            if ($response.Status -ne 200) {
                $attempt.Errors += "${name}:http_status"
                continue
            }
            if ($name -eq 'AuthSettings') {
                $attempt.EmailAuthConfigured = $response.Content -match '"email"'
                if (-not $attempt.EmailAuthConfigured) {
                    $attempt.Errors += 'AuthSettings:email_auth_missing'
                }
            }
            if ($name -eq 'ApplicationHealth') {
                try {
                    $application = ConvertFrom-DragonHavenApplicationHealth -Content $response.Content
                    $attempt.ApplicationService = $application.Service
                    $attempt.ApplicationContractVersion = $application.ContractVersion
                    $attempt.ApplicationServerTimeUtc = $application.ServerTimeUtc
                    $attempt.ApplicationClockSkewMs = $application.ClockSkewMs
                }
                catch {
                    $attempt.Errors += 'ApplicationHealth:invalid_contract'
                }
            }
        }
        $attempt.Succeeded = $attempt.Errors.Count -eq 0
        $attempts += [pscustomobject]$attempt
        # Keep the established top-level endpoint fields for report consumers.
        $report = [ordered]@{
            Environment = $Environment
            Host = ([Uri]$BaseUrl).Host
            AttemptCount = $attempts.Count
            MaximumAttempts = $MaximumAttempts
            RecoveredDuringCheck = $attempt.Succeeded -and $number -gt 1
            Attempts = $attempts
        }
        foreach ($key in $attempt.Keys) { $report[$key] = $attempt[$key] }
        if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
            $parent = Split-Path -Parent $OutputPath
            if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
        }
        if ($attempt.Succeeded -or $number -eq $MaximumAttempts) { break }
        if ($RetryDelaySeconds -gt 0) { Start-Sleep -Seconds $RetryDelaySeconds }
    }
    [pscustomobject]$report
}
