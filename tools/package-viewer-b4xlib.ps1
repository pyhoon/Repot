# Package the optional Repot UI viewer as a separate .b4xlib.
#
# The core Repot.b4xlib is headless (StandardJava) and must not pull in a UI
# stack. The viewer is therefore distributed on its own:
#   dist\RepotViewer.b4xlib  -> ui\ReportHtmlViewer.bas + manifest
#
# B4J consumers need the `jfx` library (JavaFX WebView); B4A consumers use
# the core `WebView` and need nothing extra. Both need the core Repot library.
#
# Usage:
#   .\tools\package-viewer-b4xlib.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root "preview"
$dist = Join-Path $root "dist"
$stage = Join-Path $env:TEMP "repot-viewer-stage"

if (-not (Test-Path $src)) { throw "Viewer source folder not found: $src" }

Remove-Item -Recurse -Force $stage -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $stage | Out-Null
New-Item -ItemType Directory -Path $dist -ErrorAction SilentlyContinue | Out-Null

Get-ChildItem -Path $src -Filter "*.bas" -File | ForEach-Object {
    Copy-Item $_.FullName $stage
}

$manifest = @"
Version=1.6
Author=Repot contributors
B4J.DependsOn=Json, JavaObject, jfx, jxui, Repot
B4A.DependsOn=Json, JavaObject, xui, Repot
Supported Platforms=B4A,B4J
"@
Set-Content -Path (Join-Path $stage "manifest.txt") -Value $manifest -NoNewline

$out = Join-Path $dist "RepotViewer.b4xlib"
$zip = Join-Path $dist "RepotViewer.zip"
if (Test-Path $zip) { Remove-Item $zip }
Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zip
if (Test-Path $out) { Remove-Item $out }
Rename-Item $zip $out
Write-Host "Packaged $out"

Remove-Item -Recurse -Force $stage
Get-Item $out
