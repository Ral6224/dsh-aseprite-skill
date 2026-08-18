# verify-render.ps1 — decode a rendered PNG back into an ASCII character map for
# byte-for-byte verification against your design template (no vision model needed).
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts/verify-render.ps1 cover.png
#   powershell -ExecutionPolicy Bypass -File scripts/verify-render.ps1 cover.png -Legacy
#
# By default it maps exact RGB triplets to single ASCII chars using the arne16 /
# common 16-color palette keys. Pass -PaletteFile <path> to provide a mapping of
# "R,G,B -> char"? not supported; instead edit $Map below, or use -Raw to dump
# "R,G,B" for every pixel and map yourself.
#
# Flags:
#   -Raw          emit "x,y R,G,B,A" lines instead of the ASCII grid (no palette needed)
#   -PaletteFile  path to a GIMP .gpl whose FIRST token (the color name) becomes the
#                 char; otherwise the built-in palette below is used.

param(
  [Parameter(Position = 0, Mandatory = $true)]
  [string]$Image,
  [switch]$Raw,
  [string]$PaletteFile
)

Add-Type -AssemblyName System.Drawing

# Built-in palette: exact "R,G,B" -> single char (16-color arne16-like set).
$Map = @{
  "0,0,0" = "K"; "157,157,157" = "G"; "255,255,255" = "W"; "190,38,51" = "R"
  "224,111,139" = "P"; "73,60,43" = "D"; "164,100,34" = "B"; "235,137,49" = "O"
  "247,226,107" = "Y"; "47,72,78" = "L"; "68,137,26" = "E"; "163,206,39" = "S"
  "27,38,50" = "N"; "0,87,132" = "U"; "49,162,242" = "A"; "178,220,239" = "C"
  # ascii-template-demo.lua colors (outline, hair, skin, shirt, pants)
  "45,45,48" = "X"; "112,74,44" = "H"; "255,214,170" = "F"; "226,82,60" = "T"; "72,116,204" = "Q"
}

if ($PaletteFile) {
  $Map = @{}
  Get-Content $PaletteFile | ForEach-Object {
    if ($_ -match '^\s*(\d+)\s+(\d+)\s+(\d+)\s+(.+?)\s*$') {
      $key = "$($Matches[1]),$($Matches[2]),$($Matches[3])"
      # first CSV component of the name, first char, uppercased
      $name = ($Matches[4] -split ',' -replace '\s+', '')[0]
      $ch = [string]$name[0]
      $Map[$key] = $ch.ToUpperInvariant()
    }
  }
}

if (-not (Test-Path $Image)) { Write-Error "Image not found: $Image"; exit 1 }
$full = (Resolve-Path $Image).ProviderPath
$bmp = New-Object System.Drawing.Bitmap($full)
try {
  if ($Raw) {
    for ($y = 0; $y -lt $bmp.Height; $y++) {
      for ($x = 0; $x -lt $bmp.Width; $x++) {
        $p = $bmp.GetPixel($x, $y)
        "{0} {1} {2},{3},{4},{5}" -f $x, $y, $p.R, $p.G, $p.B, $p.A
      }
    }
  } else {
    for ($y = 0; $y -lt $bmp.Height; $y++) {
      $row = ""
      for ($x = 0; $x -lt $bmp.Width; $x++) {
        $p = $bmp.GetPixel($x, $y)
        if ($p.A -eq 0) { $row += "."; continue }   # fully transparent
        $key = "$($p.R),$($p.G),$($p.B)"
        $row += if ($Map.ContainsKey($key)) { $Map[$key] } else { "?" }
      }
      "{0,3}: {1}" -f $y, $row
    }
  }
} finally {
  $bmp.Dispose()
}
