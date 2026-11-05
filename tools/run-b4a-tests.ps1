# Run the B4A engine suite on a connected device/emulator.
#
# B4A has no console runner: the tests run inside an Activity, log a summary
# line ("fixtures=N checks=M errors=E") and write it to internal storage.
# This script builds, installs, launches, waits for that line, and gates on
# errors=0 so B4A coverage is as repeatable as the B4J harness.
#
# Usage:
#   .\tools\run-b4a-tests.ps1                 # build + install + run
#   .\tools\run-b4a-tests.ps1 -NoBuild        # reuse the existing apk
#   .\tools\run-b4a-tests.ps1 -TimeoutSeconds 300
#
# Exit codes: 0 all checks passed, 1 failures, 2 no summary (app crashed or
# never started), 3 environment problem (builder/adb/device missing).

param(
    [switch]$NoBuild,
    [int]$TimeoutSeconds = 180
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$proj = Join-Path $root "tests\B4A"

function Fail([string]$Message, [int]$Code) {
    Write-Host "FAILED: $Message" -ForegroundColor Red
    exit $Code
}

if (-not $NoBuild) {
    $builderCandidates = @(
        (Join-Path $env:ProgramFiles "B4X\B4A\B4ABuilder.exe"),
        (Join-Path $env:ProgramFiles "Anywhere Software\B4A\B4ABuilder.exe")
    )
    $builder = $builderCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $builder) { Fail "B4ABuilder not found (looked in $($builderCandidates -join ', '))" 3 }

    Push-Location $proj
    & $builder -task=Build -obfuscate=False
    $code = $LASTEXITCODE
    Pop-Location
    if ($code -ne 0) { Fail "B4A build (exit $code)" 1 }
}

$apk = Get-ChildItem (Join-Path $proj "Objects") -Filter *.apk -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $apk) { Fail "no apk in tests\B4A\Objects" 3 }

$adbCandidates = @()
if ($env:ANDROID_HOME) { $adbCandidates += (Join-Path $env:ANDROID_HOME "platform-tools\adb.exe") }
if ($env:ANDROID_SDK_ROOT) { $adbCandidates += (Join-Path $env:ANDROID_SDK_ROOT "platform-tools\adb.exe") }
$adbCandidates += "C:\android\sdk\platform-tools\adb.exe"
$adb = $adbCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $adb) { Fail "adb not found (set ANDROID_HOME or install the SDK)" 3 }

$devices = & $adb devices | Select-String "device$"
if (-not $devices) { Fail "no device or emulator connected" 3 }

Write-Host "Installing $($apk.Name)..." -ForegroundColor Cyan
& $adb install -r $apk.FullName | Out-Null
if ($LASTEXITCODE -ne 0) { Fail "adb install" 1 }

& $adb shell am force-stop b4a.example | Out-Null
& $adb logcat -c | Out-Null
& $adb shell am start -n b4a.example/.main | Out-Null

Write-Host "Waiting for the summary line (up to ${TimeoutSeconds}s)..." -ForegroundColor Cyan
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$summary = $null
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 3
    $line = (& $adb logcat -d) | Select-String "checks=\d+ errors=\d+" | Select-Object -Last 1
    if ($line) { $summary = $line.ToString(); break }
}

if (-not $summary) { Fail "no summary line in logcat (crash or timeout)" 2 }

Write-Host ""
Write-Host $summary.Trim() -ForegroundColor Cyan

if ($summary -match "errors=(\d+)") {
    $errors = [int]$Matches[1]
} else {
    Fail "could not parse the summary line" 2
}

if ($errors -ne 0) { Fail "$errors check(s) failed" 1 }
Write-Host "OK: B4A suite passed" -ForegroundColor Green
exit 0
