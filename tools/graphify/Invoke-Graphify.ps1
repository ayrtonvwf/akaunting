$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$repoRootPath = $repoRoot.ProviderPath
$currentLocationPath = (Resolve-Path '.').ProviderPath
$graphifyProjectPath = Join-Path $repoRootPath 'tools/graphify'
$graphJsonPath = Join-Path $repoRootPath 'graphify-out/graph.json'
$graphHtmlPath = Join-Path $repoRootPath 'graphify-out/graph.html'
$portableGraphHtmlTitle = 'graphify - graphify-out/graph.html'
$visNetworkRuntimePath = Join-Path $graphifyProjectPath 'vendor/vis-network-9.1.6.min.js'
$visNetworkRuntimeUrl = 'https://unpkg.com/vis-network@9.1.6/standalone/umd/vis-network.min.js'
$visNetworkRuntimeSha384 = 'Ux6phic9PEHJ38YtrijhkzyJ8yQlH8i/+buBR8s3mAZOJrP1gwyvAcIYl3GWtpX1'
$requiredModuleManifests = @(
    (Join-Path $repoRootPath 'modules/OfflinePayments/composer.json')
    (Join-Path $repoRootPath 'modules/PaypalStandard/composer.json')
)

function Get-UvExecutablePath {
    $uvCommand = Get-Command uv -ErrorAction SilentlyContinue

    if ($uvCommand) {
        return $uvCommand.Source
    }

    $candidatePaths = @(
        (Join-Path $env:LOCALAPPDATA 'Microsoft/WinGet/Packages/astral-sh.uv_Microsoft.Winget.Source_8wekyb3d8bbwe/uv.exe')
        (Join-Path $env:USERPROFILE '.local/bin/uv.exe')
        (Join-Path $env:USERPROFILE 'AppData/Roaming/Python/Scripts/uv.exe')
        (Join-Path $env:ProgramFiles 'uv/uv.exe')
    )

    foreach ($candidatePath in $candidatePaths) {
        if ($candidatePath -and (Test-Path -LiteralPath $candidatePath)) {
            return (Resolve-Path -LiteralPath $candidatePath).ProviderPath
        }
    }

    return $null
}

function Invoke-LockedGraphifyCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string] $UvExecutablePath,

        [Parameter(Mandatory = $true)]
        [string[]] $Arguments,

        [Parameter(Mandatory = $true)]
        [string] $Operation
    )

    $hashSeedWasSet = Test-Path Env:PYTHONHASHSEED
    $previousHashSeed = $env:PYTHONHASHSEED

    try {
        $env:PYTHONHASHSEED = '0'
        & $UvExecutablePath @Arguments
        $exitCode = $LASTEXITCODE
    }
    finally {
        if ($hashSeedWasSet) {
            $env:PYTHONHASHSEED = $previousHashSeed
        }
        else {
            Remove-Item Env:PYTHONHASHSEED -ErrorAction SilentlyContinue
        }
    }

    if ($exitCode -ne 0) {
        throw "Graphify $Operation failed with exit code $exitCode."
    }
}

function Set-PortableGraphifyHtml {
    param(
        [Parameter(Mandatory = $true)]
        [string] $HtmlPath,

        [Parameter(Mandatory = $true)]
        [string] $PortableTitle,

        [Parameter(Mandatory = $true)]
        [string] $RuntimePath,

        [Parameter(Mandatory = $true)]
        [string] $RuntimeUrl,

        [Parameter(Mandatory = $true)]
        [string] $RuntimeSha384
    )

    if (-not (Test-Path -LiteralPath $HtmlPath)) {
        throw "Graphify did not produce graph.html at $HtmlPath"
    }

    if (-not (Test-Path -LiteralPath $RuntimePath)) {
        throw "Missing vendored vis-network runtime: $RuntimePath"
    }

    $runtimeBytes = [System.IO.File]::ReadAllBytes($RuntimePath)
    $actualRuntimeSha384 = [Convert]::ToBase64String([Security.Cryptography.SHA384]::HashData($runtimeBytes))

    if ($actualRuntimeSha384 -cne $RuntimeSha384) {
        throw "Vendored vis-network runtime failed its SHA-384 integrity check: $RuntimePath"
    }

    $runtimeContent = [System.Text.Encoding]::UTF8.GetString($runtimeBytes)

    if ($runtimeContent -match '(?i)</script') {
        throw "Vendored vis-network runtime cannot be safely inlined because it contains a closing script tag: $RuntimePath"
    }

    $htmlContent = Get-Content -LiteralPath $HtmlPath -Raw
    $titlePattern = '<title>graphify - .*?</title>'
    $titleReplacement = "<title>$PortableTitle</title>"
    $updatedHtmlContent = [regex]::Replace($htmlContent, $titlePattern, $titleReplacement, 1)

    if ($updatedHtmlContent -eq $htmlContent -and $htmlContent -notmatch [regex]::Escape($titleReplacement)) {
        throw "Graphify graph.html title could not be normalized at $HtmlPath"
    }

    $runtimePattern = '<script\b(?=[^>]*\bsrc\s*=\s*["'']' + [regex]::Escape($RuntimeUrl) + '["''])[^>]*>\s*</script>'
    $runtimeRegex = [regex]::new(
        $runtimePattern,
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    $runtimeMatches = $runtimeRegex.Matches($updatedHtmlContent)

    if ($runtimeMatches.Count -ne 1) {
        throw "Expected exactly one pinned vis-network script dependency in graph.html, found $($runtimeMatches.Count)."
    }

    $inlineRuntime = @"
<!-- vis-network 9.1.6 is inlined for offline use; license texts are vendored under tools/graphify/vendor/. -->
<script>
$runtimeContent
</script>
"@
    $updatedHtmlContent = $runtimeRegex.Replace(
        $updatedHtmlContent,
        [System.Text.RegularExpressions.MatchEvaluator] { param($match) $inlineRuntime },
        1
    )

    Set-Content -LiteralPath $HtmlPath -Value $updatedHtmlContent -Encoding utf8NoBOM
}

if ($currentLocationPath -ne $repoRootPath) {
    throw "Invoke-Graphify.ps1 must be run from the repository root: $repoRootPath"
}

$uvExecutablePath = Get-UvExecutablePath

if (-not $uvExecutablePath) {
    throw 'uv was not found. Open a fresh PowerShell session or install uv 0.12.0 before running this wrapper.'
}

foreach ($manifestPath in $requiredModuleManifests) {
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "Missing required module manifest: $manifestPath"
    }
}

$extractArguments = @(
    'run'
    '--project'
    $graphifyProjectPath
    '--locked'
    'graphify'
    'extract'
    '.'
    '--code-only'
    '--no-gitignore'
)

Invoke-LockedGraphifyCommand -UvExecutablePath $uvExecutablePath -Arguments $extractArguments -Operation 'extract'

$clusterArguments = @(
    'run'
    '--project'
    $graphifyProjectPath
    '--locked'
    'graphify'
    'cluster-only'
    '.'
    '--no-label'
)

Invoke-LockedGraphifyCommand -UvExecutablePath $uvExecutablePath -Arguments $clusterArguments -Operation 'cluster-only'

if (-not (Test-Path -LiteralPath $graphJsonPath)) {
    throw "Graphify did not produce graph.json at $graphJsonPath"
}

try {
    $graphData = Get-Content -LiteralPath $graphJsonPath -Raw | ConvertFrom-Json -Depth 100
}
catch {
    throw "Graphify graph.json could not be parsed after cluster-only: $($_.Exception.Message)"
}

$graphNodeCount = @($graphData.nodes).Count
$graphHtmlNodeLimit = [Math]::Max(5000, $graphNodeCount)
$htmlArguments = @(
    'run'
    '--project'
    $graphifyProjectPath
    '--locked'
    'graphify'
    'export'
    'html'
    '--graph'
    $graphJsonPath
    '--node-limit'
    $graphHtmlNodeLimit.ToString()
)

Invoke-LockedGraphifyCommand -UvExecutablePath $uvExecutablePath -Arguments $htmlArguments -Operation 'export html'

Set-PortableGraphifyHtml `
    -HtmlPath $graphHtmlPath `
    -PortableTitle $portableGraphHtmlTitle `
    -RuntimePath $visNetworkRuntimePath `
    -RuntimeUrl $visNetworkRuntimeUrl `
    -RuntimeSha384 $visNetworkRuntimeSha384
