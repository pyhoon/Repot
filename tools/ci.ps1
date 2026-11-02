# CI driver for Repot.
#
# Runs the verified local gates:
#   1. B4J library build          (source\B4J, -Task=BuildLibrary)
#   2. B4J fixture suite          (tools\run-fixtures.ps1)
#   3. B4A library build          (source\B4A, -task=Build -obfuscate=False)
#   4. (optional) B4A emulator run (-RunEmulator)
#
# Exit code 0 only when every enabled gate passes.

param(
    [switch]$RunEmulator,
    [switch]$SkipB4A
)

$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
$adb = "C:\android\sdk\platform-tools\adb.exe"
$failed = $false

function Fail($msg) {
    Write-Host "FAILED: $msg" -ForegroundColor Red
    $script:failed = $true
}

# Gate 1: B4J library build
Write-Host ""
Write-Host "=== B4J library build ===" -ForegroundColor Cyan
Push-Location (Join-Path $root "source\B4J")
& "C:\Program Files\B4X\B4J\B4JBuilder.exe" -Task=BuildLibrary
$code = $LASTEXITCODE
Pop-Location
if ($code -ne 0) { Fail "B4J library build (exit $code)" } else { Write-Host "PASSED" -ForegroundColor Green }

# Gate 2: B4J fixture suite (only if gate 1 passed)
if (-not $failed) {
    Write-Host ""
    Write-Host "=== B4J fixture suite ===" -ForegroundColor Cyan
    & (Join-Path $root "tools\run-fixtures.ps1")
    if ($LASTEXITCODE -ne 0) { Fail "B4J fixture suite (exit $LASTEXITCODE)" } else { Write-Host "PASSED" -ForegroundColor Green }
}

if (-not $SkipB4A -and -not $failed) {
    # Gate 3: B4A library build
    Write-Host ""
    Write-Host "=== B4A library build ===" -ForegroundColor Cyan
    Push-Location (Join-Path $root "source\B4A")
    & "C:\Program Files\B4X\B4A\B4ABuilder.exe" -task=Build -obfuscate=False
    $code = $LASTEXITCODE
    Pop-Location
    if ($code -ne 0) { Fail "B4A library build (exit $code)" } else { Write-Host "PASSED" -ForegroundColor Green }

    if (-not $failed -and $RunEmulator) {
        if (Test-Path $adb) {
            Write-Host ""
            Write-Host "=== B4A emulator run ===" -ForegroundColor Cyan
            Push-Location (Join-Path $root "tests\B4A")
            & "C:\Program Files\B4X\B4A\B4ABuilder.exe" -task=Build -obfuscate=False
            $b = $LASTEXITCODE
            Pop-Location
            if ($b -ne 0) { Fail "B4A test build (exit $b)" }
            else {
                & $adb install -r (Join-Path $root "tests\B4A\Objects\tests.apk") | Out-Null
                & $adb shell am force-stop b4a.example | Out-Null
                & $adb logcat -c | Out-Null
                & $adb shell am start -n b4a.example/.main | Out-Null
                Start-Sleep -Seconds 20
                $log = & $adb logcat -d
                if ($log -match "PASS engine" -and $log -match "errors=0") {
                    Write-Host "PASSED" -ForegroundColor Green
                } else {
                    Fail "B4A emulator run"
                }
            }
        } else {
            Write-Host "adb not found at $adb; skipping emulator run." -ForegroundColor Yellow
        }
    }
}

Write-Host ""
if ($failed) {
    Write-Host "CI: FAILED" -ForegroundColor Red
    exit 1
} else {
    Write-Host "CI: PASSED" -ForegroundColor Green
    exit 0
}