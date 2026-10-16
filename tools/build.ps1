# Renders every EVRRY asset from the SVG masters in ..\source.
# Requires Google Chrome (or Edge) for SVG rasterising; .NET System.Drawing handles cropping, alpha, ICO and JPG.
# Usage:  powershell -ExecutionPolicy Bypass -File tools\build.ps1

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$src  = Join-Path $root 'source'
$work = Join-Path ([IO.Path]::GetTempPath()) 'evrry-build'
New-Item -ItemType Directory -Force $work | Out-Null

$browser = @(
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $browser) { throw 'Chrome or Edge is required.' }

function Out-Dir($rel) {
  $p = Join-Path $root $rel
  New-Item -ItemType Directory -Force (Split-Path -Parent $p) | Out-Null
  return $p
}

# Render an SVG to an exact-size PNG.
#   rgba     32-bit with transparency
#   rgb      24-bit, no alpha channel (iOS / Apple touch)
#   opaque32 32-bit ARGB, every pixel fully opaque (Google Play)
function Render($svgName, $outRel, [int]$w, [int]$h, $mode) {
  $svg = Get-Content (Join-Path $src $svgName) -Raw
  $svg = ([regex]'<svg\b').Replace($svg, "<svg width=`"$w`" height=`"$h`"", 1)
  $tmpSvg = Join-Path $work "r.svg"
  $tmpPng = Join-Path $work "r.png"
  [IO.File]::WriteAllText($tmpSvg, $svg, (New-Object Text.UTF8Encoding $false))
  if (Test-Path $tmpPng) { Remove-Item $tmpPng }

  $ww = [Math]::Max($w, 500); $wh = [Math]::Max($h, 500)
  $args = @('--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
            '--default-background-color=00000000', "--user-data-dir=$work\profile",
            "--window-size=$ww,$wh", "--screenshot=$tmpPng", ([Uri]$tmpSvg).AbsoluteUri)
  Start-Process -FilePath $browser -ArgumentList $args -Wait -WindowStyle Hidden
  if (-not (Test-Path $tmpPng)) { throw "Render failed: $svgName" }

  $shot = [Drawing.Bitmap]::FromFile($tmpPng)
  $fmt = if ($mode -eq 'rgb') { [Drawing.Imaging.PixelFormat]::Format24bppRgb } else { [Drawing.Imaging.PixelFormat]::Format32bppArgb }
  $bmp = New-Object Drawing.Bitmap $w, $h, $fmt
  $g = [Drawing.Graphics]::FromImage($bmp)
  if ($mode -ne 'rgba') { $g.Clear([Drawing.Color]::Black) }
  $g.CompositingMode = if ($mode -eq 'rgba') { 'SourceCopy' } else { 'SourceOver' }
  $rect = New-Object Drawing.Rectangle 0, 0, $w, $h
  $g.DrawImage($shot, $rect, $rect, [Drawing.GraphicsUnit]::Pixel)
  $g.Dispose(); $shot.Dispose()

  $out = Out-Dir $outRel
  $bmp.Save($out, [Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  Write-Host ("{0,-55} {1}x{2} {3}" -f $outRel, $w, $h, $mode)
}

function Save-Jpeg($pngPath, $jpgPath, [long]$quality) {
  $img = [Drawing.Image]::FromFile($pngPath)
  $codec = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
  $ep = New-Object Drawing.Imaging.EncoderParameters 1
  $ep.Param[0] = New-Object Drawing.Imaging.EncoderParameter ([Drawing.Imaging.Encoder]::Quality), $quality
  $img.Save($jpgPath, $codec, $ep)
  $img.Dispose()
}

# Pack PNGs into a single .ico (PNG-compressed entries, supported by all modern browsers and Windows Vista+).
function Write-Ico($pngPaths, $icoPath) {
  $blobs = $pngPaths | ForEach-Object { ,[IO.File]::ReadAllBytes($_) }
  $ms = New-Object IO.MemoryStream
  $bw = New-Object IO.BinaryWriter $ms
  $bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]$blobs.Count)
  $offset = 6 + 16 * $blobs.Count
  for ($i = 0; $i -lt $blobs.Count; $i++) {
    $img = [Drawing.Image]::FromFile($pngPaths[$i]); $s = $img.Width; $img.Dispose()
    $bw.Write([byte]($s % 256)); $bw.Write([byte]($s % 256)); $bw.Write([byte]0); $bw.Write([byte]0)
    $bw.Write([uint16]1); $bw.Write([uint16]32)
    $bw.Write([uint32]$blobs[$i].Length); $bw.Write([uint32]$offset)
    $offset += $blobs[$i].Length
  }
  foreach ($b in $blobs) { $bw.Write($b) }
  $bw.Flush()
  [IO.File]::WriteAllBytes($icoPath, $ms.ToArray())
  $bw.Dispose()
}

# 1. Android launcher + notification
Render 'adaptive-foreground.svg' 'android\ic_launcher_foreground.png' 432 432 rgba
Render 'adaptive-background.svg' 'android\ic_launcher_background.png' 432 432 rgba
Render 'adaptive-monochrome.svg' 'android\ic_launcher_monochrome.png' 432 432 rgba
foreach ($d in @(@('mdpi',24), @('hdpi',36), @('xhdpi',48), @('xxhdpi',72), @('xxxhdpi',96))) {
  Render 'notification.svg' "android\res\drawable-$($d[0])\ic_stat_evrry.png" $d[1] $d[1] rgba
}
foreach ($n in 'foreground','background','monochrome') {
  Copy-Item (Join-Path $root "android\ic_launcher_$n.png") (Out-Dir "android\res\mipmap-xxxhdpi\ic_launcher_$n.png")
  Copy-Item (Join-Path $src "adaptive-$n.svg") (Join-Path $root "android\ic_launcher_$n.svg")
}

# 2. Google Play
Render 'app-icon.svg'        'playstore\play-icon-512.png'         512 512 opaque32
Render 'feature-graphic.svg' 'playstore\feature-graphic-1024x500.png' 1024 500 rgb

# 3. iOS
Render 'app-icon.svg'        'ios\AppIcon.appiconset\AppIcon-1024.png'        1024 1024 rgb
Render 'app-icon-dark.svg'   'ios\AppIcon.appiconset\AppIcon-1024-dark.png'   1024 1024 rgb
Render 'app-icon-tinted.svg' 'ios\AppIcon.appiconset\AppIcon-1024-tinted.png' 1024 1024 rgb

# 4. Web / PWA
foreach ($s in 16, 32, 48) { Render 'favicon.svg' "web\favicon-$s.png" $s $s rgba }
Write-Ico @((Join-Path $root 'web\favicon-16.png'), (Join-Path $root 'web\favicon-32.png'), (Join-Path $root 'web\favicon-48.png')) (Join-Path $root 'web\favicon.ico')
Copy-Item (Join-Path $src 'favicon.svg') (Join-Path $root 'web\favicon.svg')
Render 'app-icon.svg'     'web\apple-touch-icon.png'   180 180 rgb
Render 'pwa-icon.svg'     'web\icon-192.png'           192 192 rgba
Render 'pwa-icon.svg'     'web\icon-512.png'           512 512 rgba
Render 'pwa-maskable.svg' 'web\icon-maskable-512.png'  512 512 rgb

# 5. Marketing
Render 'og-image.svg'   'marketing\og-image-1200x630.png'     1200 630 rgb
$og = Join-Path $root 'marketing\og-image-1200x630.png'
if ((Get-Item $og).Length -gt 300KB) {
  Save-Jpeg $og (Join-Path $root 'marketing\og-image-1200x630.jpg') 88
  Remove-Item $og
  Write-Host 'og-image: PNG over 300 KB, saved as JPG instead'
}
Render 'story-card.svg' 'marketing\story-referral-card-1080x1920.png' 1080 1920 rgb
Render 'logo-navy.svg'  'marketing\evrry-logo-navy-1200.png'  1200 281 rgba
Render 'logo-white.svg' 'marketing\evrry-logo-white-1200.png' 1200 281 rgba
Copy-Item (Join-Path $src 'logo-navy.svg')  (Join-Path $root 'marketing\evrry-logo-navy.svg')
Copy-Item (Join-Path $src 'logo-white.svg') (Join-Path $root 'marketing\evrry-logo-white.svg')
Copy-Item (Join-Path $src 'symbol.svg')     (Join-Path $root 'marketing\evrry-symbol.svg')

Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
Write-Host 'Done.'
