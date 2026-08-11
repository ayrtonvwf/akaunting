# Graphify Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a pinned, repository-local Graphify setup that builds and commits an offline structural graph for Akaunting's PHP application and tests.

**Architecture:** Install Python and uv locally on this development machine, then use a locked `uv` project in `tools/graphify/` for Graphify. A root allow-list keeps extraction confined to `app/`, `modules/`, `config/`, `routes/`, and `tests/`; portable results are committed under `graphify-out/`.

**Tech Stack:** Python 3.10+, uv, Graphify `graphifyy==0.9.34`, PowerShell 7+, tree-sitter AST extraction, JSON, Git.

## Global Constraints

- Use `graphify extract . --code-only --no-gitignore`; no model/API call, API key, assistant registration, hook, watcher, CI, or MCP server.
- Pin Graphify to `0.9.34` and commit its uv lock file.
- Include only `app/`, `modules/`, `config/`, `routes/`, and `tests/`; required installed module manifests must exist.
- Commit portable Graphify output; ignore only its cache and cost files.
- Cite `EXTRACTED` edges as structural evidence; inspect source for `INFERRED` and `AMBIGUOUS` edges.

---

## File structure

| File | Responsibility |
| --- | --- |
| `.graphifyignore` | Source-root allow-list. |
| `.gitignore` | Ignores Graphify cache/cost state only. |
| `tools/graphify/pyproject.toml` and `uv.lock` | Pinned reproducible Graphify environment. |
| `tools/graphify/Invoke-Graphify.ps1` | Preflight checks and full extraction. |
| `tools/graphify/Test-GraphifyOutput.ps1` | Output/JSON/scope verification. |
| `AGENTS.md` | Agent-facing rebuild/query/evidence instructions. |
| `graphify-out/` | Committed graph, report, visualisation, and manifest. |

### Task 1: Install host prerequisites

**Files:** none.

**Interfaces:** Produces `python` (3.10+) and `uv` on PATH.

- [ ] **Step 1: Confirm missing tools**

Run `python --version` and `uv --version`; record their absence before installation.

- [ ] **Step 2: Install Python and uv**

Use the Windows package manager to install a current Python 3.12 release and Astral uv, then open a new PowerShell process so PATH refreshes.

- [ ] **Step 3: Verify tools**

Run `python --version` and `uv --version`.

Expected: Python is 3.10+ and uv returns a version.

- [ ] **Step 4: Commit**

No repository commit; the installed tools are host prerequisites.

### Task 2: Add and lock the repository-local tool

**Files:**

- Create: `.graphifyignore`
- Create: `tools/graphify/pyproject.toml`
- Create: `tools/graphify/uv.lock`
- Create: `tools/graphify/Test-GraphifyConfig.ps1`

**Interfaces:** Produces `uv run --project tools/graphify --locked graphify` and the shared scope policy.

- [ ] **Step 1: Write a failing configuration test**

The test must read the project and ignore files, require `requires-python = ">=3.10"` and `graphifyy==0.9.34`, and require `*` plus both directory and descendant negations for all five source roots.

- [ ] **Step 2: Run the test**

Expected: it fails until the configuration exists.

- [ ] **Step 3: Implement the config**

Create a `pyproject.toml` with project name `akaunting-graphify`, version `0.1.0`, Python floor `>=3.10`, and dependency `graphifyy==0.9.34`. Create `.graphifyignore` as an allow-list: ignore `*`, then unignore each source root and its descendants.

- [ ] **Step 4: Lock and verify**

Run `uv lock --project tools/graphify`, `uv run --project tools/graphify --locked graphify --version`, and the configuration test.

Expected: locked `0.9.34` and a passing test.

- [ ] **Step 5: Commit**

Commit the config, lock file, ignore policy, and test as `build: add locked graphify tool`.

### Task 3: Build and verify the committed graph

**Files:**

- Create: `tools/graphify/Invoke-Graphify.ps1`
- Create: `tools/graphify/Test-GraphifyOutput.ps1`
- Modify: `.gitignore`
- Create: `graphify-out/`

**Interfaces:** The generator must fail outside the repository root, without uv, or without either module manifest. It invokes the locked Graphify command with `extract . --code-only --no-gitignore`; the verifier requires `graph.json`, `GRAPH_REPORT.md`, and `graph.html`, parses JSON, and rejects source paths outside the five roots.

- [ ] **Step 1: Write the output verifier first**

Make the verifier fail for absent module manifests, missing output files, invalid JSON, and `vendor/` or `node_modules/` source paths.

- [ ] **Step 2: Confirm its initial failure**

Expected: it fails because `graphify-out/` does not yet exist.

- [ ] **Step 3: Implement and parser-check the generator**

Use a PowerShell wrapper around the locked uv command. It must not call Graphify install or pass a model backend. Parse-check both scripts with `System.Management.Automation.Language.Parser`.

- [ ] **Step 4: Ignore local state and generate**

Add only `graphify-out/cache/` and `graphify-out/cost.json` to `.gitignore`. Confirm both Composer-installed module manifests, run the generator from the root, inspect Graphify's emitted node-path field, and finish the verifier against that observed schema.

- [ ] **Step 5: Verify and query**

Run the verifier and a locked `graphify query` against `graphify-out/graph.json`. Confirm the output retains confidence labels and contains no dependency source paths.

- [ ] **Step 6: Commit**

Commit scripts, ignore rule, verifier, and portable graph output as `build: add akaunting code graph`.

### Task 4: Document agent usage

**Files:**

- Create: `AGENTS.md`
- Modify: `specs/northstar/LOG.md`

**Interfaces:** Produces the authoritative rebuild command, verification command, query command, scope, prerequisites, and confidence guidance for later agents.

- [ ] **Step 1: Write a failing guidance test**

Require `AGENTS.md` to name the generator, verifier, graph JSON, both module manifests, and all three confidence labels.

- [ ] **Step 2: Implement and verify guidance**

Document Python 3.10+, uv, Composer-installed modules, repository-root rebuild, output verification, locked query command, constrained scope, and evidence limits. Add a dated Graphify entry to the Northstar log.

- [ ] **Step 3: Run final verification and commit**

Run all Graphify tests and `git diff --check`; commit guidance as `docs: document graphify harness`.

## Plan self-review

Tasks 1–4 cover host prerequisites, reproducible local installation, constrained deterministic generation, committed portable output, error handling, verification, and agent-facing evidence guidance.
