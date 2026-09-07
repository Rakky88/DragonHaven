#requires -Version 7.0
[CmdletBinding()]
param(
    [ValidateSet(100, 1000)][int]$VirtualUsers = 100,
    [string]$Confirmation = '',
    [string]$BaselinePath = '',
    [string]$CleanupRunId = ''
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRef = $env:STAGING_SUPABASE_PROJECT_REF
$baseUrl = ([string]$env:STAGING_SUPABASE_URL).TrimEnd('/')
if ($projectRef -eq 'tnzathhutuwmohmjfrlo' -or $baseUrl -eq 'https://tnzathhutuwmohmjfrlo.supabase.co') {
    throw 'Production is a forbidden load-test target.'
}
if ($projectRef -notmatch '^[a-z0-9]{20}$' -or $baseUrl -ne "https://$projectRef.supabase.co" -or
    -not ([string]$env:STAGING_SUPABASE_PUBLISHABLE_KEY).StartsWith('sb_publishable_')) {
    throw 'The isolated staging configuration is invalid.'
}
$runId = [guid]::NewGuid().ToString('N')
if ($CleanupRunId) {
    if ($CleanupRunId -notmatch '^[a-f0-9]{32}$') { throw 'Invalid synthetic cleanup run identifier.' }
    $runId = $CleanupRunId
} elseif ($Confirmation -cne "RUN_DRAGONHAVEN_STAGING_LOAD_$VirtualUsers") {
    throw 'Exact staging load confirmation is required.'
}
if (-not $CleanupRunId -and $VirtualUsers -eq 1000) {
    if (-not $BaselinePath) { throw 'A successful 100-user baseline is required.' }
    $baseline = Get-Content -LiteralPath $BaselinePath -Raw | ConvertFrom-Json
    if ($baseline.schemaVersion -ne 2 -or $baseline.measurementMode -ne 'preauthenticated_browsing' -or
        $baseline.environment -ne 'staging' -or $baseline.warmupCompleted -ne $true -or
        $baseline.sessionsCoverMeasurement -ne $true -or $baseline.preparedUsers -ne 100 -or
        $baseline.peakConcurrentBrowsingUsers -ne 100 -or $baseline.steadyStateSeconds -lt 180 -or
        $baseline.minimumReadRequestsPerUser -lt 1 -or $baseline.errorRatePercent -lt 0 -or $baseline.readErrorRatePercent -lt 0 -or
        $baseline.readErrorRatePercent -gt 2 -or
        $baseline.kind -ne 'dragonhaven-staging-load-report' -or $baseline.result -ne 'passed' -or
        $baseline.virtualUsers -ne 100 -or $baseline.productionTarget -ne $false -or
        $baseline.errorRatePercent -gt 2 -or $baseline.authenticatedUsers -ne 100 -or
        $baseline.activeUsers -ne 100) {
        throw 'The 100-user baseline does not permit 1000 users.'
    }
    $latest = (Get-ChildItem supabase/migrations -Filter '*.sql' -File | Sort-Object Name | Select-Object -Last 1).BaseName.Split('_')[0]
    if ($baseline.repositoryMigrationVersion -ne $latest) { throw 'The baseline schema is stale.' }
}
# Privileged setup stays in this wrapper. The Dart load process receives only
# publishable credentials and a fresh password for each synthetic account.
try {
    $keys = Invoke-RestMethod -Method Get -Uri "https://api.supabase.com/v1/projects/$projectRef/api-keys?reveal=true" `
        -Headers @{ Authorization = "Bearer $env:STAGING_SUPABASE_ACCESS_TOKEN" }
    $adminKey = @($keys | Where-Object { $_.name -eq 'service_role' })[0].api_key
    if ([string]::IsNullOrWhiteSpace($adminKey)) { throw 'Missing setup key.' }
} catch { throw 'Could not obtain protected staging account setup credentials.' }
$adminHeaders = @{ apikey = $adminKey; Authorization = "Bearer $adminKey" }

function Invoke-AdminRequest {
    param([string]$Method, [string]$Path, [object]$Body = $null)
    $requestArguments = @{ Method = $Method; Uri = "$baseUrl/auth/v1/admin/$Path";
        Headers = $adminHeaders; ContentType = 'application/json'; TimeoutSec = 30 }
    if ($null -ne $Body) { $requestArguments.Body = ConvertTo-Json $Body -Depth 8 -Compress }
    try { return Invoke-RestMethod @requestArguments }
    catch { throw 'Synthetic staging account operation failed; response body omitted.' }
}

function Remove-RunAccounts {
    # Gather first, then delete; deleting while paging could skip shifted rows.
    $matchingAccounts = [System.Collections.Generic.List[object]]::new()
    for ($page = 1; $page -le 100; $page++) {
        $response = Invoke-AdminRequest Get "users?page=$page&per_page=1000"
        foreach ($account in $response.users) {
            if ($null -eq $account.app_metadata) { continue }
            $marker = $account.app_metadata.PSObject.Properties['dragonhaven_load_run']
            if ($null -eq $marker -or $marker.Value -cne $runId) { continue }
            if ($account.email -notmatch "^load-$runId-[0-9]+@dragonhaven-load\.invalid$" -or
                $account.id -notmatch '^[a-f0-9-]{36}$') {
                throw 'Cleanup refused an account with a mismatched synthetic identity.'
            }
            $matchingAccounts.Add($account)
        }
        if ($response.users.Count -lt 1000) { break }
        if ($page -eq 100) { throw 'Cleanup pagination exceeded its bounded account scan.' }
    }
    foreach ($account in $matchingAccounts) {
        $null = Invoke-AdminRequest Delete "users/$($account.id)" @{ should_soft_delete = $false }
    }
    return $matchingAccounts.Count
}

if ($CleanupRunId) {
    $removed = Remove-RunAccounts
    "Synthetic recovery cleanup completed: removed=$removed; no identifiers logged."
    exit 0
}
New-Item -ItemType Directory -Path staging -Force | Out-Null
$evidence = [ordered]@{ runIdentifier = $runId; requested = $VirtualUsers; created = 0;
    removed = 0; cleanupComplete = $false; credentialsRecorded = $false; emailSent = $false }
function Save-Lifecycle {
    $evidence | ConvertTo-Json | Set-Content -LiteralPath staging/load-account-lifecycle.json -Encoding utf8
}
Save-Lifecycle
$accounts = [System.Collections.Generic.List[object]]::new()
$runFailed = $false
$process = $null
. (Join-Path $PSScriptRoot 'lib/staging_load_metrics.ps1')
try {
    for ($index = 1; $index -le $VirtualUsers; $index++) {
        $passwordBytes = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32)
        $password = [Convert]::ToBase64String($passwordBytes) + 'Dh7!'
        $address = "load-$runId-$index@dragonhaven-load.invalid"
        # Admin create auto-confirms without invoking signup/invite or sending
        # mail. Addresses deliberately use a reserved, non-deliverable domain.
        $created = Invoke-AdminRequest Post 'users' @{
            email = $address; password = $password; email_confirm = $true
            app_metadata = @{ dragonhaven_load_run = $runId }
        }
        if ($created.email -cne $address -or -not $created.email_confirmed_at) {
            throw 'Synthetic account confirmation could not be verified.'
        }
        $accounts.Add(@{ email = $address; password = $password })
        $evidence.created = $accounts.Count
        if ($index % 25 -eq 0) {
            Save-Lifecycle
            "Prepared $index/$VirtualUsers synthetic accounts."
        }
    }
    Save-Lifecycle
    $start = [System.Diagnostics.ProcessStartInfo]::new()
    $start.FileName = (Get-Command dart -ErrorAction Stop).Source
    $start.UseShellExecute = $false
    foreach ($argument in @('run', 'tool/staging_load_profile.dart', '--execute',
        "--virtual-users=$VirtualUsers", '--duration-seconds=180', '--ramp-up-seconds=60',
        "--confirmation=$Confirmation", '--synthetic-accounts-confirmed', '--output=staging/load-report.json')) {
        $start.ArgumentList.Add($argument)
    }
    if ($BaselinePath) { $start.ArgumentList.Add("--baseline=$BaselinePath") }
    foreach ($name in @('STAGING_SUPABASE_ACCESS_TOKEN','SUPABASE_ACCESS_TOKEN',
        'SUPABASE_DB_PASSWORD','STAGING_SUPABASE_DB_PASSWORD','GH_TOKEN','GITHUB_TOKEN')) {
        $null = $start.Environment.Remove($name)
    }
    $start.Environment['STAGING_LOAD_CREDENTIALS_JSON'] = ConvertTo-Json @{ accounts = @($accounts.ToArray()) } -Depth 5 -Compress
    Save-StagingLoadMetricSample -ProjectRef $projectRef -AccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN -OutputPath 'staging/load-provider-metrics.json'
    $process = [System.Diagnostics.Process]::Start($start)
    $lastMetricSample = [DateTime]::UtcNow
    while (-not $process.WaitForExit(30000)) {
        'Staging load is running; account data remains private.'
        if (([DateTime]::UtcNow - $lastMetricSample).TotalSeconds -ge 60) {
            Save-StagingLoadMetricSample -ProjectRef $projectRef -AccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN -OutputPath 'staging/load-provider-metrics.json'
            $lastMetricSample = [DateTime]::UtcNow
        }
    }
    Save-StagingLoadMetricSample -ProjectRef $projectRef -AccessToken $env:STAGING_SUPABASE_ACCESS_TOKEN -OutputPath 'staging/load-provider-metrics.json'
    if ($process.ExitCode -ne 0) { $runFailed = $true }
    $process.Dispose()
    $process = $null
} finally {
    if ($null -ne $process) {
        if (-not $process.HasExited) { $process.Kill($true); $process.WaitForExit() }
        $process.Dispose()
    }
    $accounts.Clear()
    $evidence.removed = Remove-RunAccounts
    if ((Remove-RunAccounts) -ne 0) { throw 'Synthetic cleanup required a second pass; investigate before another load run.' }
    $evidence.cleanupComplete = $true
    Save-Lifecycle
    "Temporary account cleanup completed: removed=$($evidence.removed)."
}
if ($runFailed) { throw 'The bounded staging load did not pass; inspect the privacy-safe report.' }
