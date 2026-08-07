# AGENTS

## Graphify harness

Use Graphify for structural code-graph questions in this repository. The committed baseline lives in `graphify-out/`, and rebuilds are explicit repository actions.

### Prerequisites

- Python 3.10+
- `uv`
- Global interactive CLI (one-time user install): `uv tool install --force "graphifyy==0.9.34"`, followed by `uv tool update-shell` and a new terminal. This provides the `graphify` command on PATH.
- Composer-installed modules present at:
  - `modules/OfflinePayments/composer.json`
  - `modules/PaypalStandard/composer.json`

If either module manifest is missing, install the repository's Composer dependencies before rebuilding the graph.

### Authoritative commands

Run these from the repository root.

- Generator wrapper file: `tools/graphify/Invoke-Graphify.ps1`
- Output verifier file: `tools/graphify/Test-GraphifyOutput.ps1`
- Guidance verifier file: `tools/graphify/Test-GraphifyGuidance.ps1`

- Rebuild the committed graph:
  - `pwsh -File .\tools\graphify\Invoke-Graphify.ps1`
- Verify the committed output set:
  - `pwsh -File .\tools\graphify\Test-GraphifyOutput.ps1`
- Validate this guidance file:
  - `pwsh -File .\tools\graphify\Test-GraphifyGuidance.ps1`
- Query the committed graph JSON with the locked local Graphify project:
  - `uv run --project tools/graphify --locked graphify query "<question>" --graph graphify-out/graph.json`
- Query the committed graph JSON with the globally installed CLI:
  - `graphify query "<question>" --graph graphify-out/graph.json`

The repository-local locked command is authoritative for reproducible checks. The global `graphify` command is the normal interactive form for agents and developers after the one-time user install above.

### Query discovery workflow

Agents should not guess Graphify's generated node IDs. Start with a human-readable symbol, method, or repository-relative file path:

1. Resolve the symbol and inspect its source path:
   - `graphify explain "<symbol-or-file>" --graph graphify-out/graph.json`
2. If Graphify reports multiple matches, choose the match by its repository-relative `src` path and copy the corresponding `id`.
3. Run the precise traversal using that ID, selecting the relevant edge context:
   - `graphify query "<node-id>" --context call --budget 1500 --graph graphify-out/graph.json`

For example, `explain "getSelectedRecords"` identifies the matching method in `app/Abstracts/BulkAction.php`; use the reported node ID for a precise call-graph query. `EXTRACTED` edges can be cited as structural evidence, while `INFERRED` and `AMBIGUOUS` edges require source inspection.

The rebuild wrapper must be run from the repository root. It uses the locked local Graphify project in `tools/graphify/`, requires no API key, and does not depend on the machine-global Graphify install. The official project-scoped agent skill is at `.agents/skills/graphify/SKILL.md`; its optional hook and MCP workflows are not installed or required for this repository.

### Output set

Graphify writes and verifies these portable outputs under `graphify-out/`:

- `graph.json`
- `GRAPH_REPORT.md`
- `graph.html`
- `manifest.json` when Graphify produces it

Use `graphify-out/graph.json` for locked queries.

### Scope

The graph is intentionally limited to these roots:

- `app/`
- `modules/`
- `config/`
- `routes/`
- `tests/`

Everything else is out of scope, including `vendor/`, `node_modules/`, documentation, generated assets, and frontend packages.

### Evidence rules

Treat Graphify as structural evidence only.

- `EXTRACTED` edges may be cited as source-derived structural facts.
- `INFERRED` edges are leads, not proof. Inspect the cited source locations before relying on them.
- `AMBIGUOUS` edges are leads, not proof. Inspect the cited source locations before relying on them.

Graphify is not authoritative for runtime behavior outside static parsing, including macros, facade accessors, and Composer or module discovery behavior.
