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
Write-Host 'Root agent guidance is valid.'
