param()

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $projectRoot 'assets\images\dragonhaven_logo.png'
$appIconPath = Join-Path $projectRoot 'assets\images\dragonhaven_app_icon.png'
$androidResPath = Join-Path $projectRoot 'android\app\src\main\res'

function Export-BrandedImage {
    param(
        [Parameter(Mandatory = $true)]
        [System.Drawing.Image]$Source,
        [Parameter(Mandatory = $true)]
        [int]$CanvasSize,
        [Parameter(Mandatory = $true)]
        [double]$LogoScale,
        [Parameter(Mandatory = $true)]
        [System.Drawing.Color]$Background,
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    $bitmap = New-Object System.Drawing.Bitmap(
        $CanvasSize,
        $CanvasSize,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

    try {
        $graphics.Clear($Background)
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

        $maximumSize = $CanvasSize * $LogoScale
        $ratio = [Math]::Min($maximumSize / $Source.Width, $maximumSize / $Source.Height)
        $width = [Math]::Round($Source.Width * $ratio)
        $height = [Math]::Round($Source.Height * $ratio)
        $left = [Math]::Round(($CanvasSize - $width) / 2)
        $top = [Math]::Round(($CanvasSize - $height) / 2)

        $graphics.DrawImage($Source, $left, $top, $width, $height)
        $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

$logo = [System.Drawing.Image]::FromFile($sourcePath)

try {
    Export-BrandedImage `
        -Source $logo `
        -CanvasSize 1024 `
        -LogoScale 0.76 `
        -Background ([System.Drawing.Color]::White) `
        -OutputPath $appIconPath

    $densitySizes = [ordered]@{
        'drawable-mdpi' = 144
        'drawable-hdpi' = 216
        'drawable-xhdpi' = 288
        'drawable-xxhdpi' = 432
        'drawable-xxxhdpi' = 576
    }

    foreach ($entry in $densitySizes.GetEnumerator()) {
        $directory = Join-Path $androidResPath $entry.Key
        New-Item -ItemType Directory -Force $directory | Out-Null
        Export-BrandedImage `
            -Source $logo `
            -CanvasSize $entry.Value `
            -LogoScale 0.80 `
            -Background ([System.Drawing.Color]::Transparent) `
            -OutputPath (Join-Path $directory 'dragonhaven_launch_logo.png')
    }
}
finally {
    $logo.Dispose()
}

Write-Host 'Generated the white DragonHaven icon and density-aware Android splash logos.'
