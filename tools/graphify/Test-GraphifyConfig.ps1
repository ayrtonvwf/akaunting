$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$projectPath = Join-Path $PSScriptRoot 'pyproject.toml'
$ignorePath = Join-Path $repoRoot '.graphifyignore'

if (-not (Test-Path -LiteralPath $projectPath)) {
    throw "Missing Graphify project file: $projectPath"
}

if (-not (Test-Path -LiteralPath $ignorePath)) {
    throw "Missing Graphify ignore file: $ignorePath"
}

$projectContent = Get-Content -LiteralPath $projectPath -Raw
$ignoreEntries = Get-Content -LiteralPath $ignorePath | ForEach-Object { $_.Trim() } | Where-Object { $_ }

$requiredProjectPatterns = @(
    '(?m)^name\s*=\s*"akaunting-graphify"\s*$'
    '(?m)^version\s*=\s*"0.1.0"\s*$'
    '(?m)^requires-python\s*=\s*">=3.10"\s*$'
    '(?m)^\s*"graphifyy==0\.9\.34"\s*$'
)

foreach ($pattern in $requiredProjectPatterns) {
    if ($projectContent -notmatch $pattern) {
        throw "Graphify project config is missing required content matching: $pattern"
    }
}

$expectedIgnoreEntries = @(
    '*'
    '!app/'
    '!app/**'
    '!modules/'
    '!modules/**/'
    '!modules/**/*.php'
    '!modules/**/composer.json'
    '!config/'
    '!config/**'
    '!routes/'
    '!routes/**'
    '!tests/'
    '!tests/**'
)

$normalizedExpectedIgnoreContent = $expectedIgnoreEntries -join "`n"
$normalizedActualIgnoreContent = $ignoreEntries -join "`n"

if ($normalizedActualIgnoreContent -cne $normalizedExpectedIgnoreContent) {
    throw @"
Graphify ignore policy must exactly match the normalized allow-list.
Expected:
$normalizedExpectedIgnoreContent
Actual:
$normalizedActualIgnoreContent
"@
}

Write-Host 'Graphify configuration is valid.'
