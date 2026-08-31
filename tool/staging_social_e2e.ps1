#requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SupabaseUrl,

    [Parameter(Mandatory = $true)]
    [string]$PublishableKey,

    [Parameter(Mandatory = $true)]
    [string]$PrimaryEmail,

    [Parameter(Mandatory = $true)]
    [string]$PrimaryPassword,

    [Parameter(Mandatory = $true)]
    [string]$PeerEmail,

    [Parameter(Mandatory = $true)]
    [string]$PeerPassword,

    [string]$EvidencePath = 'staging/social-e2e.txt',

    [switch]$CompleteGroupAdventure,

    [string]$ProjectRef = '',

    [string]$ManagementAccessToken = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$baseUrl = $SupabaseUrl.Trim().TrimEnd('/')
$normalizedPrimaryEmail = $PrimaryEmail.Trim().ToLowerInvariant()
$normalizedPeerEmail = $PeerEmail.Trim().ToLowerInvariant()
if ($baseUrl -notmatch '^https://[a-z0-9]+\.supabase\.co$') {
    throw 'De sociale stagingtest accepteert uitsluitend een gehost HTTPS-Supabaseproject.'
}
if (-not $PublishableKey.StartsWith('sb_publishable_')) {
    throw 'De sociale stagingtest vereist een publishable clientkey.'
}
if ($normalizedPrimaryEmail -eq $normalizedPeerEmail) {
    throw 'De sociale stagingtest vereist twee verschillende testaccounts.'
}
foreach ($candidate in @($normalizedPrimaryEmail, $normalizedPeerEmail)) {
    try {
        $parsed = [System.Net.Mail.MailAddress]::new($candidate)
    } catch {
        throw 'Een afgeschermd sociaal staging-testadres is ongeldig.'
    }
    if ($parsed.Address -ne $candidate) {
        throw 'Een afgeschermd sociaal staging-testadres is ongeldig.'
    }
}
if ($PrimaryPassword.Length -lt 12 -or $PeerPassword.Length -lt 12) {
    throw 'Een afgeschermd sociaal staging-testwachtwoord is te kort.'
}
if ($CompleteGroupAdventure) {
    if ($ProjectRef -notmatch '^[a-z0-9]{20}$') {
        throw 'De Group Adventure-tijdregeling vereist een geldige staging-projectreference.'
    }
    if ($ProjectRef -eq 'tnzathhutuwmohmjfrlo') {
        throw 'De Group Adventure-tijdregeling mag nooit het productieproject gebruiken.'
    }
    if ($baseUrl -ne "https://$ProjectRef.supabase.co") {
        throw 'De Group Adventure-tijdregeling hoort niet bij de opgegeven staging-URL.'
    }
    if ([string]::IsNullOrWhiteSpace($ManagementAccessToken)) {
        throw 'De Group Adventure-tijdregeling vereist het afgeschermde staging-beheertoken.'
    }
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

    foreach ($name in @('error_code', 'message', 'msg', 'code', 'error_description')) {
        $value = Get-PropertyValue -InputObject $Body -Name $name
        if (-not [string]::IsNullOrWhiteSpace([string]$value)) {
            $safe = [string]$value
            foreach ($address in @($normalizedPrimaryEmail, $normalizedPeerEmail)) {
                $safe = $safe.Replace($address, '[redacted-email]')
            }
            if ($safe.Length -gt 180) { $safe = $safe.Substring(0, 180) }
            return "HTTP $StatusCode ($safe)"
        }
    }
    return "HTTP $StatusCode"
}

function Test-SuccessStatus {
    param([int]$StatusCode)
    return $StatusCode -ge 200 -and $StatusCode -lt 300
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
        $request.Body = ConvertTo-Json -InputObject $Body -Depth 40 -Compress
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

function Connect-StagingUser {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Email,
        [Parameter(Mandatory = $true)]
        [string]$Password
    )

    $response = Invoke-StagingJsonRequest `
        -Method Post `
        -Uri "$baseUrl/auth/v1/token?grant_type=password" `
        -Headers @{ apikey = $PublishableKey } `
        -Body @{ email = $Email; password = $Password }
    Assert-Success -Response $response -Operation 'Staging-login'
    $accessToken = [string](Get-PropertyValue -InputObject $response.Body -Name 'access_token')
    $user = Get-PropertyValue -InputObject $response.Body -Name 'user'
    $userId = [string](Get-PropertyValue -InputObject $user -Name 'id')
    $confirmedAt = Get-PropertyValue -InputObject $user -Name 'email_confirmed_at'
    if ([string]::IsNullOrWhiteSpace($accessToken) -or
        [string]::IsNullOrWhiteSpace($userId) -or
        [string]::IsNullOrWhiteSpace([string]$confirmedAt)) {
        throw 'Een sociale staging-login leverde geen bevestigde sessie op.'
    }
    return [pscustomobject]@{
        AccessToken = $accessToken
        UserId = $userId
    }
}

function Invoke-StagingRpc {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Session,
        [Parameter(Mandatory = $true)]
        [string]$Function,
        [hashtable]$Parameters = @{}
    )

    return Invoke-StagingJsonRequest `
        -Method Post `
        -Uri "$baseUrl/rest/v1/rpc/$Function" `
        -Headers @{
            apikey = $PublishableKey
            Authorization = "Bearer $($Session.AccessToken)"
        } `
        -Body $Parameters
}

function Invoke-RequiredRpc {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Session,
        [Parameter(Mandatory = $true)]
        [string]$Function,
        [hashtable]$Parameters = @{},
        [string]$Operation = $Function
    )

    $response = Invoke-StagingRpc `
        -Session $Session `
        -Function $Function `
        -Parameters $Parameters
    Assert-Success -Response $response -Operation $Operation
    return $response.Body
}

function Get-Rows {
    param([AllowNull()][object]$Body)
    return @($Body)
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
        [string]$Operation
    )

    if (-not $CompleteGroupAdventure -or
        $ProjectRef -eq 'tnzathhutuwmohmjfrlo') {
        throw 'De staging-only databasebesturing is niet veilig geactiveerd.'
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
            read_only = $false
        } -Compress) `
        -SkipHttpErrorCheck `
        -StatusCodeVariable managementStatusCode `
        -ErrorAction Stop
    if (-not (Test-SuccessStatus $managementStatusCode)) {
        throw "$Operation mislukte met HTTP $managementStatusCode."
    }
    return $body
}

function Set-StagingGroupAdventureElapsed {
    param([Parameter(Mandatory = $true)][string]$LobbyId)

    $parsedLobbyId = [Guid]::Empty
    if (-not [Guid]::TryParse($LobbyId, [ref]$parsedLobbyId)) {
        throw 'De staging-only tijdregeling kreeg geen geldige lobby-id.'
    }
    $safeLobbyId = $parsedLobbyId.ToString()
    $query = @"
with advanced as (
  update public.group_adventure_lobbies
  set ends_at = now() - interval '1 second'
  where id = '$safeLobbyId'::uuid
    and status = 'running'
    and started_at is not null
  returning id, status, ends_at
)
select id::text as lobby_id, status, ends_at <= now() as elapsed
from advanced;
"@
    $rows = Get-ManagementRows (Invoke-StagingManagementQuery `
        -Query $query `
        -Operation 'Staging-only Group Adventure-tijdregeling')
    if ($rows.Count -ne 1 -or
        [string](Get-PropertyValue -InputObject $rows[0] -Name 'lobby_id') -ne $safeLobbyId -or
        [string](Get-PropertyValue -InputObject $rows[0] -Name 'status') -ne 'running' -or
        -not [bool](Get-PropertyValue -InputObject $rows[0] -Name 'elapsed')) {
        throw 'De staging-only tijdregeling heeft niet exact één lopende testlobby versneld.'
    }
}

function Set-StagingGroupAdventureTwoPlayerFixture {
    param([Parameter(Mandatory = $true)][string]$LobbyId)

    $parsedLobbyId = [Guid]::Empty
    if (-not [Guid]::TryParse($LobbyId, [ref]$parsedLobbyId)) {
        throw 'De staging-only deelnemersregeling kreeg geen geldige lobby-id.'
    }
    $safeLobbyId = $parsedLobbyId.ToString()
    $query = @"
with adjusted as (
  update public.group_adventure_lobbies l
  set required_players = 2
  where l.id = '$safeLobbyId'::uuid
    and l.status = 'waiting'
    and l.owner_id is not null
    and (
      select count(*)
      from public.group_adventure_participants gp
      where gp.lobby_id = l.id
    ) = 1
  returning l.id, l.required_players
)
select id::text as lobby_id, required_players
from adjusted;
"@
    $rows = Get-ManagementRows (Invoke-StagingManagementQuery `
        -Query $query `
        -Operation 'Staging-only Group Adventure-deelnemersregeling')
    if ($rows.Count -ne 1 -or
        [string](Get-PropertyValue -InputObject $rows[0] -Name 'lobby_id') -ne $safeLobbyId -or
        [int](Get-PropertyValue -InputObject $rows[0] -Name 'required_players') -ne 2) {
        throw 'De staging-only deelnemersregeling heeft niet exact één wachtende testlobby aangepast.'
    }
}

function Remove-StagingGroupAdventureFixture {
    param([Parameter(Mandatory = $true)][string]$LobbyId)

    $parsedLobbyId = [Guid]::Empty
    if (-not [Guid]::TryParse($LobbyId, [ref]$parsedLobbyId)) {
        throw 'De staging-only cleanup kreeg geen geldige lobby-id.'
    }
    $safeLobbyId = $parsedLobbyId.ToString()
    $query = @"
with target as materialized (
  select id, chest_tier
  from public.group_adventure_lobbies
  where id = '$safeLobbyId'::uuid
), participants as materialized (
  select gp.user_id, gp.dragon_id, gp.reward_acknowledged_at
  from public.group_adventure_participants gp
  where gp.lobby_id = '$safeLobbyId'::uuid
), reverted_chests as (
  update public.player_chests c
  set quantity = greatest(0, c.quantity - 1), updated_at = now()
  from target t, participants p
  where p.reward_acknowledged_at is not null
    and c.owner_id = p.user_id
    and c.tier = t.chest_tier
  returning c.owner_id
), deleted_lobby as (
  delete from public.group_adventure_lobbies
  where id in (select id from target)
  returning id
), deleted_test_dragons as (
  delete from public.player_dragons d
  using participants p
  where d.id = p.dragon_id
    and d.legacy_client_id in ('staging-e2e-alpha', 'staging-e2e-beta')
    and exists (select 1 from deleted_lobby)
  returning d.id
)
select
  (select count(*) from deleted_lobby)::integer as lobby_deleted,
  (select count(*) from reverted_chests)::integer as rewards_reverted,
  (select count(*) from deleted_test_dragons)::integer as dragons_deleted;
"@
    $rows = Get-ManagementRows (Invoke-StagingManagementQuery `
        -Query $query `
        -Operation 'Staging-only Group Adventure-cleanup')
    if ($rows.Count -ne 1 -or
        [int](Get-PropertyValue -InputObject $rows[0] -Name 'lobby_deleted') -ne 1) {
        throw 'De staging-only cleanup heeft de tijdelijke testlobby niet verwijderd.'
    }
}

function Get-ChestQuantity {
    param(
        [Parameter(Mandatory = $true)][object]$Session,
        [Parameter(Mandatory = $true)][string]$Tier
    )

    $inventory = Get-Rows (Invoke-RequiredRpc `
        -Session $Session `
        -Function 'list_trade_inventory')
    $row = $inventory | Where-Object {
        [string](Get-PropertyValue -InputObject $_ -Name 'item_type') -eq 'chest' -and
        [string](Get-PropertyValue -InputObject $_ -Name 'item_key') -eq $Tier
    } | Select-Object -First 1
    if ($null -eq $row) { return 0 }
    return [int](Get-PropertyValue -InputObject $row -Name 'available')
}

function Find-RowByUser {
    param(
        [object[]]$Rows,
        [string]$UserId
    )
    return $Rows | Where-Object {
        [string](Get-PropertyValue -InputObject $_ -Name 'user_id') -eq $UserId
    } | Select-Object -First 1
}

function Get-AmsterdamDate {
    param([DateTimeOffset]$Moment)

    $zone = $null
    foreach ($zoneId in @('Europe/Amsterdam', 'W. Europe Standard Time')) {
        try {
            $zone = [TimeZoneInfo]::FindSystemTimeZoneById($zoneId)
            break
        } catch {
            continue
        }
    }
    if ($null -eq $zone) { throw 'De Amsterdam-tijdzone is niet beschikbaar.' }
    return [TimeZoneInfo]::ConvertTime($Moment, $zone).Date
}

function Write-SafeEvidence {
    param([string[]]$Lines)

    $parent = Split-Path -Parent $EvidencePath
    if (-not [string]::IsNullOrWhiteSpace($parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    @(
        'DragonHaven staging social E2E'
        "UTC: $([DateTimeOffset]::UtcNow.ToString('O'))"
        'No e-mail address, password, session token, keeper code or user id is recorded.'
        ''
    ) + $Lines | Set-Content -LiteralPath $EvidencePath -Encoding utf8
}

$primary = $null
$peer = $null
$createdLobbyId = $null
$peerJoinedLobby = $false
$friendshipCreated = $false
$groupJoinResult = 'not-run'
$groupCompletionResult = 'not-requested'
$tradeResult = 'not-run'
$friendMessageResult = 'not-run'
$conclaveResult = 'not-run'

function Remove-ActiveTrades {
    if ($null -eq $primary -or $null -eq $peer) { return }
    $rows = Get-Rows (Invoke-RequiredRpc -Session $primary -Function 'list_my_trades')
    foreach ($row in $rows) {
        $status = [string](Get-PropertyValue -InputObject $row -Name 'status')
        if ($status -notin @('awaiting_recipient', 'awaiting_initiator')) { continue }
        $tradeId = [string](Get-PropertyValue -InputObject $row -Name 'trade_id')
        $initiatorId = [string](Get-PropertyValue -InputObject $row -Name 'initiator_id')
        $ownerSession = if ($initiatorId -eq $primary.UserId) { $primary } else { $peer }
        Invoke-RequiredRpc `
            -Session $ownerSession `
            -Function 'cancel_trade' `
            -Parameters @{ p_trade_id = $tradeId } `
            -Operation 'Opruimen van actieve stagingtrade' | Out-Null
    }
}

function Remove-WaitingGroupLobbies {
    if ($null -eq $primary -or $null -eq $peer) { return }
    foreach ($entry in @(
        [pscustomobject]@{ Session = $peer; OwnersOnly = $false },
        [pscustomobject]@{ Session = $primary; OwnersOnly = $false },
        [pscustomobject]@{ Session = $peer; OwnersOnly = $true },
        [pscustomobject]@{ Session = $primary; OwnersOnly = $true }
    )) {
        $rows = Get-Rows (Invoke-RequiredRpc `
            -Session $entry.Session `
            -Function 'list_group_adventures')
        foreach ($row in $rows) {
            if ([string](Get-PropertyValue -InputObject $row -Name 'status') -ne 'waiting') {
                continue
            }
            $isOwner = [bool](Get-PropertyValue -InputObject $row -Name 'is_owner')
            $isParticipant = [bool](Get-PropertyValue -InputObject $row -Name 'is_participant')
            if ($isOwner -ne $entry.OwnersOnly -or -not $isParticipant) { continue }
            Invoke-RequiredRpc `
                -Session $entry.Session `
                -Function 'leave_group_adventure_lobby' `
                -Parameters @{
                    p_lobby_id = [string](Get-PropertyValue -InputObject $row -Name 'lobby_id')
                } `
                -Operation 'Opruimen van wachtende staginglobby' | Out-Null
        }
    }
}

function Remove-ExistingFriendship {
    if ($null -eq $primary -or $null -eq $peer) { return }
    $friends = Get-Rows (Invoke-RequiredRpc -Session $primary -Function 'list_my_friends')
    if ($null -ne (Find-RowByUser -Rows $friends -UserId $peer.UserId)) {
        Invoke-RequiredRpc `
            -Session $primary `
            -Function 'remove_friend' `
            -Parameters @{ p_friend_id = $peer.UserId } `
            -Operation 'Opruimen van bestaande stagingvriendschap' | Out-Null
        return
    }

    $requests = Get-Rows (Invoke-RequiredRpc `
        -Session $primary `
        -Function 'list_friend_requests')
    $request = Find-RowByUser -Rows $requests -UserId $peer.UserId
    if ($null -eq $request) { return }
    $requestId = [string](Get-PropertyValue -InputObject $request -Name 'request_id')
    $direction = [string](Get-PropertyValue -InputObject $request -Name 'direction')
    $acceptingSession = if ($direction -eq 'incoming') { $primary } else { $peer }
    Invoke-RequiredRpc `
        -Session $acceptingSession `
        -Function 'respond_friend_request' `
        -Parameters @{ p_request_id = $requestId; p_response = 'accepted' } `
        -Operation 'Herstellen van achtergebleven stagingverzoek' | Out-Null
    Invoke-RequiredRpc `
        -Session $primary `
        -Function 'remove_friend' `
        -Parameters @{ p_friend_id = $peer.UserId } `
        -Operation 'Opruimen van herstelde stagingvriendschap' | Out-Null
}

function Remove-ExistingConclaves {
    if ($null -eq $primary -or $null -eq $peer) { return }
    foreach ($session in @($primary, $peer)) {
        $snapshot = Invoke-RequiredRpc `
            -Session $session `
            -Function 'get_my_conclave_snapshot' `
            -Operation 'Bestaande staging-Conclave controleren'
        if ($null -eq $snapshot) { continue }
        $role = [string](Get-PropertyValue -InputObject $snapshot -Name 'my_role')
        if ($role -eq 'flightmaster') {
            Invoke-RequiredRpc `
                -Session $session `
                -Function 'dissolve_conclave' `
                -Operation 'Bestaande staging-Conclave opheffen' | Out-Null
        } else {
            Invoke-RequiredRpc `
                -Session $session `
                -Function 'leave_conclave' `
                -Operation 'Bestaande staging-Conclave verlaten' | Out-Null
        }
    }
}

function Close-StagingSessions {
    foreach ($session in @($primary, $peer)) {
        if ($null -eq $session) { continue }
        try {
            $response = Invoke-StagingJsonRequest `
                -Method Post `
                -Uri "$baseUrl/auth/v1/logout" `
                -Headers @{
                    apikey = $PublishableKey
                    Authorization = "Bearer $($session.AccessToken)"
                } `
                -Body $null
            if (-not (Test-SuccessStatus $response.StatusCode)) {
                Write-Warning 'Een tijdelijke sociale stagingsessie kon niet worden ingetrokken.'
            }
        } catch {
            Write-Warning 'Een tijdelijke sociale stagingsessie kon niet worden ingetrokken.'
        }
    }
}

try {
    $primary = Connect-StagingUser `
        -Email $normalizedPrimaryEmail `
        -Password $PrimaryPassword
    $peer = Connect-StagingUser `
        -Email $normalizedPeerEmail `
        -Password $PeerPassword

    foreach ($session in @($primary, $peer)) {
        Invoke-RequiredRpc `
            -Session $session `
            -Function 'ensure_my_online_account' `
            -Operation 'Sociale accountbootstrap' | Out-Null
    }
    Invoke-RequiredRpc `
        -Session $primary `
        -Function 'update_my_profile' `
        -Parameters @{
            p_display_name = 'Staging Alpha'
            p_title = 'title_001'
            p_portrait_key = 'portrait_001'
        } `
        -Operation 'Primair stagingprofiel bijwerken' | Out-Null
    Invoke-RequiredRpc `
        -Session $peer `
        -Function 'update_my_profile' `
        -Parameters @{
            p_display_name = 'Staging Beta'
            p_title = 'title_001'
            p_portrait_key = 'portrait_001'
        } `
        -Operation 'Tweede stagingprofiel bijwerken' | Out-Null

    Remove-ActiveTrades
    Remove-WaitingGroupLobbies
    Remove-ExistingConclaves
    Remove-ExistingFriendship

    $peerProfileRows = Get-Rows (Invoke-RequiredRpc `
        -Session $peer `
        -Function 'get_my_profile')
    if ($peerProfileRows.Count -ne 1) {
        throw 'Het tweede stagingprofiel kon niet eenduidig worden geladen.'
    }
    $peerKeeperCode = [string](Get-PropertyValue `
        -InputObject $peerProfileRows[0] `
        -Name 'keeper_code')
    if ([string]::IsNullOrWhiteSpace($peerKeeperCode)) {
        throw 'Het tweede stagingprofiel heeft geen Keeper ID.'
    }

    $friendRequestId = [string](Invoke-RequiredRpc `
        -Session $primary `
        -Function 'send_friend_request' `
        -Parameters @{ p_keeper_code = $peerKeeperCode } `
        -Operation 'Stagingvriendschapsverzoek versturen')
    if ([string]::IsNullOrWhiteSpace($friendRequestId)) {
        throw 'Het stagingvriendschapsverzoek leverde geen request-id op.'
    }
    $incoming = Find-RowByUser `
        -Rows (Get-Rows (Invoke-RequiredRpc `
            -Session $peer `
            -Function 'list_friend_requests')) `
        -UserId $primary.UserId
    if ($null -eq $incoming -or
        [string](Get-PropertyValue -InputObject $incoming -Name 'direction') -ne 'incoming' -or
        [string](Get-PropertyValue -InputObject $incoming -Name 'request_id') -ne $friendRequestId) {
        throw 'Het tweede stagingaccount zag het vriendschapsverzoek niet correct.'
    }
    Invoke-RequiredRpc `
        -Session $peer `
        -Function 'respond_friend_request' `
        -Parameters @{ p_request_id = $friendRequestId; p_response = 'accepted' } `
        -Operation 'Stagingvriendschapsverzoek accepteren' | Out-Null
    $friendshipCreated = $true
    foreach ($pair in @(
        [pscustomobject]@{ Session = $primary; Other = $peer },
        [pscustomobject]@{ Session = $peer; Other = $primary }
    )) {
        $friends = Get-Rows (Invoke-RequiredRpc `
            -Session $pair.Session `
            -Function 'list_my_friends')
        if ($null -eq (Find-RowByUser -Rows $friends -UserId $pair.Other.UserId)) {
            throw 'De geaccepteerde stagingvriendschap was niet wederzijds zichtbaar.'
        }
    }

    foreach ($session in @($primary, $peer)) {
        Invoke-RequiredRpc `
            -Session $session `
            -Function 'set_social_preferences' `
            -Parameters @{
                p_friend_messages_allowed = $true
                p_share_achievements_with_conclave = $false
            } `
            -Operation 'Staging-berichtvoorkeuren inschakelen' | Out-Null
    }
    $messageMarker = "staging-message-$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
    $friendMessageId = [string](Invoke-RequiredRpc `
        -Session $primary `
        -Function 'send_friend_message' `
        -Parameters @{ p_friend_id = $peer.UserId; p_body = $messageMarker } `
        -Operation 'Staging-vriendbericht versturen')
    if ([string]::IsNullOrWhiteSpace($friendMessageId)) {
        throw 'Het staging-vriendbericht leverde geen message-id op.'
    }
    $peerConversations = Get-Rows (Invoke-RequiredRpc `
        -Session $peer `
        -Function 'list_friend_conversations')
    $peerConversation = $peerConversations | Where-Object {
        [string](Get-PropertyValue -InputObject $_ -Name 'friend_id') -eq $primary.UserId
    } | Select-Object -First 1
    if ($null -eq $peerConversation -or
        [long](Get-PropertyValue -InputObject $peerConversation -Name 'unread_count') -lt 1 -or
        [string](Get-PropertyValue -InputObject $peerConversation -Name 'last_message') -ne $messageMarker) {
        throw 'Het staging-vriendbericht was niet als ongelezen gesprek zichtbaar.'
    }
    $openedMessages = Get-Rows (Invoke-RequiredRpc `
        -Session $peer `
        -Function 'open_friend_messages' `
        -Parameters @{ p_friend_id = $primary.UserId } `
        -Operation 'Staging-vriendbericht openen')
    $openedMessage = $openedMessages | Where-Object {
        [string](Get-PropertyValue -InputObject $_ -Name 'message_id') -eq $friendMessageId
    } | Select-Object -First 1
    if ($null -eq $openedMessage -or
        [string](Get-PropertyValue -InputObject $openedMessage -Name 'body') -ne $messageMarker -or
        [string]::IsNullOrWhiteSpace([string](Get-PropertyValue -InputObject $openedMessage -Name 'read_at'))) {
        throw 'Het staging-vriendbericht werd niet correct geopend en gelezen gemarkeerd.'
    }
    Invoke-RequiredRpc `
        -Session $peer `
        -Function 'set_social_preferences' `
        -Parameters @{
            p_friend_messages_allowed = $false
            p_share_achievements_with_conclave = $false
        } `
        -Operation 'Staging-vriendberichten uitschakelen' | Out-Null
    $blockedMessage = Invoke-StagingRpc `
        -Session $primary `
        -Function 'send_friend_message' `
        -Parameters @{
            p_friend_id = $peer.UserId
            p_body = "blocked-$messageMarker"
        }
    if (Test-SuccessStatus $blockedMessage.StatusCode) {
        throw 'Een staging-vriendbericht passeerde ten onrechte de opt-out.'
    }
    $blockedFailure = Get-SafeFailure `
        -Body $blockedMessage.Body `
        -StatusCode $blockedMessage.StatusCode
    if ($blockedFailure -notmatch 'messages_disabled') {
        throw 'De staging-vriendbericht-opt-out gaf niet de verwachte veilige foutcode.'
    }
    Invoke-RequiredRpc `
        -Session $peer `
        -Function 'set_social_preferences' `
        -Parameters @{
            p_friend_messages_allowed = $true
            p_share_achievements_with_conclave = $false
        } `
        -Operation 'Staging-vriendberichten herstellen' | Out-Null
    $friendMessageResult = 'send, unread projection, read acknowledgement and opt-out passed'

    $conclaveName = "E2E-$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
    $conclaveId = [string](Invoke-RequiredRpc `
        -Session $primary `
        -Function 'create_conclave' `
        -Parameters @{
            p_name = $conclaveName
            p_emblem_key = 'conclave_emblem_01'
            p_description = 'Temporary staging verification'
            p_language = 'en'
            p_visibility = 'public'
            p_member_limit = 4
        } `
        -Operation 'Staging-Conclave oprichten')
    if ([string]::IsNullOrWhiteSpace($conclaveId)) {
        throw 'De staging-Conclave leverde geen Conclave-id op.'
    }
    $duplicateConclave = Invoke-StagingRpc `
        -Session $peer `
        -Function 'create_conclave' `
        -Parameters @{
            p_name = "  $($conclaveName.ToLowerInvariant())  "
            p_emblem_key = 'conclave_emblem_02'
            p_description = ''
            p_language = 'en'
            p_visibility = 'public'
            p_member_limit = 4
        }
    if (Test-SuccessStatus $duplicateConclave.StatusCode) {
        throw 'Een dubbele staging-Conclave-naam werd ten onrechte geaccepteerd.'
    }
    $duplicateFailure = Get-SafeFailure `
        -Body $duplicateConclave.Body `
        -StatusCode $duplicateConclave.StatusCode
    if ($duplicateFailure -notmatch 'conclave_name_taken') {
        throw 'De dubbele staging-Conclave-naam gaf niet de verwachte veilige foutcode.'
    }
    $directory = Get-Rows (Invoke-RequiredRpc `
        -Session $peer `
        -Function 'list_conclaves')
    $directoryEntry = $directory | Where-Object {
        [string](Get-PropertyValue -InputObject $_ -Name 'conclave_id') -eq $conclaveId
    } | Select-Object -First 1
    if ($null -eq $directoryEntry -or
        [string](Get-PropertyValue -InputObject $directoryEntry -Name 'name') -ne $conclaveName) {
        throw 'De openbare staging-Conclave was niet correct vindbaar.'
    }
    $joinResult = [string](Invoke-RequiredRpc `
        -Session $peer `
        -Function 'request_or_join_conclave' `
        -Parameters @{ p_conclave_id = $conclaveId } `
        -Operation 'Staging-Conclave toetreden')
    if ($joinResult -ne 'joined') {
        throw 'De openbare staging-Conclave leverde niet het verwachte join-resultaat.'
    }
    Invoke-RequiredRpc `
        -Session $primary `
        -Function 'set_conclave_member_role' `
        -Parameters @{ p_user_id = $peer.UserId; p_role = 'warden' } `
        -Operation 'Staging-Conclave Warden toekennen' | Out-Null
    $peerSnapshot = Invoke-RequiredRpc `
        -Session $peer `
        -Function 'get_my_conclave_snapshot' `
        -Operation 'Staging-Conclave voor Warden laden'
    $peerConclave = Get-PropertyValue -InputObject $peerSnapshot -Name 'conclave'
    if ([string](Get-PropertyValue -InputObject $peerSnapshot -Name 'my_role') -ne 'warden' -or
        [int](Get-PropertyValue -InputObject $peerConclave -Name 'member_count') -ne 2) {
        throw 'De staging-Conclave-rang of ledentelling klopt niet.'
    }
    $conclaveMessageId = [string](Invoke-RequiredRpc `
        -Session $peer `
        -Function 'send_conclave_message' `
        -Parameters @{
            p_kind = 'text'
            p_body = 'Temporary staging Conclave message'
            p_payload = @{}
        } `
        -Operation 'Staging-Conclavebericht versturen')
    $primarySnapshot = Invoke-RequiredRpc `
        -Session $primary `
        -Function 'get_my_conclave_snapshot' `
        -Operation 'Staging-Conclavebericht laden'
    $conclaveMessages = @(Get-PropertyValue -InputObject $primarySnapshot -Name 'messages')
    if ($null -eq ($conclaveMessages | Where-Object {
        [string](Get-PropertyValue -InputObject $_ -Name 'message_id') -eq $conclaveMessageId
    } | Select-Object -First 1)) {
        throw 'Het staging-Conclavebericht was niet zichtbaar voor de Flightmaster.'
    }
    $contributionRows = Get-Rows (Invoke-RequiredRpc `
        -Session $primary `
        -Function 'contribute_to_conclave' `
        -Operation 'Staging-Aerie verzorgen')
    if ($contributionRows.Count -ne 1 -or
        [int](Get-PropertyValue -InputObject $contributionRows[0] -Name 'xp') -ne 10 -or
        [int](Get-PropertyValue -InputObject $contributionRows[0] -Name 'aerie_stage') -ne 1) {
        throw 'De staging-Aerie-bijdrage gaf niet exact de verwachte voortgang.'
    }
    Invoke-RequiredRpc `
        -Session $peer `
        -Function 'leave_conclave' `
        -Operation 'Staging-Warden laten vertrekken' | Out-Null
    Invoke-RequiredRpc `
        -Session $primary `
        -Function 'dissolve_conclave' `
        -Operation 'Staging-Conclave gecontroleerd opheffen' | Out-Null
    foreach ($session in @($primary, $peer)) {
        $emptySnapshot = Invoke-RequiredRpc `
            -Session $session `
            -Function 'get_my_conclave_snapshot' `
            -Operation 'Opgeruimde staging-Conclave controleren'
        if ($null -ne $emptySnapshot) {
            throw 'De tijdelijke staging-Conclave is niet volledig opgeruimd.'
        }
    }
    $conclaveResult = 'normalized unique naming, join, role, chat, contribution and cleanup passed'

    $testInventory = @{
        eggs = @()
        chests = @{ wooden = 1 }
        relics = @{}
        relic_variants = @{}
    }
    foreach ($session in @($primary, $peer)) {
        Invoke-RequiredRpc `
            -Session $session `
            -Function 'synchronize_trade_inventory' `
            -Parameters @{ p_inventory = $testInventory } `
            -Operation 'Staging-trade-inventory synchroniseren' | Out-Null
    }

    $today = Get-AmsterdamDate -Moment ([DateTimeOffset]::UtcNow)
    $priorTrades = Get-Rows (Invoke-RequiredRpc `
        -Session $primary `
        -Function 'list_my_trades')
    $completedToday = $priorTrades | Where-Object {
        [string](Get-PropertyValue -InputObject $_ -Name 'status') -eq 'completed' -and
        [string](Get-PropertyValue -InputObject $_ -Name 'user_id') -eq $peer.UserId -and
        (Get-AmsterdamDate -Moment ([DateTimeOffset]::Parse(
            [string](Get-PropertyValue -InputObject $_ -Name 'updated_at')
        ))) -eq $today
    } | Select-Object -First 1

    if ($null -eq $completedToday) {
        $tradeId = [string](Invoke-RequiredRpc `
            -Session $primary `
            -Function 'create_trade' `
            -Parameters @{
                p_friend_id = $peer.UserId
                p_item = @{ kind = 'chest'; key = 'wooden' }
            } `
            -Operation 'Stagingtrade aanmaken')
        if ([string]::IsNullOrWhiteSpace($tradeId)) {
            throw 'De stagingtrade leverde geen trade-id op.'
        }
        $peerTrade = Get-Rows (Invoke-RequiredRpc `
            -Session $peer `
            -Function 'list_my_trades') | Where-Object {
                [string](Get-PropertyValue -InputObject $_ -Name 'trade_id') -eq $tradeId
            } | Select-Object -First 1
        if ($null -eq $peerTrade -or
            [string](Get-PropertyValue -InputObject $peerTrade -Name 'status') -ne 'awaiting_recipient') {
            throw 'Het tweede stagingaccount zag de trade niet als te beantwoorden.'
        }
        Invoke-RequiredRpc `
            -Session $peer `
            -Function 'respond_trade' `
            -Parameters @{
                p_trade_id = $tradeId
                p_item = @{ kind = 'chest'; key = 'wooden' }
            } `
            -Operation 'Stagingtrade beantwoorden' | Out-Null
        Invoke-RequiredRpc `
            -Session $primary `
            -Function 'complete_trade' `
            -Parameters @{ p_trade_id = $tradeId } `
            -Operation 'Stagingtrade afronden' | Out-Null
        $tradeResult = 'created, reciprocated and completed'
    } else {
        $tradeResult = 'existing completed trade for this Amsterdam day revalidated'
    }

    foreach ($session in @($primary, $peer)) {
        $inventory = Get-Rows (Invoke-RequiredRpc `
            -Session $session `
            -Function 'list_trade_inventory')
        $wooden = $inventory | Where-Object {
            [string](Get-PropertyValue -InputObject $_ -Name 'item_type') -eq 'chest' -and
            [string](Get-PropertyValue -InputObject $_ -Name 'item_key') -eq 'wooden'
        } | Select-Object -First 1
        if ($null -eq $wooden -or
            [int](Get-PropertyValue -InputObject $wooden -Name 'available') -ne 1) {
            throw 'De afgeronde stagingtrade behield niet exact één houten kist per testaccount.'
        }
    }

    $groupStatusRows = Get-Rows (Invoke-RequiredRpc `
        -Session $primary `
        -Function 'get_current_group_adventure_status')
    if ($groupStatusRows.Count -ne 1 -or
        [bool](Get-PropertyValue -InputObject $groupStatusRows[0] -Name 'already_completed')) {
        throw 'Het primaire stagingaccount is deze week al aan een gestart Group Adventure gekoppeld.'
    }
    $adventureId = [string](Get-PropertyValue `
        -InputObject $groupStatusRows[0] `
        -Name 'adventure_id')
    $dragonAlpha = @{
        client_id = 'staging-e2e-alpha'
        name = 'E2E Alpha'
        lineage_id = 'staging_e2e'
        stage = 'ascended'
        xp = 100000
        might = 300
        arcana = 300
        spirit = 300
        evolution_path = 'might'
        prismatic = $false
        sinister = $false
    }
    $dragonBeta = @{
        client_id = 'staging-e2e-beta'
        name = 'E2E Beta'
        lineage_id = 'staging_e2e'
        stage = 'ascended'
        xp = 100000
        might = 300
        arcana = 300
        spirit = 300
        evolution_path = 'might'
        prismatic = $false
        sinister = $false
    }
    $createdLobbyId = [string](Invoke-RequiredRpc `
        -Session $primary `
        -Function 'create_group_adventure_lobby' `
        -Parameters @{ p_adventure_id = $adventureId; p_dragon = $dragonAlpha } `
        -Operation 'Staging Group Adventure-lobby aanmaken')
    if ([string]::IsNullOrWhiteSpace($createdLobbyId)) {
        throw 'De staging Group Adventure leverde geen lobby-id op.'
    }
    $peerLobby = Get-Rows (Invoke-RequiredRpc `
        -Session $peer `
        -Function 'list_group_adventures') | Where-Object {
            [string](Get-PropertyValue -InputObject $_ -Name 'lobby_id') -eq $createdLobbyId
        } | Select-Object -First 1
    if ($null -eq $peerLobby -or
        [string](Get-PropertyValue -InputObject $peerLobby -Name 'status') -ne 'waiting') {
        throw 'De vriend zag de wachtende staging Group Adventure-lobby niet.'
    }
    $requiredPlayers = [int](Get-PropertyValue `
        -InputObject $peerLobby `
        -Name 'required_players')
    $originalRequiredPlayers = $requiredPlayers
    if ($CompleteGroupAdventure -and $requiredPlayers -gt 2) {
        Set-StagingGroupAdventureTwoPlayerFixture -LobbyId $createdLobbyId
        $requiredPlayers = 2
    }
    if ($requiredPlayers -gt 2) {
        $joinResponse = Invoke-StagingRpc `
            -Session $peer `
            -Function 'join_group_adventure_lobby' `
            -Parameters @{ p_lobby_id = $createdLobbyId; p_dragon = $dragonBeta }
        Assert-Success -Response $joinResponse -Operation 'Staging Group Adventure deelnemen'
        if ([bool]$joinResponse.Body) {
            throw 'De tweepersoons-stagingtest startte onverwacht een Group Adventure.'
        }
        $peerJoinedLobby = $true
        $joinedLobby = Get-Rows (Invoke-RequiredRpc `
            -Session $peer `
            -Function 'list_group_adventures') | Where-Object {
                [string](Get-PropertyValue -InputObject $_ -Name 'lobby_id') -eq $createdLobbyId
            } | Select-Object -First 1
        if ($null -eq $joinedLobby -or
            -not [bool](Get-PropertyValue -InputObject $joinedLobby -Name 'is_participant')) {
            throw 'De deelname aan de staging Group Adventure was niet zichtbaar.'
        }
        $groupJoinResult = "created, joined and left safely ($requiredPlayers-player offer)"
    } elseif (-not $CompleteGroupAdventure) {
        $groupJoinResult = 'join skipped safely because a 2-player offer would start a multi-day run'
    } else {
        $joinResponse = Invoke-StagingRpc `
            -Session $peer `
            -Function 'join_group_adventure_lobby' `
            -Parameters @{ p_lobby_id = $createdLobbyId; p_dragon = $dragonBeta }
        Assert-Success -Response $joinResponse -Operation 'Staging Group Adventure starten'
        if (-not [bool]$joinResponse.Body) {
            throw 'De volledige stagingtest heeft de tweepersoons-Group Adventure niet gestart.'
        }
        $groupJoinResult = if ($originalRequiredPlayers -gt 2) {
            "${originalRequiredPlayers}-player fixture normalized to two; adventure started through the regular server RPC"
        } else {
            'two-player adventure started server-authoritatively'
        }

        foreach ($session in @($primary, $peer)) {
            $runningLobby = Get-Rows (Invoke-RequiredRpc `
                -Session $session `
                -Function 'list_group_adventures') | Where-Object {
                    [string](Get-PropertyValue -InputObject $_ -Name 'lobby_id') -eq $createdLobbyId
                } | Select-Object -First 1
            if ($null -eq $runningLobby -or
                [string](Get-PropertyValue -InputObject $runningLobby -Name 'status') -ne 'running' -or
                -not [bool](Get-PropertyValue -InputObject $runningLobby -Name 'is_participant')) {
                throw 'De gestarte staging-Group Adventure was niet voor beide deelnemers zichtbaar.'
            }
        }

        Set-StagingGroupAdventureElapsed -LobbyId $createdLobbyId

        foreach ($session in @($primary, $peer)) {
            $completedLobby = Get-Rows (Invoke-RequiredRpc `
                -Session $session `
                -Function 'list_group_adventures') | Where-Object {
                    [string](Get-PropertyValue -InputObject $_ -Name 'lobby_id') -eq $createdLobbyId
                } | Select-Object -First 1
            if ($null -eq $completedLobby -or
                [string](Get-PropertyValue -InputObject $completedLobby -Name 'status') -ne 'completed' -or
                [bool](Get-PropertyValue -InputObject $completedLobby -Name 'reward_acknowledged')) {
                throw 'De versnelde staging-Group Adventure leverde niet voor beide spelers een openstaande reward op.'
            }
        }

        $claimedRewards = @()
        foreach ($entry in @(
            [pscustomobject]@{ Session = $primary; DragonId = 'staging-e2e-alpha' },
            [pscustomobject]@{ Session = $peer; DragonId = 'staging-e2e-beta' }
        )) {
            $rewardRows = Get-Rows (Invoke-RequiredRpc `
                -Session $entry.Session `
                -Function 'claim_group_adventure_reward' `
                -Parameters @{ p_lobby_id = $createdLobbyId } `
                -Operation 'Group Adventure-reward claimen')
            if ($rewardRows.Count -ne 1) {
                throw 'De staging-Group Adventure leverde niet exact één reward per deelnemer.'
            }
            $reward = $rewardRows[0]
            $rewardTier = [string](Get-PropertyValue -InputObject $reward -Name 'chest_tier')
            if ([string](Get-PropertyValue -InputObject $reward -Name 'lobby_id') -ne $createdLobbyId -or
                [string](Get-PropertyValue -InputObject $reward -Name 'adventure_id') -ne $adventureId -or
                [string](Get-PropertyValue -InputObject $reward -Name 'dragon_id') -ne $entry.DragonId -or
                [int](Get-PropertyValue -InputObject $reward -Name 'participant_count') -ne 2 -or
                [int](Get-PropertyValue -InputObject $reward -Name 'xp') -le 0 -or
                [int](Get-PropertyValue -InputObject $reward -Name 'stat_points') -le 0 -or
                [string](Get-PropertyValue -InputObject $reward -Name 'focus') -notin @('might', 'arcana', 'spirit') -or
                $rewardTier -notin @('gold', 'dragon', 'mythical')) {
                throw 'De staging-Group Adventure-reward bevatte ongeldige servervelden.'
            }

            $beforeChest = Get-ChestQuantity `
                -Session $entry.Session `
                -Tier $rewardTier
            Invoke-RequiredRpc `
                -Session $entry.Session `
                -Function 'acknowledge_group_adventure_reward' `
                -Parameters @{ p_lobby_id = $createdLobbyId } `
                -Operation 'Group Adventure-reward bevestigen' | Out-Null
            $afterChest = Get-ChestQuantity `
                -Session $entry.Session `
                -Tier $rewardTier
            if ($afterChest -ne $beforeChest + 1) {
                throw 'De eerste Group Adventure-acknowledgement voegde niet exact één rewardkist toe.'
            }

            Invoke-RequiredRpc `
                -Session $entry.Session `
                -Function 'acknowledge_group_adventure_reward' `
                -Parameters @{ p_lobby_id = $createdLobbyId } `
                -Operation 'Group Adventure-acknowledgement herhalen' | Out-Null
            if ((Get-ChestQuantity -Session $entry.Session -Tier $rewardTier) -ne $afterChest) {
                throw 'Een herhaalde Group Adventure-acknowledgement voegde een dubbele reward toe.'
            }

            $replayClaim = Invoke-StagingRpc `
                -Session $entry.Session `
                -Function 'claim_group_adventure_reward' `
                -Parameters @{ p_lobby_id = $createdLobbyId }
            if ((Test-SuccessStatus $replayClaim.StatusCode) -or
                (Get-SafeFailure `
                    -Body $replayClaim.Body `
                    -StatusCode $replayClaim.StatusCode) -notmatch 'group_reward_not_ready') {
                throw 'Een reeds bevestigde Group Adventure-reward kon opnieuw worden geclaimd.'
            }
            $claimedRewards += $reward
        }

        foreach ($field in @(
            'adventure_id', 'xp', 'focus', 'stat_points', 'chest_tier',
            'participant_count'
        )) {
            if ((Get-PropertyValue -InputObject $claimedRewards[0] -Name $field) -ne
                (Get-PropertyValue -InputObject $claimedRewards[1] -Name $field)) {
                throw "De Group Adventure-deelnemers kregen geen identieke serverreward voor $field."
            }
        }

        Remove-StagingGroupAdventureFixture -LobbyId $createdLobbyId
        $createdLobbyId = $null
        $peerJoinedLobby = $false
        $postCleanupStatus = Get-Rows (Invoke-RequiredRpc `
            -Session $primary `
            -Function 'get_current_group_adventure_status')
        if ($postCleanupStatus.Count -ne 1 -or
            [bool](Get-PropertyValue -InputObject $postCleanupStatus[0] -Name 'already_completed')) {
            throw 'De staging-only Group Adventure-fixture is niet volledig herbruikbaar opgeruimd.'
        }
        $groupCompletionResult = 'completion, equal rewards, acknowledgement and replay guard passed'
    }

    if ($null -ne $createdLobbyId -and $peerJoinedLobby) {
        Invoke-RequiredRpc `
            -Session $peer `
            -Function 'leave_group_adventure_lobby' `
            -Parameters @{ p_lobby_id = $createdLobbyId } `
            -Operation 'Tweede account uit staginglobby laten vertrekken' | Out-Null
        $peerJoinedLobby = $false
    }
    if ($null -ne $createdLobbyId) {
        Invoke-RequiredRpc `
            -Session $primary `
            -Function 'leave_group_adventure_lobby' `
            -Parameters @{ p_lobby_id = $createdLobbyId } `
            -Operation 'Staging Group Adventure-lobby verwijderen' | Out-Null
        $createdLobbyId = $null
    }

    Invoke-RequiredRpc `
        -Session $primary `
        -Function 'remove_friend' `
        -Parameters @{ p_friend_id = $peer.UserId } `
        -Operation 'Stagingvriendschap na test verwijderen' | Out-Null
    $friendshipCreated = $false
    foreach ($session in @($primary, $peer)) {
        $friends = Get-Rows (Invoke-RequiredRpc `
            -Session $session `
            -Function 'list_my_friends')
        if ($null -ne (Find-RowByUser `
            -Rows $friends `
            -UserId $(if ($session.UserId -eq $primary.UserId) {
                $peer.UserId
            } else {
                $primary.UserId
            }))) {
            throw 'De tijdelijke stagingvriendschap is niet volledig opgeruimd.'
        }
    }

    Write-SafeEvidence -Lines @(
        'Result: two-account social flow passed.'
        'Two confirmed password logins and idempotent bootstraps: passed.'
        'Friend request, incoming projection, acceptance and mutual visibility: passed.'
        "Friend Messages: $friendMessageResult."
        "Conclave flow: $conclaveResult."
        "Trade flow: $tradeResult."
        'Trade inventory transfer invariant: passed.'
        "Group Adventure flow: $groupJoinResult."
        "Group Adventure completion: $groupCompletionResult."
        'Group Adventure fixture cleanup: passed.'
        'Temporary friendship cleanup: passed.'
    )
    'Tweepersoons stagingflow voor Friends, trade en Group Adventures is geslaagd.'
} finally {
    try {
        if ($CompleteGroupAdventure -and $null -ne $createdLobbyId) {
            Remove-StagingGroupAdventureFixture -LobbyId $createdLobbyId
            $createdLobbyId = $null
            $peerJoinedLobby = $false
        }
    } catch {
        Write-Warning 'De staging-only Group Adventure-fixture kon niet volledig worden opgeruimd.'
    }
    try {
        if ($peerJoinedLobby -and $null -ne $createdLobbyId -and $null -ne $peer) {
            Invoke-RequiredRpc `
                -Session $peer `
                -Function 'leave_group_adventure_lobby' `
                -Parameters @{ p_lobby_id = $createdLobbyId } | Out-Null
            $peerJoinedLobby = $false
        }
    } catch {
        Write-Warning 'Het tweede stagingaccount kon niet uit de tijdelijke lobby worden verwijderd.'
    }
    try {
        if ($null -ne $createdLobbyId -and $null -ne $primary) {
            Invoke-RequiredRpc `
                -Session $primary `
                -Function 'leave_group_adventure_lobby' `
                -Parameters @{ p_lobby_id = $createdLobbyId } | Out-Null
            $createdLobbyId = $null
        }
    } catch {
        Write-Warning 'De tijdelijke sociale staginglobby kon niet worden verwijderd.'
    }
    try {
        Remove-ExistingConclaves
    } catch {
        Write-Warning 'Niet alle tijdelijke staging-Conclaves konden automatisch worden opgeruimd.'
    }
    try {
        Remove-ActiveTrades
    } catch {
        Write-Warning 'Niet alle tijdelijke stagingtrades konden automatisch worden opgeruimd.'
    }
    try {
        Remove-ExistingFriendship
        $friendshipCreated = $false
    } catch {
        Write-Warning 'De tijdelijke stagingvriendschap kon niet automatisch worden opgeruimd.'
    }
    Close-StagingSessions
}
