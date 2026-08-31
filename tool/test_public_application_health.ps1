[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\public_auth_health.ps1')

$validPayload = @{
    status = 'ok'
    service = 'dragonhaven-online'
    contract_version = 1
    server_time_utc = [DateTimeOffset]::UtcNow.ToString('o')
} | ConvertTo-Json -Compress
$parsed = ConvertFrom-DragonHavenApplicationHealth -Content $validPayload
if ($parsed.ContractVersion -ne 1 -or
    $parsed.Service -ne 'dragonhaven-online' -or
    $parsed.ClockSkewMs -gt 5000) {
    throw 'A valid application health payload was not parsed correctly.'
}

$invalidContractRejected = $false
try {
    ConvertFrom-DragonHavenApplicationHealth -Content (@{
        status = 'ok'
        service = 'wrong-service'
        contract_version = 1
        server_time_utc = [DateTimeOffset]::UtcNow.ToString('o')
    } | ConvertTo-Json -Compress) | Out-Null
}
catch {
    $invalidContractRejected = $true
}
if (-not $invalidContractRejected) {
    throw 'An invalid application health contract was accepted.'
}

$staleClockRejected = $false
try {
    ConvertFrom-DragonHavenApplicationHealth -Content (@{
        status = 'ok'
        service = 'dragonhaven-online'
        contract_version = 1
        server_time_utc = '2020-01-01T00:00:00.000Z'
    } | ConvertTo-Json -Compress) | Out-Null
}
catch {
    $staleClockRejected = $true
}
if (-not $staleClockRejected) {
    throw 'An unsafe application health server clock was accepted.'
}

$arrayRejected = $false
try {
    ConvertFrom-DragonHavenApplicationHealth -Content '[]' | Out-Null
}
catch {
    $arrayRejected = $true
}
if (-not $arrayRejected) {
    throw 'An array was accepted as application health contract.'
}

'Application health parser positive and negative checks passed.'
