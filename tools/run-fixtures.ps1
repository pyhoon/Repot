<#
.SYNOPSIS
    Builds the Repot fixture checker and validates the fixtures.

.DESCRIPTION
    Runs the official B4J command-line builder, then executes the checker
    against fixtures/ and maps its result to a process exit code.

    Exit code 0 means the checker wrote errors=0. Any other outcome exits 1.
    This wrapper exists because a B4J console app cannot set a process exit
    code itself; see docs/b4x-notes.md.

.EXAMPLE
    .\tools\run-fixtures.ps1

.EXAMPLE
    .\tools\run-fixtures.ps1 -NoBuild
#>
[CmdletBinding()]
param(
    [string]$Fixtures,
    [switch]$NoBuild
)

$repo = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($Fixtures)) {
    $Fixtures = Join-Path $repo 'fixtures'
}
if (-not (Test-Path $Fixtures)) {
    throw "Fixtures folder not found: $Fixtures"
}
$Fixtures = (Resolve-Path $Fixtures).Path

$project = Join-Path $repo 'source\RepotTests'
$builder = Join-Path $env:ProgramFiles 'B4X\B4J\B4JBuilder.exe'
if (-not (Test-Path $builder)) {
    throw "B4JBuilder not found at $builder"
}

function Get-JavaBin {
    $ini = Join-Path $env:APPDATA 'Anywhere Software\B4J\b4xV5.ini'
    if (Test-Path $ini) {
        $line = Select-String -Path $ini -Pattern '^JavaBin=(.+)$' | Select-Object -First 1
        if ($line) { return $line.Matches[0].Groups[1].Value.Trim() }
    }
    return $null
}

if (-not $NoBuild) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    Push-Location $project
    try {
        $buildLog = & $builder -Task=Build 2>&1 | Out-String
        $buildCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
        $ErrorActionPreference = $previous
    }
    if ($buildCode -ne 0) {
        Write-Host $buildLog
        throw "Build failed with exit code $buildCode"
    }
    Write-Verbose $buildLog
}

$javaBin = Get-JavaBin
if ($javaBin) {
    $java = Join-Path $javaBin 'java.exe'
}
else {
    $java = 'java'
}

$objects = Join-Path $project 'Objects'
Push-Location $objects
try {
    $output = & $java -jar 'RepotTests.jar' $Fixtures $objects 2>&1 | Out-String
}
finally {
    Pop-Location
}
Write-Host $output

$resultFile = Join-Path $objects 'fixture-check.txt'
if (-not (Test-Path $resultFile)) {
    throw "The checker did not write $resultFile"
}

$summary = Get-Content $resultFile -TotalCount 1
if ($summary -match 'errors=0\b') {
    Write-Host "OK: $summary"
    exit 0
}

Write-Host "FAILED: $summary"
exit 1
