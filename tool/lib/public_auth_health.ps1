function Invoke-DragonHavenPublicRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$BaseUrl,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$PublishableKey,
        [ValidateSet('GET', 'POST')][string]$Method = 'GET',
        [string]$JsonBody = '',
        [int]$TimeoutSeconds = 60
    )

    $curl = @(
        Get-Command 'curl.exe' -CommandType Application -ErrorAction SilentlyContinue
    ) | Select-Object -First 1
    if ($null -eq $curl) {
        $curl = @(
            Get-Command 'curl' -CommandType Application -ErrorAction SilentlyContinue
        ) | Select-Object -First 1
    }
    if ($null -eq $curl) {
        throw 'curl is required for the public server health check.'
    }

    $temporaryOutput = [System.IO.Path]::GetTempFileName()
    try {
        $arguments = @(
            '--silent',
            '--show-error',
            '--connect-timeout', "$TimeoutSeconds",
            '--max-time', "$TimeoutSeconds",
            '--header', "apikey: $PublishableKey",
            '--header', 'accept: application/json',
            '--user-agent', 'DragonHaven-Public-Health/1',
            '--output', $temporaryOutput,
            '--write-out', '%{http_code}|%{time_total}'
        )
        if ($Method -eq 'POST') {
            $arguments += @(
                '--request', 'POST',
                '--header', 'content-type: application/json',
                '--data-raw', $JsonBody
            )
        }
        $arguments += "$($BaseUrl.TrimEnd('/'))$Path"
        $metrics = (& $curl.Source @arguments | Out-String).Trim()
        if ($LASTEXITCODE -ne 0) {
            throw "Public health request '$Path' failed."
        }
        if ($metrics -notmatch '^(\d{3})\|([0-9]+(?:\.[0-9]+)?)$') {
            throw "Public health request '$Path' returned invalid metrics."
        }
        [pscustomobject]@{
            Status = [int]$Matches[1]
            DurationMs = [int]([double]$Matches[2] * 1000)
            Content = Get-Content -LiteralPath $temporaryOutput -Raw
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporaryOutput) {
            Remove-Item -LiteralPath $temporaryOutput -Force
        }
    }
}

function ConvertFrom-DragonHavenApplicationHealth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [int]$MaximumClockSkewSeconds = 300
    )

    if ($MaximumClockSkewSeconds -lt 1 -or $MaximumClockSkewSeconds -gt 3600) {
        throw 'MaximumClockSkewSeconds must be between 1 and 3600.'
    }

    try {
        $payload = $Content | ConvertFrom-Json
    }
    catch {
        throw 'The public application health response is not valid JSON.'
    }
    if ($null -eq $payload -or $payload -is [System.Array]) {
        throw 'The public application health response must be one JSON object.'
    }
    if ([string]$payload.status -ne 'ok' -or
        [string]$payload.service -ne 'dragonhaven-online' -or
        [int]$payload.contract_version -ne 1) {
        throw 'The public application health contract is invalid.'
    }

    $serverTime = [DateTimeOffset]::MinValue
    if (-not [DateTimeOffset]::TryParse(
        [string]$payload.server_time_utc,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::AssumeUniversal,
        [ref]$serverTime
    )) {
        throw 'The public application health server time is invalid.'
    }
    $clockSkewMs = [math]::Abs(
        [int64]([DateTimeOffset]::UtcNow - $serverTime.ToUniversalTime()).TotalMilliseconds
    )
    if ($clockSkewMs -gt ($MaximumClockSkewSeconds * 1000)) {
        throw 'The public application health server clock is outside the safe window.'
    }

    [pscustomobject]@{
        Service = [string]$payload.service
        ContractVersion = [int]$payload.contract_version
        ServerTimeUtc = $serverTime.ToUniversalTime().ToString('o')
        ClockSkewMs = $clockSkewMs
    }
}
