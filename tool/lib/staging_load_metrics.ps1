function ConvertTo-SafeLoadMetrics {
    param([string]$Text)
    # Export aggregates only. Never persist labels, database names, SQL or raw metrics.
    $values = @{}
    foreach ($line in ($Text -split "`n")) {
        if ($line -notmatch '^([a-zA-Z_:][a-zA-Z0-9_:]*)(\{.*\})?\s+([0-9.eE+\-]+)\s*$') { continue }
        $metricName = $Matches[1]; $labels = $Matches[2]
        $number = 0.0
        if (-not [double]::TryParse($Matches[3], [Globalization.NumberStyles]::Float,
            [Globalization.CultureInfo]::InvariantCulture, [ref]$number) -or
            [double]::IsNaN($number) -or [double]::IsInfinity($number) -or $number -lt 0) { continue }
        if ($labels -match 'service_type="([^\"]+)"' -and $Matches[1] -ne 'db') { continue }
        $key = switch ($metricName) {
            'node_cpu_seconds_total' {
                if ($labels -match 'mode="(guest|guest_nice)"') { continue }
                if ($labels -match 'mode="idle"') {
                    if (-not $values.ContainsKey('cpuIdleSeconds')) { $values.cpuIdleSeconds = 0.0 }
                    $values.cpuIdleSeconds += $number
                }
                'cpuTotalSeconds'
            }
            'pg_stat_database_numbackends' { 'databaseConnections' }
            'pg_settings_max_connections' { 'maxDatabaseConnections' }
            'node_memory_MemAvailable_bytes' { 'memoryAvailableBytes' }
            'node_memory_MemTotal_bytes' { 'memoryTotalBytes' }
            'node_network_transmit_bytes_total' {
                if ($labels -match 'device="lo"') { continue }
                'hostNetworkTransmitBytes'
            }
            default { continue }
        }
        if ([string]::IsNullOrEmpty($key)) { continue }
        if (-not $values.ContainsKey($key)) { $values[$key] = 0.0 }
        $values[$key] += $number
    }
    return $values
}

function Save-StagingLoadMetricSample {
    param([string]$ProjectRef, [string]$AccessToken, [string]$OutputPath,
          [string]$PhasePath = 'staging/load-phase.json')
    if ($ProjectRef -notmatch '^[a-z0-9]{20}$' -or $ProjectRef -eq 'tnzathhutuwmohmjfrlo') {
        throw 'Production is a forbidden load-test target.'
    }
    $phase = 'preparation'
    if (Test-Path -LiteralPath $PhasePath) {
        $phaseData = Get-Content -LiteralPath $PhasePath -Raw | ConvertFrom-Json
        if ($phaseData.phase -eq 'browsing') { $phase = 'browsing' }
    }
    $sample = [ordered]@{ checkedAtUtc = [DateTime]::UtcNow.ToString('o'); phase = $phase;
        available = $false; values = @{} }
    try {
        $response = Invoke-WebRequest -Method Get -TimeoutSec 20 `
            -Uri "https://api.supabase.com/v1/projects/$ProjectRef/analytics/endpoints/metrics" `
            -Headers @{ Authorization = "Bearer $AccessToken" }
        $text = if ($response.Content -is [byte[]]) { [Text.Encoding]::UTF8.GetString($response.Content) } else { [string]$response.Content }
        $sample.values = ConvertTo-SafeLoadMetrics -Text $text
        $sample.available = $sample.values.Count -gt 0
    } catch {
        # A failed optional metrics scrape must never skip synthetic cleanup.
        # Do not record a provider response or exception containing credentials.
        $sample.available = $false
    }
    $samples = @()
    if (Test-Path -LiteralPath $OutputPath) {
        $samples = @((Get-Content -LiteralPath $OutputPath -Raw | ConvertFrom-Json).samples)
    }
    [ordered]@{ kind = 'dragonhaven-staging-provider-metrics'; environment = 'staging';
        productionTarget = $false; sampleIntervalSeconds = 60;
        networkCounterIsBilledEgress = $false;
        samples = @($samples) + @($sample) } |
        ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
}
