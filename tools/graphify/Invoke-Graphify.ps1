$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$repoRootPath = $repoRoot.ProviderPath
$currentLocationPath = (Resolve-Path '.').ProviderPath
$graphifyProjectPath = Join-Path $repoRootPath 'tools/graphify'
$graphJsonPath = Join-Path $repoRootPath 'graphify-out/graph.json'
$graphHtmlPath = Join-Path $repoRootPath 'graphify-out/graph.html'
$portableGraphHtmlTitle = 'graphify - graphify-out/graph.html'
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

function Set-PortableGraphifyHtmlTitle {
    param(
        [Parameter(Mandatory = $true)]
        [string] $HtmlPath,

        [Parameter(Mandatory = $true)]
        [string] $PortableTitle
    )

    if (-not (Test-Path -LiteralPath $HtmlPath)) {
        throw "Graphify did not produce graph.html at $HtmlPath"
    }

    $htmlContent = Get-Content -LiteralPath $HtmlPath -Raw
    $titlePattern = '<title>graphify - .*?</title>'
    $replacement = "<title>$PortableTitle</title>"
    $updatedHtmlContent = [regex]::Replace($htmlContent, $titlePattern, $replacement, 1)

    if ($updatedHtmlContent -eq $htmlContent -and $htmlContent -notmatch [regex]::Escape($replacement)) {
        throw "Graphify graph.html title could not be normalized at $HtmlPath"
    }

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

& $uvExecutablePath @extractArguments

if ($LASTEXITCODE -ne 0) {
    throw "Graphify extract failed with exit code $LASTEXITCODE."
}

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

& $uvExecutablePath @clusterArguments

if ($LASTEXITCODE -ne 0) {
    throw "Graphify cluster-only failed with exit code $LASTEXITCODE."
}

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

& $uvExecutablePath @htmlArguments

if ($LASTEXITCODE -ne 0) {
    throw "Graphify export html failed with exit code $LASTEXITCODE."
}

Set-PortableGraphifyHtmlTitle -HtmlPath $graphHtmlPath -PortableTitle $portableGraphHtmlTitle
