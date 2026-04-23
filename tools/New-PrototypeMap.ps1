[CmdletBinding()]
param(
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $ProjectRoot = (Resolve-Path (Join-Path $scriptDir "..")).Path
}

Add-Type -AssemblyName System.Drawing

$assetsDir = Join-Path $ProjectRoot "assets\tiles"
$mapsDir = Join-Path $ProjectRoot "maps"
$docsDir = Join-Path $ProjectRoot "docs"

foreach ($dir in @($assetsDir, $mapsDir, $docsDir)) {
    [void](New-Item -ItemType Directory -Path $dir -Force)
}

$groundTilesetPath = Join-Path $assetsDir "modern-office-ground.png"
$collisionTilesetPath = Join-Path $assetsDir "modern-office-collision.png"
$mapPath = Join-Path $mapsDir "ninja-office-prototype.tmj"
$mapJsonPath = Join-Path $mapsDir "ninja-office-prototype.json"
$previewPath = Join-Path $docsDir "layout-preview.svg"
$scenePreviewPath = Join-Path $docsDir "modern-office-preview.png"

$tileSize = 32
$mapWidth = 32
$mapHeight = 20
$sceneWidth = $mapWidth * $tileSize
$sceneHeight = $mapHeight * $tileSize

function New-Color {
    param(
        [string]$Hex,
        [int]$Alpha = 255
    )

    $color = [System.Drawing.ColorTranslator]::FromHtml($Hex)
    return [System.Drawing.Color]::FromArgb($Alpha, $color.R, $color.G, $color.B)
}

function New-Brush {
    param(
        [string]$Hex,
        [int]$Alpha = 255
    )

    return [System.Drawing.SolidBrush]::new((New-Color -Hex $Hex -Alpha $Alpha))
}

function New-Pen {
    param(
        [string]$Hex,
        [float]$Width = 1,
        [int]$Alpha = 255
    )

    return [System.Drawing.Pen]::new((New-Color -Hex $Hex -Alpha $Alpha), $Width)
}

function New-RoundedPath {
    param(
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [float]$Radius
    )

    $diameter = [Math]::Min($Radius * 2, [Math]::Min($Width, $Height))
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()

    if ($diameter -le 0) {
        $path.AddRectangle([System.Drawing.RectangleF]::new($X, $Y, $Width, $Height))
        return $path
    }

    $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
    $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
    $path.AddArc($X + $Width - $diameter, $Y + $Height - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function Fill-RoundedRect {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [float]$Radius,
        [string]$Hex,
        [int]$Alpha = 255
    )

    $path = New-RoundedPath -X $X -Y $Y -Width $Width -Height $Height -Radius $Radius
    $brush = New-Brush -Hex $Hex -Alpha $Alpha

    try {
        $Graphics.FillPath($brush, $path)
    }
    finally {
        $brush.Dispose()
        $path.Dispose()
    }
}

function Draw-RoundedRect {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [float]$Radius,
        [string]$Hex,
        [float]$StrokeWidth = 1,
        [int]$Alpha = 255
    )

    $path = New-RoundedPath -X $X -Y $Y -Width $Width -Height $Height -Radius $Radius
    $pen = New-Pen -Hex $Hex -Width $StrokeWidth -Alpha $Alpha

    try {
        $Graphics.DrawPath($pen, $path)
    }
    finally {
        $pen.Dispose()
        $path.Dispose()
    }
}

function Fill-Rect {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [string]$Hex,
        [int]$Alpha = 255
    )

    $brush = New-Brush -Hex $Hex -Alpha $Alpha

    try {
        $Graphics.FillRectangle($brush, $X, $Y, $Width, $Height)
    }
    finally {
        $brush.Dispose()
    }
}

function Fill-Ellipse {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [string]$Hex,
        [int]$Alpha = 255
    )

    $brush = New-Brush -Hex $Hex -Alpha $Alpha

    try {
        $Graphics.FillEllipse($brush, $X, $Y, $Width, $Height)
    }
    finally {
        $brush.Dispose()
    }
}

function Draw-Line {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X1,
        [float]$Y1,
        [float]$X2,
        [float]$Y2,
        [string]$Hex,
        [float]$Width = 1,
        [int]$Alpha = 255
    )

    $pen = New-Pen -Hex $Hex -Width $Width -Alpha $Alpha

    try {
        $Graphics.DrawLine($pen, $X1, $Y1, $X2, $Y2)
    }
    finally {
        $pen.Dispose()
    }
}

function Draw-SoftShadow {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [float]$Radius,
        [int]$Alpha = 28,
        [float]$OffsetX = 0,
        [float]$OffsetY = 10
    )

    Fill-RoundedRect -Graphics $Graphics -X ($X + $OffsetX) -Y ($Y + $OffsetY) -Width $Width -Height $Height -Radius $Radius -Hex "#0f1720" -Alpha $Alpha
}

function Draw-Plant {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y
    )

    Fill-RoundedRect -Graphics $Graphics -X $X -Y ($Y + 18) -Width 24 -Height 14 -Radius 8 -Hex "#5c6676"
    Fill-Ellipse -Graphics $Graphics -X ($X - 2) -Y 0 -Width 14 -Height 28 -Hex "#56b083"
    Fill-Ellipse -Graphics $Graphics -X ($X + 7) -Y 2 -Width 14 -Height 26 -Hex "#66c596"
    Fill-Ellipse -Graphics $Graphics -X ($X + 14) -Y 0 -Width 14 -Height 28 -Hex "#3ea576"
}

function Draw-Laptop {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y,
        [ValidateSet("north", "south")]
        [string]$Facing
    )

    if ($Facing -eq "north") {
        Fill-RoundedRect -Graphics $Graphics -X $X -Y $Y -Width 22 -Height 14 -Radius 4 -Hex "#1f2630"
        Fill-RoundedRect -Graphics $Graphics -X ($X + 2) -Y ($Y + 2) -Width 18 -Height 10 -Radius 3 -Hex "#7ed4ff"
        Fill-RoundedRect -Graphics $Graphics -X ($X - 1) -Y ($Y + 15) -Width 24 -Height 7 -Radius 3 -Hex "#c7cfdb"
        Draw-Line -Graphics $Graphics -X1 ($X + 2) -Y1 ($Y + 18.5) -X2 ($X + 20) -Y2 ($Y + 18.5) -Hex "#9ea9b9" -Width 1
    }
    else {
        Fill-RoundedRect -Graphics $Graphics -X ($X - 1) -Y $Y -Width 24 -Height 7 -Radius 3 -Hex "#c7cfdb"
        Draw-Line -Graphics $Graphics -X1 ($X + 2) -Y1 ($Y + 3.5) -X2 ($X + 20) -Y2 ($Y + 3.5) -Hex "#9ea9b9" -Width 1
        Fill-RoundedRect -Graphics $Graphics -X $X -Y ($Y + 8) -Width 22 -Height 14 -Radius 4 -Hex "#1f2630"
        Fill-RoundedRect -Graphics $Graphics -X ($X + 2) -Y ($Y + 10) -Width 18 -Height 10 -Radius 3 -Hex "#7ed4ff"
    }
}

function Draw-Chair {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y,
        [ValidateSet("north", "south")]
        [string]$Facing
    )

    Fill-Ellipse -Graphics $Graphics -X ($X + 8) -Y ($Y + 12) -Width 12 -Height 12 -Hex "#44515f" -Alpha 80

    if ($Facing -eq "north") {
        Fill-RoundedRect -Graphics $Graphics -X ($X + 3) -Y ($Y + 10) -Width 22 -Height 12 -Radius 6 -Hex "#d9dde7"
        Fill-RoundedRect -Graphics $Graphics -X ($X + 7) -Y $Y -Width 14 -Height 14 -Radius 5 -Hex "#8896a8"
        Draw-Line -Graphics $Graphics -X1 ($X + 14) -Y1 ($Y + 13) -X2 ($X + 14) -Y2 ($Y + 27) -Hex "#69788c" -Width 2
    }
    else {
        Fill-RoundedRect -Graphics $Graphics -X ($X + 7) -Y ($Y + 12) -Width 14 -Height 14 -Radius 5 -Hex "#8896a8"
        Fill-RoundedRect -Graphics $Graphics -X ($X + 3) -Y ($Y + 4) -Width 22 -Height 12 -Radius 6 -Hex "#d9dde7"
        Draw-Line -Graphics $Graphics -X1 ($X + 14) -Y1 ($Y + 1) -X2 ($X + 14) -Y2 ($Y + 16) -Hex "#69788c" -Width 2
    }
}

function New-Property {
    param(
        [string]$Name,
        [string]$Type,
        $Value
    )

    return [ordered]@{
        name = $Name
        type = $Type
        value = $Value
    }
}

function Mark-CollidableRect {
    param(
        [System.Collections.Generic.HashSet[string]]$Mask,
        [int]$TileX,
        [int]$TileY,
        [int]$TileWidth,
        [int]$TileHeight
    )

    for ($yy = $TileY; $yy -lt ($TileY + $TileHeight); $yy++) {
        for ($xx = $TileX; $xx -lt ($TileX + $TileWidth); $xx++) {
            [void]$Mask.Add("$xx,$yy")
        }
    }
}

function New-SceneBitmap {
    $bitmap = [System.Drawing.Bitmap]::new($sceneWidth, $sceneHeight)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.Clear((New-Color -Hex "#edf2f8"))

    $roomOuterX = 96
    $roomOuterY = 64
    $roomOuterWidth = 832
    $roomOuterHeight = 448

    $roomInnerX = 128
    $roomInnerY = 96
    $roomInnerWidth = 768
    $roomInnerHeight = 384

    $entryMatX = 456
    $entryMatY = 454
    $entryMatWidth = 112
    $entryMatHeight = 28

    $boothX = 726
    $boothY = 120
    $boothWidth = 150
    $boothHeight = 154

    $counterX = 154
    $counterY = 126
    $counterWidth = 156
    $counterHeight = 72

    $deskIslandX = 258
    $deskIslandY = 242
    $deskIslandWidth = 508
    $deskIslandHeight = 118

    try {
        Fill-RoundedRect -Graphics $graphics -X 0 -Y 0 -Width $sceneWidth -Height $sceneHeight -Radius 0 -Hex "#edf2f8"

        Fill-Ellipse -Graphics $graphics -X -90 -Y -60 -Width 340 -Height 260 -Hex "#dfe8f2" -Alpha 220
        Fill-Ellipse -Graphics $graphics -X 780 -Y 470 -Width 300 -Height 220 -Hex "#dbe7f7" -Alpha 220

        Draw-SoftShadow -Graphics $graphics -X $roomOuterX -Y $roomOuterY -Width $roomOuterWidth -Height $roomOuterHeight -Radius 34 -Alpha 34 -OffsetY 18
        Fill-RoundedRect -Graphics $graphics -X $roomOuterX -Y $roomOuterY -Width $roomOuterWidth -Height $roomOuterHeight -Radius 34 -Hex "#d4dcea"
        Fill-RoundedRect -Graphics $graphics -X $roomInnerX -Y $roomInnerY -Width $roomInnerWidth -Height $roomInnerHeight -Radius 28 -Hex "#fbfcfe"
        Draw-RoundedRect -Graphics $graphics -X $roomOuterX -Y $roomOuterY -Width $roomOuterWidth -Height $roomOuterHeight -Radius 34 -Hex "#9eacbe" -StrokeWidth 3
        Draw-RoundedRect -Graphics $graphics -X $roomInnerX -Y $roomInnerY -Width $roomInnerWidth -Height $roomInnerHeight -Radius 28 -Hex "#d8e0eb" -StrokeWidth 2

        for ($x = $roomInnerX + 8; $x -lt ($roomInnerX + $roomInnerWidth - 8); $x += 28) {
            $alpha = if (([int](($x - $roomInnerX) / 28) % 2) -eq 0) { 20 } else { 10 }
            Fill-Rect -Graphics $graphics -X $x -Y $roomInnerY -Width 16 -Height $roomInnerHeight -Hex "#dfe6f0" -Alpha $alpha
        }

        for ($y = $roomInnerY + 28; $y -lt ($roomInnerY + $roomInnerHeight); $y += 58) {
            Draw-Line -Graphics $graphics -X1 ($roomInnerX + 10) -Y1 $y -X2 ($roomInnerX + $roomInnerWidth - 10) -Y2 $y -Hex "#eef2f7" -Width 1
        }

        Fill-RoundedRect -Graphics $graphics -X 230 -Y 208 -Width 566 -Height 182 -Radius 28 -Hex "#dde7f1"
        Fill-RoundedRect -Graphics $graphics -X 248 -Y 226 -Width 530 -Height 146 -Radius 24 -Hex "#e5edf7"
        Fill-RoundedRect -Graphics $graphics -X $entryMatX -Y $entryMatY -Width $entryMatWidth -Height $entryMatHeight -Radius 14 -Hex "#313947"

        Draw-SoftShadow -Graphics $graphics -X $counterX -Y $counterY -Width $counterWidth -Height $counterHeight -Radius 18 -Alpha 20 -OffsetY 10
        Fill-RoundedRect -Graphics $graphics -X $counterX -Y $counterY -Width $counterWidth -Height $counterHeight -Radius 18 -Hex "#6b7a8f"
        Fill-RoundedRect -Graphics $graphics -X ($counterX + 6) -Y $counterY -Width ($counterWidth - 12) -Height 14 -Radius 12 -Hex "#8b9ab0"
        Fill-RoundedRect -Graphics $graphics -X ($counterX + 22) -Y ($counterY + 16) -Width 32 -Height 34 -Radius 10 -Hex "#222a34"
        Fill-Ellipse -Graphics $graphics -X ($counterX + 58) -Y ($counterY + 20) -Width 12 -Height 12 -Hex "#d8e4f4"
        Fill-Ellipse -Graphics $graphics -X ($counterX + 76) -Y ($counterY + 20) -Width 12 -Height 12 -Hex "#d8e4f4"
        Fill-RoundedRect -Graphics $graphics -X ($counterX + 102) -Y ($counterY + 18) -Width 34 -Height 26 -Radius 8 -Hex "#465468"
        Draw-Plant -Graphics $graphics -X ($counterX + 112) -Y ($counterY - 10)

        Draw-SoftShadow -Graphics $graphics -X $boothX -Y $boothY -Width $boothWidth -Height $boothHeight -Radius 20 -Alpha 24 -OffsetY 10
        Draw-RoundedRect -Graphics $graphics -X $boothX -Y $boothY -Width $boothWidth -Height $boothHeight -Radius 20 -Hex "#8fa3bb" -StrokeWidth 4
        Fill-RoundedRect -Graphics $graphics -X ($boothX + 8) -Y ($boothY + 8) -Width ($boothWidth - 16) -Height ($boothHeight - 16) -Radius 16 -Hex "#b9dff6" -Alpha 72
        Draw-Line -Graphics $graphics -X1 ($boothX + 48) -Y1 ($boothY + 8) -X2 ($boothX + 48) -Y2 ($boothY + $boothHeight - 8) -Hex "#a8bfd7" -Width 2 -Alpha 180
        Draw-Line -Graphics $graphics -X1 ($boothX + $boothWidth - 48) -Y1 ($boothY + 8) -X2 ($boothX + $boothWidth - 48) -Y2 ($boothY + $boothHeight - 8) -Hex "#a8bfd7" -Width 2 -Alpha 180
        Fill-RoundedRect -Graphics $graphics -X ($boothX + 28) -Y ($boothY + 40) -Width 32 -Height 56 -Radius 14 -Hex "#aebccc"
        Fill-RoundedRect -Graphics $graphics -X ($boothX + 92) -Y ($boothY + 40) -Width 32 -Height 56 -Radius 14 -Hex "#aebccc"
        Fill-Ellipse -Graphics $graphics -X ($boothX + 56) -Y ($boothY + 72) -Width 36 -Height 36 -Hex "#6a7787"
        Fill-Ellipse -Graphics $graphics -X ($boothX + 63) -Y ($boothY + 79) -Width 22 -Height 22 -Hex "#f6f8fb"

        Draw-SoftShadow -Graphics $graphics -X $deskIslandX -Y $deskIslandY -Width $deskIslandWidth -Height $deskIslandHeight -Radius 30 -Alpha 22 -OffsetY 12
        Fill-RoundedRect -Graphics $graphics -X $deskIslandX -Y $deskIslandY -Width $deskIslandWidth -Height $deskIslandHeight -Radius 30 -Hex "#4f5d6d"
        Fill-RoundedRect -Graphics $graphics -X ($deskIslandX + 10) -Y ($deskIslandY + 12) -Width ($deskIslandWidth - 20) -Height ($deskIslandHeight - 24) -Radius 24 -Hex "#5d6d7f"
        Fill-RoundedRect -Graphics $graphics -X ($deskIslandX + 24) -Y ($deskIslandY + 50) -Width ($deskIslandWidth - 48) -Height 18 -Radius 9 -Hex "#8aa1ba"
        Fill-RoundedRect -Graphics $graphics -X ($deskIslandX + 60) -Y ($deskIslandY + 84) -Width 388 -Height 10 -Radius 5 -Hex "#d5dde8"
        Fill-RoundedRect -Graphics $graphics -X ($deskIslandX + 60) -Y ($deskIslandY + 24) -Width 388 -Height 10 -Radius 5 -Hex "#d5dde8"

        $stationPositions = @(286, 376, 466, 556, 646)
        foreach ($stationX in $stationPositions) {
            Draw-Laptop -Graphics $graphics -X $stationX -Y 258 -Facing "north"
            Draw-Laptop -Graphics $graphics -X $stationX -Y 308 -Facing "south"
            Draw-Chair -Graphics $graphics -X ($stationX - 4) -Y 210 -Facing "north"
            Draw-Chair -Graphics $graphics -X ($stationX - 4) -Y 342 -Facing "south"
        }

        Fill-RoundedRect -Graphics $graphics -X 470 -Y 274 -Width 84 -Height 54 -Radius 18 -Hex "#95a7bc"
        Fill-RoundedRect -Graphics $graphics -X 492 -Y 288 -Width 40 -Height 26 -Radius 13 -Hex "#ecf2f7"

        Draw-Plant -Graphics $graphics -X 184 -Y 410
        Draw-Plant -Graphics $graphics -X 820 -Y 408
        Draw-Plant -Graphics $graphics -X 816 -Y 168

        Fill-RoundedRect -Graphics $graphics -X 160 -Y 386 -Width 126 -Height 52 -Radius 18 -Hex "#cfd8e4"
        Fill-RoundedRect -Graphics $graphics -X 172 -Y 398 -Width 102 -Height 12 -Radius 6 -Hex "#90a1b7"
        Fill-RoundedRect -Graphics $graphics -X 172 -Y 416 -Width 78 -Height 10 -Radius 5 -Hex "#eff4fa"

        Fill-RoundedRect -Graphics $graphics -X 476 -Y 482 -Width 72 -Height 22 -Radius 10 -Hex "#8db3d3" -Alpha 150
        Draw-RoundedRect -Graphics $graphics -X 476 -Y 482 -Width 72 -Height 22 -Radius 10 -Hex "#5d7c97" -StrokeWidth 2
        Draw-Line -Graphics $graphics -X1 512 -Y1 482 -X2 512 -Y2 504 -Hex "#5d7c97" -Width 2
    }
    finally {
        $graphics.Dispose()
    }

    return $bitmap
}

function Write-GroundTileset {
    param([System.Drawing.Bitmap]$SceneBitmap)

    $tileCount = $mapWidth * $mapHeight
    $columns = 16
    $rows = [Math]::Ceiling($tileCount / $columns)
    $tilesetBitmap = [System.Drawing.Bitmap]::new($columns * $tileSize, $rows * $tileSize)
    $graphics = [System.Drawing.Graphics]::FromImage($tilesetBitmap)
    $data = [System.Collections.Generic.List[int]]::new()

    try {
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.Clear([System.Drawing.Color]::Transparent)

        $tileIndex = 0
        for ($tileY = 0; $tileY -lt $mapHeight; $tileY++) {
            for ($tileX = 0; $tileX -lt $mapWidth; $tileX++) {
                $srcRect = [System.Drawing.Rectangle]::new($tileX * $tileSize, $tileY * $tileSize, $tileSize, $tileSize)
                $dstRect = [System.Drawing.Rectangle]::new(($tileIndex % $columns) * $tileSize, [Math]::Floor($tileIndex / $columns) * $tileSize, $tileSize, $tileSize)
                $graphics.DrawImage($SceneBitmap, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
                $data.Add($tileIndex + 1)
                $tileIndex++
            }
        }

        $tilesetBitmap.Save($groundTilesetPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $graphics.Dispose()
        $tilesetBitmap.Dispose()
    }

    return [ordered]@{
        Data = @($data)
        Tileset = [ordered]@{
            columns = $columns
            firstgid = 1
            image = "../assets/tiles/modern-office-ground.png"
            imageheight = $rows * $tileSize
            imagewidth = $columns * $tileSize
            margin = 0
            name = "modern-office-ground"
            spacing = 0
            tilecount = $tileCount
            tiledversion = "1.11.0"
            tileheight = $tileSize
            tilewidth = $tileSize
        }
    }
}

function Write-CollisionTileset {
    param([System.Collections.Generic.HashSet[string]]$CollisionMask)

    $bitmap = [System.Drawing.Bitmap]::new($tileSize, $tileSize)
    $bitmap.Save($collisionTilesetPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()

    $collisionGid = ($mapWidth * $mapHeight) + 1
    $data = ,0 * ($mapWidth * $mapHeight)

    for ($tileY = 0; $tileY -lt $mapHeight; $tileY++) {
        for ($tileX = 0; $tileX -lt $mapWidth; $tileX++) {
            if ($CollisionMask.Contains("$tileX,$tileY")) {
                $data[($tileY * $mapWidth) + $tileX] = $collisionGid
            }
        }
    }

    return [ordered]@{
        Data = $data
        Tileset = [ordered]@{
            columns = 1
            firstgid = $collisionGid
            image = "../assets/tiles/modern-office-collision.png"
            imageheight = $tileSize
            imagewidth = $tileSize
            margin = 0
            name = "modern-office-collision"
            spacing = 0
            tilecount = 1
            tiledversion = "1.11.0"
            tileheight = $tileSize
            tilewidth = $tileSize
            tiles = @(
                [ordered]@{
                    id = 0
                    properties = @(
                        (New-Property -Name "collides" -Type "bool" -Value $true)
                    )
                }
            )
        }
    }
}

function New-CollisionMask {
    $mask = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($x in 3..28) {
        [void]$mask.Add("$x,2")
    }

    foreach ($y in 2..15) {
        [void]$mask.Add("3,$y")
        [void]$mask.Add("28,$y")
    }

    foreach ($x in 3..28) {
        if ($x -notin 15, 16) {
            [void]$mask.Add("$x,15")
        }
    }

    Mark-CollidableRect -Mask $mask -TileX 5 -TileY 4 -TileWidth 5 -TileHeight 2
    Mark-CollidableRect -Mask $mask -TileX 8 -TileY 7 -TileWidth 16 -TileHeight 5
    Mark-CollidableRect -Mask $mask -TileX 22 -TileY 4 -TileWidth 5 -TileHeight 1
    Mark-CollidableRect -Mask $mask -TileX 22 -TileY 4 -TileWidth 1 -TileHeight 5
    Mark-CollidableRect -Mask $mask -TileX 26 -TileY 4 -TileWidth 1 -TileHeight 5
    Mark-CollidableRect -Mask $mask -TileX 22 -TileY 5 -TileWidth 1 -TileHeight 3
    Mark-CollidableRect -Mask $mask -TileX 26 -TileY 5 -TileWidth 1 -TileHeight 3
    Mark-CollidableRect -Mask $mask -TileX 23 -TileY 6 -TileWidth 2 -TileHeight 1
    Mark-CollidableRect -Mask $mask -TileX 5 -TileY 12 -TileWidth 4 -TileHeight 2
    [void]$mask.Add("5,13")
    [void]$mask.Add("25,13")
    [void]$mask.Add("25,5")

    return $mask
}

function Write-MapFile {
    $sceneBitmap = New-SceneBitmap

    try {
        $ground = Write-GroundTileset -SceneBitmap $sceneBitmap
        $collision = Write-CollisionTileset -CollisionMask (New-CollisionMask)
        $sceneBitmap.Save($scenePreviewPath, [System.Drawing.Imaging.ImageFormat]::Png)

        $startLayerData = ,0 * ($mapWidth * $mapHeight)
        $startLayerData[(14 * $mapWidth) + 15] = 1
        $startLayerData[(14 * $mapWidth) + 16] = 1

        $layers = @(
            [ordered]@{
                data = $ground.Data
                height = $mapHeight
                id = 1
                name = "Ground"
                opacity = 1
                type = "tilelayer"
                visible = $true
                width = $mapWidth
                x = 0
                y = 0
            },
            [ordered]@{
                data = $collision.Data
                height = $mapHeight
                id = 2
                name = "Collision"
                opacity = 1
                type = "tilelayer"
                visible = $true
                width = $mapWidth
                x = 0
                y = 0
            },
            [ordered]@{
                data = $startLayerData
                height = $mapHeight
                id = 3
                name = "start"
                opacity = 1
                type = "tilelayer"
                visible = $false
                width = $mapWidth
                x = 0
                y = 0
            },
            [ordered]@{
                draworder = "topdown"
                id = 4
                name = "floorLayer"
                objects = @()
                opacity = 1
                type = "objectgroup"
                visible = $true
                x = 0
                y = 0
            },
            [ordered]@{
                draworder = "topdown"
                id = 5
                name = "Areas"
                objects = @()
                opacity = 1
                type = "objectgroup"
                visible = $true
                x = 0
                y = 0
            }
        )

        $map = [ordered]@{
            compressionlevel = -1
            height = $mapHeight
            infinite = $false
            layers = $layers
            nextlayerid = 6
            nextobjectid = 1
            orientation = "orthogonal"
            properties = @(
                (New-Property -Name "mapName" -Type "string" -Value "Modern Office Prototype"),
                (New-Property -Name "mapDescription" -Type "string" -Value "Escritorio moderno com 10 estacoes, notebooks, ilha central e booth privado."),
                (New-Property -Name "mapCopyright" -Type "string" -Value "Original modern office prototype built for WorkAdventure.")
            )
            renderorder = "right-down"
            tiledversion = "1.11.0"
            tileheight = $tileSize
            tilesets = @(
                $ground.Tileset,
                $collision.Tileset
            )
            tilewidth = $tileSize
            type = "map"
            version = "1.10"
            width = $mapWidth
        }

        $json = $map | ConvertTo-Json -Depth 100
        Set-Content -Path $mapPath -Value $json -Encoding utf8
        Set-Content -Path $mapJsonPath -Value $json -Encoding utf8
    }
    finally {
        $sceneBitmap.Dispose()
    }
}

function Write-LayoutPreview {
    $svg = @'
<svg xmlns="http://www.w3.org/2000/svg" width="980" height="640" viewBox="0 0 980 640">
  <rect width="980" height="640" fill="#eef3f8"/>
  <rect x="110" y="62" width="760" height="470" rx="34" fill="#d5deea" stroke="#9fadc0" stroke-width="8"/>
  <rect x="140" y="92" width="700" height="410" rx="28" fill="#fbfcfe" stroke="#dbe3ee" stroke-width="4"/>
  <rect x="204" y="224" width="572" height="182" rx="28" fill="#dce5f0"/>
  <rect x="252" y="258" width="476" height="106" rx="26" fill="#586678"/>
  <rect x="274" y="274" width="432" height="16" rx="8" fill="#d7dfe9"/>
  <rect x="274" y="332" width="432" height="16" rx="8" fill="#d7dfe9"/>

  <g fill="#1f2630">
    <rect x="292" y="264" width="22" height="14" rx="4"/>
    <rect x="382" y="264" width="22" height="14" rx="4"/>
    <rect x="472" y="264" width="22" height="14" rx="4"/>
    <rect x="562" y="264" width="22" height="14" rx="4"/>
    <rect x="652" y="264" width="22" height="14" rx="4"/>
    <rect x="292" y="336" width="22" height="14" rx="4"/>
    <rect x="382" y="336" width="22" height="14" rx="4"/>
    <rect x="472" y="336" width="22" height="14" rx="4"/>
    <rect x="562" y="336" width="22" height="14" rx="4"/>
    <rect x="652" y="336" width="22" height="14" rx="4"/>
  </g>

  <g fill="#7ed4ff">
    <rect x="294" y="266" width="18" height="10" rx="3"/>
    <rect x="384" y="266" width="18" height="10" rx="3"/>
    <rect x="474" y="266" width="18" height="10" rx="3"/>
    <rect x="564" y="266" width="18" height="10" rx="3"/>
    <rect x="654" y="266" width="18" height="10" rx="3"/>
    <rect x="294" y="338" width="18" height="10" rx="3"/>
    <rect x="384" y="338" width="18" height="10" rx="3"/>
    <rect x="474" y="338" width="18" height="10" rx="3"/>
    <rect x="564" y="338" width="18" height="10" rx="3"/>
    <rect x="654" y="338" width="18" height="10" rx="3"/>
  </g>

  <g fill="#d9dde7">
    <rect x="286" y="216" width="28" height="14" rx="6"/>
    <rect x="376" y="216" width="28" height="14" rx="6"/>
    <rect x="466" y="216" width="28" height="14" rx="6"/>
    <rect x="556" y="216" width="28" height="14" rx="6"/>
    <rect x="646" y="216" width="28" height="14" rx="6"/>
    <rect x="286" y="374" width="28" height="14" rx="6"/>
    <rect x="376" y="374" width="28" height="14" rx="6"/>
    <rect x="466" y="374" width="28" height="14" rx="6"/>
    <rect x="556" y="374" width="28" height="14" rx="6"/>
    <rect x="646" y="374" width="28" height="14" rx="6"/>
  </g>

  <rect x="702" y="120" width="136" height="150" rx="20" fill="#b8dff6" fill-opacity="0.45" stroke="#8fa4bb" stroke-width="4"/>
  <rect x="724" y="160" width="28" height="54" rx="12" fill="#afbbc9"/>
  <rect x="788" y="160" width="28" height="54" rx="12" fill="#afbbc9"/>
  <circle cx="770" cy="212" r="18" fill="#6a7787"/>
  <circle cx="770" cy="212" r="11" fill="#f6f8fb"/>

  <rect x="154" y="128" width="148" height="72" rx="18" fill="#6b7a8f"/>
  <rect x="160" y="128" width="136" height="14" rx="10" fill="#8d9bb0"/>
  <rect x="178" y="148" width="32" height="34" rx="10" fill="#222a34"/>
  <circle cx="225" cy="160" r="6" fill="#d8e4f4"/>
  <circle cx="243" cy="160" r="6" fill="#d8e4f4"/>

  <rect x="450" y="502" width="80" height="24" rx="12" fill="#313947"/>
  <rect x="462" y="532" width="56" height="12" rx="6" fill="#8db3d3"/>

  <text x="490" y="142" font-family="Aptos, Segoe UI, sans-serif" font-size="30" font-weight="700" text-anchor="middle" fill="#243041">Modern shared office</text>
  <text x="490" y="440" font-family="Aptos, Segoe UI, sans-serif" font-size="22" font-weight="700" text-anchor="middle" fill="#3a4758">10 estacoes em uma ilha central com notebooks</text>
  <text x="770" y="298" font-family="Aptos, Segoe UI, sans-serif" font-size="20" font-weight="700" text-anchor="middle" fill="#3a4758">Booth privado</text>
  <text x="228" y="226" font-family="Aptos, Segoe UI, sans-serif" font-size="18" font-weight="700" text-anchor="middle" fill="#3a4758">Coffee bar</text>
  <text x="490" y="574" font-family="Aptos, Segoe UI, sans-serif" font-size="18" font-weight="700" text-anchor="middle" fill="#3a4758">Entrada central</text>
</svg>
'@

    Set-Content -Path $previewPath -Value $svg -Encoding utf8
}

Write-MapFile
Write-LayoutPreview

Write-Host "Tileset principal criado em: $groundTilesetPath"
Write-Host "Tileset de colisao criado em: $collisionTilesetPath"
Write-Host "Mapa criado em: $mapPath"
Write-Host "Mapa JSON criado em: $mapJsonPath"
Write-Host "Preview criado em: $previewPath"
Write-Host "Preview raster criado em: $scenePreviewPath"
