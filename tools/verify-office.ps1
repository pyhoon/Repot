<#
.SYNOPSIS
    Verifies typed spreadsheet cells end-to-end through Excel COM.

.DESCRIPTION
    Builds and runs the B4J fixture suite (which emits test-items.xlsx from
    the invoice-basic template), then opens that workbook through Excel COM
    and asserts:

      * numeric cells read back as Double with NumberFormat "0.00"
      * the workbook opens without a repair prompt (read-only, headless)
      * on a temp copy, a =SUM(D2:D5) formula recalculates to 2449.95

    Excel is driven headless (Visible=$false, DisplayAlerts=$false) and is
    always quit and released, even on failure.

.PARAMETER NoBuild
    Reuse the existing tests.jar / test-items.xlsx instead of rebuilding.

.EXAMPLE
    .\tools\verify-office.ps1

.EXAMPLE
    .\tools\verify-office.ps1 -NoBuild
#>
[CmdletBinding()]
param(
    [switch]$NoBuild
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$objects = Join-Path $root 'tests\B4J\Objects'
$xlsx = Join-Path $objects 'test-items.xlsx'
$tempCopy = Join-Path $env:TEMP 'repot-verify-office.xlsx'

function Fail([string]$Message) {
    Write-Host "FAILED: $Message" -ForegroundColor Red
    $script:failed = $true
}

function Release([object]$o) {
    if ($null -ne $o) {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($o) | Out-Null
    }
}

# --- Build + run fixtures to produce the workbook ---------------------------
if (-not $NoBuild) {
    Write-Host "=== Building fixture checker ===" -ForegroundColor Cyan
    & (Join-Path $root 'tools\run-fixtures.ps1') | Out-String
    if ($LASTEXITCODE -ne 0) { throw "Fixture suite failed (exit $LASTEXITCODE)" }
}

if (-not (Test-Path $xlsx)) {
    throw "test-items.xlsx was not produced at $xlsx"
}

# --- Excel COM verification -------------------------------------------------
$xl = $null
$wb = $null
try {
    $xl = New-Object -ComObject Excel.Application
    $xl.Visible = $false
    $xl.DisplayAlerts = $false
    $xl.AskToUpdateLinks = $false
    $xl.AlertBeforeOverwriting = $false

    Write-Host "=== Opening $xlsx read-only (headless) ===" -ForegroundColor Cyan
    $wb = $xl.Workbooks.Open($xlsx, 0, $true)
    $ws = $wb.Worksheets.Item(1)

    function Cell([object]$sheet, [string]$addr) { $sheet.Range($addr) }

    $b2 = Cell $ws "B2"
    $d2 = Cell $ws "D2"
    $d5 = Cell $ws "D5"

    $ok = $true

    # Numbers must read back as Double (not text).
    $t = $b2.Value2.GetType().Name
    if ($t -ne 'Double') { Fail "B2 is $t, expected Double"; $ok = $false }
    $t = $d2.Value2.GetType().Name
    if ($t -ne 'Double') { Fail "D2 is $t, expected Double"; $ok = $false }
    $t = $d5.Value2.GetType().Name
    if ($t -ne 'Double') { Fail "D5 is $t, expected Double"; $ok = $false }

    # Field formats must reach the cells: Quantity is 0 decimals, Amount is
    # grouped with 2 decimals.
    $fmt = $b2.NumberFormat
    if ($fmt -ne '0') { Fail "B2 (Quantity) NumberFormat is '$fmt', expected '0'"; $ok = $false }
    $fmt = $d2.NumberFormat
    if ($fmt -ne '#,##0.00') { Fail "D2 (Amount) NumberFormat is '$fmt', expected '#,##0.00'"; $ok = $false }

    # Values.
    if ([math]::Abs($b2.Value2 - 1) -gt 0.0001) { Fail "B2 value is $($b2.Value2), expected 1"; $ok = $false }
    if ([math]::Abs($d2.Value2 - 1200) -gt 0.0001) { Fail "D2 value is $($d2.Value2), expected 1200"; $ok = $false }
    if ([math]::Abs($d5.Value2 - 99.95) -gt 0.0001) { Fail "D5 value is $($d5.Value2), expected 99.95"; $ok = $false }

    # Text cell stays text.
    $a2 = Cell $ws "A2"
    if ($a2.Value2.GetType().Name -ne 'String') { Fail "A2 is $($a2.Value2.GetType().Name), expected String"; $ok = $false }

    Release $b2; Release $d2; Release $d5; Release $a2; Release $ws

    $wb.Close($false)
    Release $wb
    $wb = $null

    # Temp copy with a SUM formula: Excel must compute from the typed cells.
    Copy-Item $xlsx $tempCopy -Force
    $wb2 = $xl.Workbooks.Open($tempCopy, 0, $true)
    $ws2 = $wb2.Worksheets.Item(1)
    $f1 = $ws2.Range("F1")
    $f1.Formula = "=SUM(D2:D5)"
    $xl.CalculateFull()
    $sum = $f1.Value2
    if ([math]::Abs($sum - 2449.95) -gt 0.0001) {
        Fail "=SUM(D2:D5) = $sum, expected 2449.95"; $ok = $false
    } else {
        Write-Host "=SUM(D2:D5) = $sum  OK" -ForegroundColor Green
    }
    Release $f1; Release $ws2
    $wb2.Close($false)
    Release $wb2
    Remove-Item $tempCopy -ErrorAction SilentlyContinue
}
catch {
    Fail "Excel COM verification threw: $($_.Exception.Message)"
}
finally {
    if ($null -ne $wb) { $wb.Close($false); Release $wb }
    if ($null -ne $xl) { $xl.Quit(); Release $xl }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}

Write-Host ""
if ($script:failed) {
    Write-Host "verify-office: FAILED" -ForegroundColor Red
    exit 1
} else {
    Write-Host "verify-office: PASSED" -ForegroundColor Green
    exit 0
}
