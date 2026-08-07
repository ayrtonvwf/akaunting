$ErrorActionPreference = 'Stop'

$tempBasePath = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$tempRootPath = Join-Path $tempBasePath ("akaunting-graphify-wrapper-test-{0}" -f [guid]::NewGuid().ToString('N'))
$tempRootFullPath = [System.IO.Path]::GetFullPath($tempRootPath)
$tempPrefix = $tempBasePath.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) + [System.IO.Path]::DirectorySeparatorChar

if (-not $tempRootFullPath.StartsWith($tempPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to create Graphify wrapper test workspace outside the system temp directory: $tempRootFullPath"
}

$wrapperSourcePath = Join-Path $PSScriptRoot 'Invoke-Graphify.ps1'
$vendorRuntimeSourcePath = Join-Path $PSScriptRoot 'vendor/vis-network-9.1.6.min.js'
$wrapperPath = Join-Path $tempRootFullPath 'tools/graphify/Invoke-Graphify.ps1'
$vendorRuntimePath = Join-Path $tempRootFullPath 'tools/graphify/vendor/vis-network-9.1.6.min.js'
$fakeUvPath = Join-Path $tempRootFullPath 'fake-bin/uv.ps1'
$invocationLogPath = Join-Path $tempRootFullPath 'uv-invocations.log'
$originalPath = $env:PATH
$originalSeedWasSet = Test-Path Env:PYTHONHASHSEED
$originalSeed = $env:PYTHONHASHSEED

$fakeUvScript = @'
$logPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'uv-invocations.log'
$repoRoot = Split-Path -Parent $PSScriptRoot
$graphifyOutPath = Join-Path $repoRoot 'graphify-out'
$commandLine = $args -join "`t"
Add-Content -LiteralPath $logPath -Value ("{0}|{1}" -f $env:PYTHONHASHSEED, $commandLine) -Encoding utf8NoBOM

if ($args -contains 'extract') {
    New-Item -ItemType Directory -Path $graphifyOutPath -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $graphifyOutPath 'graph.json') -Value '{"nodes":[],"edges":[]}' -Encoding utf8NoBOM
    Set-Content -LiteralPath (Join-Path $graphifyOutPath 'GRAPH_REPORT.md') -Value '# fake report' -Encoding utf8NoBOM
    Set-Content -LiteralPath (Join-Path $graphifyOutPath 'manifest.json') -Value '{}' -Encoding utf8NoBOM
}

if ($args -contains 'export') {
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>graphify - C:\absolute\graphify-out\graph.html</title>
<script src="https://unpkg.com/vis-network@9.1.6/standalone/umd/vis-network.min.js"
        integrity="sha384-Ux6phic9PEHJ38YtrijhkzyJ8yQlH8i/+buBR8s3mAZOJrP1gwyvAcIYl3GWtpX1"
        crossorigin="anonymous"></script>
</head>
<body></body>
</html>
"@
    Set-Content -LiteralPath (Join-Path $graphifyOutPath 'graph.html') -Value $html -Encoding utf8NoBOM
}

$global:LASTEXITCODE = 0
'@

try {
    New-Item -ItemType Directory -Path (Split-Path -Parent $wrapperPath) -Force | Out-Null
    New-Item -ItemType Directory -Path (Split-Path -Parent $vendorRuntimePath) -Force | Out-Null
    New-Item -ItemType Directory -Path (Split-Path -Parent $fakeUvPath) -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempRootFullPath 'modules/OfflinePayments') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempRootFullPath 'modules/PaypalStandard') -Force | Out-Null
    Copy-Item -LiteralPath $wrapperSourcePath -Destination $wrapperPath
    Copy-Item -LiteralPath $vendorRuntimeSourcePath -Destination $vendorRuntimePath
    Set-Content -LiteralPath $fakeUvPath -Value $fakeUvScript -Encoding utf8NoBOM
    Set-Content -LiteralPath (Join-Path $tempRootFullPath 'modules/OfflinePayments/composer.json') -Value '{}' -Encoding utf8NoBOM
    Set-Content -LiteralPath (Join-Path $tempRootFullPath 'modules/PaypalStandard/composer.json') -Value '{}' -Encoding utf8NoBOM

    $env:PATH = "$(Split-Path -Parent $fakeUvPath)$([System.IO.Path]::PathSeparator)$originalPath"
    $env:PYTHONHASHSEED = 'caller-seed'
    Push-Location $tempRootFullPath

    try {
        & $wrapperPath
    }
    finally {
        Pop-Location
    }

    if ($env:PYTHONHASHSEED -cne 'caller-seed') {
        throw "Graphify wrapper did not restore the caller's PYTHONHASHSEED value. Actual: $env:PYTHONHASHSEED"
    }

    $invocations = @(Get-Content -LiteralPath $invocationLogPath)

    if ($invocations.Count -ne 3) {
        throw "Expected exactly three locked Graphify subprocesses, found $($invocations.Count)."
    }

    foreach ($invocation in $invocations) {
        if (-not $invocation.StartsWith('0|', [System.StringComparison]::Ordinal)) {
            throw "Graphify subprocess did not receive PYTHONHASHSEED=0: $invocation"
        }
    }

    $expectedCommandFragments = @(
        "graphify`textract`t.`t--code-only`t--no-gitignore"
        "graphify`tcluster-only`t.`t--no-label"
        "graphify`texport`thtml`t--graph"
    )

    for ($index = 0; $index -lt $expectedCommandFragments.Count; $index++) {
        if (-not $invocations[$index].Contains($expectedCommandFragments[$index], [System.StringComparison]::Ordinal)) {
            throw "Unexpected Graphify subprocess arguments: $($invocations[$index])"
        }
    }

    $forbiddenArguments = @('--watch', '--hook', '--model', '--backend', '--api-key')

    foreach ($forbiddenArgument in $forbiddenArguments) {
        if (($invocations -join "`n") -match [regex]::Escape($forbiddenArgument)) {
            throw "Graphify wrapper introduced forbidden argument: $forbiddenArgument"
        }
    }

    $graphHtmlPath = Join-Path $tempRootFullPath 'graphify-out/graph.html'
    $graphHtml = Get-Content -LiteralPath $graphHtmlPath -Raw

    if ($graphHtml -match '(?i)<script\b[^>]*\bsrc\s*=') {
        throw 'Graphify wrapper left an external script dependency in graph.html.'
    }

    if ($graphHtml -notmatch [regex]::Escape('* @version 9.1.6')) {
        throw 'Graphify wrapper did not inline the pinned vis-network runtime.'
    }

    if ($graphHtml -notmatch '<title>graphify - graphify-out/graph\.html</title>') {
        throw 'Graphify wrapper did not normalize the graph.html title.'
    }

    Write-Host 'Graphify wrapper smoke test passed.'
}
finally {
    $env:PATH = $originalPath

    if ($originalSeedWasSet) {
        $env:PYTHONHASHSEED = $originalSeed
    }
    else {
        Remove-Item Env:PYTHONHASHSEED -ErrorAction SilentlyContinue
    }

    if (
        (Test-Path -LiteralPath $tempRootFullPath) -and
        $tempRootFullPath.StartsWith($tempPrefix, [System.StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $tempRootFullPath).StartsWith('akaunting-graphify-wrapper-test-', [System.StringComparison]::Ordinal)
    ) {
        Remove-Item -LiteralPath $tempRootFullPath -Recurse -Force
    }
}
