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

    [string]$EvidencePath = 'staging/social-e2e.txt'
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
$tradeResult = 'not-run'

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
    } else {
        $groupJoinResult = 'join skipped safely because a 2-player offer would start a multi-day run'
    }

    if ($peerJoinedLobby) {
        Invoke-RequiredRpc `
            -Session $peer `
            -Function 'leave_group_adventure_lobby' `
            -Parameters @{ p_lobby_id = $createdLobbyId } `
            -Operation 'Tweede account uit staginglobby laten vertrekken' | Out-Null
        $peerJoinedLobby = $false
    }
    Invoke-RequiredRpc `
        -Session $primary `
        -Function 'leave_group_adventure_lobby' `
        -Parameters @{ p_lobby_id = $createdLobbyId } `
        -Operation 'Staging Group Adventure-lobby verwijderen' | Out-Null
    $createdLobbyId = $null

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
        "Trade flow: $tradeResult."
        'Trade inventory transfer invariant: passed.'
        "Group Adventure flow: $groupJoinResult."
        'Waiting Group Adventure cleanup: passed.'
        'Temporary friendship cleanup: passed.'
        'Group completion/reward remains a separate safe test.'
    )
    'Tweepersoons stagingflow voor Friends, trade en veilige Group Adventure-deelname is geslaagd.'
} finally {
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
