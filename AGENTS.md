# AGENTS

## Graphify harness

Use Graphify for structural code-graph questions in this repository. The committed baseline lives in `graphify-out/`, and rebuilds are explicit repository actions.

### Prerequisites

- Python 3.10+
- `uv`
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

The rebuild wrapper must be run from the repository root. It uses the locked local Graphify project in `tools/graphify/`, requires no API key, and does not depend on any machine-global Graphify or Codex installation.

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
