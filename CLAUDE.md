# AGENTS

<!-- OPENWIKI:START -->

## OpenWiki

This repository has a generated `openwiki/` evidence index. It is optional just-in-time context, not required startup reading.

- Treat source code and tests as authoritative. A brief's unknowns and review items are verification gaps, not automatic requirements.
- Prefer the narrowest quiet validation that proves the changed behavior. Preserve complete failure output.

The scheduled OpenWiki GitHub Actions workflow refreshes the repository wiki. Do not hand-edit generated OpenWiki pages unless explicitly asked; prefer updating source code/docs and letting OpenWiki regenerate.

<!-- OPENWIKI:END -->

## Evidence order

1. Read `openwiki/index.md`, `openwiki/quickstart.md`, and the relevant system or workflow page for orientation.
2. Use the locked Graphify query for source relationships.
3. Verify behavior in current source, configuration, manifests/lockfiles, and focused tests.
4. Consult external documentation only when local evidence cannot establish the fact.

OpenWiki is a navigation map, not an override of implementation evidence. When it is stale or incomplete, report the page, source location, and discrepancy. Do not edit the OpenWiki bundle.

## Maintenance workflows

- For unfamiliar paths, use `akaunting-codebase-navigation`.
- For test additions, use `akaunting-test-coverage`; read `openwiki/testing.md`, and use the in-memory SQLite PHPUnit configuration in `phpunit.xml`.
- For Composer, NPM, or lockfile changes, use `akaunting-dependency-upgrade`; check root and module manifests plus `overrides/` before changing a constraint.

### Parallel test isolation

`php artisan test --parallel` runs multiple worker processes against this repo. Any new file-backed driver, temp path, or on-disk cache touched by tests must be scoped per worker via `Tests\Concerns\IsolatesParallelTestState::testToken()` (see `tests/CreatesApplication.php`), or it will race across workers the same way the shared Blade compiled-view directory once did (issue #5). `tests/Unit/ParallelIsolationTest.php` guards the known isolation points — extend it when adding a new shared-writable path.

### Project map

- `app/` contains the application’s Laravel domain, HTTP, jobs, models, and supporting code.
- `modules/` contains bundled extension modules, including OfflinePayments and PaypalStandard.
- `config/` contains application configuration.
- `routes/` defines web, API, portal, and other HTTP entry points.
- `database/` contains factories, migrations, and seed data.
- `tests/` contains the core PHPUnit feature and unit tests.
- `overrides/` holds repository-maintained dependency overrides.
- `openwiki/` is the generated evidence-navigation index.

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
