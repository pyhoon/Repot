# Package the Repot engine as a single .b4xlib.
#
# Runs the B4J library build (as a compile check), then zips the shared
# .bas modules and a manifest.txt into dist\Repot.b4xlib. A .b4xlib is a
# source distribution: the host IDE unpacks the modules and compiles
# them into the project, so the compiled jar/xml are NOT included.
# The .b4xlib is a plain zip archive (rename to .zip to inspect).
#
# Usage:
#   .\tools\package-b4xlib.ps1            # build + package
#   .\tools\package-b4xlib.ps1 -NoBuild    # skip the compile check

param(
    [switch]$NoBuild
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root "source"
$b4j = Join-Path $src "B4J"
$dist = Join-Path $root "dist"
$stage = Join-Path $env:TEMP "repot-b4xlib-stage"

if (-not $NoBuild) {
    $builderCandidates = @(
        (Join-Path $env:ProgramFiles "B4X\B4J\B4JBuilder.exe"),
        (Join-Path $env:ProgramFiles "Anywhere Software\B4J\B4JBuilder.exe")
    )
    $builder = $builderCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $builder) { throw "B4JBuilder not found (looked in $($builderCandidates -join ', '))" }
    Push-Location $b4j
    & $builder -Task=BuildLibrary
    if ($LASTEXITCODE -ne 0) { Pop-Location; throw "B4J library build failed (exit $LASTEXITCODE)" }
    Pop-Location
}

Remove-Item -Recurse -Force $stage -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $stage | Out-Null
New-Item -ItemType Directory -Path $dist -ErrorAction SilentlyContinue | Out-Null

# Shared modules (all .bas at the source root). UI modules live in ui\ and
# are packaged separately as RepotViewer.b4xlib, so the core library stays
# headless (see docs/architecture.md).
Get-ChildItem -Path $src -Filter "*.bas" -File |
    ForEach-Object { Copy-Item $_.FullName $stage }

# Manifest.
$manifest = @"
Version=1.6
B4J.DependsOn=Json, JavaObject, pdfbox-app-3.0.8
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
