# AGENTS

## Graphify

For codebase architecture and relationship questions, use the project-scoped Graphify skill instead of reproducing its workflow here:

- Cross-agent runtimes: `.agents/skills/graphify/SKILL.md`
- Claude Code: `.claude/skills/graphify/SKILL.md`

Repository-specific constraints:

- The committed baseline is under `graphify-out/`; rebuilds are explicit actions.
- Run `pwsh -File tools/graphify/Invoke-Graphify.ps1` from the repository root.
- Validate with `pwsh -File tools/graphify/Test-GraphifyOutput.ps1` and `pwsh -File tools/graphify/Test-GraphifyGuidance.ps1`.
- Use the locked local query command for reproducible checks: `uv run --project tools/graphify --locked graphify query "<question>" --graph graphify-out/graph.json`.
- Rebuild prerequisites are Python 3.10+, `uv`, and Composer modules at `modules/OfflinePayments/composer.json` and `modules/PaypalStandard/composer.json`.
- The graph scope is `app/`, `modules/`, `config/`, `routes/`, and `tests/`; exclude vendor, frontend, documentation, and generated assets.
- Treat Graphify as structural evidence: `EXTRACTED` is source-derived; `INFERRED` and `AMBIGUOUS` require source inspection.
- Graphify requires no API key, and this repository does not install its hooks or MCP integration.

<!-- OPENWIKI:START -->

## OpenWiki

This repository has a generated `openwiki/` evidence index. It is optional just-in-time context, not required startup reading.

- Treat source code and tests as authoritative. A brief's unknowns and review items are verification gaps, not automatic requirements.
- Prefer the narrowest quiet validation that proves the changed behavior. Preserve complete failure output.

The scheduled OpenWiki GitHub Actions workflow refreshes the repository wiki. Do not hand-edit generated OpenWiki pages unless explicitly asked; prefer updating source code/docs and letting OpenWiki regenerate.

<!-- OPENWIKI:END -->
