[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AndroidAppId,

    [Parameter(Mandatory = $true)]
    [string]$GemsAdUnitId,

    [Parameter(Mandatory = $true)]
    [string]$CoinsAdUnitId,

    [Parameter(Mandatory = $true)]
    [string]$PublisherId,

    [string]$SsvSourceRevision = '',

    [string]$SsvSetupCustomData = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRef = 'tnzathhutuwmohmjfrlo'
$testPublisherNumber = '3940256099942544'
$appPattern = '^ca-app-pub-([0-9]{16})~([0-9]{10})$'
$unitPattern = '^ca-app-pub-([0-9]{16})/([0-9]{10})$'
$publisherPattern = '^pub-([0-9]{16})$'
$sourceRevisionPattern = '^[0-9a-f]{40}$'
$setupCustomDataPattern = '^[0-9a-f]{64}$'

$AndroidAppId = $AndroidAppId.Trim()
$GemsAdUnitId = $GemsAdUnitId.Trim()
$CoinsAdUnitId = $CoinsAdUnitId.Trim()
$PublisherId = $PublisherId.Trim()
$SsvSourceRevision = $SsvSourceRevision.Trim().ToLowerInvariant()
$SsvSetupCustomData = $SsvSetupCustomData.Trim().ToLowerInvariant()

$appMatch = [regex]::Match($AndroidAppId, $appPattern)
$gemsMatch = [regex]::Match($GemsAdUnitId, $unitPattern)
$coinsMatch = [regex]::Match($CoinsAdUnitId, $unitPattern)
$publisherMatch = [regex]::Match($PublisherId, $publisherPattern)

if (-not $appMatch.Success) {
    throw 'AndroidAppId moet het formaat ca-app-pub-0000000000000000~0000000000 hebben.'
}
if (-not $gemsMatch.Success) {
    throw 'GemsAdUnitId moet het formaat ca-app-pub-0000000000000000/0000000000 hebben.'
}
if (-not $coinsMatch.Success) {
    throw 'CoinsAdUnitId moet het formaat ca-app-pub-0000000000000000/0000000000 hebben.'
}
if (-not $publisherMatch.Success) {
    throw 'PublisherId moet het formaat pub-0000000000000000 hebben.'
}
if ($GemsAdUnitId -eq $CoinsAdUnitId) {
    throw 'Free gems en Free coins moeten twee verschillende rewarded-ad-unit-ID''s gebruiken.'
}

$publisherNumber = $publisherMatch.Groups[1].Value
$idPublisherNumbers = @(
    $appMatch.Groups[1].Value,
    $gemsMatch.Groups[1].Value,
    $coinsMatch.Groups[1].Value
)
if (@($idPublisherNumbers | Where-Object { $_ -ne $publisherNumber }).Count -ne 0) {
    throw 'De app-ID, beide ad-unit-ID''s en publisher-ID horen niet bij hetzelfde AdMob-account.'
}
if ($publisherNumber -eq $testPublisherNumber) {
    throw 'Google-test-ID''s mogen niet als productieconfiguratie worden opgeslagen.'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$gitCommand = Get-Command git -ErrorAction SilentlyContinue
if ([string]::IsNullOrWhiteSpace($SsvSourceRevision)) {
    if ($null -eq $gitCommand) {
        throw 'Git is nodig om de exacte SSV-broncommit te bepalen. Geef anders -SsvSourceRevision op.'
    }
    $revisionOutput = & $gitCommand.Source -C $repoRoot rev-parse HEAD 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "De huidige Git-commit kon niet worden bepaald: $($revisionOutput | Out-String)"
    }
    $SsvSourceRevision = ($revisionOutput | Out-String).Trim().ToLowerInvariant()
}
if ($SsvSourceRevision -notmatch $sourceRevisionPattern) {
    throw 'SsvSourceRevision moet exact een volledige Git-commit van 40 hextekens zijn.'
}
if ([string]::IsNullOrWhiteSpace($SsvSetupCustomData)) {
    $setupBytes = New-Object byte[] 32
    $random = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $random.GetBytes($setupBytes)
    } finally {
        $random.Dispose()
    }
    $SsvSetupCustomData = [BitConverter]::ToString($setupBytes).Replace('-', '').ToLowerInvariant()
}
if ($SsvSetupCustomData -notmatch $setupCustomDataPattern) {
    throw 'SsvSetupCustomData moet exact 64 kleine hextekens bevatten.'
}

$toolsDirectory = Join-Path $repoRoot '.tools'
$definesPath = Join-Path $toolsDirectory 'rewarded-ads-build-defines.json'
$appAdsPath = Join-Path $toolsDirectory 'app-ads.txt'
$ssvSecretsPath = Join-Path $toolsDirectory 'rewarded-ads-ssv-secrets.env'
$ssvSetupPath = Join-Path $toolsDirectory 'rewarded-ads-ssv-setup.json'
$appAdsTemplatePath = Join-Path $repoRoot 'app-ads.txt.template'
$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)

New-Item -ItemType Directory -Path $toolsDirectory -Force | Out-Null
$defines = [ordered]@{
    DRAGONHAVEN_ENVIRONMENT = 'production'
    DRAGONHAVEN_REWARDED_ADS_MODE = 'production'
    DRAGONHAVEN_ADMOB_ANDROID_APP_ID = $AndroidAppId
    DRAGONHAVEN_ADMOB_REWARDED_GEMS_ID = $GemsAdUnitId
    DRAGONHAVEN_ADMOB_REWARDED_COINS_ID = $CoinsAdUnitId
}
[IO.File]::WriteAllText(
    $definesPath,
    (($defines | ConvertTo-Json) + [Environment]::NewLine),
    $utf8WithoutBom
)
if (-not (Test-Path -LiteralPath $appAdsTemplatePath -PathType Leaf)) {
    throw 'app-ads.txt.template ontbreekt.'
}
$appAdsTemplate = (Get-Content -LiteralPath $appAdsTemplatePath -Raw).Trim()
if ($appAdsTemplate -ne
    'google.com, pub-XXXXXXXXXXXXXXXX, DIRECT, f08c47fec0942fa0') {
    throw 'app-ads.txt.template heeft een onverwachte inhoud.'
}
$appAdsLine = $appAdsTemplate.Replace('pub-XXXXXXXXXXXXXXXX', $PublisherId)
[IO.File]::WriteAllText(
    $appAdsPath,
    ($appAdsLine + [Environment]::NewLine),
    $utf8WithoutBom
)
$ssvSecrets = @(
    "ADMOB_REWARDED_GEMS_AD_UNIT_ID=$GemsAdUnitId"
    "ADMOB_REWARDED_COINS_AD_UNIT_ID=$CoinsAdUnitId"
    "REWARDED_AD_SSV_SETUP_CUSTOM_DATA=$SsvSetupCustomData"
    "REWARDED_AD_SSV_SOURCE_REVISION=$SsvSourceRevision"
) -join [Environment]::NewLine
[IO.File]::WriteAllText(
    $ssvSecretsPath,
    ($ssvSecrets + [Environment]::NewLine),
    $utf8WithoutBom
)
$ssvSetup = [ordered]@{
    callbackUrl = "https://$projectRef.supabase.co/functions/v1/rewarded-ad-ssv"
    userId = 'dragonhaven-ssv-setup'
    customData = $SsvSetupCustomData
}
[IO.File]::WriteAllText(
    $ssvSetupPath,
    (($ssvSetup | ConvertTo-Json) + [Environment]::NewLine),
    $utf8WithoutBom
)

Write-Host 'Rewarded-ad-configuratie is gecontroleerd.'
Write-Host "Build-defines: $definesPath"
Write-Host "Te publiceren app-ads.txt: $appAdsPath"
Write-Host "SSV-functieconfiguratie: $ssvSecretsPath"
Write-Host "SSV Verify URL-invoer: $ssvSetupPath"
Write-Host "SSV-broncommit: $SsvSourceRevision"
if ($null -ne $gitCommand) {
    $ssvChanges = @(
        & $gitCommand.Source -C $repoRoot status --short --untracked-files=all -- `
            supabase/functions/rewarded-ad-ssv 2>$null
    )
    if ($LASTEXITCODE -eq 0 -and $ssvChanges.Count -gt 0) {
        Write-Warning ('De SSV-functie heeft niet-gecommitte wijzigingen. ' +
            'Commit eerst, voer dit script opnieuw uit en deploy pas daarna; ' +
            'anders klopt de broncommit niet met de gedeployde code.')
    }
}
Write-Host ''
Write-Host 'Sla eerst de openbare GitHub Variables op terwijl advertenties uit blijven:'
Write-Host "gh variable set DRAGONHAVEN_REWARDED_ADS_ENABLED --body 'false'"
Write-Host "gh variable set DRAGONHAVEN_ADMOB_ANDROID_APP_ID --body '$AndroidAppId'"
Write-Host "gh variable set DRAGONHAVEN_ADMOB_REWARDED_GEMS_ID --body '$GemsAdUnitId'"
Write-Host "gh variable set DRAGONHAVEN_ADMOB_REWARDED_COINS_ID --body '$CoinsAdUnitId'"
Write-Host "gh variable set DRAGONHAVEN_ADMOB_PUBLISHER_ID --body '$PublisherId'"
Write-Host ''
Write-Host 'Configureer daarna de SSV-functie voor exact deze commit:'
Write-Host ('supabase secrets set --project-ref ' + $projectRef +
    ' --env-file "' + $ssvSecretsPath + '"')
Write-Host ("supabase functions deploy rewarded-ad-ssv --project-ref $projectRef " +
    '--no-verify-jwt --use-api')
Write-Host ''
Write-Host 'SSV-callback voor beide rewarded-ad-units:'
Write-Host "https://$projectRef.supabase.co/functions/v1/rewarded-ad-ssv"
Write-Host ''
Write-Host 'Publiceer .tools/app-ads.txt exact op /app-ads.txt van de ontwikkelaarswebsite.'
Write-Host 'Laat de server-kill-switch en GitHub-enable-variable uit tijdens de eerste controles.'
Write-Host 'Na een geslaagde interne test is de laatste GitHub-stap:'
Write-Host "gh variable set DRAGONHAVEN_REWARDED_ADS_ENABLED --body 'true'"
Write-Host ''
Write-Host 'Na iedere latere commit: voer dit script opnieuw uit, zet de SSV-secrets opnieuw en deploy de functie opnieuw.'
