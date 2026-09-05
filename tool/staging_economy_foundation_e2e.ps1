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

    [string]$EvidencePath = 'staging/economy-foundation-e2e.txt'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$productionProjectRef = 'tnzathhutuwmohmjfrlo'
$baseUrl = $SupabaseUrl.Trim().TrimEnd('/')
$normalizedEmail = $Email.Trim().ToLowerInvariant()

if ($baseUrl -notmatch '^https://[a-z0-9]+\.supabase\.co$') {
    throw 'The economy foundation test accepts only a hosted HTTPS Supabase project.'
}
if ($ProjectRef -notmatch '^[a-z0-9]{20}$') {
    throw 'The economy foundation test requires a valid staging project reference.'
}
if ($ProjectRef -eq $productionProjectRef -or
    $baseUrl -eq "https://$productionProjectRef.supabase.co") {
    throw 'The economy foundation test must never target production.'
}
if ($baseUrl -ne "https://$ProjectRef.supabase.co") {
    throw 'The staging URL and project reference do not match.'
}
if (-not $PublishableKey.StartsWith('sb_publishable_')) {
    throw 'The economy foundation test requires a publishable client key.'
}
if ([string]::IsNullOrWhiteSpace($ManagementAccessToken)) {
    throw 'The economy foundation test requires the protected management token.'
}
try {
    $parsedEmail = [System.Net.Mail.MailAddress]::new($normalizedEmail)
} catch {
    throw 'The protected staging test address is invalid.'
}
if ($parsedEmail.Address -ne $normalizedEmail -or $Password.Length -lt 12) {
    throw 'The protected staging test account configuration is invalid.'
}
if ($EvidencePath -notmatch '^staging[\\/][a-zA-Z0-9._-]+$') {
    throw 'The evidence file must be directly inside the staging directory.'
}
if (-not (Test-Path -LiteralPath 'supabase/migrations/202609050037_economy_authority_foundation.sql')) {
    throw 'Repository migration 37 is missing.'
}

function Get-PropertyValue {
    param(
        [AllowNull()][object]$InputObject,
        [Parameter(Mandatory = $true)][string]$Name
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
        [AllowNull()][object]$Value,
        [Parameter(Mandatory = $true)][string]$Name
    )
    if ($Value -is [bool]) { return $Value }
    $parsed = $false
    if ([bool]::TryParse([string]$Value, [ref]$parsed)) { return $parsed }
    throw "The staging query did not return a boolean for $Name."
}

function Test-SuccessStatus {
    param([int]$StatusCode)
    return $StatusCode -ge 200 -and $StatusCode -lt 300
}

function Invoke-StagingJsonRequest {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][hashtable]$Headers,
        [AllowNull()][object]$Body
    )
    $request = @{
        Method = 'Post'
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
        [Parameter(Mandatory = $true)][object]$Response,
        [Parameter(Mandatory = $true)][string]$Operation
    )
    if (-not (Test-SuccessStatus $Response.StatusCode)) {
        throw "$Operation failed with HTTP $($Response.StatusCode)."
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
        [Parameter(Mandatory = $true)][string]$Query,
        [Parameter(Mandatory = $true)][string]$Operation,
        [bool]$ReadOnly = $true
    )
    if ($ProjectRef -eq $productionProjectRef -or
        $baseUrl -eq "https://$productionProjectRef.supabase.co") {
        throw 'The staging-only database query is not safely activated.'
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
        throw "$Operation failed with HTTP $managementStatusCode."
    }
    return @(Get-ManagementRows -Body $body)
}

function Assert-SingleRow {
    param(
        [Parameter(Mandatory = $true)][object[]]$Rows,
        [Parameter(Mandatory = $true)][string]$Operation
    )
    if ($Rows.Count -ne 1) {
        throw "$Operation did not return exactly one result."
    }
    return $Rows[0]
}

$anonymousContract = Invoke-StagingJsonRequest `
    -Uri "$baseUrl/rest/v1/rpc/get_my_economy_contract" `
    -Headers @{ apikey = $PublishableKey } `
    -Body @{}
if (Test-SuccessStatus $anonymousContract.StatusCode) {
    throw 'An anonymous client could execute the authenticated economy contract RPC.'
}
$anonymousAccessDenied = $true

$login = Invoke-StagingJsonRequest `
    -Uri "$baseUrl/auth/v1/token?grant_type=password" `
    -Headers @{ apikey = $PublishableKey } `
    -Body @{ email = $normalizedEmail; password = $Password }
Assert-Success -Response $login -Operation 'Staging login'
$accessToken = [string](Get-PropertyValue -InputObject $login.Body -Name 'access_token')
$user = Get-PropertyValue -InputObject $login.Body -Name 'user'
$rawUserId = [string](Get-PropertyValue -InputObject $user -Name 'id')
$confirmedAt = Get-PropertyValue -InputObject $user -Name 'email_confirmed_at'
$parsedUserId = [Guid]::Empty
if ([string]::IsNullOrWhiteSpace($accessToken) -or
    -not [Guid]::TryParse($rawUserId, [ref]$parsedUserId) -or
    [string]::IsNullOrWhiteSpace([string]$confirmedAt)) {
    throw 'The staging login did not return a confirmed session.'
}

$contractResponse = Invoke-StagingJsonRequest `
    -Uri "$baseUrl/rest/v1/rpc/get_my_economy_contract" `
    -Headers @{
        apikey = $PublishableKey
        Authorization = "Bearer $accessToken"
    } `
    -Body @{}
Assert-Success -Response $contractResponse -Operation 'Authenticated economy contract lookup'
$contractRows = @($contractResponse.Body)
if ($contractRows.Count -ne 1) {
    throw 'The authenticated economy contract lookup was not unambiguous.'
}
$contract = $contractRows[0]
if ([string](Get-PropertyValue $contract 'authority_mode') -ne 'legacy_client' -or
    [int](Get-PropertyValue $contract 'protocol_version') -ne 1 -or
    [int](Get-PropertyValue $contract 'minimum_client_build') -ne 10061 -or
    (ConvertTo-StrictBoolean (Get-PropertyValue $contract 'mutations_enabled') 'mutations_enabled') -or
    [long](Get-PropertyValue $contract 'server_revision') -lt 0 -or
    [long](Get-PropertyValue $contract 'wallet_revision') -lt 0) {
    throw 'The economy contract is not in its required dormant compatibility state.'
}
$authenticatedContractVerified = $true

$schemaRow = Assert-SingleRow `
    -Rows (Invoke-StagingManagementQuery `
        -Operation 'Economy foundation schema verification' `
        -Query @"
with valuable_tables(table_name) as (
  values
    ('player_economy_authority'),
    ('economy_mutation_requests'),
    ('player_item_instances'),
    ('player_chest_instances'),
    ('economy_reward_claims'),
    ('economy_ledger_entries')
)
select
  exists (
    select 1 from supabase_migrations.schema_migrations
    where version = '202609050037'
  ) as migration_37_applied,
  (
    select count(*) = 6
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    join valuable_tables v on v.table_name = c.relname
    where n.nspname = 'public' and c.relkind = 'r' and c.relrowsecurity
  ) as all_valuable_tables_have_rls,
  not exists (
    select 1
    from valuable_tables v
    where has_table_privilege('anon', format('public.%I', v.table_name), 'select')
       or has_table_privilege('anon', format('public.%I', v.table_name), 'insert')
       or has_table_privilege('anon', format('public.%I', v.table_name), 'update')
       or has_table_privilege('anon', format('public.%I', v.table_name), 'delete')
       or has_table_privilege('authenticated', format('public.%I', v.table_name), 'select')
       or has_table_privilege('authenticated', format('public.%I', v.table_name), 'insert')
       or has_table_privilege('authenticated', format('public.%I', v.table_name), 'update')
       or has_table_privilege('authenticated', format('public.%I', v.table_name), 'delete')
  ) as direct_client_table_access_absent,
  exists (
    select 1 from private.economy_contract
    where singleton and protocol_version = 1
      and minimum_client_build = 10061 and not mutations_enabled
  ) as global_mutations_disabled,
  exists (
    select 1 from public.player_economy_authority
    where user_id = '$($parsedUserId.ToString())'::uuid
      and authority_mode = 'legacy_client' and protocol_version = 1
  ) as keeper_remains_legacy,
  exists (
    select 1
    from pg_trigger t
    join pg_class c on c.oid = t.tgrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'economy_ledger_entries'
      and t.tgname = 'economy_ledger_entries_reject_change'
      and not t.tgisinternal and t.tgenabled = 'O'
  ) as append_only_trigger_enabled,
  not has_function_privilege('anon', 'public.get_my_economy_contract()', 'execute')
    and has_function_privilege('authenticated', 'public.get_my_economy_contract()', 'execute')
    as rpc_grants_are_scoped;
"@) `
    -Operation 'Economy foundation schema verification'

foreach ($flag in @(
    'migration_37_applied',
    'all_valuable_tables_have_rls',
    'direct_client_table_access_absent',
    'global_mutations_disabled',
    'keeper_remains_legacy',
    'append_only_trigger_enabled',
    'rpc_grants_are_scoped'
)) {
    if (-not (ConvertTo-StrictBoolean `
            -Value (Get-PropertyValue -InputObject $schemaRow -Name $flag) `
            -Name $flag)) {
        throw "The economy foundation schema failed on $flag."
    }
}

$disabledMutationRow = Assert-SingleRow `
    -Rows (Invoke-StagingManagementQuery `
        -ReadOnly $false `
        -Operation 'Dormant mutation rejection verification' `
        -Query @"
do `$test`$
begin
  perform set_config('request.jwt.claim.sub', '$($parsedUserId.ToString())', true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  begin
    perform private.begin_economy_mutation(
      gen_random_uuid(), 'audit.dormant_probe', 1, 10061, '{}'::jsonb
    );
    raise exception 'economy_mutation_unexpectedly_enabled';
  exception
    when others then
      if sqlerrm <> 'economy_mutations_disabled' then
        raise;
      end if;
  end;
end
`$test`$;
select not exists (
  select 1 from public.economy_mutation_requests
  where owner_id = '$($parsedUserId.ToString())'::uuid
    and operation = 'audit.dormant_probe'
) as no_probe_was_persisted;
"@) `
    -Operation 'Dormant mutation rejection verification'
if (-not (ConvertTo-StrictBoolean `
        -Value (Get-PropertyValue $disabledMutationRow 'no_probe_was_persisted') `
        -Name 'no_probe_was_persisted')) {
    throw 'The disabled mutation probe persisted economy state.'
}
$disabledMutationRejected = $true

$evidenceDirectory = Split-Path -Parent $EvidencePath
New-Item -ItemType Directory -Path $evidenceDirectory -Force | Out-Null
@(
    'DragonHaven staging economy foundation E2E'
    "generated_at_utc=$([DateTime]::UtcNow.ToString('o'))"
    'environment=staging'
    'production_targeted=false'
    'repository_migration_37_present=true'
    'remote_migration_37_applied=true'
    "anonymous_access_denied=$($anonymousAccessDenied.ToString().ToLowerInvariant())"
    "authenticated_contract_verified=$($authenticatedContractVerified.ToString().ToLowerInvariant())"
    "disabled_mutation_rejected=$($disabledMutationRejected.ToString().ToLowerInvariant())"
    'valuable_table_rls_verified=true'
    'direct_client_table_access_absent=true'
    'append_only_trigger_verified=true'
    'raw_identifiers_recorded=false'
    'credentials_recorded=false'
) | Set-Content -LiteralPath $EvidencePath -Encoding utf8

$accessToken = $null
$ManagementAccessToken = $null
$Password = $null
$normalizedEmail = $null

Write-Host 'The isolated staging economy foundation verification passed.'
