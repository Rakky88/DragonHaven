#requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('RequestConfirmation', 'VerifyConfirmedAccount')]
    [string]$Mode,

    [Parameter(Mandatory = $true)]
    [string]$SupabaseUrl,

    [Parameter(Mandatory = $true)]
    [string]$PublishableKey,

    [Parameter(Mandatory = $true)]
    [string]$Email,

    [Parameter(Mandatory = $true)]
    [string]$Password,

    [string]$EvidencePath = 'staging/auth-e2e.txt'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$baseUrl = $SupabaseUrl.Trim().TrimEnd('/')
$normalizedEmail = $Email.Trim().ToLowerInvariant()
if ($baseUrl -notmatch '^https://[a-z0-9]+\.supabase\.co$') {
    throw 'De staging Auth-test accepteert uitsluitend een gehost HTTPS-Supabaseproject.'
}
if (-not $PublishableKey.StartsWith('sb_publishable_')) {
    throw 'De staging Auth-test vereist een publishable clientkey.'
}
try {
    $parsedEmail = [System.Net.Mail.MailAddress]::new($normalizedEmail)
} catch {
    throw 'Het afgeschermde staging-testadres is ongeldig.'
}
if ($parsedEmail.Address -ne $normalizedEmail) {
    throw 'Het afgeschermde staging-testadres is ongeldig.'
}
if ($Password.Length -lt 12) {
    throw 'Het afgeschermde staging-testwachtwoord is te kort.'
}

function Get-PropertyValue {
    param(
        [AllowNull()]
        [object]$InputObject,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($null -eq $InputObject) { return $null }
    if ($InputObject -is [System.Collections.IDictionary]) {
        return $InputObject[$Name]
    }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Get-SafeFailure {
    param(
        [AllowNull()]
        [object]$Body,
        [Parameter(Mandatory = $true)]
        [int]$StatusCode
    )

    # PostgREST returns raised SQL exceptions as code P0001 plus the useful,
    # stable application error in message. Prefer that application error so
    # assertions do not mistake a correctly rejected request for a test failure.
    foreach ($name in @('error_code', 'message', 'msg', 'code', 'error_description')) {
        $value = Get-PropertyValue -InputObject $Body -Name $name
        if (-not [string]::IsNullOrWhiteSpace([string]$value)) {
            $safe = ([string]$value).Replace($normalizedEmail, '[redacted-email]')
            if ($safe.Length -gt 180) { $safe = $safe.Substring(0, 180) }
            return "HTTP $StatusCode ($safe)"
        }
    }
    return "HTTP $StatusCode"
}

function Invoke-StagingJsonRequest {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Get', 'Post')]
        [string]$Method,
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        [Parameter(Mandatory = $true)]
        [hashtable]$Headers,
        [AllowNull()]
        [object]$Body
    )

    $request = @{
        Method = $Method
        Uri = $Uri
        Headers = $Headers
        SkipHttpErrorCheck = $true
        StatusCodeVariable = 'requestStatusCode'
        ErrorAction = 'Stop'
    }
    if ($null -ne $Body) {
        $request.ContentType = 'application/json'
        $request.Body = ConvertTo-Json -InputObject $Body -Depth 30 -Compress
    }
    $response = Invoke-RestMethod @request
    return [pscustomobject]@{
        StatusCode = [int]$requestStatusCode
        Body = $response
    }
}

function Test-SuccessStatus {
    param([int]$StatusCode)
    return $StatusCode -ge 200 -and $StatusCode -lt 300
}

function Write-SafeEvidence {
    param([string[]]$Lines)

    $parent = Split-Path -Parent $EvidencePath
    if (-not [string]::IsNullOrWhiteSpace($parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    @(
        'DragonHaven staging Auth E2E'
        "UTC: $([DateTimeOffset]::UtcNow.ToString('O'))"
        "Mode: $Mode"
        'No e-mail address, password, session token or user id is recorded.'
        ''
    ) + $Lines | Set-Content -LiteralPath $EvidencePath -Encoding utf8
}

$publicHeaders = @{ apikey = $PublishableKey }
$loginBody = @{ email = $normalizedEmail; password = $Password }
$login = Invoke-StagingJsonRequest `
    -Method Post `
    -Uri "$baseUrl/auth/v1/token?grant_type=password" `
    -Headers $publicHeaders `
    -Body $loginBody

if ($Mode -eq 'RequestConfirmation') {
    if (Test-SuccessStatus $login.StatusCode) {
        $accessToken = Get-PropertyValue -InputObject $login.Body -Name 'access_token'
        if ([string]::IsNullOrWhiteSpace([string]$accessToken)) {
            throw 'Staging Auth accepteerde de login zonder een sessietoken terug te geven.'
        }
        Write-SafeEvidence -Lines @(
            'Result: account was already confirmed; no e-mail was sent.'
            'Password login: passed.'
        )
        'Het staging-testaccount was al bevestigd; er is geen e-mail verstuurd.'
        exit 0
    }

    $loginFailure = Get-SafeFailure -Body $login.Body -StatusCode $login.StatusCode
    $loginFailureText = $loginFailure.ToLowerInvariant()
    if ($loginFailureText.Contains('email_not_confirmed') -or
        $loginFailureText.Contains('email not confirmed')) {
        $mailRequest = Invoke-StagingJsonRequest `
            -Method Post `
            -Uri "$baseUrl/auth/v1/resend" `
            -Headers $publicHeaders `
            -Body @{ type = 'signup'; email = $normalizedEmail }
        if (-not (Test-SuccessStatus $mailRequest.StatusCode)) {
            $failure = Get-SafeFailure -Body $mailRequest.Body -StatusCode $mailRequest.StatusCode
            throw "De bevestigingsmail kon niet opnieuw worden aangevraagd: $failure"
        }
        Write-SafeEvidence -Lines @(
            'Result: confirmation e-mail was requested for the existing account.'
            'Unconfirmed login rejection: passed.'
        )
        'Bevestigingsmail voor het bestaande staging-testaccount aangevraagd.'
        exit 0
    }

    $signup = Invoke-StagingJsonRequest `
        -Method Post `
        -Uri "$baseUrl/auth/v1/signup" `
        -Headers $publicHeaders `
        -Body @{
            email = $normalizedEmail
            password = $Password
            data = @{ display_name = 'Staging Keeper' }
        }
    if (-not (Test-SuccessStatus $signup.StatusCode)) {
        $failure = Get-SafeFailure -Body $signup.Body -StatusCode $signup.StatusCode
        throw "Het staging-testaccount kon niet worden aangemaakt: $failure"
    }

    $signupUser = Get-PropertyValue -InputObject $signup.Body -Name 'user'
    if ($null -eq $signupUser) { $signupUser = $signup.Body }
    $identities = Get-PropertyValue -InputObject $signupUser -Name 'identities'
    if ($null -ne $identities -and @($identities).Count -eq 0) {
        throw 'Dit staging-adres bestaat al met andere inloggegevens; het wachtwoord is niet gewijzigd.'
    }
    Write-SafeEvidence -Lines @(
        'Result: account created and confirmation e-mail requested.'
        'Unconfirmed password login was rejected before signup: passed.'
    )
    'Staging-testaccount aangemaakt; de bevestigingsmail is aangevraagd.'
    exit 0
}

if (-not (Test-SuccessStatus $login.StatusCode)) {
    $failure = Get-SafeFailure -Body $login.Body -StatusCode $login.StatusCode
    throw "Het bevestigde staging-testaccount kon niet inloggen: $failure"
}
$accessToken = [string](Get-PropertyValue -InputObject $login.Body -Name 'access_token')
$user = Get-PropertyValue -InputObject $login.Body -Name 'user'
$confirmedAt = Get-PropertyValue -InputObject $user -Name 'email_confirmed_at'
if ([string]::IsNullOrWhiteSpace($accessToken) -or
    [string]::IsNullOrWhiteSpace([string]$confirmedAt)) {
    throw 'De staging-login leverde geen bevestigde gebruikerssessie op.'
}

$authenticatedHeaders = @{
    apikey = $PublishableKey
    Authorization = "Bearer $accessToken"
}
function Invoke-StagingRpc {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Function,
        [hashtable]$Parameters = @{}
    )
    return Invoke-StagingJsonRequest `
        -Method Post `
        -Uri "$baseUrl/rest/v1/rpc/$Function" `
        -Headers $authenticatedHeaders `
        -Body $Parameters
}

$bootstrap = Invoke-StagingRpc -Function 'ensure_my_online_account'
if (-not (Test-SuccessStatus $bootstrap.StatusCode)) {
    $failure = Get-SafeFailure -Body $bootstrap.Body -StatusCode $bootstrap.StatusCode
    throw "Accountbootstrap mislukte: $failure"
}

$profile = Invoke-StagingRpc -Function 'get_my_profile'
$profileRows = @($profile.Body)
if (-not (Test-SuccessStatus $profile.StatusCode) -or $profileRows.Count -ne 1) {
    $failure = Get-SafeFailure -Body $profile.Body -StatusCode $profile.StatusCode
    throw "Het stagingprofiel kon niet eenduidig worden geladen: $failure"
}

$importReport = Invoke-StagingRpc -Function 'get_my_legacy_import_report'
$importReportRows = @($importReport.Body)
if (-not (Test-SuccessStatus $importReport.StatusCode)) {
    $failure = Get-SafeFailure -Body $importReport.Body -StatusCode $importReport.StatusCode
    throw "Het privacyveilige import-auditrapport kon niet worden geladen: $failure"
}
$inventoryImported = [bool](Get-PropertyValue -InputObject $profileRows[0] -Name 'inventory_imported')
$importAuditEvidence = 'Privacy-safe legacy import report: coherent empty state passed.'
if ($inventoryImported) {
    if ($importReportRows.Count -ne 1) {
        throw 'Een geïmporteerd stagingaccount heeft niet exact één import-auditrapport.'
    }
    $importVersion = [int](Get-PropertyValue -InputObject $importReportRows[0] -Name 'import_version')
    $sourceSchemaVersion = [int](Get-PropertyValue -InputObject $importReportRows[0] -Name 'source_schema_version')
    $importSummary = Get-PropertyValue -InputObject $importReportRows[0] -Name 'report'
    if ($importVersion -lt 0 -or $importVersion -gt 1 -or
        $sourceSchemaVersion -lt 0 -or $sourceSchemaVersion -gt 1000 -or
        $null -eq $importSummary) {
        throw 'Het import-auditrapport bevat geen geldige versie of samenvatting.'
    }
    $importAuditEvidence = "Privacy-safe legacy import report: version $importVersion passed."
} elseif ($importReportRows.Count -ne 0) {
    throw 'Een nog niet geïmporteerd stagingaccount heeft onverwacht een import-auditrapport.'
}

$before = Invoke-StagingRpc -Function 'get_cloud_game_save'
if (-not (Test-SuccessStatus $before.StatusCode)) {
    $failure = Get-SafeFailure -Body $before.Body -StatusCode $before.StatusCode
    throw "De bestaande stagingback-up kon niet worden gelezen: $failure"
}
$beforeRows = @($before.Body)
if ($beforeRows.Count -gt 1) {
    throw 'De stagingback-up leverde meer dan één huidige revisie op.'
}
$expectedRevision = 0L
$state = @{ schemaVersion = 1 }
if ($beforeRows.Count -eq 1) {
    $expectedRevision = [long](Get-PropertyValue -InputObject $beforeRows[0] -Name 'revision')
    $existingState = Get-PropertyValue -InputObject $beforeRows[0] -Name 'state'
    if ($null -ne $existingState) {
        $state = ConvertFrom-Json `
            -InputObject (ConvertTo-Json -InputObject $existingState -Depth 30 -Compress) `
            -AsHashtable
    }
}
$nonce = [Guid]::NewGuid().ToString('N')
$state['_stagingE2E'] = @{
    nonce = $nonce
    checkedAt = [DateTimeOffset]::UtcNow.ToString('O')
}

$pushed = Invoke-StagingRpc -Function 'push_cloud_game_save' -Parameters @{
    p_expected_revision = $expectedRevision
    p_state = $state
    p_device_id = 'github-staging-e2e'
}
$pushedRows = @($pushed.Body)
if (-not (Test-SuccessStatus $pushed.StatusCode) -or $pushedRows.Count -ne 1) {
    $failure = Get-SafeFailure -Body $pushed.Body -StatusCode $pushed.StatusCode
    throw "De stagingback-up kon niet worden opgeslagen: $failure"
}
$newRevision = [long](Get-PropertyValue -InputObject $pushedRows[0] -Name 'revision')
if ($newRevision -ne ($expectedRevision + 1)) {
    throw 'De stagingback-up kreeg niet de verwachte volgende revisie.'
}

$restored = Invoke-StagingRpc -Function 'get_cloud_game_save'
$restoredRows = @($restored.Body)
if (-not (Test-SuccessStatus $restored.StatusCode) -or $restoredRows.Count -ne 1) {
    $failure = Get-SafeFailure -Body $restored.Body -StatusCode $restored.StatusCode
    throw "De zojuist opgeslagen stagingback-up kon niet worden hersteld: $failure"
}
$restoredState = Get-PropertyValue -InputObject $restoredRows[0] -Name 'state'
$restoredMarker = Get-PropertyValue -InputObject $restoredState -Name '_stagingE2E'
$restoredNonce = Get-PropertyValue -InputObject $restoredMarker -Name 'nonce'
if ([string]$restoredNonce -ne $nonce) {
    throw 'De herstelde stagingback-up komt niet overeen met de opgeslagen revisie.'
}

$conflict = Invoke-StagingRpc -Function 'push_cloud_game_save' -Parameters @{
    p_expected_revision = $expectedRevision
    p_state = $state
    p_device_id = 'github-staging-e2e-stale'
}
$conflictFailure = Get-SafeFailure -Body $conflict.Body -StatusCode $conflict.StatusCode
if ((Test-SuccessStatus $conflict.StatusCode) -or
    -not $conflictFailure.ToLowerInvariant().Contains('cloud_save_conflict')) {
    throw 'Een verouderde stagingback-up werd niet met cloud_save_conflict geweigerd.'
}

$logout = Invoke-StagingJsonRequest `
    -Method Post `
    -Uri "$baseUrl/auth/v1/logout" `
    -Headers $authenticatedHeaders `
    -Body $null
if (-not (Test-SuccessStatus $logout.StatusCode)) {
    $failure = Get-SafeFailure -Body $logout.Body -StatusCode $logout.StatusCode
    throw "De tijdelijke stagingsessie kon niet netjes worden ingetrokken: $failure"
}

Write-SafeEvidence -Lines @(
    'Result: confirmed account flow passed.'
    'Password login and confirmed-email check: passed.'
    'Idempotent account bootstrap: passed.'
    'Profile read: passed.'
    $importAuditEvidence
    "Cloud backup roundtrip: revision $expectedRevision -> $newRevision passed."
    'Stale cloud backup conflict protection: passed.'
    'Session logout: passed.'
)
'Bevestigde staging-accountflow, back-uprondgang en conflictbeveiliging zijn geslaagd.'
