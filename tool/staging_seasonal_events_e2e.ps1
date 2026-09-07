#requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$SupabaseUrl,
    [Parameter(Mandatory = $true)][string]$PublishableKey,
    [Parameter(Mandatory = $true)][string]$Email,
    [Parameter(Mandatory = $true)][string]$Password,
    [Parameter(Mandatory = $true)][string]$ProjectRef,
    [Parameter(Mandatory = $true)][string]$ManagementAccessToken,
    [string]$EvidencePath = 'staging/seasonal-events-e2e.txt'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$productionProjectRef = 'tnzathhutuwmohmjfrlo'
$baseUrl = $SupabaseUrl.Trim().TrimEnd('/')
$normalizedEmail = $Email.Trim().ToLowerInvariant()

if ($ProjectRef -notmatch '^[a-z0-9]{20}$' -or
    $ProjectRef -eq $productionProjectRef -or
    $baseUrl -ne "https://$ProjectRef.supabase.co") {
    throw 'The seasonal E2E test accepts only the configured non-production staging project.'
}
if (-not $PublishableKey.StartsWith('sb_publishable_') -or
    [string]::IsNullOrWhiteSpace($ManagementAccessToken)) {
    throw 'The protected staging configuration is invalid.'
}
if ($EvidencePath -notmatch '^staging[\\/][a-zA-Z0-9._-]+$') {
    throw 'The evidence file must remain directly inside staging.'
}

function Get-Value {
    param([AllowNull()][object]$Object, [Parameter(Mandatory = $true)][string]$Name)
    if ($null -eq $Object) { return $null }
    if ($Object -is [System.Collections.IDictionary]) { return $Object[$Name] }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Test-Success([int]$StatusCode) {
    return $StatusCode -ge 200 -and $StatusCode -lt 300
}

function Invoke-JsonRequest {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][hashtable]$Headers,
        [AllowNull()][object]$Body
    )
    $statusCode = 0
    $parameters = @{
        Method = 'Post'
        Uri = $Uri
        Headers = $Headers
        SkipHttpErrorCheck = $true
        StatusCodeVariable = 'statusCode'
        ErrorAction = 'Stop'
    }
    if ($null -ne $Body) {
        $parameters.ContentType = 'application/json'
        $parameters.Body = ConvertTo-Json $Body -Depth 12 -Compress
    }
    $bodyValue = Invoke-RestMethod @parameters
    return [pscustomobject]@{ StatusCode = [int]$statusCode; Body = $bodyValue }
}

function Assert-Success {
    param([Parameter(Mandatory = $true)][object]$Response,
        [Parameter(Mandatory = $true)][string]$Operation)
    if (-not (Test-Success $Response.StatusCode)) {
        throw "$Operation failed with HTTP $($Response.StatusCode)."
    }
}

function Invoke-ManagementQuery {
    param(
        [Parameter(Mandatory = $true)][string]$Query,
        [Parameter(Mandatory = $true)][string]$Operation,
        [bool]$ReadOnly = $true
    )
    if ($ProjectRef -eq $productionProjectRef) {
        throw 'A staging-only database query was pointed at production.'
    }
    $managementStatus = 0
    $body = Invoke-RestMethod `
        -Method Post `
        -Uri "https://api.supabase.com/v1/projects/$ProjectRef/database/query" `
        -Headers @{ Authorization = "Bearer $ManagementAccessToken"; Accept = 'application/json' } `
        -ContentType 'application/json' `
        -Body (ConvertTo-Json @{ query = $Query; read_only = $ReadOnly } -Compress) `
        -SkipHttpErrorCheck `
        -StatusCodeVariable managementStatus `
        -ErrorAction Stop
    if (-not (Test-Success $managementStatus)) {
        throw "$Operation failed with HTTP $managementStatus."
    }
    foreach ($name in @('result', 'data')) {
        $rows = Get-Value $body $name
        if ($null -ne $rows) { return @($rows) }
    }
    return @($body)
}

function Assert-True {
    param([AllowNull()][object]$Value, [Parameter(Mandatory = $true)][string]$Name)
    if ($Value -is [bool] -and $Value) { return }
    if ([string]$Value -eq 'true') { return }
    throw "Seasonal validation failed on $Name."
}

$schemaRows = @(Invoke-ManagementQuery -Operation 'Seasonal schema verification' -Query @'
with seasonal_tables(table_name) as (
  values ('seasonal_event_previews'), ('seasonal_trial_attempts'),
    ('seasonal_trial_bests'), ('seasonal_event_prizes'),
    ('seasonal_pair_adventures'), ('seasonal_pair_occurrences')
)
select
  exists (select 1 from supabase_migrations.schema_migrations
    where version = '202609070040') as migration_40_applied,
  (select count(*) = 6 from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    join seasonal_tables s on s.table_name = c.relname
    where n.nspname = 'public' and c.relkind = 'r' and c.relrowsecurity)
    as all_tables_have_rls,
  not exists (select 1 from seasonal_tables s where
    has_table_privilege('anon', format('public.%I', s.table_name), 'select') or
    has_table_privilege('anon', format('public.%I', s.table_name), 'insert') or
    has_table_privilege('authenticated', format('public.%I', s.table_name), 'select') or
    has_table_privilege('authenticated', format('public.%I', s.table_name), 'insert') or
    has_table_privilege('authenticated', format('public.%I', s.table_name), 'update') or
    has_table_privilege('authenticated', format('public.%I', s.table_name), 'delete'))
    as direct_table_access_absent,
  not has_function_privilege('anon',
    'public.list_my_seasonal_event_previews()', 'execute') and
  has_function_privilege('authenticated',
    'public.list_my_seasonal_event_previews()', 'execute') and
  not has_function_privilege('anon',
    'public.get_seasonal_trial_rankings(text,text,boolean,integer)', 'execute') and
  has_function_privilege('authenticated',
    'public.get_seasonal_trial_rankings(text,text,boolean,integer)', 'execute') and
  not has_function_privilege('anon',
    'public.list_my_seasonal_pair_adventures()', 'execute') and
  has_function_privilege('authenticated',
    'public.list_my_seasonal_pair_adventures()', 'execute') and
  not has_function_privilege('anon',
    'public.get_seasonal_community_progress(text)', 'execute') and
  has_function_privilege('authenticated',
    'public.get_seasonal_community_progress(text)', 'execute')
    as rpc_grants_are_scoped,
  not has_function_privilege('public',
    'public.seasonal_event_window(text,timestamp with time zone)', 'execute') and
  not has_function_privilege('anon',
    'public.seasonal_event_window(text,timestamp with time zone)', 'execute') and
  not has_function_privilege('authenticated',
    'public.seasonal_event_window(text,timestamp with time zone)', 'execute')
    as internal_window_is_private,
  exists (select 1 from pg_constraint c where c.conname =
    'social_notifications_kind_check' and
    pg_get_constraintdef(c.oid) like '%seasonal_pair_invite%' and
    pg_get_constraintdef(c.oid) like '%seasonal_pair_ready%')
    as notification_contract_extended;
'@)
if ($schemaRows.Count -ne 1) { throw 'Seasonal schema verification was ambiguous.' }
foreach ($flag in @(
    'migration_40_applied', 'all_tables_have_rls', 'direct_table_access_absent',
    'rpc_grants_are_scoped', 'internal_window_is_private',
    'notification_contract_extended')) {
    Assert-True (Get-Value $schemaRows[0] $flag) $flag
}

$anonymous = Invoke-JsonRequest `
    -Uri "$baseUrl/rest/v1/rpc/list_my_seasonal_event_previews" `
    -Headers @{ apikey = $PublishableKey } -Body @{}
if (Test-Success $anonymous.StatusCode) {
    throw 'Anonymous seasonal RPC access was unexpectedly accepted.'
}

$login = Invoke-JsonRequest `
    -Uri "$baseUrl/auth/v1/token?grant_type=password" `
    -Headers @{ apikey = $PublishableKey } `
    -Body @{ email = $normalizedEmail; password = $Password }
Assert-Success $login 'Staging login'
$accessToken = [string](Get-Value $login.Body 'access_token')
$user = Get-Value $login.Body 'user'
$userId = [string](Get-Value $user 'id')
$parsedUserId = [Guid]::Empty
if ([string]::IsNullOrWhiteSpace($accessToken) -or
    -not [Guid]::TryParse($userId, [ref]$parsedUserId)) {
    throw 'The staging login did not return a valid session.'
}
$authHeaders = @{ apikey = $PublishableKey; Authorization = "Bearer $accessToken" }

$previewList = Invoke-JsonRequest `
    -Uri "$baseUrl/rest/v1/rpc/list_my_seasonal_event_previews" `
    -Headers $authHeaders -Body @{}
Assert-Success $previewList 'Authenticated preview lookup'

$pairList = Invoke-JsonRequest `
    -Uri "$baseUrl/rest/v1/rpc/list_my_seasonal_pair_adventures" `
    -Headers $authHeaders -Body @{}
Assert-Success $pairList 'Authenticated Valentine lookup'

$community = Invoke-JsonRequest `
    -Uri "$baseUrl/rest/v1/rpc/get_seasonal_community_progress" `
    -Headers $authHeaders -Body @{ p_event_id = 'pride_every_color' }
Assert-Success $community 'Authenticated Pride community lookup'

$invalidTrial = Invoke-JsonRequest `
    -Uri "$baseUrl/rest/v1/rpc/start_seasonal_trial_attempt" `
    -Headers $authHeaders `
    -Body @{ p_event_id = 'halloween_witchlight'; p_trial_key = 'invalid' }
if (Test-Success $invalidTrial.StatusCode) {
    throw 'An invalid seasonal Trial key was accepted.'
}

$profileRows = @(Invoke-ManagementQuery -Operation 'Read staging Keeper code' -Query "select keeper_code from public.profiles where user_id = '$userId'::uuid;")
if ($profileRows.Count -ne 1) { throw 'The staging Keeper profile is missing.' }
$originalKeeperCode = [string](Get-Value $profileRows[0] 'keeper_code')
if ($originalKeeperCode -notmatch '^[A-Za-z0-9-]+$') {
    throw 'The staging Keeper code cannot be restored safely.'
}

$attemptId = $null
$occurrenceKey = $null
$keeperTemporarilyChanged = $false
try {
    $conflicts = @(Invoke-ManagementQuery -Operation 'Check preview Keeper-code isolation' -Query "select count(*)::integer as count from public.profiles where keeper_code = 'DH-17792DC5' and user_id <> '$userId'::uuid;")
    if ([int](Get-Value $conflicts[0] 'count') -ne 0) {
        throw 'The staging preview Keeper code is already assigned to another account.'
    }
    Invoke-ManagementQuery -ReadOnly $false -Operation 'Temporarily authorize staging preview' -Query "update public.profiles set keeper_code = 'DH-17792DC5' where user_id = '$userId'::uuid;" | Out-Null
    $keeperTemporarilyChanged = $true

    $preview = Invoke-JsonRequest `
        -Uri "$baseUrl/rest/v1/rpc/redeem_seasonal_event_preview" `
        -Headers $authHeaders -Body @{ p_code = 'HALLOWEENEVENT' }
    Assert-Success $preview 'Seasonal preview activation'

    $start = Invoke-JsonRequest `
        -Uri "$baseUrl/rest/v1/rpc/start_seasonal_trial_attempt" `
        -Headers $authHeaders `
        -Body @{ p_event_id = 'halloween_witchlight'; p_trial_key = 'witchlightWard' }
    Assert-Success $start 'Simulated seasonal Trial start'
    $startRows = @($start.Body)
    if ($startRows.Count -ne 1) { throw 'Seasonal Trial start was ambiguous.' }
    $attemptId = [string](Get-Value $startRows[0] 'attempt_id')
    $completionToken = [string](Get-Value $startRows[0] 'completion_token')
    $occurrenceKey = [string](Get-Value $startRows[0] 'occurrence_key')
    $parsedAttemptId = [Guid]::Empty
    $parsedToken = [Guid]::Empty
    if (-not [Guid]::TryParse($attemptId, [ref]$parsedAttemptId) -or
        -not [Guid]::TryParse($completionToken, [ref]$parsedToken) -or
        -not $occurrenceKey.StartsWith('preview:halloween_witchlight:') -or
        -not [bool](Get-Value $startRows[0] 'simulated')) {
        throw 'Seasonal preview attempt did not use its isolated simulated contract.'
    }

    Invoke-ManagementQuery -ReadOnly $false -Operation 'Backdate staging Trial clock' -Query "update public.seasonal_trial_attempts set started_at = now() - interval '45 seconds' where id = '$attemptId'::uuid and user_id = '$userId'::uuid;" | Out-Null
    $complete = Invoke-JsonRequest `
        -Uri "$baseUrl/rest/v1/rpc/complete_seasonal_trial_attempt" `
        -Headers $authHeaders -Body @{
            p_attempt_id = $attemptId
            p_completion_token = $completionToken
            p_score = 100
            p_correct_actions = 1
            p_total_actions = 1
            p_duration_ms = 30000
        }
    Assert-Success $complete 'Simulated seasonal Trial completion'
    $completeRows = @($complete.Body)
    if ($completeRows.Count -ne 1 -or
        -not [bool](Get-Value $completeRows[0] 'accepted') -or
        -not [bool](Get-Value $completeRows[0] 'simulated')) {
        throw 'The simulated seasonal score was not accepted as simulated.'
    }

    $rankings = Invoke-JsonRequest `
        -Uri "$baseUrl/rest/v1/rpc/get_seasonal_trial_rankings" `
        -Headers $authHeaders -Body @{
            p_event_id = 'halloween_witchlight'
            p_occurrence_key = $occurrenceKey
            p_preview = $true
            p_limit = 100
        }
    Assert-Success $rankings 'Preview ranking lookup'
    if (@($rankings.Body).Count -lt 1) {
        throw 'The accepted preview score was absent from its isolated ranking.'
    }
}
finally {
    try {
        $attemptCleanup = if ($null -ne $attemptId -and
            $attemptId -match '^[0-9a-fA-F-]{36}$') {
            "delete from public.seasonal_trial_attempts where id = '$attemptId'::uuid;"
        } else { '' }
        Invoke-ManagementQuery -ReadOnly $false `
            -Operation 'Clean seasonal staging attempt' `
            -Query "delete from public.seasonal_event_prizes where user_id = '$userId'::uuid and event_id = 'halloween_witchlight'; delete from public.seasonal_trial_bests where user_id = '$userId'::uuid and occurrence_key = 'preview:halloween_witchlight:$userId'; $attemptCleanup delete from public.seasonal_event_previews where user_id = '$userId'::uuid and event_id = 'halloween_witchlight';" |
            Out-Null
    }
    finally {
        if ($keeperTemporarilyChanged) {
            Invoke-ManagementQuery -ReadOnly $false `
                -Operation 'Restore staging Keeper code' `
                -Query "update public.profiles set keeper_code = '$originalKeeperCode' where user_id = '$userId'::uuid;" |
                Out-Null
        }
    }
}

$evidenceDirectory = Split-Path -Parent $EvidencePath
New-Item -ItemType Directory -Path $evidenceDirectory -Force | Out-Null
@(
    'DragonHaven seasonal events staging E2E'
    "Checked at UTC: $([DateTime]::UtcNow.ToString('o'))"
    'Project class: isolated non-production staging'
    'Migration 40, RLS, table revokes and RPC grants: passed'
    'Anonymous denial and authenticated seasonal reads: passed'
    'Invalid Trial rejection: passed'
    'Simulated preview start, completion and ranking: passed'
    'Temporary Keeper authorization and test rows: restored/removed'
    'No credential values or player content are included in this evidence.'
) | Set-Content -LiteralPath $EvidencePath -Encoding utf8

'Seasonal events staging E2E passed.'
