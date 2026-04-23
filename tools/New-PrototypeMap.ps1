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

$assetsDir = Join-Path $ProjectRoot "assets\tiles"
$mapsDir = Join-Path $ProjectRoot "maps"
$docsDir = Join-Path $ProjectRoot "docs"

foreach ($dir in @($assetsDir, $mapsDir, $docsDir)) {
    [void](New-Item -ItemType Directory -Path $dir -Force)
}

$tilesetPath = Join-Path $assetsDir "ninja-office-tiles.png"
$mapPath = Join-Path $mapsDir "ninja-office-prototype.tmj"
$mapJsonPath = Join-Path $mapsDir "ninja-office-prototype.json"
$previewPath = Join-Path $docsDir "layout-preview.svg"

$tileSize = 32
$mapWidth = 28
$mapHeight = 18

$gidTatami = 1
$gidWood = 2
$gidGrass = 3
$gidStone = 4
$gidWall = 5
$gidDoor = 6
$gidDesk = 7
$gidChair = 8
$gidSharedTable = 9
$gidMeetingTable = 10
$gidPlant = 11
$gidBanner = 12

function New-ColorBrush {
    param([string]$Hex)
    return [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($Hex))
}

function New-ColorPen {
    param(
        [string]$Hex,
        [float]$Width = 1
    )
    return [System.Drawing.Pen]::new([System.Drawing.ColorTranslator]::FromHtml($Hex), $Width)
}

function Get-TileRect {
    param([int]$TileIndex)
    $columns = 4
    $x = ($TileIndex % $columns) * $tileSize
    $y = [math]::Floor($TileIndex / $columns) * $tileSize
    return [System.Drawing.Rectangle]::new($x, $y, $tileSize, $tileSize)
}

function Fill-Rect {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Rectangle]$Rect,
        [string]$Hex
    )
    $brush = New-ColorBrush $Hex
    try {
        $Graphics.FillRectangle($brush, $Rect)
    }
    finally {
        $brush.Dispose()
    }
}

function Draw-Rect {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Rectangle]$Rect,
        [string]$Hex,
        [float]$Width = 1
    )
    $pen = New-ColorPen -Hex $Hex -Width $Width
    try {
        $Graphics.DrawRectangle($pen, $Rect)
    }
    finally {
        $pen.Dispose()
    }
}

function Write-TilesetImage {
    Add-Type -AssemblyName System.Drawing

    $bitmap = [System.Drawing.Bitmap]::new($tileSize * 4, $tileSize * 3)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

    try {
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

        $rect = Get-TileRect 0
        Fill-Rect $graphics $rect "#d8c89a"
        for ($y = 0; $y -lt $tileSize; $y += 8) {
            Draw-Rect $graphics ([System.Drawing.Rectangle]::new($rect.X + 2, $rect.Y + $y + 1, $tileSize - 5, 4)) "#8ca367"
        }
        Draw-Rect $graphics $rect "#9a8252"

        $rect = Get-TileRect 1
        Fill-Rect $graphics $rect "#8a5a3b"
        for ($x = 4; $x -lt $tileSize; $x += 6) {
            $pen = New-ColorPen "#6d4329"
            try {
                $graphics.DrawLine($pen, $rect.X + $x, $rect.Y, $rect.X + $x - 2, $rect.Y + $tileSize)
            }
            finally {
                $pen.Dispose()
            }
        }
        Draw-Rect $graphics $rect "#5f3823"

        $rect = Get-TileRect 2
        Fill-Rect $graphics $rect "#4c8b47"
        foreach ($dot in @(
            @(5, 7), @(12, 15), @(22, 9), @(25, 23), @(9, 25), @(18, 20)
        )) {
            Fill-Rect $graphics ([System.Drawing.Rectangle]::new($rect.X + $dot[0], $rect.Y + $dot[1], 3, 3)) "#6fba5d"
        }
        Draw-Rect $graphics $rect "#2f5c2c"

        $rect = Get-TileRect 3
        Fill-Rect $graphics $rect "#7d7a74"
        foreach ($stone in @(
            [System.Drawing.Rectangle]::new($rect.X + 4, $rect.Y + 5, 8, 6),
            [System.Drawing.Rectangle]::new($rect.X + 15, $rect.Y + 10, 10, 7),
            [System.Drawing.Rectangle]::new($rect.X + 8, $rect.Y + 20, 12, 6),
            [System.Drawing.Rectangle]::new($rect.X + 24, $rect.Y + 19, 5, 5)
        )) {
            Fill-Rect $graphics $stone "#9c9991"
            Draw-Rect $graphics $stone "#66635d"
        }
        Draw-Rect $graphics $rect "#5f5c58"

        $rect = Get-TileRect 4
        Fill-Rect $graphics $rect "#d7d0bb"
        Fill-Rect $graphics ([System.Drawing.Rectangle]::new($rect.X + 4, $rect.Y + 4, $tileSize - 8, $tileSize - 8)) "#efe8d2"
        foreach ($offset in @(10, 20)) {
            $pen = New-ColorPen "#705d44"
            try {
                $graphics.DrawLine($pen, $rect.X + $offset, $rect.Y + 4, $rect.X + $offset, $rect.Y + $tileSize - 4)
                $graphics.DrawLine($pen, $rect.X + 4, $rect.Y + $offset, $rect.X + $tileSize - 4, $rect.Y + $offset)
            }
            finally {
                $pen.Dispose()
            }
        }
        Draw-Rect $graphics $rect "#5d4b36" 2

        $rect = Get-TileRect 5
        Fill-Rect $graphics $rect "#d8c8a7"
        Fill-Rect $graphics ([System.Drawing.Rectangle]::new($rect.X + 5, $rect.Y, $tileSize - 10, $tileSize)) "#f3ebd8"
        $pen = New-ColorPen "#6b573d" 2
        try {
            $graphics.DrawLine($pen, $rect.X + 5, $rect.Y + 6, $rect.X + 5, $rect.Y + $tileSize - 6)
            $graphics.DrawLine($pen, $rect.X + $tileSize - 5, $rect.Y + 6, $rect.X + $tileSize - 5, $rect.Y + $tileSize - 6)
            $graphics.DrawLine($pen, $rect.X + 5, $rect.Y + 6, $rect.X + $tileSize - 5, $rect.Y + 6)
            $graphics.DrawLine($pen, $rect.X + 5, $rect.Y + $tileSize - 6, $rect.X + $tileSize - 5, $rect.Y + $tileSize - 6)
        }
        finally {
            $pen.Dispose()
        }
        Draw-Rect $graphics $rect "#705d44"

        $rect = Get-TileRect 6
        Fill-Rect $graphics $rect "#74472d"
        Fill-Rect $graphics ([System.Drawing.Rectangle]::new($rect.X + 3, $rect.Y + 4, $tileSize - 6, $tileSize - 10)) "#a76f4d"
        Fill-Rect $graphics ([System.Drawing.Rectangle]::new($rect.X + 6, $rect.Y + 8, $tileSize - 12, $tileSize - 16)) "#c18d68"
        Fill-Rect $graphics ([System.Drawing.Rectangle]::new($rect.X + 11, $rect.Y + 11, 10, 6)) "#d9e7f2"
        Draw-Rect $graphics $rect "#563221"

        $rect = Get-TileRect 7
        Fill-Rect $graphics $rect "#8b5b3d"
        Fill-Rect $graphics ([System.Drawing.Rectangle]::new($rect.X + 8, $rect.Y + 10, 16, 10)) "#bf8b63"
        foreach ($leg in @(10, 21)) {
            Fill-Rect $graphics ([System.Drawing.Rectangle]::new($rect.X + $leg, $rect.Y + 20, 3, 7)) "#5f3823"
        }
        Draw-Rect $graphics $rect "#563221"

        $rect = Get-TileRect 8
        Fill-Rect $graphics $rect "#7b522d"
        Fill-Rect $graphics ([System.Drawing.Rectangle]::new($rect.X + 6, $rect.Y + 6, 20, 20)) "#b88551"
        Fill-Rect $graphics ([System.Drawing.Rectangle]::new($rect.X + 10, $rect.Y + 10, 12, 12)) "#d0a66f"
        Draw-Rect $graphics $rect "#523418"

        $rect = Get-TileRect 9
        Fill-Rect $graphics $rect "#7c5332"
        Fill-Rect $graphics ([System.Drawing.Rectangle]::new($rect.X + 3, $rect.Y + 9, $tileSize - 6, 14)) "#bb8652"
        Fill-Rect $graphics ([System.Drawing.Rectangle]::new($rect.X + 7, $rect.Y + 12, $tileSize - 14, 8)) "#d2a76b"
        Draw-Rect $graphics $rect "#523418"

        $rect = Get-TileRect 10
        Fill-Rect $graphics $rect "#5f4a2f"
        Fill-Rect $graphics ([System.Drawing.Rectangle]::new($rect.X + 10, $rect.Y + 18, 12, 8)) "#7d5d36"
        Fill-Rect $graphics ([System.Drawing.Rectangle]::new($rect.X + 6, $rect.Y + 5, 20, 16)) "#3c8d47"
        Fill-Rect $graphics ([System.Drawing.Rectangle]::new($rect.X + 10, $rect.Y + 2, 12, 10)) "#57b15f"
        Draw-Rect $graphics $rect "#3f2d18"

        $rect = Get-TileRect 11
        Fill-Rect $graphics $rect "#70492d"
        Fill-Rect $graphics ([System.Drawing.Rectangle]::new($rect.X + 6, $rect.Y + 4, $tileSize - 12, $tileSize - 8)) "#b53c2f"
        Fill-Rect $graphics ([System.Drawing.Rectangle]::new($rect.X + 12, $rect.Y + 8, 8, 16)) "#f0d6a1"
        Draw-Rect $graphics $rect "#512f1a"
    }
    finally {
        $graphics.Dispose()
        $bitmap.Save($tilesetPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $bitmap.Dispose()
    }
}

function New-LayerData {
    param([int]$DefaultGid = 0)
    $data = ,0 * ($mapWidth * $mapHeight)
    if ($DefaultGid -ne 0) {
        for ($i = 0; $i -lt $data.Length; $i++) {
            $data[$i] = $DefaultGid
        }
    }
    return $data
}

function Set-Tile {
    param(
        $Data,
        [int]$X,
        [int]$Y,
        [int]$Gid
    )
    if ($X -lt 0 -or $X -ge $mapWidth -or $Y -lt 0 -or $Y -ge $mapHeight) {
        throw "Tile fora do mapa: ($X,$Y)"
    }
    $Data[($Y * $mapWidth) + $X] = $Gid
}

function Fill-TileRect {
    param(
        $Data,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [int]$Gid
    )
    for ($yy = $Y; $yy -lt ($Y + $Height); $yy++) {
        for ($xx = $X; $xx -lt ($X + $Width); $xx++) {
            Set-Tile -Data $Data -X $xx -Y $yy -Gid $Gid
        }
    }
}

function Set-HLine {
    param(
        $Data,
        [int]$X,
        [int]$Y,
        [int]$Length,
        [int]$Gid
    )
    for ($xx = $X; $xx -lt ($X + $Length); $xx++) {
        Set-Tile -Data $Data -X $xx -Y $Y -Gid $Gid
    }
}

function Set-VLine {
    param(
        $Data,
        [int]$X,
        [int]$Y,
        [int]$Length,
        [int]$Gid
    )
    for ($yy = $Y; $yy -lt ($Y + $Length); $yy++) {
        Set-Tile -Data $Data -X $X -Y $yy -Gid $Gid
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

function New-RectangleArea {
    param(
        [int]$Id,
        [string]$Name,
        [int]$TileX,
        [int]$TileY,
        [int]$TileWidth,
        [int]$TileHeight,
        [hashtable[]]$Properties
    )
    return [ordered]@{
        class = "area"
        height = $TileHeight * $tileSize
        id = $Id
        name = $Name
        properties = $Properties
        rotation = 0
        type = "area"
        visible = $true
        width = $TileWidth * $tileSize
        x = $TileX * $tileSize
        y = $TileY * $tileSize
    }
}

function Write-MapFile {
    $ground = New-LayerData -DefaultGid $gidGrass
    $details = New-LayerData
    $furniture = New-LayerData
    $spawnLayerData = New-LayerData

    Fill-TileRect -Data $ground -X 4 -Y 2 -Width 20 -Height 13 -Gid $gidWood
    Fill-TileRect -Data $details -X 13 -Y 14 -Width 2 -Height 4 -Gid $gidStone

    Set-HLine -Data $furniture -X 4 -Y 2 -Length 20 -Gid $gidWall
    Set-HLine -Data $furniture -X 4 -Y 14 -Length 20 -Gid $gidWall
    Set-VLine -Data $furniture -X 4 -Y 2 -Length 13 -Gid $gidWall
    Set-VLine -Data $furniture -X 23 -Y 2 -Length 13 -Gid $gidWall
    Set-Tile -Data $furniture -X 13 -Y 14 -Gid $gidDoor
    Set-Tile -Data $furniture -X 14 -Y 14 -Gid $gidDoor

    foreach ($x in @(7, 10, 13, 16, 19)) {
        Set-Tile -Data $furniture -X $x -Y 5 -Gid $gidDesk
        Set-Tile -Data $furniture -X $x -Y 6 -Gid $gidChair
        Set-Tile -Data $furniture -X $x -Y 9 -Gid $gidDesk
        Set-Tile -Data $furniture -X $x -Y 10 -Gid $gidChair
    }

    foreach ($coord in @(
        @(6, 4), @(21, 4), @(6, 12), @(21, 12)
    )) {
        Set-Tile -Data $furniture -X $coord[0] -Y $coord[1] -Gid $gidPlant
    }

    foreach ($coord in @(
        @(8, 3), @(12, 3), @(15, 3), @(19, 3)
    )) {
        Set-Tile -Data $furniture -X $coord[0] -Y $coord[1] -Gid $gidBanner
    }

    Fill-TileRect -Data $spawnLayerData -X 13 -Y 13 -Width 2 -Height 1 -Gid $gidWood

    $layers = @(
        [ordered]@{
            data = $ground
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
            data = $details
            height = $mapHeight
            id = 2
            name = "Details"
            opacity = 1
            type = "tilelayer"
            visible = $true
            width = $mapWidth
            x = 0
            y = 0
        },
        [ordered]@{
            data = $furniture
            height = $mapHeight
            id = 3
            name = "Furniture"
            opacity = 1
            type = "tilelayer"
            visible = $true
            width = $mapWidth
            x = 0
            y = 0
        },
        [ordered]@{
            data = $spawnLayerData
            height = $mapHeight
            id = 4
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
            id = 5
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
            id = 6
            name = "Areas"
            objects = @()
            opacity = 1
            type = "objectgroup"
            visible = $true
            x = 0
            y = 0
        }
    )

    $tileset = [ordered]@{
        columns = 4
        firstgid = 1
        image = "../assets/tiles/ninja-office-tiles.png"
        imageheight = 96
        imagewidth = 128
        margin = 0
        name = "ninja-office-tiles"
        spacing = 0
        tilecount = 12
        tiledversion = "1.11.0"
        tileheight = $tileSize
        tilewidth = $tileSize
        tiles = @(
            [ordered]@{ id = 4; properties = @((New-Property -Name "collides" -Type "bool" -Value $true)) },
            [ordered]@{ id = 6; properties = @((New-Property -Name "collides" -Type "bool" -Value $true)) },
            [ordered]@{ id = 7; properties = @((New-Property -Name "collides" -Type "bool" -Value $true)) },
            [ordered]@{ id = 8; properties = @((New-Property -Name "collides" -Type "bool" -Value $true)) },
            [ordered]@{ id = 9; properties = @((New-Property -Name "collides" -Type "bool" -Value $true)) },
            [ordered]@{ id = 10; properties = @((New-Property -Name "collides" -Type "bool" -Value $true)) }
        )
    }

    $map = [ordered]@{
        compressionlevel = -1
        height = $mapHeight
        infinite = $false
        layers = $layers
        nextlayerid = 7
        nextobjectid = 1
        orientation = "orthogonal"
        properties = @(
            (New-Property -Name "mapName" -Type "string" -Value "Vila Shinobi Office"),
            (New-Property -Name "mapDescription" -Type "string" -Value "Sala unica com 10 estacoes individuais para trabalho compartilhado."),
            (New-Property -Name "mapCopyright" -Type "string" -Value "Original prototype inspired by a generic ninja-village aesthetic.")
        )
        renderorder = "right-down"
        tiledversion = "1.11.0"
        tileheight = $tileSize
        tilesets = @($tileset)
        tilewidth = $tileSize
        type = "map"
        version = "1.10"
        width = $mapWidth
    }

    $json = $map | ConvertTo-Json -Depth 100
    Set-Content -Path $mapPath -Value $json -Encoding utf8
    Set-Content -Path $mapJsonPath -Value $json -Encoding utf8
}

function Write-LayoutPreview {
    $svg = @'
<svg xmlns="http://www.w3.org/2000/svg" width="940" height="620" viewBox="0 0 940 620">
  <rect width="940" height="620" fill="#e7ecdf"/>
  <rect x="170" y="70" width="600" height="430" rx="30" fill="#9b6a43" stroke="#523418" stroke-width="10"/>
  <rect x="210" y="110" width="520" height="330" rx="24" fill="#efe4c8" stroke="#6d543a" stroke-width="4"/>
  <text x="470" y="150" font-family="Segoe UI, Arial, sans-serif" font-size="28" text-anchor="middle" fill="#3f2d18">Sala compartilhada</text>

  <g fill="#b88453" stroke="#523418" stroke-width="4">
    <rect x="255" y="200" width="54" height="24" rx="10"/>
    <rect x="335" y="200" width="54" height="24" rx="10"/>
    <rect x="415" y="200" width="54" height="24" rx="10"/>
    <rect x="495" y="200" width="54" height="24" rx="10"/>
    <rect x="575" y="200" width="54" height="24" rx="10"/>
    <rect x="255" y="300" width="54" height="24" rx="10"/>
    <rect x="335" y="300" width="54" height="24" rx="10"/>
    <rect x="415" y="300" width="54" height="24" rx="10"/>
    <rect x="495" y="300" width="54" height="24" rx="10"/>
    <rect x="575" y="300" width="54" height="24" rx="10"/>
  </g>

  <g fill="#6d543a">
    <rect x="271" y="228" width="22" height="14" rx="7"/>
    <rect x="351" y="228" width="22" height="14" rx="7"/>
    <rect x="431" y="228" width="22" height="14" rx="7"/>
    <rect x="511" y="228" width="22" height="14" rx="7"/>
    <rect x="591" y="228" width="22" height="14" rx="7"/>
    <rect x="271" y="328" width="22" height="14" rx="7"/>
    <rect x="351" y="328" width="22" height="14" rx="7"/>
    <rect x="431" y="328" width="22" height="14" rx="7"/>
    <rect x="511" y="328" width="22" height="14" rx="7"/>
    <rect x="591" y="328" width="22" height="14" rx="7"/>
  </g>

  <text x="470" y="385" font-family="Segoe UI, Arial, sans-serif" font-size="22" text-anchor="middle" fill="#3f2d18">10 estacoes individuais</text>

  <rect x="435" y="500" width="70" height="44" rx="12" fill="#7b7a75"/>
  <text x="470" y="528" font-family="Segoe UI, Arial, sans-serif" font-size="18" text-anchor="middle" fill="#ffffff">Entrada</text>
</svg>
'@

    Set-Content -Path $previewPath -Value $svg -Encoding utf8
}

Write-TilesetImage
Write-MapFile
Write-LayoutPreview

Write-Host "Tileset criado em: $tilesetPath"
Write-Host "Mapa criado em: $mapPath"
Write-Host "Mapa JSON criado em: $mapJsonPath"
Write-Host "Preview criado em: $previewPath"
