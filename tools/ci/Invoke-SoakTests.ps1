<#
.SYNOPSIS
    Soak-test harness: runs the parallel PHPUnit suite N times in a row,
    wiping the compiled-view caches between each run, to empirically catch
    rare test-isolation races (e.g. workers colliding on shared Blade
    compiled-view directories) that a single run wouldn't reveal.

.DESCRIPTION
    Windows/local-dev equivalent of tools/ci/soak-tests.sh. Aborts on the
    FIRST failing iteration with a clear error -- that first failure is the
    reproduction and later iterations are not worth running past it.

.PARAMETER Iterations
    Number of times to run the suite. Defaults to 40.

.EXAMPLE
    pwsh -File tools/ci/Invoke-SoakTests.ps1
    pwsh -File tools/ci/Invoke-SoakTests.ps1 100

.NOTES
    Must be run from the repository root.
#>

param(
    [Parameter(Position = 0)]
    [int]$Iterations = 40
)

$ErrorActionPreference = 'Stop'

$viewDirs = @(
    'storage/framework/views',
    'storage/framework/testing/views'
)

function Clear-ViewDirs {
    foreach ($dir in $viewDirs) {
        if (Test-Path $dir) {
            Get-ChildItem -Path $dir -Recurse -Force |
                Where-Object { $_.Name -ne '.gitignore' } |
                Sort-Object -Property { $_.FullName.Length } -Descending |
                Remove-Item -Recurse -Force -Confirm:$false
        }
    }
}

for ($i = 1; $i -le $Iterations; $i++) {
    Write-Host "Iteration $i/$Iterations"

    Clear-ViewDirs

    php artisan test --parallel --processes=8

    if ($LASTEXITCODE -ne 0) {
        Write-Error "FAILED on iteration $i"
        exit 1
    }
}

Write-Host "Soak test complete: $Iterations/$Iterations iterations passed"
