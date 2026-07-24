Add-Type -AssemblyName System.Drawing

$outputPath = Join-Path $PSScriptRoot "..\SukebanMahjong\Assets.xcassets\AppIcon.appiconset\AppIcon.png"
$ink = [System.Drawing.Color]::FromArgb(255, 7, 10, 20)
$felt = [System.Drawing.Color]::FromArgb(255, 10, 84, 62)
$feltLight = [System.Drawing.Color]::FromArgb(255, 18, 126, 84)
$red = [System.Drawing.Color]::FromArgb(255, 211, 30, 45)
$ivory = [System.Drawing.Color]::FromArgb(255, 246, 236, 194)
$gold = [System.Drawing.Color]::FromArgb(255, 239, 165, 35)
$blue = [System.Drawing.Color]::FromArgb(255, 34, 88, 180)

$grid = [System.Drawing.Color[]]::new(32 * 32)

function Set-Rect(
    [int]$left,
    [int]$top,
    [int]$width,
    [int]$height,
    [System.Drawing.Color]$color
) {
    for ($row = $top; $row -lt ($top + $height); $row++) {
        for ($column = $left; $column -lt ($left + $width); $column++) {
            $grid[$row * 32 + $column] = $color
        }
    }
}

function Set-Tile([int]$tileOrigin) {
    Set-Rect ($tileOrigin + 1) 5 8 18 $ink
    Set-Rect $tileOrigin 4 8 17 $ink
    Set-Rect ($tileOrigin + 1) 5 6 14 $ivory
    Set-Rect ($tileOrigin + 1) 19 7 2 $gold
}

Set-Rect 0 0 32 32 $ink
Set-Rect 1 1 30 30 $gold
Set-Rect 2 2 28 28 $felt
Set-Rect 3 3 26 1 $feltLight

# 中・發の大きな字牌。
Set-Tile 12
Set-Tile 21
Set-Rect 13 5 8 18 $ink
Set-Rect 12 4 8 17 $ink
Set-Rect 13 5 6 14 $ivory
Set-Rect 13 19 7 2 $gold

Set-Rect 14 7 5 1 $red
Set-Rect 14 8 1 8 $red
Set-Rect 18 8 1 8 $red
Set-Rect 14 12 5 1 $red
Set-Rect 14 16 5 1 $red
Set-Rect 16 6 1 12 $red

Set-Rect 23 7 5 1 $feltLight
Set-Rect 25 6 1 3 $feltLight
Set-Rect 23 10 5 1 $feltLight
Set-Rect 24 11 1 5 $feltLight
Set-Rect 27 11 1 5 $feltLight
Set-Rect 23 13 5 1 $feltLight
Set-Rect 23 16 2 1 $feltLight
Set-Rect 27 16 2 1 $feltLight

# 左側の一筒。赤青の点と中央の金輪で数牌を表す。
Set-Rect 5 8 2 2 $red
Set-Rect 8 8 2 2 $red
Set-Rect 5 12 2 2 $blue
Set-Rect 8 12 2 2 $red
Set-Rect 5 16 2 2 $red
Set-Rect 8 16 2 2 $red
Set-Rect 6 11 3 3 $gold
Set-Rect 7 12 1 1 $ink

# 手牌六枚と赤いリーチ棒。
Set-Rect 4 23 4 5 $ink
Set-Rect 5 24 2 3 $ivory
Set-Rect 8 23 4 5 $ink
Set-Rect 9 24 2 3 $ivory
Set-Rect 12 23 4 5 $ink
Set-Rect 13 24 2 3 $ivory
Set-Rect 16 23 4 5 $ink
Set-Rect 17 24 2 3 $ivory
Set-Rect 20 23 4 5 $ink
Set-Rect 21 24 2 3 $ivory
Set-Rect 24 23 4 5 $ink
Set-Rect 25 24 2 3 $ivory
Set-Rect 6 29 20 1 $ivory
Set-Rect 7 29 18 1 $red
Set-Rect 15 29 2 1 $ivory

$small = [System.Drawing.Bitmap]::new(
    32,
    32,
    [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
)
for ($row = 0; $row -lt 32; $row++) {
    for ($column = 0; $column -lt 32; $column++) {
        $pixelColor = $grid[$row * 32 + $column]
        $small.SetPixel($column, $row, $pixelColor)
    }
}

$large = [System.Drawing.Bitmap]::new(
    1024,
    1024,
    [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
)
$graphics = [System.Drawing.Graphics]::FromImage($large)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$graphics.DrawImage(
    $small,
    [System.Drawing.Rectangle]::new(0, 0, 1024, 1024),
    0,
    0,
    32,
    32,
    [System.Drawing.GraphicsUnit]::Pixel
)
$large.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$large.Dispose()
$small.Dispose()

Write-Output $outputPath
