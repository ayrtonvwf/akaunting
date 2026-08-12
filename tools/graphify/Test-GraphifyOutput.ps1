$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$graphifyOutPath = Join-Path $repoRoot 'graphify-out'
$graphJsonPath = Join-Path $graphifyOutPath 'graph.json'
$reportPath = Join-Path $graphifyOutPath 'GRAPH_REPORT.md'
$htmlPath = Join-Path $graphifyOutPath 'graph.html'
$allowedRoots = @('app/', 'modules/', 'config/', 'routes/', 'tests/')

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

function Test-IsAllowedGraphifySourcePath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $SourcePath,

        [Parameter(Mandatory = $true)]
        [string[]] $AllowedRoots
    )

    $normalizedSourcePath = $SourcePath.Replace('\', '/')

    if (
        [System.IO.Path]::IsPathRooted($SourcePath) -or
        $normalizedSourcePath.StartsWith('/', [System.StringComparison]::Ordinal) -or
        $normalizedSourcePath -match '^[A-Za-z]:'
    ) {
        return $false
    }

    $pathSegments = @($normalizedSourcePath.Split('/'))

    if ($pathSegments -contains '..') {
        return $false
    }

    $relativeSegments = @($pathSegments | Where-Object { $_ -and $_ -ne '.' })

    if ($relativeSegments.Count -lt 2) {
        return $false
    }

    $normalizedRelativePath = $relativeSegments -join '/'

    foreach ($allowedRoot in $AllowedRoots) {
        if ($normalizedRelativePath.StartsWith($allowedRoot, [System.StringComparison]::Ordinal)) {
            return $true
        }
    }

    return $false
}

function Assert-SelfContainedGraphHtml {
    param(
        [Parameter(Mandatory = $true)]
        [string] $HtmlPath
    )

    $htmlContent = Get-Content -LiteralPath $HtmlPath -Raw
    $scriptTags = [regex]::Matches($htmlContent, '<script\b[^>]*>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    foreach ($scriptTag in $scriptTags) {
        if ($scriptTag.Value -match '(?i)\bsrc\s*=') {
            throw "Graphify graph.html includes an external script dependency: $($scriptTag.Value)"
        }
    }

    $linkTags = [regex]::Matches($htmlContent, '<link\b[^>]*>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $relPattern = '(?i)\brel\s*=\s*(?:"(?<value>[^"]*)"|''(?<value>[^'']*)''|(?<value>[^\s>]+))'

    foreach ($linkTag in $linkTags) {
        $relMatch = [regex]::Match($linkTag.Value, $relPattern)

        if (
            $relMatch.Success -and
            @($relMatch.Groups['value'].Value -split '\s+') -contains 'stylesheet' -and
            $linkTag.Value -match '(?i)\bhref\s*='
        ) {
            throw "Graphify graph.html includes an external stylesheet dependency: $($linkTag.Value)"
        }
    }

    $styleTags = [regex]::Matches(
        $htmlContent,
        '<style\b[^>]*>(?<content>.*?)</style>',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    foreach ($styleTag in $styleTags) {
        if ($styleTag.Groups['content'].Value -match '(?i)@import\b') {
            throw 'Graphify graph.html includes an external stylesheet import.'
        }
    }

}

foreach ($requiredOutputPath in @($graphJsonPath, $reportPath, $htmlPath)) {
    if (-not (Test-Path -LiteralPath $requiredOutputPath)) {
        throw "Missing Graphify output file: $requiredOutputPath"
    }
}

Assert-SelfContainedGraphHtml -HtmlPath $htmlPath

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
    $normalizedSourcePath = $sourcePath.Replace('\', '/')

    if ($normalizedSourcePath -match '(^|/)(vendor|node_modules)(/|$)') {
        throw "Graphify graph.json includes out-of-scope dependency source path: $sourcePath"
    }

    if (-not (Test-IsAllowedGraphifySourcePath -SourcePath $sourcePath -AllowedRoots $allowedRoots)) {
        throw "Graphify graph.json includes out-of-scope source path: $sourcePath"
    }
}

Write-Host 'Graphify output is valid.'
