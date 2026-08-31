#requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SupabaseUrl,

    [Parameter(Mandatory = $true)]
    [string]$PublishableKey,

    [Parameter(Mandatory = $true)]
    [string]$Email,

    [Parameter(Mandatory = $true)]
    [string]$Password,

    [Parameter(Mandatory = $true)]
    [string]$ProjectRef,

    [Parameter(Mandatory = $true)]
    [string]$ManagementAccessToken,

    [string]$EvidencePath = 'staging/support-privacy-e2e.txt'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$productionProjectRef = 'tnzathhutuwmohmjfrlo'
$baseUrl = $SupabaseUrl.Trim().TrimEnd('/')
$normalizedEmail = $Email.Trim().ToLowerInvariant()

if ($baseUrl -notmatch '^https://[a-z0-9]+\.supabase\.co$') {
    throw 'De supportprivacytest accepteert uitsluitend een gehost HTTPS-Supabaseproject.'
}
if ($ProjectRef -notmatch '^[a-z0-9]{20}$') {
    throw 'De supportprivacytest vereist een geldige staging-projectreference.'
}
if ($ProjectRef -eq $productionProjectRef -or
    $baseUrl -eq "https://$productionProjectRef.supabase.co") {
    throw 'De supportprivacytest mag nooit het productieproject gebruiken.'
}
if ($baseUrl -ne "https://$ProjectRef.supabase.co") {
    throw 'De staging-URL hoort niet bij de staging-projectreference.'
}
if (-not $PublishableKey.StartsWith('sb_publishable_')) {
    throw 'De supportprivacytest vereist een publishable clientkey.'
}
if ([string]::IsNullOrWhiteSpace($ManagementAccessToken)) {
    throw 'De supportprivacytest vereist het afgeschermde staging-beheertoken.'
}
try {
    $parsedEmail = [System.Net.Mail.MailAddress]::new($normalizedEmail)
} catch {
    throw 'Het afgeschermde staging-testadres is ongeldig.'
}
if ($parsedEmail.Address -ne $normalizedEmail -or $Password.Length -lt 12) {
    throw 'De afgeschermde staging-testaccountconfiguratie is ongeldig.'
}
if ($EvidencePath -notmatch '^staging[\\/][a-zA-Z0-9._-]+$') {
    throw 'Het bewijsbestand moet rechtstreeks in de stagingmap staan.'
}
if (-not (Test-Path -LiteralPath 'supabase/migrations/202608310033_support_privacy_operations.sql')) {
    throw 'De repository bevat migratie 33 niet.'
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

function ConvertTo-StrictBoolean {
    param(
        [AllowNull()]
        [object]$Value,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($Value -is [bool]) { return $Value }
    $parsed = $false
    if ([bool]::TryParse([string]$Value, [ref]$parsed)) { return $parsed }
    throw "De stagingquery retourneerde geen boolean voor $Name."
}

function Test-SuccessStatus {
    param([int]$StatusCode)
    return $StatusCode -ge 200 -and $StatusCode -lt 300
}

function Get-SafeFailure {
    param(
        [AllowNull()]
        [object]$Body,
        [Parameter(Mandatory = $true)]
        [int]$StatusCode
    )

    foreach ($name in @('error_code', 'code', 'message', 'msg', 'error_description')) {
        $value = [string](Get-PropertyValue -InputObject $Body -Name $name)
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $safe = $value.Replace($normalizedEmail, '[redacted-email]')
            if ($safe.Length -gt 160) { $safe = $safe.Substring(0, 160) }
            return "HTTP $StatusCode ($safe)"
        }
    }
    return "HTTP $StatusCode"
}

function Invoke-StagingJsonRequest {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Post')]
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
        $request.Body = ConvertTo-Json -InputObject $Body -Depth 20 -Compress
    }
    $response = Invoke-RestMethod @request
    return [pscustomobject]@{
        StatusCode = [int]$requestStatusCode
        Body = $response
    }
}

function Assert-Success {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Response,
        [Parameter(Mandatory = $true)]
        [string]$Operation
    )

    if (-not (Test-SuccessStatus $Response.StatusCode)) {
        $failure = Get-SafeFailure -Body $Response.Body -StatusCode $Response.StatusCode
        throw "$Operation mislukte: $failure"
    }
}

function Get-ManagementRows {
    param([AllowNull()][object]$Body)

    if ($null -eq $Body) { return @() }
    foreach ($name in @('result', 'data')) {
        $value = Get-PropertyValue -InputObject $Body -Name $name
        if ($null -ne $value) { return @($value) }
    }
    return @($Body)
}

function Invoke-StagingManagementQuery {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Query,
        [Parameter(Mandatory = $true)]
        [string]$Operation,
        [bool]$ReadOnly = $false
    )

    if ($ProjectRef -eq $productionProjectRef -or
        $baseUrl -eq "https://$productionProjectRef.supabase.co") {
        throw 'De staging-only databasequery is niet veilig geactiveerd.'
    }
    $managementStatusCode = 0
    $body = Invoke-RestMethod `
        -Method Post `
        -Uri "https://api.supabase.com/v1/projects/$ProjectRef/database/query" `
        -Headers @{
            Authorization = "Bearer $ManagementAccessToken"
            Accept = 'application/json'
        } `
        -ContentType 'application/json' `
        -Body (ConvertTo-Json -InputObject @{
            query = $Query
            read_only = $ReadOnly
        } -Compress) `
        -SkipHttpErrorCheck `
        -StatusCodeVariable managementStatusCode `
        -ErrorAction Stop
    if (-not (Test-SuccessStatus $managementStatusCode)) {
        throw "$Operation mislukte met HTTP $managementStatusCode."
    }
    return @(Get-ManagementRows -Body $body)
}

function Assert-SingleRow {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Rows,
        [Parameter(Mandatory = $true)]
        [string]$Operation
    )

    if ($Rows.Count -ne 1) {
        throw "$Operation retourneerde niet exact één resultaat."
    }
    return $Rows[0]
}

$login = Invoke-StagingJsonRequest `
    -Method Post `
    -Uri "$baseUrl/auth/v1/token?grant_type=password" `
    -Headers @{ apikey = $PublishableKey } `
    -Body @{ email = $normalizedEmail; password = $Password }
Assert-Success -Response $login -Operation 'Staging-login'
$accessToken = [string](Get-PropertyValue -InputObject $login.Body -Name 'access_token')
$user = Get-PropertyValue -InputObject $login.Body -Name 'user'
$rawUserId = [string](Get-PropertyValue -InputObject $user -Name 'id')
$confirmedAt = Get-PropertyValue -InputObject $user -Name 'email_confirmed_at'
$parsedUserId = [Guid]::Empty
if ([string]::IsNullOrWhiteSpace($accessToken) -or
    -not [Guid]::TryParse($rawUserId, [ref]$parsedUserId) -or
    [string]::IsNullOrWhiteSpace([string]$confirmedAt)) {
    throw 'De staging-login leverde geen bevestigde sessie op.'
}
$safeUserId = $parsedUserId.ToString()

$profile = Invoke-StagingJsonRequest `
    -Method Post `
    -Uri "$baseUrl/rest/v1/rpc/get_my_profile" `
    -Headers @{
        apikey = $PublishableKey
        Authorization = "Bearer $accessToken"
    } `
    -Body @{}
Assert-Success -Response $profile -Operation 'Stagingprofiel ophalen'
$profileRows = @($profile.Body)
if ($profileRows.Count -ne 1) {
    throw 'Het stagingprofiel kon niet eenduidig worden geladen.'
}
$keeperCode = [string](Get-PropertyValue -InputObject $profileRows[0] -Name 'keeper_code')
$profileUserId = [string](Get-PropertyValue -InputObject $profileRows[0] -Name 'user_id')
if ($keeperCode -notmatch '^DH-[A-F0-9]{8}$' -or $profileUserId -ne $safeUserId) {
    throw 'Het stagingprofiel heeft geen consistente Keeper ID.'
}

$suffix = ([Guid]::NewGuid().ToString('N').Substring(0, 12)).ToUpperInvariant()
$caseReference = "DH-SUP-STAGE-$suffix"
$cleanupCaseReference = "DH-SUP-CLEAN-$suffix"
$operatorRef = 'staging.audit'

$denied = Invoke-StagingJsonRequest `
    -Method Post `
    -Uri "$baseUrl/rest/v1/rpc/support_lookup_keeper" `
    -Headers @{
        apikey = $PublishableKey
        Authorization = "Bearer $accessToken"
    } `
    -Body @{
        p_keeper_code = $keeperCode
        p_case_reference = $caseReference
        p_reason_code = 'incident_review'
        p_operator_ref = $operatorRef
    }
if (Test-SuccessStatus $denied.StatusCode) {
    throw 'Een normale ingelogde gebruiker kon de supportlookup uitvoeren.'
}
$authenticatedAccessDenied = $true

$migrationRow = Assert-SingleRow `
    -Rows (Invoke-StagingManagementQuery `
        -ReadOnly $true `
        -Operation 'Migratie-33-controle' `
        -Query @"
select exists (
  select 1
  from supabase_migrations.schema_migrations
  where version = '202608310033'
) as migration_33_applied;
"@) `
    -Operation 'Migratie-33-controle'
if (-not (ConvertTo-StrictBoolean `
        -Value (Get-PropertyValue -InputObject $migrationRow -Name 'migration_33_applied') `
        -Name 'migration_33_applied')) {
    throw 'Migratie 33 is niet op het stagingproject toegepast.'
}

$lookupRow = Assert-SingleRow `
    -Rows (Invoke-StagingManagementQuery `
        -Operation 'Service-role supportlookup' `
        -Query @"
with role_context as materialized (
  select set_config('request.jwt.claim.role', 'service_role', true)
), lookup as materialized (
  select public.support_lookup_keeper(
    '$keeperCode',
    '$caseReference',
    'incident_review',
    '$operatorRef'
  ) as result
  from role_context
)
select
  result ->> 'access_id' as access_id,
  (result ->> 'found')::boolean as found,
  result ->> 'case_reference' = '$caseReference' as case_matches,
  result ->> 'user_id' = '$safeUserId' as user_matches,
  result ->> 'correlation_ids_available' = 'false' as correlation_ids_absent,
  not (result ?| array['email', 'phone', 'display_name', 'keeper_code', 'inventory', 'state'])
    as top_level_private_fields_absent,
  not (coalesce(result -> 'account', '{}'::jsonb) ?| array['email', 'phone'])
    as account_private_fields_absent,
  not (coalesce(result -> 'cloud_save', '{}'::jsonb) ?| array['state', 'save', 'inventory'])
    as save_body_absent
from lookup;
"@) `
    -Operation 'Service-role supportlookup'

$accessId = [string](Get-PropertyValue -InputObject $lookupRow -Name 'access_id')
$parsedAccessId = [Guid]::Empty
if (-not [Guid]::TryParse($accessId, [ref]$parsedAccessId)) {
    throw 'De supportlookup leverde geen geldige audit-id op.'
}
foreach ($flag in @(
    'found',
    'case_matches',
    'user_matches',
    'correlation_ids_absent',
    'top_level_private_fields_absent',
    'account_private_fields_absent',
    'save_body_absent'
)) {
    if (-not (ConvertTo-StrictBoolean `
            -Value (Get-PropertyValue -InputObject $lookupRow -Name $flag) `
            -Name $flag)) {
        throw "De minimale supportresponse faalde op $flag."
    }
}
$privacySafeResponseVerified = $true
$safeAccessId = $parsedAccessId.ToString()

$logRow = Assert-SingleRow `
    -Rows (Invoke-StagingManagementQuery `
        -ReadOnly $true `
        -Operation 'Supportinzagelog controleren' `
        -Query @"
select
  count(*) = 1 as exactly_one,
  bool_and(target_user_id = '$safeUserId'::uuid) as target_matches,
  bool_and(length(keeper_code_sha256) = 64) as keeper_hash_only,
  bool_and(operator_ref = '$operatorRef') as operator_matches,
  bool_and(case_reference = '$caseReference') as case_matches,
  bool_and(reason_code = 'incident_review') as reason_matches,
  bool_and(result_found) as result_found,
  bool_and(expires_at between accessed_at + interval '29 days 23 hours'
    and accessed_at + interval '30 days 1 hour') as retention_matches
from private.support_access_log
where id = '$safeAccessId'::uuid;
"@) `
    -Operation 'Supportinzagelog controleren'
foreach ($flag in @(
    'exactly_one',
    'target_matches',
    'keeper_hash_only',
    'operator_matches',
    'case_matches',
    'reason_matches',
    'result_found',
    'retention_matches'
)) {
    if (-not (ConvertTo-StrictBoolean `
            -Value (Get-PropertyValue -InputObject $logRow -Name $flag) `
            -Name $flag)) {
        throw "Het supportinzagelog faalde op $flag."
    }
}
$accessLogVerified = $true

$sentinelRow = Assert-SingleRow `
    -Rows (Invoke-StagingManagementQuery `
        -Operation 'Verlopen staging-sentinel aanmaken' `
        -Query @"
insert into private.support_access_log(
  target_user_id,
  keeper_code_sha256,
  operator_ref,
  case_reference,
  reason_code,
  result_found,
  accessed_at,
  expires_at
) values (
  null,
  repeat('0', 64),
  '$operatorRef',
  '$cleanupCaseReference',
  'incident_review',
  false,
  now() - interval '31 days',
  now() - interval '1 second'
)
returning id::text as sentinel_id;
"@) `
    -Operation 'Verlopen staging-sentinel aanmaken'
$sentinelId = [string](Get-PropertyValue -InputObject $sentinelRow -Name 'sentinel_id')
$parsedSentinelId = [Guid]::Empty
if (-not [Guid]::TryParse($sentinelId, [ref]$parsedSentinelId)) {
    throw 'De cleanup-sentinel leverde geen geldige audit-id op.'
}
$safeSentinelId = $parsedSentinelId.ToString()

$purgeRow = Assert-SingleRow `
    -Rows (Invoke-StagingManagementQuery `
        -Operation 'Supportprivacycleanup uitvoeren' `
        -Query "select private.purge_expired_support_privacy_records() as result;") `
    -Operation 'Supportprivacycleanup uitvoeren'
$purgeResult = Get-PropertyValue -InputObject $purgeRow -Name 'result'
$removedSupportLogs = [int](Get-PropertyValue -InputObject $purgeResult -Name 'support_access_logs')
if ($removedSupportLogs -lt 1) {
    throw 'De supportprivacycleanup rapporteerde geen verwijderde staging-sentinel.'
}
$sentinelCheck = Assert-SingleRow `
    -Rows (Invoke-StagingManagementQuery `
        -ReadOnly $true `
        -Operation 'Supportprivacycleanup verifiëren' `
        -Query @"
select not exists (
  select 1 from private.support_access_log
  where id = '$safeSentinelId'::uuid
) as sentinel_removed;
"@) `
    -Operation 'Supportprivacycleanup verifiëren'
if (-not (ConvertTo-StrictBoolean `
        -Value (Get-PropertyValue -InputObject $sentinelCheck -Name 'sentinel_removed') `
        -Name 'sentinel_removed')) {
    throw 'De verlopen staging-sentinel is niet fysiek verwijderd.'
}
$cleanupVerified = $true

$evidenceDirectory = Split-Path -Parent $EvidencePath
New-Item -ItemType Directory -Path $evidenceDirectory -Force | Out-Null
@(
    'DragonHaven staging support privacy E2E'
    "generated_at_utc=$([DateTime]::UtcNow.ToString('o'))"
    'environment=staging'
    'production_targeted=false'
    'repository_migration_33_present=true'
    'remote_migration_33_applied=true'
    "authenticated_access_denied=$($authenticatedAccessDenied.ToString().ToLowerInvariant())"
    "privacy_safe_response_verified=$($privacySafeResponseVerified.ToString().ToLowerInvariant())"
    "access_log_verified=$($accessLogVerified.ToString().ToLowerInvariant())"
    'access_log_retention_days=30'
    "expired_cleanup_verified=$($cleanupVerified.ToString().ToLowerInvariant())"
    'raw_identifiers_recorded=false'
    'credentials_recorded=false'
) | Set-Content -LiteralPath $EvidencePath -Encoding utf8

$accessToken = $null
$ManagementAccessToken = $null
$Password = $null
$keeperCode = $null
$safeUserId = $null

Write-Host 'Privacyarme testsupportflow op geïsoleerde staging is geslaagd.'
