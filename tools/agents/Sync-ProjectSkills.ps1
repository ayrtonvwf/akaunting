$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$projectSkills = @('akaunting-codebase-navigation')

foreach ($skill in $projectSkills) {
    $canonicalDirectory = Join-Path $repoRoot ".agents\skills\$skill"
    $claudeDirectory = Join-Path $repoRoot ".claude\skills\$skill"

    if (-not (Test-Path -LiteralPath $canonicalDirectory -PathType Container)) {
        throw "Missing canonical project skill directory: $canonicalDirectory"
    }

    New-Item -ItemType Directory -Path $claudeDirectory -Force | Out-Null
    Copy-Item -Path (Join-Path $canonicalDirectory '*') -Destination $claudeDirectory -Recurse -Force
}

Write-Host 'Project skill mirrors synchronized.'
