param()

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$dragonRoot = Join-Path $projectRoot 'assets\images\dragons'
$furnitureRoot = Join-Path $projectRoot 'assets\images\furniture_atlases'

function Export-PaddedGrid {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][int]$Columns,
        [Parameter(Mandatory = $true)][int]$Rows,
        [double]$Scale = 0.92
    )

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    if (-not $resolved.StartsWith($projectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to edit an asset outside the project: $resolved"
    }

    $source = [System.Drawing.Bitmap]::FromFile($resolved)
    $output = New-Object System.Drawing.Bitmap(
        $source.Width,
        $source.Height,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    $graphics = [System.Drawing.Graphics]::FromImage($output)
    try {
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

        for ($row = 0; $row -lt $Rows; $row++) {
            for ($column = 0; $column -lt $Columns; $column++) {
                $sourceLeft = [Math]::Round($column * $source.Width / $Columns)
                $sourceRight = [Math]::Round(($column + 1) * $source.Width / $Columns)
                $sourceTop = [Math]::Round($row * $source.Height / $Rows)
                $sourceBottom = [Math]::Round(($row + 1) * $source.Height / $Rows)
                $cellWidth = $sourceRight - $sourceLeft
                $cellHeight = $sourceBottom - $sourceTop
                $targetWidth = [Math]::Round($cellWidth * $Scale)
                $targetHeight = [Math]::Round($cellHeight * $Scale)
                $targetLeft = $sourceLeft + [Math]::Round(($cellWidth - $targetWidth) / 2)
                $targetTop = $sourceTop + [Math]::Round(($cellHeight - $targetHeight) / 2)
                $target = New-Object System.Drawing.Rectangle($targetLeft, $targetTop, $targetWidth, $targetHeight)
                $crop = New-Object System.Drawing.Rectangle($sourceLeft, $sourceTop, $cellWidth, $cellHeight)
                $graphics.DrawImage($source, $target, $crop, [System.Drawing.GraphicsUnit]::Pixel)
            }
        }

        $temporary = "$resolved.padded.png"
        $output.Save($temporary, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $graphics.Dispose()
        $output.Dispose()
        $source.Dispose()
    }
    Move-Item -LiteralPath $temporary -Destination $resolved -Force
}

Export-PaddedGrid -Path (Join-Path $dragonRoot 'mysterious_egg.png') -Columns 1 -Rows 1
Get-ChildItem -LiteralPath $dragonRoot -Filter '*_hatchling.png' | ForEach-Object {
    Export-PaddedGrid -Path $_.FullName -Columns 1 -Rows 1
}
Get-ChildItem -LiteralPath $dragonRoot -Filter '*_forms.png' | ForEach-Object {
    Export-PaddedGrid -Path $_.FullName -Columns 2 -Rows 2
}
Get-ChildItem -LiteralPath $furnitureRoot -Filter '*.png' | ForEach-Object {
    Export-PaddedGrid -Path $_.FullName -Columns 4 -Rows 2
}

Write-Host 'Applied consistent transparent safety margins to all dragon and furniture sprites.'
