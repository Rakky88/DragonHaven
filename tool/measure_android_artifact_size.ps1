[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ArtifactPath,

    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

$artifact = Get-Item -LiteralPath (Resolve-Path -LiteralPath $ArtifactPath)
$extension = $artifact.Extension.ToLowerInvariant()
if ($extension -notin @('.aab', '.apk')) {
    throw 'ArtifactPath must point to an .aab or .apk file.'
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($artifact.FullName)

function Get-ArtifactGroup {
    param(
        [string]$EntryName,
        [string]$ArtifactExtension
    )

    $normalized = $EntryName.Replace('\', '/')
    $baseRelative = if ($ArtifactExtension -eq '.aab' -and $normalized.StartsWith('base/')) {
        $normalized.Substring(5)
    } else {
        $normalized
    }

    $imagePrefix = 'assets/flutter_assets/assets/images/'
    if ($baseRelative.StartsWith($imagePrefix)) {
        $relativeImage = $baseRelative.Substring($imagePrefix.Length)
        $firstSegment = ($relativeImage -split '/', 2)[0]
        if ($relativeImage -notmatch '/') {
            return 'images/other'
        }
        return "images/$firstSegment"
    }

    if ($baseRelative -match '^res/raw/' -or
        ($ArtifactExtension -eq '.apk' -and
            $baseRelative -match '^res/[^/]+\.(ogg|mp3|wav|mid)$')) {
        return 'android_audio'
    }
    if ($baseRelative.StartsWith('assets/flutter_assets/')) {
        return 'other_flutter_assets'
    }
    if ($baseRelative.StartsWith('lib/')) {
        return 'native_libraries'
    }
    if ($baseRelative.StartsWith('dex/') -or $baseRelative -match '^classes[0-9]*\.dex$') {
        return 'dex'
    }
    if ($normalized.StartsWith('BUNDLE-METADATA/')) {
        return 'bundle_metadata'
    }
    if ($normalized.StartsWith('META-INF/')) {
        return 'signing_metadata'
    }
    if ($baseRelative.StartsWith('res/') -or
        $baseRelative -in @('AndroidManifest.xml', 'resources.pb', 'resources.arsc')) {
        return 'android_resources'
    }
    return 'other'
}

try {
    $entryRows = @(
        $archive.Entries |
            Where-Object { $_.Length -gt 0 } |
            ForEach-Object {
                [pscustomobject]@{
                    name = $_.FullName
                    group = Get-ArtifactGroup `
                        -EntryName $_.FullName `
                        -ArtifactExtension $extension
                    uncompressedBytes = [long]$_.Length
                    compressedBytes = [long]$_.CompressedLength
                }
            }
    )

    $groups = @(
        $entryRows |
            Group-Object group |
            ForEach-Object {
                $uncompressed = ($_.Group |
                    Measure-Object uncompressedBytes -Sum).Sum
                $compressed = ($_.Group |
                    Measure-Object compressedBytes -Sum).Sum
                [pscustomobject]@{
                    group = $_.Name
                    files = $_.Count
                    uncompressedBytes = [long]$uncompressed
                    compressedBytes = [long]$compressed
                    uncompressedMiB = [math]::Round($uncompressed / 1MB, 2)
                    compressedMiB = [math]::Round($compressed / 1MB, 2)
                }
            } |
            Sort-Object compressedBytes -Descending
    )

    $universalMediaBytes = (
        $groups |
            Where-Object {
                $_.group.StartsWith('images/') -or $_.group -eq 'android_audio'
            } |
            Measure-Object compressedBytes -Sum
    ).Sum

    $largestEntries = @(
        $entryRows |
            Sort-Object compressedBytes -Descending |
            Select-Object -First 25 |
            ForEach-Object {
                [pscustomobject]@{
                    name = $_.name
                    group = $_.group
                    uncompressedBytes = $_.uncompressedBytes
                    compressedBytes = $_.compressedBytes
                    compressedMiB = [math]::Round($_.compressedBytes / 1MB, 2)
                }
            }
    )

    $report = [ordered]@{
        generatedAtUtc = [DateTime]::UtcNow.ToString('o')
        artifact = $artifact.Name
        kind = $extension.TrimStart('.')
        artifactBytes = [long]$artifact.Length
        artifactMiB = [math]::Round($artifact.Length / 1MB, 2)
        archiveEntries = $entryRows.Count
        universalMediaCompressedBytes = [long]$universalMediaBytes
        universalMediaCompressedMiB = [math]::Round($universalMediaBytes / 1MB, 2)
        note = 'Archive compression is not the Play Console per-device download estimate.'
        groups = $groups
        largestEntries = $largestEntries
    }

    $json = $report | ConvertTo-Json -Depth 6
    if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
        $parent = Split-Path -Parent $OutputPath
        if (-not [string]::IsNullOrWhiteSpace($parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        Set-Content -LiteralPath $OutputPath -Value $json -Encoding utf8
    }
    $json
} finally {
    $archive.Dispose()
}
