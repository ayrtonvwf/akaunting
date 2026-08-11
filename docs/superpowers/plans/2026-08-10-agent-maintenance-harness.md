# Agent Maintenance Harness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a reproducible Codex and Claude maintenance harness that navigates Akaunting with OpenWiki and Graphify, improves test coverage safely, and upgrades dependencies deliberately.

**Architecture:** Root `AGENTS.md` and `CLAUDE.md` are an exact shared operating contract. `.agents/skills/` is the canonical source for three Akaunting-specific skills; `tools/agents/Sync-ProjectSkills.ps1` produces and validates their Claude mirrors. APM pins and deploys three externally sourced process skills to Codex and Claude, while its manifest and lockfile are the shared external-skill inventory.

**Tech Stack:** Markdown/Agent Skills, PowerShell 7, Microsoft Agent Package Manager (APM), Graphify, OpenWiki OKF Markdown bundle, Laravel/PHPUnit.

## Global Constraints

- Preserve the committed Graphify baseline under `graphify-out/`; rebuilds remain explicit and use the existing project wrapper.
- Retain every Graphify constraint already checked by `tools/graphify/Test-GraphifyGuidance.ps1`.
- Treat `openwiki/` as a read-only navigation bundle. Verify current behavior in source, configuration, manifests/lockfiles, and focused tests.
- When OpenWiki disagrees with local evidence, report the OpenWiki page, source path, and reason in the handoff. Do not edit the bundle.
- Do not modify application code, application dependencies, package constraints, package lockfiles, tests, or OpenWiki content.
- Use APM only for the external `obra/superpowers` skill subset. Do not install a broad generic Laravel or frontend skills catalog.
- Keep all project skill names lowercase and hyphenated, matching their directory names.
- Do not use `apm install --force`; a collision with locally owned files must be investigated rather than overwritten.

---

## File structure

| File | Responsibility |
| --- | --- |
| `AGENTS.md` | Canonical, concise Codex/Claude project operating contract. |
| `CLAUDE.md` | Byte-identical root copy of `AGENTS.md`. |
| `apm.yml` | APM manifest pinning targets and the three external process skills. |
| `apm.lock.yaml` | APM-generated resolution and integrity lockfile. |
| `.gitignore` | Ignores APM's local module/cache directory. |
| `.agents/skills/akaunting-codebase-navigation/SKILL.md` | Canonical navigation workflow. |
| `.agents/skills/akaunting-test-coverage/SKILL.md` | Canonical test-coverage workflow. |
| `.agents/skills/akaunting-dependency-upgrade/SKILL.md` | Canonical dependency-upgrade workflow. |
| `.claude/skills/akaunting-*/SKILL.md` | Generated mirrors of the three project skills. |
| `tools/agents/Sync-ProjectSkills.ps1` | Copies only the named project skills from `.agents` to `.claude`. |
| `tools/agents/Test-AgentHarness.ps1` | Validates guidance parity, skill metadata/mirrors, and required navigation rules. |
| `tools/graphify/Test-GraphifyGuidance.ps1` | Keeps its Graphify-content checks while accepting the expanded root guidance. |

## Task 1: Establish shared root guidance and its regression check

**Files:**
- Create: `CLAUDE.md`
- Create: `tools/agents/Test-AgentHarness.ps1`
- Modify: `AGENTS.md`
- Modify: `tools/graphify/Test-GraphifyGuidance.ps1`

**Interfaces:**
- Consumes: current Graphify rules in `AGENTS.md`, `openwiki/index.md`, `openwiki/quickstart.md`, `openwiki/testing.md`, `phpunit.xml`, and `composer.json`.
- Produces: identical root instructions for Codex and Claude, plus `Test-AgentHarness.ps1` for later tasks.

- [ ] **Step 1: Write the guidance parity assertion first**

Create `tools/agents/Test-AgentHarness.ps1` with a `Test-RequiredText` helper and these initial checks:

```powershell
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$agentsPath = Join-Path $repoRoot 'AGENTS.md'
$claudePath = Join-Path $repoRoot 'CLAUDE.md'

if (-not (Test-Path -LiteralPath $agentsPath)) { throw "Missing $agentsPath" }
if (-not (Test-Path -LiteralPath $claudePath)) { throw "Missing $claudePath" }
if ((Get-FileHash -LiteralPath $agentsPath -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $claudePath -Algorithm SHA256).Hash) {
    throw 'AGENTS.md and CLAUDE.md must be byte-identical.'
}

$content = Get-Content -LiteralPath $agentsPath -Raw
foreach ($text in @('openwiki/index.md', 'openwiki/quickstart.md', 'openwiki/testing.md', 'Graphify', 'EXTRACTED', 'INFERRED', 'AMBIGUOUS', 'Do not edit the OpenWiki bundle')) {
    if (-not $content.Contains($text)) { throw "Missing root guidance: $text" }
}
Write-Host 'Root agent guidance is valid.'
```

- [ ] **Step 2: Run the new check and confirm the expected failure**

Run: `pwsh -File tools/agents/Test-AgentHarness.ps1`

Expected: non-zero exit because `CLAUDE.md` does not yet exist.

- [ ] **Step 3: Write the shared operating contract**

Replace the minimal root `AGENTS.md` with concise sections in this order, then copy it byte-for-byte to `CLAUDE.md`:

```markdown
# AGENTS

## Evidence order

1. Read `openwiki/index.md`, `openwiki/quickstart.md`, and the relevant system or workflow page for orientation.
2. Use the locked Graphify query for source relationships.
3. Verify behavior in current source, configuration, manifests/lockfiles, and focused tests.
4. Consult external documentation only when local evidence cannot establish the fact.

OpenWiki is a navigation map, not an override of implementation evidence. When it is stale or incomplete, report the page, source location, and discrepancy; do not edit the OpenWiki bundle.

## Maintenance workflows

- For unfamiliar paths, use `akaunting-codebase-navigation`.
- For test additions, use `akaunting-test-coverage`; PHPUnit uses the in-memory SQLite configuration in `phpunit.xml`.
- For Composer, NPM, or lockfile changes, use `akaunting-dependency-upgrade`; check root and module manifests plus `overrides/` before changing a constraint.

## Graphify
```

Keep the complete existing Graphify section after these new sections. Include a short project map naming `app/`, `modules/`, `config/`, `routes/`, `database/`, `tests/`, `overrides/`, and `openwiki/`; describe each with its current repository role. Do not add generic Laravel advice or a module-authoring workflow.

Create `CLAUDE.md` by copying the completed `AGENTS.md` bytes, not by adding a redirect or a Claude-specific header.

- [ ] **Step 4: Keep the existing Graphify regression test useful**

In `tools/graphify/Test-GraphifyGuidance.ps1`, replace only the 45-line router ceiling with a 120-line ceiling and update the message to: `AGENTS.md should remain concise; move detailed task workflows into project skills.` Leave every existing required Graphify pattern unchanged.

- [ ] **Step 5: Run both guidance checks**

Run:

```powershell
pwsh -File tools/agents/Test-AgentHarness.ps1
pwsh -File tools/graphify/Test-GraphifyGuidance.ps1
```

Expected: both commands print their success messages and exit `0`.

- [ ] **Step 6: Commit the root-guidance unit**

```bash
git add AGENTS.md CLAUDE.md tools/agents/Test-AgentHarness.ps1 tools/graphify/Test-GraphifyGuidance.ps1
git commit -m "docs: add shared agent maintenance guidance"
```

## Task 2: Add deterministic external-skill management with APM

**Files:**
- Create: `apm.yml`
- Create: `apm.lock.yaml` (generated)
- Modify: `.gitignore`
- Create: APM-generated selected skill copies under `.agents/skills/` and `.claude/skills/`
- Modify: `tools/agents/Test-AgentHarness.ps1`

**Interfaces:**
- Consumes: APM's `codex` and `claude` targets and the `obra/superpowers` v6.1.1 skills collection.
- Produces: pinned process skills: `test-driven-development`, `systematic-debugging`, and `verification-before-completion`.

- [ ] **Step 1: Add assertions for the approved external inventory**

Extend `Test-AgentHarness.ps1` with this target-and-skill loop before installing anything:

```powershell
$externalSkills = @('test-driven-development', 'systematic-debugging', 'verification-before-completion')
foreach ($skill in $externalSkills) {
    foreach ($root in @('.agents\skills', '.claude\skills')) {
        $path = Join-Path $repoRoot "$root\$skill\SKILL.md"
        if (-not (Test-Path -LiteralPath $path)) { throw "Missing deployed external skill: $path" }
    }
}
```

- [ ] **Step 2: Run the check and confirm the expected failure**

Run: `pwsh -File tools/agents/Test-AgentHarness.ps1`

Expected: non-zero exit naming the first missing external skill.

- [ ] **Step 3: Install APM and declare the restricted skill subset**

Install the official Windows APM CLI once if `Get-Command apm` returns no command:

```powershell
irm https://aka.ms/apm-windows | iex
```

Create `apm.yml` with the following manifest:

```yaml
name: akaunting-agent-harness
version: 0.1.0
description: Shared maintenance skills for Akaunting agents
targets:
  - codex
  - claude
dependencies:
  apm:
    - git: obra/superpowers#v6.1.1
      skills:
        - test-driven-development
        - systematic-debugging
        - verification-before-completion
```

Add `apm_modules/` as a new line in the root `.gitignore` so APM's local downloaded modules do not become project artifacts.

- [ ] **Step 4: Preview, install, and lock the selected skills**

Run:

```powershell
apm install --target codex,claude --dry-run
apm install --target codex,claude
apm install --target codex,claude --frozen
```

Expected: the dry run writes nothing; the install writes `apm.lock.yaml` and deploys exactly the three selected external skills to `.agents/skills/` and `.claude/skills/`; the frozen install exits `0` without resolving a new dependency.

- [ ] **Step 5: Verify the new inventory and APM integrity**

Run:

```powershell
pwsh -File tools/agents/Test-AgentHarness.ps1
apm audit
```

Expected: the validation sees all three skills at both target paths, and APM reports no integrity or deployment drift findings.

- [ ] **Step 6: Commit the APM baseline**

```bash
git add .gitignore apm.yml apm.lock.yaml .agents/skills .claude/skills tools/agents/Test-AgentHarness.ps1
git commit -m "build: pin shared agent process skills"
```

## Task 3: Add canonical project-skill mirroring and codebase navigation

**Files:**
- Create: `tools/agents/Sync-ProjectSkills.ps1`
- Create: `.agents/skills/akaunting-codebase-navigation/SKILL.md`
- Create: `.claude/skills/akaunting-codebase-navigation/SKILL.md` (generated)
- Modify: `tools/agents/Test-AgentHarness.ps1`

**Interfaces:**
- Consumes: canonical project skills in `.agents/skills/`, OpenWiki indexes/pages, and the locked Graphify query command.
- Produces: byte-identical Claude mirrors for the named project skills and an evidence-based navigation workflow.

- [ ] **Step 1: Add the project-skill mirror assertion**

Extend `Test-AgentHarness.ps1` with an initial canonical skill list containing only `akaunting-codebase-navigation` and these parity checks. Later tasks append their skill name to the same list only when that skill is being introduced:

```powershell
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
```

- [ ] **Step 2: Run the assertion and confirm the expected failure**

Run: `pwsh -File tools/agents/Test-AgentHarness.ps1`

Expected: non-zero exit naming `akaunting-codebase-navigation` as the first missing canonical project skill.

- [ ] **Step 3: Implement the restricted sync command**

Create `tools/agents/Sync-ProjectSkills.ps1`. It must define the same three fixed names as the validation script, create only `.claude/skills/<name>/`, and recursively copy each canonical directory with `Copy-Item -Recurse -Force`. It must not enumerate, overwrite, or delete Graphify or APM-owned external skills. End with `Write-Host 'Project skill mirrors synchronized.'`.

- [ ] **Step 4: Write the navigation skill**

Create `.agents/skills/akaunting-codebase-navigation/SKILL.md` with this frontmatter and workflow:

```markdown
---
name: akaunting-codebase-navigation
description: Navigate unfamiliar Akaunting behavior, Laravel request flows, source relationships, or project structure by combining the OpenWiki bundle, the locked Graphify query, and current source verification.
---

# Akaunting Codebase Navigation

1. Read `openwiki/index.md` and `openwiki/quickstart.md`. Read the relevant system or workflow page before naming code paths.
2. Run `uv run --project tools/graphify --locked graphify query "<specific question>" --graph graphify-out/graph.json` for structural evidence.
3. Inspect the cited current route, controller, request, job, model, configuration, manifest, and nearest test as applicable. Treat `EXTRACTED` graph edges as source-derived; validate `INFERRED` and `AMBIGUOUS` edges in source.
4. State the OpenWiki page, Graphify query, and source locations used. If OpenWiki is absent, stale, or contradictory, report its page and the contradicting local evidence; do not edit OpenWiki.
```

Use `tools/agents/Sync-ProjectSkills.ps1` to create the Claude mirror.

- [ ] **Step 5: Run the check and inspect the mirror boundary**

Run:

```powershell
pwsh -File tools/agents/Sync-ProjectSkills.ps1
pwsh -File tools/agents/Test-AgentHarness.ps1
git diff -- .claude/skills/graphify .agents/skills/graphify
```

Expected: both PowerShell commands exit `0`; the Git diff does not show a Graphify change caused by synchronization.

- [ ] **Step 6: Commit the navigation unit**

```bash
git add tools/agents/Sync-ProjectSkills.ps1 tools/agents/Test-AgentHarness.ps1 .agents/skills/akaunting-codebase-navigation .claude/skills/akaunting-codebase-navigation
git commit -m "feat: add Akaunting navigation skill"
```

## Task 4: Add the Akaunting test-coverage skill

**Files:**
- Create: `.agents/skills/akaunting-test-coverage/SKILL.md`
- Create: `.claude/skills/akaunting-test-coverage/SKILL.md` (generated)
- Modify: `tools/agents/Test-AgentHarness.ps1`

**Interfaces:**
- Consumes: `openwiki/testing.md`, relevant OpenWiki domain/workflow pages, `phpunit.xml`, `tests/Feature/FeatureTestCase.php`, `tests/Feature/PaymentTestCase.php`, `tests/TestCase.php`, and current source/tests.
- Produces: a test-selection and coverage workflow that reports, but never changes, OpenWiki drift.

- [ ] **Step 1: Add content assertions for the test-coverage skill**

Add `akaunting-test-coverage` to the existing `$projectSkills` array in `Test-AgentHarness.ps1`, then add this required-text block:

```powershell
$coveragePath = Join-Path $repoRoot '.agents\skills\akaunting-test-coverage\SKILL.md'
foreach ($text in @('openwiki/testing.md', 'phpunit.xml', 'SQLite', 'tests/Feature', 'tests/Unit', 'modules/*/Tests', 'Do not edit OpenWiki')) {
    if (-not (Get-Content -LiteralPath $coveragePath -Raw).Contains($text)) { throw "Test-coverage skill is missing: $text" }
}
```

- [ ] **Step 2: Run the check and confirm the expected failure**

Run: `pwsh -File tools/agents/Test-AgentHarness.ps1`

Expected: non-zero exit because the canonical test-coverage skill is missing.

- [ ] **Step 3: Write the test-coverage skill**

Create `.agents/skills/akaunting-test-coverage/SKILL.md` with the required frontmatter and these numbered instructions:

```markdown
---
name: akaunting-test-coverage
description: Improve Akaunting automated test coverage by deriving behavior from OpenWiki and existing tests, tracing the current implementation, and running the narrowest relevant PHPUnit checks first.
---

# Akaunting Test Coverage

1. Read `openwiki/testing.md` and the relevant OpenWiki system or workflow page. Use them to identify behavior, not to override source.
2. Trace the behavior through routes, controllers, requests, jobs, models, events, and current tests. Start navigation with `akaunting-codebase-navigation` when the path is unfamiliar.
3. Place an HTTP/business workflow in `tests/Feature` or `modules/*/Tests/Feature`; place isolated logic in `tests/Unit` or `modules/*/Tests/Unit`. Reuse `FeatureTestCase`, `PaymentTestCase`, factories, and existing helpers before creating test-only infrastructure.
4. Respect `phpunit.xml`: tests use the in-memory SQLite connection, synchronous queues, and array mail. Run the most specific test file or test name first with `php artisan test <path-or-filter>`, then run the proportionate feature, unit, module, or full suite.
5. Report any OpenWiki page that is missing, stale, or contradicted by source/tests. Include the page and source locations; do not edit OpenWiki.
```

- [ ] **Step 4: Synchronize and validate the skill**

Run:

```powershell
pwsh -File tools/agents/Sync-ProjectSkills.ps1
pwsh -File tools/agents/Test-AgentHarness.ps1
```

Expected: both commands exit `0`, and the validation confirms an identical Claude mirror.

- [ ] **Step 5: Commit the coverage unit**

```bash
git add tools/agents/Test-AgentHarness.ps1 .agents/skills/akaunting-test-coverage .claude/skills/akaunting-test-coverage
git commit -m "feat: add Akaunting test coverage skill"
```

## Task 5: Add the Akaunting dependency-upgrade skill

**Files:**
- Create: `.agents/skills/akaunting-dependency-upgrade/SKILL.md`
- Create: `.claude/skills/akaunting-dependency-upgrade/SKILL.md` (generated)
- Modify: `tools/agents/Test-AgentHarness.ps1`

**Interfaces:**
- Consumes: `openwiki/configuration.md`, relevant OpenWiki system pages, root and module `composer.json`, root `package.json`, lockfiles, and `overrides/`.
- Produces: a scoped compatibility-and-verification workflow for dependency changes.

- [ ] **Step 1: Add content assertions for the dependency-upgrade skill**

Add `akaunting-dependency-upgrade` to the existing `$projectSkills` array in `Test-AgentHarness.ps1`, then add this block:

```powershell
$upgradePath = Join-Path $repoRoot '.agents\skills\akaunting-dependency-upgrade\SKILL.md'
foreach ($text in @('openwiki/configuration.md', 'composer.json', 'package.json', 'overrides/', 'composer.lock', 'package-lock.json', 'composer update <package>', 'Do not edit OpenWiki')) {
    if (-not (Get-Content -LiteralPath $upgradePath -Raw).Contains($text)) { throw "Dependency-upgrade skill is missing: $text" }
}
```

- [ ] **Step 2: Run the check and confirm the expected failure**

Run: `pwsh -File tools/agents/Test-AgentHarness.ps1`

Expected: non-zero exit because the canonical dependency-upgrade skill is missing.

- [ ] **Step 3: Write the dependency-upgrade skill**

Create `.agents/skills/akaunting-dependency-upgrade/SKILL.md` with this content:

```markdown
---
name: akaunting-dependency-upgrade
description: Upgrade Akaunting Composer, NPM, or lockfile dependencies safely by establishing package ownership, checking module and override impact, and verifying only after a scoped change is understood.
---

# Akaunting Dependency Upgrade

1. Read `openwiki/configuration.md` and the relevant OpenWiki system page to map affected behavior. Treat these pages as navigation only; verify all version and compatibility facts locally.
2. Identify ownership in root `composer.json`, module `composer.json` files, root `package.json`, `composer.lock`, and `package-lock.json`. Inspect `overrides/` before changing an affected package.
3. Inspect the dependency's release/migration notes and current callers, configuration, service providers, and focused tests. Identify direct, transitive, module, override, configuration, and schema impact before editing constraints.
4. Prefer a named scoped update such as `composer update <package> --with-all-dependencies` or the package manager's equivalent; do not run an unconstrained all-package update unless the user explicitly requests it.
5. Verify the changed dependency with targeted tests first, then a proportionate broader suite and the relevant build command when frontend packages change. Record exact commands and results.
6. Report any OpenWiki discrepancy with its page and the contradicting local source, manifest, lockfile, or test; do not edit OpenWiki.
```

- [ ] **Step 4: Synchronize and validate the skill**

Run:

```powershell
pwsh -File tools/agents/Sync-ProjectSkills.ps1
pwsh -File tools/agents/Test-AgentHarness.ps1
```

Expected: both commands exit `0`, including frontmatter, required content, and mirror-parity checks.

- [ ] **Step 5: Commit the dependency-upgrade unit**

```bash
git add tools/agents/Test-AgentHarness.ps1 .agents/skills/akaunting-dependency-upgrade .claude/skills/akaunting-dependency-upgrade
git commit -m "feat: add Akaunting dependency upgrade skill"
```

## Task 6: Run the full harness acceptance review

**Files:**
- Modify if needed: only files listed in this plan.
- Test: root guidance, Graphify guidance, custom skill mirrors, frozen APM installation, and APM audit.

**Interfaces:**
- Consumes: every harness artifact from Tasks 1 through 5.
- Produces: a reproducible, documented maintenance harness without application or OpenWiki changes.

- [ ] **Step 1: Verify structural and guidance contracts**

Run:

```powershell
pwsh -File tools/agents/Test-AgentHarness.ps1
pwsh -File tools/graphify/Test-GraphifyGuidance.ps1
pwsh -File tools/graphify/Test-GraphifyOutput.ps1
```

Expected: all three commands exit `0` and print their success messages.

- [ ] **Step 2: Verify reproducible external-skill installation**

Run:

```powershell
apm install --target codex,claude --frozen
apm audit
```

Expected: frozen install does not re-resolve or alter the approved inventory; the audit exits `0` with no integrity or deployment drift finding.

- [ ] **Step 3: Confirm the scope boundary**

Run:

```powershell
git diff --check
git diff --name-only HEAD~5..HEAD
git status --short
```

Expected: no whitespace errors; committed harness changes are limited to root agent files, APM metadata, agent skill directories, and `tools/agents`/Graphify validation; no application code, package constraints/lockfiles, tests, or `openwiki/` files appear.

- [ ] **Step 4: Commit acceptance-only corrections if required**

```bash
git add AGENTS.md CLAUDE.md .gitignore apm.yml apm.lock.yaml .agents .claude tools/agents tools/graphify/Test-GraphifyGuidance.ps1
git diff --cached --quiet || git commit -m "test: verify agent maintenance harness"
```

## Plan self-review

- The plan implements the shared root guidance, APM-pinned external skills, three project skills, OpenWiki/Graphify evidence order, drift-reporting contract, skill mirror ownership, and acceptance gates defined in `docs/superpowers/specs/2026-08-10-agent-harness-design.md`.
- Every custom skill has a failing validation step before creation, a concrete portable frontmatter block, a synchronization step, and a passing validation step.
- The APM task uses a fixed subset and target list, checks a dry run before writing, validates a frozen reinstall, and audits deployed content.
- No task changes Akaunting application code, dependencies, application lockfiles, test suites, or the OpenWiki bundle.
