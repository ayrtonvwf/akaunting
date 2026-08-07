$ErrorActionPreference = 'Stop'

$tempBasePath = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$tempRootPath = Join-Path $tempBasePath ("akaunting-graphify-output-test-{0}" -f [guid]::NewGuid().ToString('N'))
$tempRootFullPath = [System.IO.Path]::GetFullPath($tempRootPath)
$tempPrefix = $tempBasePath.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) + [System.IO.Path]::DirectorySeparatorChar

if (-not $tempRootFullPath.StartsWith($tempPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to create Graphify output test workspace outside the system temp directory: $tempRootFullPath"
}

$verifierSourcePath = Join-Path $PSScriptRoot 'Test-GraphifyOutput.ps1'
$verifierPath = Join-Path $tempRootFullPath 'tools/graphify/Test-GraphifyOutput.ps1'
$graphifyOutPath = Join-Path $tempRootFullPath 'graphify-out'
$graphJsonPath = Join-Path $graphifyOutPath 'graph.json'
$htmlPath = Join-Path $graphifyOutPath 'graph.html'
$failures = [System.Collections.Generic.List[string]]::new()

function Set-GraphifyOutputFixture {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $SourcePaths,

        [Parameter(Mandatory = $true)]
        [string] $Html
    )

    $nodes = foreach ($sourcePath in $SourcePaths) {
        [ordered]@{
            id = $sourcePath
            metadata = [ordered]@{
                source_file = $sourcePath
            }
        }
    }

    [ordered]@{ nodes = @($nodes); edges = @() } |
        ConvertTo-Json -Depth 10 |
        Set-Content -LiteralPath $graphJsonPath -Encoding utf8NoBOM
    Set-Content -LiteralPath $htmlPath -Value $Html -Encoding utf8NoBOM
}

function Invoke-OutputVerifier {
    try {
        & $verifierPath *> $null

        return [pscustomobject]@{
            Succeeded = $true
            Message = $null
        }
    }
    catch {
        return [pscustomobject]@{
            Succeeded = $false
            Message = $_.Exception.Message
        }
    }
}

$selfContainedHtml = @'
<!DOCTYPE html>
<html>
<head>
<style>body { color: #fff; }</style>
<script>window.vis = {};</script>
</head>
<body></body>
</html>
'@

try {
    New-Item -ItemType Directory -Path (Split-Path -Parent $verifierPath) -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempRootFullPath 'modules/OfflinePayments') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempRootFullPath 'modules/PaypalStandard') -Force | Out-Null
    New-Item -ItemType Directory -Path $graphifyOutPath -Force | Out-Null
    Copy-Item -LiteralPath $verifierSourcePath -Destination $verifierPath
    Set-Content -LiteralPath (Join-Path $tempRootFullPath 'modules/OfflinePayments/composer.json') -Value '{}' -Encoding utf8NoBOM
    Set-Content -LiteralPath (Join-Path $tempRootFullPath 'modules/PaypalStandard/composer.json') -Value '{}' -Encoding utf8NoBOM
    Set-Content -LiteralPath (Join-Path $graphifyOutPath 'GRAPH_REPORT.md') -Value '# fixture' -Encoding utf8NoBOM
    Set-Content -LiteralPath (Join-Path $graphifyOutPath 'manifest.json') -Value '{}' -Encoding utf8NoBOM

    $validPaths = @(
        'app/Services/Valid.php'
        './modules/OfflinePayments/Valid.php'
        'config/app.php'
        'routes/web.php'
        'tests/Unit/ValidTest.php'
        'app\Models\WindowsSeparator.php'
    )
    Set-GraphifyOutputFixture -SourcePaths $validPaths -Html $selfContainedHtml
    $validResult = Invoke-OutputVerifier

    if (-not $validResult.Succeeded) {
        $failures.Add("Valid in-scope relative paths were rejected: $($validResult.Message)")
    }

    $invalidPaths = @(
        '../app/Outside.php'
        '/app/Absolute.php'
        '\app\Rooted.php'
        'app/../../outside.php'
        'app/../config/Outside.php'
        'C:\app\Drive.php'
        'C:/app/Drive.php'
        '\\server\share\app\Unc.php'
        '//server/share/app/Unc.php'
    )

    foreach ($invalidPath in $invalidPaths) {
        Set-GraphifyOutputFixture -SourcePaths @($invalidPath) -Html $selfContainedHtml
        $invalidResult = Invoke-OutputVerifier

        if ($invalidResult.Succeeded) {
            $failures.Add("Traversal or rooted source path was accepted: $invalidPath")
        }
    }

    $externalDependencyCases = [ordered]@{
        'external script' = @'
<html><head><script src="https://cdn.example.test/runtime.js"></script></head><body></body></html>
'@
        'external stylesheet' = @'
<html><head><link rel="stylesheet" href="https://cdn.example.test/theme.css"></head><body></body></html>
'@
        'protocol-relative script' = @'
<html><head><script src="//cdn.example.test/runtime.js"></script></head><body></body></html>
'@
        'external stylesheet import' = @'
<html><head><style>@import url("https://cdn.example.test/theme.css");</style></head><body></body></html>
'@
    }

    foreach ($caseName in $externalDependencyCases.Keys) {
        Set-GraphifyOutputFixture -SourcePaths @('app/Valid.php') -Html $externalDependencyCases[$caseName]
        $dependencyResult = Invoke-OutputVerifier

        if ($dependencyResult.Succeeded) {
            $failures.Add("Graph HTML with $caseName dependency was accepted.")
        }
    }

    if ($failures.Count -gt 0) {
        throw "Graphify output regression failures:`n- $($failures -join "`n- ")"
    }

    Write-Host 'Graphify output regression tests passed.'
}
finally {
    if (
        (Test-Path -LiteralPath $tempRootFullPath) -and
        $tempRootFullPath.StartsWith($tempPrefix, [System.StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $tempRootFullPath).StartsWith('akaunting-graphify-output-test-', [System.StringComparison]::Ordinal)
    ) {
        Remove-Item -LiteralPath $tempRootFullPath -Recurse -Force
    }
}
