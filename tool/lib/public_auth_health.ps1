function Invoke-DragonHavenPublicRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$BaseUrl,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$PublishableKey,
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
            '--user-agent', 'DragonHaven-Public-Health/1',
            '--output', $temporaryOutput,
            '--write-out', '%{http_code}|%{time_total}',
            "$($BaseUrl.TrimEnd('/'))$Path"
        )
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
