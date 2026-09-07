Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib/staging_load_metrics.ps1')
$fixture = @'
node_cpu_seconds_total{cpu="0",mode="idle",service_type="db"} 10
node_cpu_seconds_total{cpu="0",mode="user",service_type="db"} 5
node_cpu_seconds_total{cpu="0",mode="guest",service_type="db"} 99
node_cpu_seconds_total{cpu="0",mode="idle",service_type="auth"} 99
pg_stat_database_numbackends{datname="private-name",service_type="db"} 8
node_network_transmit_bytes_total{device="lo"} 99
node_network_transmit_bytes_total{device="eth0"} 30
node_memory_MemTotal_bytes{} +Inf
secret_sql{query="private-sql"} 5
'@
$result = ConvertTo-SafeLoadMetrics $fixture
if ($result.cpuTotalSeconds -ne 15 -or $result.cpuIdleSeconds -ne 10 -or
    $result.databaseConnections -ne 8 -or $result.hostNetworkTransmitBytes -ne 30 -or
    $result.Count -ne 4 -or ($result | ConvertTo-Json) -match 'private|secret|datname|query') {
    throw 'Metric parsing/privacy contract failed.'
}
$blocked = $false
try {
    Save-StagingLoadMetricSample -ProjectRef tnzathhutuwmohmjfrlo `
        -AccessToken unused -OutputPath unused
} catch { $blocked = $_.Exception.Message -eq 'Production is a forbidden load-test target.' }
if (-not $blocked) { throw 'Production metrics target was not blocked before network access.' }
'Staging metrics allowlist and production block passed without network access.'
