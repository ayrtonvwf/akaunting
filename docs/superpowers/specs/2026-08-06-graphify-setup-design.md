# Graphify setup design

## Goal

Add a reproducible, repository-local Graphify setup for the Northstar harness. The setup must create and commit a deterministic code graph that agents and developers can query without relying on machine-global assistant registration or an API-backed semantic pass.

This implements the code-graph layer described in `specs/northstar/PLAN.md`. It answers structural questions such as where a symbol is used and what references it; it does not replace product documentation, the planned generated wiki, or verified repository guidance.

## Scope

The graph includes only these source roots:

- `app/`
- `modules/`
- `config/`
- `routes/`
- `tests/`

`modules/` is deliberately included even though it is Git-ignored: Composer installs the two module packages there, and the Northstar plan identifies that code as part of the application surface. Generated assets, documentation, dependencies, frontend packages, and every other root are excluded.

## Architecture

Graphify is installed and run as a local `uv` project under `tools/graphify/`:

- `pyproject.toml` pins the `graphifyy` package and declares Python 3.10 or later.
- `uv.lock` locks Graphify and all of its transitive dependencies for repeatable installation.
- A repository PowerShell wrapper invokes Graphify through that locked project from the repository root.
- `.graphifyignore` is an allow-list for the five source roots. The wrapper uses `--no-gitignore` so the Git-ignored installed modules are visible, while the allow-list still prevents all other paths from being indexed.

The wrapper performs a full `graphify extract . --code-only` rebuild. The code-only path is local tree-sitter extraction: it uses no model, API key, assistant integration, watcher, hook, or background service.

## Outputs and versioning

The portable graph outputs are committed in `graphify-out/`:

- `graph.json` — machine-readable graph used by Graphify queries.
- `GRAPH_REPORT.md` — generated structural summary.
- `graph.html` — interactive visual graph.
- Graphify's portable manifest, when produced.

Machine-specific or high-churn Graphify cache and cost files are ignored. No Graphify command modifies global Codex configuration or installs a per-machine assistant skill.

The committed graph is the baseline available immediately after checkout. Rebuilding it is an explicit repository action, not an automatic Git hook; that keeps graph updates reviewable and avoids hidden local behavior.

## Agent guidance

`AGENTS.md` documents the prerequisites, exact rebuild command, query examples, output location, and evidence rules. It defines Graphify as structural evidence only:

- `EXTRACTED` edges may be cited as source-derived structural facts.
- `INFERRED` and `AMBIGUOUS` edges are leads, not proof; an agent must verify their source locations before relying on them.
- Runtime mechanisms outside static parsing remain outside Graphify's authority, including macros, facade accessors, and Composer/module discovery.

## Failure handling

The wrapper fails before generating output if it is invoked outside the repository root, `uv` is unavailable, or either installed module directory is absent. The module check prevents a partial graph from being mistaken for the required application graph. Its failure message directs the user to install dependencies with Composer before retrying.

The full rebuild replaces the committed baseline only after Graphify completes successfully. A failed extraction must leave the prior committed graph intact for review and query.

## Verification

Automated verification checks that:

1. the expected generated files exist;
2. `graph.json` is valid JSON and contains graph data;
3. indexed source paths are confined to `app/`, `modules/`, `config/`, `routes/`, or `tests/`;
4. no indexed path begins in `vendor/` or `node_modules/`.

Manual acceptance is a clean-machine reproduction: install Python 3.10+ and `uv`, install Composer dependencies, run the documented repository command, and query the generated or committed graph through the locked Graphify invocation. The graph must be usable with no API key and no machine-global Graphify or Codex setup.

## Non-goals

- Installing Graphify globally or registering its Codex integration.
- Building the planned OpenWiki/OKF layer.
- Indexing vendor dependencies, frontend packages, generated assets, or documentation.
- Adding a Git hook, file watcher, CI job, MCP server, or semantic/model-backed Graphify pass.
