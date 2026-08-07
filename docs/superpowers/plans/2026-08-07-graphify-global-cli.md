# Graphify Global CLI and Agent Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the pinned Graphify CLI invocable as `graphify` in a user shell and add Graphify’s official project-scoped agent skill without enabling hooks or MCP.

**Architecture:** Install the published `graphifyy==0.9.34` package as a user-level `uv` tool, then refresh the user shell so its executable directory is on PATH. Generate the official project skill into the repository and retain the existing locked local Graphify project and PowerShell rebuild wrappers for reproducible repository output.

**Tech Stack:** Graphify CLI 0.9.34, `uv` tool installation, Markdown agent skill files, PowerShell verification scripts, GitHub pull request workflow.

## Global Constraints

- The Graphify package must remain pinned to `graphifyy==0.9.34`.
- The repository-local `tools/graphify/uv.lock` remains authoritative for deterministic graph rebuilds.
- No Graphify hooks, MCP server, API key, or machine-global repository dependency may be added.
- The project skill must teach agents to discover symbols/files with `graphify explain` and investigate relationships with `graphify query`.
- Existing unrelated working-tree changes must not be staged or modified.

---

### Task 1: Install and verify the user-level CLI

**Files:**
- Modify: user-level `uv` tool environment, outside the repository
- Test: PowerShell command resolution and `graphify --help`

**Interfaces:**
- Consumes: published package `graphifyy==0.9.34`
- Produces: a user-shell command named `graphify`

- [ ] **Step 1: Install the pinned CLI**

Run from PowerShell:

```powershell
uv tool install --force "graphifyy==0.9.34"
uv tool update-shell
```

- [ ] **Step 2: Verify the executable and version**

Run:

```powershell
Get-Command graphify
graphify --help
```

Expected: PowerShell resolves an executable named `graphify`, and the help output lists the Graphify CLI commands.

### Task 2: Add the official project skill and repository guidance

**Files:**
- Create: `.agents/skills/graphify/SKILL.md` and any official references generated beside it
- Modify: `AGENTS.md`
- Test: `tools/graphify/Test-GraphifyGuidance.ps1` and direct skill-file inspection

**Interfaces:**
- Consumes: the globally resolved `graphify` command and the repository’s `graphify-out/graph.json`
- Produces: project-scoped instructions agents can discover for Graphify queries

- [ ] **Step 1: Generate the project-scoped official skill**

Run the Graphify project installer that creates the cross-framework agent skill, then inspect its output:

```powershell
graphify install --project --platform agents
git status --short
```

Keep the generated skill and reference files. Do not retain any generated `.codex/hooks.json`, hook installer output, MCP configuration, or API-key configuration.

- [ ] **Step 2: Update `AGENTS.md`**

Document that `graphify` is the normal interactive command after the user-level `uv` installation, while the locked `uv run --project tools/graphify --locked graphify ...` form remains the deterministic fallback and rebuild path. Preserve the existing scope and evidence rules.

- [ ] **Step 3: Verify agent query discovery guidance**

Run:

```powershell
pwsh -File .\tools\graphify\Test-GraphifyGuidance.ps1
rg -n "graphify explain|graphify query|graphify install --project|uv tool install|hooks|MCP" AGENTS.md .agents/skills/graphify
```

Expected: the guidance verifier passes; the skill explains symbol/file discovery before precise node queries; no hook or MCP setup is documented as required.

### Task 3: Run the repository verification suite and publish

**Files:**
- Modify: only the files intentionally created or changed in Tasks 1–2
- Test: Graphify configuration, output, regression, wrapper, guidance, and Git checks

**Interfaces:**
- Consumes: the installed CLI, official skill, and existing committed Graphify baseline
- Produces: a reviewed commit pushed to `chore/graphify-setup` and an updated draft PR

- [ ] **Step 1: Run Graphify checks**

```powershell
pwsh -File .\tools\graphify\Test-GraphifyConfig.ps1
pwsh -File .\tools\graphify\Test-GraphifyOutput.ps1
pwsh -File .\tools\graphify\Test-GraphifyOutputRegression.ps1
pwsh -File .\tools\graphify\Test-GraphifyWrapper.ps1
pwsh -File .\tools\graphify\Test-GraphifyGuidance.ps1
git diff --check HEAD -- .agents AGENTS.md tools/graphify
```

- [ ] **Step 2: Commit only the scoped changes**

```powershell
git add AGENTS.md .agents docs/superpowers/plans/2026-08-07-graphify-global-cli.md
git commit -m "docs: install graphify cli and agent skill"
```

- [ ] **Step 3: Push and verify the draft PR**

```powershell
git push origin chore/graphify-setup
gh pr view 2 --json url,isDraft,headRefName,statusCheckRollup
```

Expected: the new commit is on the existing draft PR, and unrelated working-tree files remain unstaged.
