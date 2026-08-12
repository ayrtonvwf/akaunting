$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$projectSkills = @('akaunting-codebase-navigation', 'akaunting-test-coverage', 'akaunting-dependency-upgrade')

foreach ($skill in $projectSkills) {
    $canonicalDirectory = Join-Path $repoRoot ".agents\skills\$skill"
    $claudeDirectory = Join-Path $repoRoot ".claude\skills\$skill"

    if (-not (Test-Path -LiteralPath $canonicalDirectory -PathType Container)) {
        throw "Missing canonical project skill directory: $canonicalDirectory"
    }

    New-Item -ItemType Directory -Path $claudeDirectory -Force | Out-Null
    Copy-Item -Path (Join-Path $canonicalDirectory '*') -Destination $claudeDirectory -Recurse -Force
}

# AGENTS.md is the single source of root agent guidance. CLAUDE.md is generated from it so the
# two cannot drift; Test-AgentHarness.ps1 asserts they are byte-identical.
$agentsPath = Join-Path $repoRoot 'AGENTS.md'
if (-not (Test-Path -LiteralPath $agentsPath -PathType Leaf)) {
    throw "Missing canonical root guidance: $agentsPath"
}

Copy-Item -LiteralPath $agentsPath -Destination (Join-Path $repoRoot 'CLAUDE.md') -Force

Write-Host 'Project skill mirrors synchronized.'
Write-Host 'CLAUDE.md regenerated from AGENTS.md.'
