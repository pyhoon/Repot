# Package the Repot engine as a single .b4xlib.
#
# Runs the B4J library build, then zips the shared .bas modules together
# with the produced jar/xml and a manifest.txt into dist\Repot.b4xlib.
# The .b4xlib is a plain zip archive (rename to .zip to inspect).
#
# Usage:
#   .\tools\package-b4xlib.ps1            # build + package
#   .\tools\package-b4xlib.ps1 -NoBuild    # reuse an existing build

param(
    [switch]$NoBuild
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root "source"
$b4j = Join-Path $src "B4J"
$additional = "C:\B4X\Additional\B4J"
$dist = Join-Path $root "dist"
$stage = Join-Path $env:TEMP "repot-b4xlib-stage"

if (-not $NoBuild) {
    Push-Location $b4j
    & "C:\Program Files\B4X\B4J\B4JBuilder.exe" -Task=BuildLibrary
    if ($LASTEXITCODE -ne 0) { Pop-Location; throw "B4J library build failed (exit $LASTEXITCODE)" }
    Pop-Location
}

if (-not (Test-Path (Join-Path $additional "Repot.jar"))) { throw "Repot.jar not found in $additional" }
if (-not (Test-Path (Join-Path $additional "Repot.xml"))) { throw "Repot.xml not found in $additional" }

Remove-Item -Recurse -Force $stage -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $stage | Out-Null
New-Item -ItemType Directory -Path $dist -ErrorAction SilentlyContinue | Out-Null

# Shared modules (all .bas at the source root).
Get-ChildItem -Path $src -Filter "*.bas" -File | ForEach-Object {
    Copy-Item $_.FullName $stage
}

# Compiled artifacts.
Copy-Item (Join-Path $additional "Repot.jar") $stage
Copy-Item (Join-Path $additional "Repot.xml") $stage

# Manifest.
$manifest = @"
Version=1.5
B4J.DependsOn=Json, JavaObject
B4A.DependsOn=Json, JavaObject, Printing, FileProvider
"@
Set-Content -Path (Join-Path $stage "manifest.txt") -Value $manifest -NoNewline

$out = Join-Path $dist "Repot.b4xlib"
# Zip into .b4xlib (Compress-Archive only accepts .zip; rename afterwards).
$zip = Join-Path $dist "Repot.zip"
if (Test-Path $zip) { Remove-Item $zip }
Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zip
if (Test-Path $out) { Remove-Item $out }
Rename-Item $zip $out
Write-Host "Packaged $out"

# Clean up.
Remove-Item -Recurse -Force $stage
Get-Item $out
