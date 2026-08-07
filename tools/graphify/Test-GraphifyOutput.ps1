$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$graphifyOutPath = Join-Path $repoRoot 'graphify-out'
$graphJsonPath = Join-Path $graphifyOutPath 'graph.json'
$reportPath = Join-Path $graphifyOutPath 'GRAPH_REPORT.md'
$htmlPath = Join-Path $graphifyOutPath 'graph.html'
$allowedRoots = @('app/', 'modules/', 'config/', 'routes/', 'tests/')
$requiredModuleManifests = @(
    (Join-Path $repoRoot 'modules/OfflinePayments/composer.json')
    (Join-Path $repoRoot 'modules/PaypalStandard/composer.json')
)

function Add-SourcePaths {
    param(
        [AllowNull()]
        $Value,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.HashSet[string]] $Paths
    )

    if ($null -eq $Value) {
        return
    }

    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($key in $Value.Keys) {
            $entry = $Value[$key]

            if ($key -eq 'source_file' -and $entry -is [string] -and -not [string]::IsNullOrWhiteSpace($entry)) {
                $null = $Paths.Add($entry)
            }

            Add-SourcePaths -Value $entry -Paths $Paths
        }

        return
    }

    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
        foreach ($item in $Value) {
            Add-SourcePaths -Value $item -Paths $Paths
        }

        return
    }

    $property = $Value.PSObject.Properties['source_file']

    if ($property -and $property.Value -is [string] -and -not [string]::IsNullOrWhiteSpace($property.Value)) {
        $null = $Paths.Add($property.Value)
    }

    foreach ($childProperty in $Value.PSObject.Properties) {
        Add-SourcePaths -Value $childProperty.Value -Paths $Paths
    }
}

foreach ($manifestPath in $requiredModuleManifests) {
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "Missing required module manifest: $manifestPath"
    }
}

foreach ($requiredOutputPath in @($graphJsonPath, $reportPath, $htmlPath)) {
    if (-not (Test-Path -LiteralPath $requiredOutputPath)) {
        throw "Missing Graphify output file: $requiredOutputPath"
    }
}

try {
    $graph = Get-Content -LiteralPath $graphJsonPath -Raw | ConvertFrom-Json -Depth 100
}
catch {
    throw "Graphify graph.json is not valid JSON: $($_.Exception.Message)"
}

$sourcePaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
Add-SourcePaths -Value $graph -Paths $sourcePaths

if ($sourcePaths.Count -eq 0) {
    throw 'Graphify graph.json did not expose any source_file values to verify.'
}

foreach ($sourcePath in $sourcePaths) {
    $normalizedSourcePath = $sourcePath.Replace('\', '/').TrimStart('./')

    if ($normalizedSourcePath -match '(^|/)(vendor|node_modules)(/|$)') {
        throw "Graphify graph.json includes out-of-scope dependency source path: $sourcePath"
    }

    $isAllowedPath = $false

    foreach ($allowedRoot in $allowedRoots) {
        if ($normalizedSourcePath.StartsWith($allowedRoot, [System.StringComparison]::Ordinal)) {
            $isAllowedPath = $true
            break
        }
    }

    if (-not $isAllowedPath) {
        throw "Graphify graph.json includes out-of-scope source path: $sourcePath"
    }
}

Write-Host 'Graphify output is valid.'
