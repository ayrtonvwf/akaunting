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
