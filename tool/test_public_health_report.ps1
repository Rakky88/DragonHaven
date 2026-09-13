$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/public_health_report.ps1')

$script:calls = 0
$script:scenario = 'healthy'
function Invoke-DragonHavenPublicRequest {
    param($BaseUrl, $Path, $PublishableKey, $Method, $JsonBody, $TimeoutSeconds)
    $script:calls++
    if ($script:scenario -eq 'transport' -and $Path -eq '/auth/v1/health') {
        throw 'PRIVATE_SENTINEL must never reach the report'
    }
    $status = 200
    if (($script:scenario -eq 'transient' -and $script:calls -eq 1) -or
        ($script:scenario -eq 'persistent' -and $Path -eq '/auth/v1/health')) {
        $status = 503
    }
    $content = '{"email":true,"private":"PRIVATE_SENTINEL"}'
    if ($Path -like '/rest/*') {
        $content = @{
            status = 'ok'; service = 'dragonhaven-online'; contract_version = 1
            server_time_utc = [DateTimeOffset]::UtcNow.ToString('o')
        } | ConvertTo-Json
        if ($script:scenario -eq 'contract') { $content = '{"private":"PRIVATE_SENTINEL"}' }
    }
    [pscustomobject]@{ Status = $status; DurationMs = 12; Content = $content }
}

$output = Join-Path ([IO.Path]::GetTempPath()) ('health-test-' + [guid]::NewGuid() + '.json')
try {
    foreach ($scenario in @('healthy', 'transient', 'persistent', 'transport', 'contract')) {
        $script:scenario = $scenario
        $script:calls = 0
        $report = Invoke-DragonHavenPublicHealthCheck -BaseUrl 'https://example.invalid' `
            -PublishableKey 'PRIVATE_SENTINEL' -MaximumAttempts 2 -RetryDelaySeconds 0 -OutputPath $output
        $storedText = Get-Content -LiteralPath $output -Raw
        $stored = $storedText | ConvertFrom-Json
        if ($storedText.Contains('PRIVATE_SENTINEL')) { throw 'Private data escaped into evidence.' }
        $expectedSuccess = $scenario -in @('healthy', 'transient')
        if ($report.Succeeded -ne $expectedSuccess -or $stored.Succeeded -ne $expectedSuccess) {
            throw "Wrong success status: $scenario"
        }
        $expectedAttempts = if ($scenario -eq 'healthy') { 1 } else { 2 }
        if ($report.AttemptCount -ne $expectedAttempts -or $script:calls -ne 3 * $expectedAttempts) {
            throw "Wrong request/attempt count: $scenario"
        }
        if ($report.RecoveredDuringCheck -ne ($scenario -eq 'transient')) { throw 'Wrong recovery status.' }
        if ($scenario -eq 'transient' -and $stored.Attempts[0].AuthHealthStatus -ne 503) {
            throw 'The failed first attempt was lost.'
        }
        if ($scenario -eq 'transport' -and $stored.AuthHealthStatus -ne 0) { throw 'Missing transport status.' }
        if ($scenario -eq 'contract' -and $stored.Errors -notcontains 'ApplicationHealth:invalid_contract') {
            throw 'Invalid contract was not recorded.'
        }
    }
    $script:scenario = 'healthy'; $script:calls = 0
    $report = Invoke-DragonHavenPublicHealthCheck -BaseUrl 'https://example.invalid' `
        -PublishableKey 'PRIVATE_SENTINEL' -SkipApplicationHealth
    if ($script:calls -ne 2 -or $report.ApplicationHealthChecked) { throw 'Skip behavior changed.' }
    'Health evidence checks passed: healthy, recovered, persistent, transport, contract, privacy and skip.'
}
finally { if (Test-Path -LiteralPath $output) { Remove-Item -LiteralPath $output -Force } }
