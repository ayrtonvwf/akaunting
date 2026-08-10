$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$agentsPath = Join-Path $repoRoot 'AGENTS.md'
$claudePath = Join-Path $repoRoot 'CLAUDE.md'

function Test-RequiredText {
    param(
        [string] $Content,
        [string] $Text
    )

    if (-not $Content.Contains($Text)) { throw "Missing root guidance: $Text" }
}

if (-not (Test-Path -LiteralPath $agentsPath)) { throw "Missing $agentsPath" }
if (-not (Test-Path -LiteralPath $claudePath)) { throw "Missing $claudePath" }
if ((Get-FileHash -LiteralPath $agentsPath -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $claudePath -Algorithm SHA256).Hash) {
    throw 'AGENTS.md and CLAUDE.md must be byte-identical.'
}

$content = Get-Content -LiteralPath $agentsPath -Raw
foreach ($text in @('openwiki/index.md', 'openwiki/quickstart.md', 'openwiki/testing.md', 'Graphify', 'EXTRACTED', 'INFERRED', 'AMBIGUOUS', 'Do not edit the OpenWiki bundle')) {
    Test-RequiredText -Content $content -Text $text
}

$externalSkills = @('test-driven-development', 'systematic-debugging', 'verification-before-completion', 'using-superpowers')
foreach ($skill in $externalSkills) {
    foreach ($root in @('.agents\skills', '.claude\skills')) {
        $path = Join-Path $repoRoot "$root\$skill\SKILL.md"
        if (-not (Test-Path -LiteralPath $path)) { throw "Missing deployed external skill: $path" }
    }
}

$projectSkills = @('akaunting-codebase-navigation')
foreach ($skill in $projectSkills) {
    $canonical = Join-Path $repoRoot ".agents\skills\$skill\SKILL.md"
    $claudeMirror = Join-Path $repoRoot ".claude\skills\$skill\SKILL.md"
    if (-not (Test-Path -LiteralPath $canonical)) { throw "Missing canonical project skill: $canonical" }
    if (-not (Test-Path -LiteralPath $claudeMirror)) { throw "Missing Claude mirror: $claudeMirror" }
    if ((Get-FileHash $canonical -Algorithm SHA256).Hash -ne (Get-FileHash $claudeMirror -Algorithm SHA256).Hash) { throw "Skill mirror drift: $skill" }
    $frontmatter = Get-Content -LiteralPath $canonical -Raw
    if ($frontmatter -notmatch "(?ms)^---\r?\nname: $skill\r?\ndescription: .+?\r?\n---") { throw "Invalid frontmatter: $skill" }
}

Write-Host 'Root agent guidance is valid.'
