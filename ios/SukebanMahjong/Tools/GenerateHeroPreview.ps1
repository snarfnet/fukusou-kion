Add-Type -AssemblyName System.Drawing

$outputPath = Join-Path $PSScriptRoot "..\Design\heroine-akari-preview.png"
$ink = [System.Drawing.Color]::FromArgb(255, 10, 10, 20)
$skin = [System.Drawing.Color]::FromArgb(255, 255, 184, 122)
$red = [System.Drawing.Color]::FromArgb(255, 218, 31, 45)
$ivory = [System.Drawing.Color]::FromArgb(255, 240, 232, 194)
$grid = [System.Drawing.Color[]]::new(16 * 16)

function Set-SpriteRect(
    [int]$originX,
    [int]$originY,
    [int]$blockWidth,
    [int]$blockHeight,
    [System.Drawing.Color]$blockColor
) {
    for ($spriteY = $originY; $spriteY -lt ($originY + $blockHeight); $spriteY++) {
        for ($spriteX = $originX; $spriteX -lt ($originX + $blockWidth); $spriteX++) {
            $grid[$spriteY * 16 + $spriteX] = $blockColor
        }
    }
}

Set-SpriteRect 0 0 16 16 $ink
Set-SpriteRect 5 4 6 8 $skin
Set-SpriteRect 3 2 10 3 $red
Set-SpriteRect 5 0 8 3 $red
Set-SpriteRect 3 5 3 7 $red
Set-SpriteRect 6 7 1 1 $ink
Set-SpriteRect 9 7 1 1 $ink
Set-SpriteRect 5 6 2 1 $red
Set-SpriteRect 7 10 3 1 $red
Set-SpriteRect 4 12 8 4 $red
Set-SpriteRect 7 12 2 4 $ivory

$small = [System.Drawing.Bitmap]::new(
    16,
    16,
    [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
)
for ($pixelY = 0; $pixelY -lt 16; $pixelY++) {
    for ($pixelX = 0; $pixelX -lt 16; $pixelX++) {
        $pixelColor = $grid[$pixelY * 16 + $pixelX]
        $small.SetPixel($pixelX, $pixelY, $pixelColor)
    }
}

$large = [System.Drawing.Bitmap]::new(
    512,
    512,
    [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
)
$graphics = [System.Drawing.Graphics]::FromImage($large)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$graphics.DrawImage(
    $small,
    [System.Drawing.Rectangle]::new(0, 0, 512, 512),
    0,
    0,
    16,
    16,
    [System.Drawing.GraphicsUnit]::Pixel
)
$large.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$large.Dispose()
$small.Dispose()

Write-Output $outputPath
