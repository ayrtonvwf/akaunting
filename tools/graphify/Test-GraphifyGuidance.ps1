$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$agentsPath = Join-Path $repoRoot 'AGENTS.md'
$claudeSkillPath = Join-Path $repoRoot '.claude\skills\graphify\SKILL.md'

if (-not (Test-Path -LiteralPath $agentsPath)) {
    throw "Missing agent guidance file: $agentsPath"
}

if (-not (Test-Path -LiteralPath $claudeSkillPath)) {
    throw "Missing Claude Code Graphify skill: $claudeSkillPath"
}

$agentsContent = Get-Content -LiteralPath $agentsPath -Raw

if (($agentsContent -split "`r?`n").Count -gt 120) {
    throw "AGENTS.md should remain concise; move detailed task workflows into project skills."
}

$requiredPatterns = [ordered]@{
    'Python 3.10+ prerequisite' = '(?im)Python 3\.10\+'
    'uv prerequisite' = '(?im)(^|\s)`?uv`?(\s|$)'
    'official project skill guidance' = '(?im)\.agents/skills/graphify/SKILL\.md'
    'Claude Code project skill guidance' = '(?im)\.claude/skills/graphify/SKILL\.md'
    'no hooks and MCP guidance' = '(?im)does not install its hooks or MCP integration'
    'repository-root rebuild guidance' = '(?im)repository root'
    'generator wrapper path' = '(?im)tools/graphify/Invoke-Graphify\.ps1'
    'verifier wrapper path' = '(?im)tools/graphify/Test-GraphifyOutput\.ps1'
    'locked query command' = '(?im)uv run --project tools/graphify --locked graphify query'
    'graph JSON path' = '(?im)graphify-out/graph\.json'
    'OfflinePayments module manifest' = '(?im)modules/OfflinePayments/composer\.json'
    'PaypalStandard module manifest' = '(?im)modules/PaypalStandard/composer\.json'
    'scope root app/' = '(?im)`?app/`?'
    'scope root modules/' = '(?im)`?modules/`?'
    'scope root config/' = '(?im)`?config/`?'
    'scope root routes/' = '(?im)`?routes/`?'
    'scope root tests/' = '(?im)`?tests/`?'
    'no API key guidance' = '(?im)no API key'
    'EXTRACTED confidence label' = '(?im)(^|\W)EXTRACTED(\W|$)'
    'INFERRED confidence label' = '(?im)(^|\W)INFERRED(\W|$)'
    'AMBIGUOUS confidence label' = '(?im)(^|\W)AMBIGUOUS(\W|$)'
}

foreach ($description in $requiredPatterns.Keys) {
    $pattern = $requiredPatterns[$description]

    if ($agentsContent -notmatch $pattern) {
        throw "AGENTS.md is missing required guidance for $description (pattern: $pattern)"
    }
}

Write-Host 'Graphify agent guidance is valid.'
