# OpenWiki / Graphify Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix every defect named in `specs/northstar/OPENWIKI-GRAPHIFY-AUDIT.md` so the two generated evidence layers stop returning confident falsehoods, and so the guidance files stop instructing agents to do things the tooling cannot do.

**Architecture:** Two independent workstreams over a shared prerequisite. Workstream A is deterministic hand edits to guidance and tooling (`AGENTS.md`, `.graphifyignore`, three PowerShell validation scripts, both graphify `SKILL.md` copies) plus one graph rebuild. Workstream B corrects the `openwiki/` bundle in place: a throwaway PowerShell script computes the dead-citation list, then a single Sonnet 5 subagent applies that list and repairs four prose defects. Path existence is supplied to the subagent as established fact, never asked as a question.

**Tech Stack:** PowerShell 7 (pwsh 7.6.3), `uv` 0.12.0 with a locked `graphifyy==0.9.34` project under `tools/graphify/`, Python 3.12, Markdown. No PHP or Composer is required — `modules/` is copied in from the main checkout.

## Global Constraints

- Design source of truth: `docs/superpowers/specs/2026-08-11-openwiki-graphify-remediation-design.md`. Findings source: `specs/northstar/OPENWIKI-GRAPHIFY-AUDIT.md` (arrives in Task 1).
- **Do not run the OpenWiki CLI.** No `openwiki code`, no `openwiki init`, no `--update`. All bundle corrections are direct file edits.
- **Do not modify `openwiki/.last-update.json`.** It is the generator's diff anchor at `gitHead: 1a03c3ee59587e422b4275295986ba95430df136`.
- **Do not change `OPENWIKI_MODEL_ID`** in `.github/workflows/openwiki-update.yml`. It stays `claude-haiku-4-5`.
- **Do not add CI checks, committed validation scripts, staleness gates, or probe scorers.** The citation-sweep script in Task 7 is throwaway and lives in the scratchpad, never in the repo.
- `AGENTS.md` and `CLAUDE.md` must stay byte-identical (`Test-AgentHarness.ps1:16`). `CLAUDE.md` is generated — never hand-edit it; run `pwsh -File tools/agents/Sync-ProjectSkills.ps1` after any `AGENTS.md` change.
- `AGENTS.md` must stay at or under 120 lines (`Test-GraphifyGuidance.ps1`).
- All `pwsh` scripts under `tools/graphify/` must be invoked from the repository root.
- Repository root for this work: `C:\Users\ayrto\projects\akaunting\.claude\worktrees\openwiki-graphify-improvements-f24f80`. Main checkout (source of `modules/`): `C:\Users\ayrto\projects\akaunting`.
- Scratchpad for throwaway files: `C:\Users\ayrto\AppData\Local\Temp\claude\C--Users-ayrto-projects-akaunting--claude-worktrees-openwiki-graphify-improvements-f24f80\4e13fcc1-4f3e-468f-a3ef-693823b49a32\scratchpad`
- Commit messages end with `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`.

## File Structure

**Created:**
- `specs/northstar/OPENWIKI-GRAPHIFY-AUDIT.md` — the audit, ported from a sibling worktree. Source document for every change here.

**Modified — guidance:**
- `AGENTS.md` — gains the parallel-isolation section (Task 1) and the graph capability boundary (Task 4); loses two pieces of dead guidance (Task 4).
- `CLAUDE.md` — generated from `AGENTS.md`; never hand-edited.
- `.agents/skills/graphify/SKILL.md` + `.claude/skills/graphify/SKILL.md` — replaced with a thin repo-locked skill (Task 6). Their `references/` directories are deleted.

**Modified — tooling:**
- `tools/agents/Sync-ProjectSkills.ps1` — generates `CLAUDE.md` from `AGENTS.md` (Task 1); mirrors the graphify skill (Task 6).
- `.graphifyignore` + `tools/graphify/Test-GraphifyConfig.ps1` — narrowed allow-list and its pinned expectation, which must move together (Task 2).
- `tools/graphify/Test-GraphifyOutput.ps1` — loses the module-manifest precondition (Task 5).

**Modified — generated artifacts:**
- `graphify-out/graph.json`, `graph.html`, `GRAPH_REPORT.md`, `manifest.json` — rebuilt (Task 3).
- `openwiki/testing.md`, `openwiki/workflows/permissions-workflow.md`, `openwiki/workflows/invoice-workflow.md`, `openwiki/systems/modules/overview.md`, plus any page carrying a dead citation, plus `openwiki/log.md` (Task 8).

---

### Task 1: Port the audit and its in-flight fixes

The audit document and two fixes it describes as already applied live untracked in a sibling worktree. Both worktrees sit on `9dd32e349`, so this is a copy, not a merge. Nothing downstream can cite the audit until this lands, and `Test-AgentHarness.ps1` is red until it does.

**Files:**
- Create: `specs/northstar/OPENWIKI-GRAPHIFY-AUDIT.md`
- Modify: `AGENTS.md` (insert a section after the "Maintenance workflows" bullets)
- Modify: `tools/agents/Sync-ProjectSkills.ps1:16` (append CLAUDE.md generation)
- Modify: `CLAUDE.md` (regenerated, not hand-edited)
- Source: `C:\Users\ayrto\projects\akaunting\.claude\worktrees\test-openwiki-graphify-agent-0ec8aa`

**Interfaces:**
- Produces: `specs/northstar/OPENWIKI-GRAPHIFY-AUDIT.md` on this branch — every later task cites it. `pwsh -File tools/agents/Sync-ProjectSkills.ps1` becomes the only supported way to update `CLAUDE.md`.

- [ ] **Step 1: Run the harness test to see it fail**

```bash
pwsh -File tools/agents/Test-AgentHarness.ps1
```

Expected: FAIL with `AGENTS.md and CLAUDE.md must be byte-identical.` — `CLAUDE.md` currently carries a "Parallel test isolation" section that `AGENTS.md` lacks, and lacks the `# AGENTS` heading and OPENWIKI markers that `AGENTS.md` has.

- [ ] **Step 2: Copy the audit document in**

```bash
cp "C:/Users/ayrto/projects/akaunting/.claude/worktrees/test-openwiki-graphify-agent-0ec8aa/specs/northstar/OPENWIKI-GRAPHIFY-AUDIT.md" specs/northstar/OPENWIKI-GRAPHIFY-AUDIT.md
```

Do **not** copy that worktree's `specs/northstar/LOG.md` change; it is unrelated to this work.

- [ ] **Step 3: Add the parallel-isolation section to `AGENTS.md`**

Insert immediately after the `- For Composer, NPM, or lockfile changes, use \`akaunting-dependency-upgrade\`; …` bullet and before `### Project map`:

```markdown
### Parallel test isolation

`php artisan test --parallel` runs multiple worker processes against this repo. Any new file-backed driver, temp path, or on-disk cache touched by tests must be scoped per worker via `Tests\Concerns\IsolatesParallelTestState::testToken()` (see `tests/CreatesApplication.php`), or it will race across workers the same way the shared Blade compiled-view directory once did (issue #5). `tests/Unit/ParallelIsolationTest.php` guards the known isolation points — extend it when adding a new shared-writable path.
```

- [ ] **Step 4: Make `Sync-ProjectSkills.ps1` generate `CLAUDE.md`**

Replace the final line of `tools/agents/Sync-ProjectSkills.ps1` (`Write-Host 'Project skill mirrors synchronized.'`) with:

```powershell
# AGENTS.md is the single source of root agent guidance. CLAUDE.md is generated from it so the
# two cannot drift; Test-AgentHarness.ps1 asserts they are byte-identical.
$agentsPath = Join-Path $repoRoot 'AGENTS.md'
if (-not (Test-Path -LiteralPath $agentsPath -PathType Leaf)) {
    throw "Missing canonical root guidance: $agentsPath"
}

Copy-Item -LiteralPath $agentsPath -Destination (Join-Path $repoRoot 'CLAUDE.md') -Force

Write-Host 'Project skill mirrors synchronized.'
Write-Host 'CLAUDE.md regenerated from AGENTS.md.'
```

- [ ] **Step 5: Regenerate `CLAUDE.md`**

```bash
pwsh -File tools/agents/Sync-ProjectSkills.ps1
```

Expected: prints `Project skill mirrors synchronized.` then `CLAUDE.md regenerated from AGENTS.md.`

- [ ] **Step 6: Run the harness test to verify it passes**

```bash
pwsh -File tools/agents/Test-AgentHarness.ps1
```

Expected: PASS, printing `Root agent guidance is valid.`

- [ ] **Step 7: Commit**

```bash
git add specs/northstar/OPENWIKI-GRAPHIFY-AUDIT.md AGENTS.md CLAUDE.md tools/agents/Sync-ProjectSkills.ps1
git commit -m "docs: port OpenWiki/Graphify audit and its harness fixes

Brings specs/northstar/OPENWIKI-GRAPHIFY-AUDIT.md onto this branch as the
source document for the remediation, along with the two fixes the audit
describes as already applied: the Parallel test isolation section that had
been added to CLAUDE.md only, and CLAUDE.md generation from AGENTS.md so
the two cannot drift again.

Test-AgentHarness.ps1 was red before this commit and is green after.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 2: Narrow `.graphifyignore` and its pinned expectation

`!modules/**` admits six non-PHP files — `offline-payments.min.js`, `offline-payments.js`, `webpack.mix.js`, `package.json`, and both module `composer.json` files — contradicting `AGENTS.md`'s claim that frontend and generated assets are out of scope. A minified bundle became a `rationale` node (audit finding 8). This lands **before** the rebuild so one rebuild covers it.

`Test-GraphifyConfig.ps1` compares `.graphifyignore` byte-for-byte against `$expectedIgnoreEntries`, so both files change together.

**Files:**
- Modify: `.graphifyignore:4-5`
- Modify: `tools/graphify/Test-GraphifyConfig.ps1` (`$expectedIgnoreEntries`)

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: the narrowed scope the Task 3 rebuild reads.

- [ ] **Step 1: Write the failing expectation first**

Edit `$expectedIgnoreEntries` in `tools/graphify/Test-GraphifyConfig.ps1`, replacing the `'!modules/'` and `'!modules/**'` entries so the array reads:

```powershell
$expectedIgnoreEntries = @(
    '*'
    '!app/'
    '!app/**'
    '!modules/'
    '!modules/**/'
    '!modules/**/*.php'
    '!modules/**/composer.json'
    '!config/'
    '!config/**'
    '!routes/'
    '!routes/**'
    '!tests/'
    '!tests/**'
)
```

`!modules/**/` (with the trailing slash) keeps subdirectories traversable; without it the two negated file patterns can never be reached.

- [ ] **Step 2: Run the config test to verify it fails**

```bash
pwsh -File tools/graphify/Test-GraphifyConfig.ps1
```

Expected: FAIL with `Graphify ignore policy must exactly match the normalized allow-list.` and a diff showing `.graphifyignore` still has the old `!modules/**` line.

- [ ] **Step 3: Apply the same change to `.graphifyignore`**

The whole file becomes:

```gitignore
*
!app/
!app/**
!modules/
!modules/**/
!modules/**/*.php
!modules/**/composer.json
!config/
!config/**
!routes/
!routes/**
!tests/
!tests/**
```

- [ ] **Step 4: Run the config test to verify it passes**

```bash
pwsh -File tools/graphify/Test-GraphifyConfig.ps1
```

Expected: PASS, printing `Graphify configuration is valid.`

- [ ] **Step 5: Commit**

```bash
git add .graphifyignore tools/graphify/Test-GraphifyConfig.ps1
git commit -m "chore: exclude module frontend assets from the Graphify scope

!modules/** admitted offline-payments.min.js, offline-payments.js,
webpack.mix.js and package.json into the graph, contradicting AGENTS.md's
claim that frontend and generated assets are out of scope; a minified
bundle had become a rationale node.

Narrows to PHP sources plus the two module composer.json manifests, which
are neither frontend nor generated and which both Graphify wrappers require.
Test-GraphifyConfig.ps1 pins this list byte-for-byte, so it moves too.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 3: Populate `modules/` and rebuild the graph

The committed baseline is stale by five files and reports `createApplication() loc=L14` for a method now at L17 (audit finding 7). The rebuild must come before the wiki correction pass, because the Task 8 subagent uses the graph as a check.

`modules/` is a gitignored post-install path, empty in this worktree and populated in the main checkout. There is no `composer` or `php` on `PATH`. Both `Invoke-Graphify.ps1:159-163` and `Test-GraphifyOutput.ps1` throw without the two manifests.

**Files:**
- Create (untracked, gitignored): `modules/OfflinePayments/`, `modules/PaypalStandard/`
- Modify: `graphify-out/graph.json`, `graphify-out/graph.html`, `graphify-out/GRAPH_REPORT.md`, `graphify-out/manifest.json`

**Interfaces:**
- Consumes: the narrowed `.graphifyignore` from Task 2.
- Produces: a `graphify-out/graph.json` whose `built_at_commit` is current and whose `createApplication()` node reports `loc=L17`. Task 8 queries it.

- [ ] **Step 1: Confirm `modules/` is empty and the rebuild would be degraded**

```bash
ls modules/
```

Expected: empty, or the directory does not exist. If it already contains `OfflinePayments` and `PaypalStandard`, skip to Step 3.

- [ ] **Step 2: Copy both modules in from the main checkout**

```bash
mkdir -p modules && cp -r "C:/Users/ayrto/projects/akaunting/modules/OfflinePayments" modules/ && cp -r "C:/Users/ayrto/projects/akaunting/modules/PaypalStandard" modules/ && ls modules/OfflinePayments/composer.json modules/PaypalStandard/composer.json
```

Expected: both manifest paths listed. These are gitignored and must never appear in a commit — Step 7 checks that.

- [ ] **Step 3: Record the pre-rebuild staleness so the fix is provable**

```bash
grep -o '"built_at_commit": "[^"]*"' graphify-out/graph.json | head -1
```

Expected: `4fc6d5662` (the audit's recorded value). Also note the current `HEAD`:

```bash
git rev-parse --short HEAD
```

- [ ] **Step 4: Rebuild**

Must run from the repository root; the wrapper throws otherwise.

```bash
pwsh -File tools/graphify/Invoke-Graphify.ps1
```

Expected: extract, then `cluster-only`, then `export html`, then the vis-network inlining, with no thrown error. This takes minutes and costs nothing — there is no model in the code path.

- [ ] **Step 5: Verify the two stale facts are gone**

```bash
uv run --project tools/graphify --locked graphify query "createApplication CreatesApplication" --graph graphify-out/graph.json --budget 6000
```

Expected: a `createApplication()` node citing `tests/CreatesApplication.php` at **L17**, not L14. Then confirm the three previously-absent parallel-isolation files are now present:

```bash
grep -c "IsolatesParallelTestState" graphify-out/graph.json
```

Expected: a non-zero count.

- [ ] **Step 6: Verify the narrowed scope from Task 2 actually took effect**

This is the real test of Task 2 — the `.graphifyignore` change is only correct if module PHP is still graphed and the frontend assets are not.

```bash
grep -c "modules/OfflinePayments/.*\.php" graphify-out/graph.json && grep -c "offline-payments.min.js\|webpack.mix.js" graphify-out/graph.json
```

Expected: a non-zero count for module PHP, and `0` for the frontend assets. If module PHP is also `0`, the `!modules/**/` directory-traversal line is missing or wrong — fix `.graphifyignore` and `Test-GraphifyConfig.ps1` together, then rebuild.

- [ ] **Step 7: Verify the LLM-derived analysis artifact survived**

`graphify-out/.graphify_analysis.json` is committed and cannot be regenerated without a model. The rebuild must not have removed it.

```bash
ls -la graphify-out/.graphify_analysis.json && git status --short graphify-out/
```

Expected: the file exists. `git status` should list modifications to `graph.json`, `graph.html`, `GRAPH_REPORT.md` and `manifest.json` only. If `.graphify_analysis.json` shows as deleted, restore it with `git checkout -- graphify-out/.graphify_analysis.json` before continuing.

- [ ] **Step 8: Run the output verifier**

```bash
pwsh -File tools/graphify/Test-GraphifyOutput.ps1
```

Expected: PASS. (It passes here only because `modules/` is populated — Task 5 is what makes it pass on a clean checkout.)

- [ ] **Step 9: Commit**

```bash
git add graphify-out/
git status --short
```

Confirm no `modules/` path appears in the staged set, then:

```bash
git commit -m "chore: rebuild the Graphify baseline

Clears the two stale facts the audit found: the three parallel-isolation
files were absent from the graph, and tests/CreatesApplication.php kept a
node reporting createApplication() at L14 when the method is now at L17 —
a stale line number on a live symbol, which no path-existence check finds.

Also picks up the narrowed module scope from the previous commit. Built
with modules/ populated from the main checkout so module nodes are not
silently dropped.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 4: Document the graph's capability boundary in `AGENTS.md`

Two of the audit's twelve probes (P06, P10) missed for reasons that are capability boundaries rather than defects, and the agent had to spend a query discovering each. Two other pieces of guidance are dead: `AMBIGUOUS` never fires, and "a brief's unknowns and review items" names vocabulary that exists nowhere in the bundle.

**Files:**
- Modify: `AGENTS.md:9` (inside the OPENWIKI marker block), `AGENTS.md:57`, and the `## Graphify` constraints list
- Modify: `CLAUDE.md` (regenerated)

**Interfaces:**
- Consumes: the `AGENTS.md` shape from Task 1.
- Produces: the capability-boundary text that Task 6's thin skill mirrors. The two must agree.

- [ ] **Step 1: Fix the unactionable "brief's unknowns" sentence**

`AGENTS.md:9` currently reads:

```markdown
- Treat source code and tests as authoritative. A brief's unknowns and review items are verification gaps, not automatic requirements.
```

Replace with:

```markdown
- Treat source code and tests as authoritative. Items under "Outstanding Critic Items" in `openwiki/log.md` are verification gaps, not automatic requirements.
```

Note: this line sits inside the `<!-- OPENWIKI:START -->` / `<!-- OPENWIKI:END -->` block, so the scheduled generator can overwrite it. That is part of the deferred decision recorded in the design document, not a reason to skip the fix.

- [ ] **Step 2: Replace the dead `AMBIGUOUS` instruction with the real distribution**

`AGENTS.md:57` currently reads:

```markdown
- Treat Graphify as structural evidence: `EXTRACTED` is source-derived; `INFERRED` and `AMBIGUOUS` require source inspection.
```

Replace with:

```markdown
- Treat Graphify as structural evidence: edges are 86.9% `EXTRACTED` (source-derived, confidence 1.0) and 13.1% `INFERRED` (verify in source). No edge currently carries `AMBIGUOUS`, so do not wait for that label to justify a source check.
```

The token `AMBIGUOUS` must remain present — both `Test-GraphifyGuidance.ps1` and `Test-AgentHarness.ps1:21` assert it appears.

- [ ] **Step 3: Add the capability boundary to the `## Graphify` constraints list**

Append these four bullets to the existing list under `## Graphify`, after the `Graphify requires no API key…` line:

```markdown
- Routes and config resolve at file level only: every `routes/*.php` is one node at `loc=L1` with no edges to controllers, and every `config/*.php` is one node with no keys. Grep those directories directly. Querying `"routes/admin.php"` returns the OfflinePayments file, not the root one.
- `overrides/` and the root `composer.json` / `package.json` are outside the graph scope and are unmentioned by OpenWiki. For dependency-coupling questions, read `overrides/` directly; neither evidence layer can answer.
- `graphify query` seeds by token-matching node labels, not by meaning. Query with symbol names; prose questions misfire silently and return irrelevant nodes at full confidence.
- Pass `--budget 6000` as a floor. The default 2000 truncates correct answers, which reads to an agent as absence.
```

- [ ] **Step 4: Regenerate `CLAUDE.md` and run both guidance tests**

```bash
pwsh -File tools/agents/Sync-ProjectSkills.ps1 && pwsh -File tools/graphify/Test-GraphifyGuidance.ps1 && pwsh -File tools/agents/Test-AgentHarness.ps1
```

Expected: `CLAUDE.md regenerated from AGENTS.md.`, then `Graphify agent guidance is valid.`, then `Root agent guidance is valid.` If the guidance test fails on the line ceiling, the capability bullets are too verbose — tighten them rather than raising the ceiling.

- [ ] **Step 5: Confirm the line ceiling has headroom**

```bash
awk 'END {print NR}' AGENTS.md
```

Expected: comfortably under 120.

- [ ] **Step 6: Commit**

```bash
git add AGENTS.md CLAUDE.md
git commit -m "docs: document the Graphify capability boundary in AGENTS.md

The audit's two MISS probes both failed on undocumented boundaries: routes
and config resolve at file level only, and overrides/ plus the root
manifests are outside the graph scope entirely. Both cost a wasted query
to rediscover. Also records that query seeding is token-matching rather
than semantic, and that --budget 6000 is the floor because the default
truncates correct answers into apparent absence.

Replaces two pieces of dead guidance: AMBIGUOUS, which no edge carries,
now states the real EXTRACTED/INFERRED split; and the 'brief's unknowns
and review items' sentence, whose vocabulary exists nowhere in the bundle,
now names openwiki/log.md's Outstanding Critic Items.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 5: Drop the module-manifest precondition from `Test-GraphifyOutput.ps1`

The verifier throws unless both module manifests exist. It never reads them, and `modules/` is gitignored, so it fails on any clean checkout that has not run `composer install`. It also fails `Test-GraphifyOutputRegression.ps1`, which copies the verifier into a temp fixture containing only `graphify-out/`. One change clears both red scripts.

`Invoke-Graphify.ps1` **keeps** its precondition: a rebuild without `modules/` silently produces a degraded graph, which is exactly what a hard precondition is for.

**Files:**
- Modify: `tools/graphify/Test-GraphifyOutput.ps1` (the `$requiredModuleManifests` declaration and the `foreach` that checks it)

**Interfaces:**
- Consumes: nothing.
- Produces: a verifier that passes on a clean checkout. Task 9 runs it.

- [ ] **Step 1: Run the regression test to see it fail**

```bash
pwsh -File tools/graphify/Test-GraphifyOutputRegression.ps1
```

Expected: FAIL, reporting a missing required module manifest under the temp fixture path — the fixture contains only `graphify-out/`, never a `modules/` directory.

- [ ] **Step 2: Delete the declaration**

Remove these five lines from the top of `tools/graphify/Test-GraphifyOutput.ps1`:

```powershell
$requiredModuleManifests = @(
    (Join-Path $repoRoot 'modules/OfflinePayments/composer.json')
    (Join-Path $repoRoot 'modules/PaypalStandard/composer.json')
)
```

- [ ] **Step 3: Delete the check**

Remove this block, which sits immediately before the `foreach ($requiredOutputPath in @($graphJsonPath, $reportPath, $htmlPath))` loop:

```powershell
foreach ($manifestPath in $requiredModuleManifests) {
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "Missing required module manifest: $manifestPath"
    }
}
```

Leave the identical block in `tools/graphify/Invoke-Graphify.ps1:159-163` untouched.

- [ ] **Step 4: Run the regression test to verify it passes**

```bash
pwsh -File tools/graphify/Test-GraphifyOutputRegression.ps1
```

Expected: PASS.

- [ ] **Step 5: Verify the verifier still passes against the real artifact**

```bash
pwsh -File tools/graphify/Test-GraphifyOutput.ps1
```

Expected: PASS.

- [ ] **Step 6: Verify the rebuild wrapper still refuses without modules**

```bash
grep -n "Missing required module manifest" tools/graphify/Invoke-Graphify.ps1
```

Expected: one hit. The rebuild precondition is deliberately retained.

- [ ] **Step 7: Commit**

```bash
git add tools/graphify/Test-GraphifyOutput.ps1
git commit -m "fix: let the Graphify verifier run on a clean checkout

Test-GraphifyOutput.ps1 threw unless both module composer.json manifests
existed, but it never read them and modules/ is gitignored, so it failed
on any checkout that had not run composer install. It also failed
Test-GraphifyOutputRegression.ps1, which builds a temp fixture containing
only graphify-out/ — both scripts were red for this one reason.

Invoke-Graphify.ps1 keeps the precondition: a rebuild without modules/
produces a degraded graph silently, which is what it guards against.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 6: Replace both graphify `SKILL.md` copies with a repo-locked skill

`.agents/skills/graphify/SKILL.md` and `.claude/skills/graphify/SKILL.md` are byte-identical 40,775-byte copies of the upstream generic skill. It prescribes `uv tool install graphifyy`, LLM semantic extraction and community labeling, all of which contradict this repository's locked, wrapper-only, `--no-label` workflow (audit finding 9). Their `references/` directories are equally contradictory — `query.md` documents `save-result`, `reflect`, `LESSONS.md` and `graphify-out/.graphify_python`, none of which this repo uses — so the genuinely useful subcommand material is carried inline instead.

**Files:**
- Modify: `.agents/skills/graphify/SKILL.md` (full replacement)
- Delete: `.agents/skills/graphify/references/` and `.claude/skills/graphify/references/` (8 files each)
- Modify: `tools/agents/Sync-ProjectSkills.ps1:2` (mirror the graphify skill so the two copies cannot drift)
- Modify: `.claude/skills/graphify/SKILL.md` (regenerated by the sync)

**Interfaces:**
- Consumes: the capability-boundary wording from Task 4 — the skill must not contradict `AGENTS.md`.
- Produces: a skill an agent can load without also reading `AGENTS.md` and still follow the right procedure.

- [ ] **Step 1: Confirm the current state**

```bash
wc -c .agents/skills/graphify/SKILL.md .claude/skills/graphify/SKILL.md && grep -c "uv tool install graphifyy" .agents/skills/graphify/SKILL.md
```

Expected: both 40775 bytes, and at least one hit for the contradictory install instruction.

- [ ] **Step 2: Write the replacement skill**

Overwrite `.agents/skills/graphify/SKILL.md` entirely with:

````markdown
---
name: graphify
description: "Use for questions about this repository's architecture, file relationships, or where a symbol is used. Queries the committed Graphify code graph at graphify-out/graph.json through a locked local CLI. Prefer this over grep for what-calls-what questions; use grep for routes and config."
---

# Graphify (Akaunting)

This repository pins Graphify to a **committed baseline and a locked local project**. Ignore generic Graphify instructions found elsewhere: there is no global `graphifyy` install here, no LLM semantic extraction, no community labeling, no git hooks, and no MCP integration. Graphify needs no API key.

The graph is structural evidence, not documentation. For prose about how a subsystem works, read `openwiki/`. Verify both against current source.

## Query the graph

Run from the repository root:

```
uv run --project tools/graphify --locked graphify query "<question>" --graph graphify-out/graph.json --budget 6000
```

- **Seed with symbol names, not prose.** Seeding is a token match against node labels, not semantic. A natural-language question misfires silently and returns irrelevant nodes at full confidence — one audited probe seeded on `Reviews` because the question contained the word "views".
- **`--budget 6000` is the floor.** The default of 2000 truncates correct answers, which reads as absence.
- Add `--dfs` to trace one path instead of the default breadth-first sweep.

Two other subcommands, same invocation prefix:

```
uv run --project tools/graphify --locked graphify path "NodeA" "NodeB" --graph graphify-out/graph.json
uv run --project tools/graphify --locked graphify explain "NodeName" --graph graphify-out/graph.json
```

`path` finds the shortest route between two named nodes; `explain` describes everything connected to one node. Cite `source_file` and `loc` when quoting a result.

## What the graph cannot answer

- **Routes and config are file-level only.** Each `routes/*.php` is a single node at `loc=L1` with no edges to controllers; each `config/*.php` is one node with no keys. Route-to-controller resolution and config-key lookup are structurally impossible — grep those directories. Querying `"routes/admin.php"` returns the OfflinePayments file, not the root one.
- **`overrides/` and the root `composer.json` / `package.json` are out of scope**, with zero nodes. For dependency-coupling questions, read `overrides/` directly.
- Scope is `app/`, `modules/`, `config/`, `routes/`, `tests/` — PHP sources plus the two module `composer.json` manifests. See `.graphifyignore`.
- Edges are 86.9% `EXTRACTED` (source-derived, confidence 1.0) and 13.1% `INFERRED` (verify in source). No edge currently carries `AMBIGUOUS`.
- Communities are unnamed (`Community N`) because the wrapper passes `--no-label`. Community structure carries no semantic signal.

## Rebuild

Rebuilds are explicit actions, never automatic. The graph builds deterministically with no model in the loop, so it costs nothing but time.

```
pwsh -File tools/graphify/Invoke-Graphify.ps1
```

Prerequisites: Python 3.10+, `uv`, run from the repository root, and `modules/OfflinePayments/composer.json` plus `modules/PaypalStandard/composer.json` must exist. `modules/` is a gitignored post-install path — without it the wrapper refuses, because a rebuild would otherwise drop every module node silently.

`graphify-out/.graphify_analysis.json` is model-derived and cannot be regenerated by this wrapper. Never delete it.

Validate after rebuilding:

```
pwsh -File tools/graphify/Test-GraphifyOutput.ps1
pwsh -File tools/graphify/Test-GraphifyGuidance.ps1
```

The pinned toolchain is `graphifyy==0.9.34` in `tools/graphify/pyproject.toml`, verified by `tools/graphify/Test-GraphifyConfig.ps1`.
````

- [ ] **Step 3: Delete both `references/` directories**

```bash
rm -rf .agents/skills/graphify/references .claude/skills/graphify/references
```

- [ ] **Step 4: Add the graphify skill to the sync list**

In `tools/agents/Sync-ProjectSkills.ps1:2`, change:

```powershell
$projectSkills = @('akaunting-codebase-navigation', 'akaunting-test-coverage', 'akaunting-dependency-upgrade')
```

to:

```powershell
$projectSkills = @('akaunting-codebase-navigation', 'akaunting-test-coverage', 'akaunting-dependency-upgrade', 'graphify')
```

`Copy-Item` will not remove files deleted from the canonical copy, which is why Step 3 deletes both sides explicitly.

- [ ] **Step 5: Mirror and verify the two copies match**

```bash
pwsh -File tools/agents/Sync-ProjectSkills.ps1 && diff .agents/skills/graphify/SKILL.md .claude/skills/graphify/SKILL.md && echo IDENTICAL && ls .agents/skills/graphify/ .claude/skills/graphify/
```

Expected: `IDENTICAL`, and each directory listing shows `SKILL.md` alone.

- [ ] **Step 6: Verify no contradictory instruction survives**

```bash
grep -rn "uv tool install\|--no-label\|save-result\|graphify reflect\|LESSONS.md" .agents/skills/graphify/ .claude/skills/graphify/
```

Expected: only the `--no-label` mention in the Communities bullet, which explains the repo's setting rather than prescribing a different one. No `uv tool install`, no `save-result`, no `reflect`, no `LESSONS.md`.

- [ ] **Step 7: Run the guidance and harness tests**

```bash
pwsh -File tools/graphify/Test-GraphifyGuidance.ps1 && pwsh -File tools/agents/Test-AgentHarness.ps1
```

Expected: both pass. `Test-GraphifyGuidance.ps1` requires `.claude/skills/graphify/SKILL.md` to exist, which it still does.

- [ ] **Step 8: Commit**

```bash
git add .agents/skills/graphify .claude/skills/graphify tools/agents/Sync-ProjectSkills.ps1
git commit -m "docs: replace the generic graphify skill with a repo-locked one

Both copies were byte-identical 40KB dumps of the upstream generic skill,
prescribing uv tool install graphifyy, LLM semantic extraction and
community labeling — all contradicted by this repo's locked, wrapper-only,
--no-label workflow. The reconciliation existed only as prose in AGENTS.md,
so an agent loading the skill without it followed the wrong procedure.

The replacement states only what this repository actually does, and
carries the graph's capability boundaries so the skill is correct on its
own. The references/ directories go with it: query.md documented
save-result, reflect and LESSONS.md, none of which this repo uses. The
useful query/path/explain material is carried inline.

Adds graphify to Sync-ProjectSkills.ps1 so the two copies cannot drift.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 7: Compute the dead-citation list

Path existence is a computable fact and is supplied to the Task 8 subagent as established input, never asked as a question. Blurring computed input with model judgment is the mechanism that produced these defects in the first place.

This script is **throwaway**. It lives in the scratchpad and is never committed — the design explicitly rules out a permanent citation checker.

**Files:**
- Create (scratchpad, not committed): `Find-DeadCitations.ps1`
- Create (scratchpad, not committed): `dead-citations.txt`

**Interfaces:**
- Consumes: nothing.
- Produces: `dead-citations.txt`, a list of `page:line → cited path` entries. Task 8 consumes it as fact; Task 9 re-runs the script expecting zero entries.

- [ ] **Step 1: Write the sweep script**

Save as `$SCRATCH/Find-DeadCitations.ps1`, where `$SCRATCH` is the scratchpad path from Global Constraints:

```powershell
param(
    [Parameter(Mandatory = $true)]
    [string] $RepoRoot
)

$ErrorActionPreference = 'Stop'

# Rooted citations only: a path starting at one of the repository's real top-level directories.
$citationPattern = '(?<![\w./-])((?:app|config|routes|tests|database|resources|modules|overrides|bootstrap|public|storage)/[\w./-]*[\w-])'

# Non-defects, per the audit. Anything matching these is skipped rather than reported.
$waiverPatterns = @(
    '^modules/OfflinePayments/'      # Composer-installed, gitignored, absent from a clean checkout
    '^modules/PaypalStandard/'       # same
    '^modules/MyModule'              # tutorial placeholder
    '^modules/YourModule'            # tutorial placeholder
    '^App/Console/Commands/MyCommand\.php$'  # tutorial placeholder
)

$pages = Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'openwiki') -Recurse -Filter '*.md' -File
$findings = [System.Collections.Generic.List[string]]::new()
$citationCount = 0

foreach ($page in $pages) {
    $relativePage = $page.FullName.Substring($RepoRoot.Length).TrimStart('\', '/').Replace('\', '/')
    $lineNumber = 0

    foreach ($line in (Get-Content -LiteralPath $page.FullName)) {
        $lineNumber++

        foreach ($match in [regex]::Matches($line, $citationPattern)) {
            $cited = $match.Groups[1].Value
            $citationCount++

            if ($waiverPatterns | Where-Object { $cited -match $_ }) { continue }

            $candidates = @($cited)
            if ($cited -notmatch '\.\w+$') { $candidates += "$cited.php" }  # extensionless symbol refs

            $resolved = $false
            foreach ($candidate in $candidates) {
                if (Test-Path -LiteralPath (Join-Path $RepoRoot $candidate)) { $resolved = $true; break }
            }

            if (-not $resolved) {
                $findings.Add("{0}:{1} -> {2}" -f $relativePage, $lineNumber, $cited)
            }
        }
    }
}

Write-Host ("Scanned {0} pages, {1} rooted citations, {2} unresolved." -f $pages.Count, $citationCount, $findings.Count)
$findings | Sort-Object -Unique
```

- [ ] **Step 2: Run it**

```bash
pwsh -File "$SCRATCH/Find-DeadCitations.ps1" -RepoRoot "C:/Users/ayrto/projects/akaunting/.claude/worktrees/openwiki-graphify-improvements-f24f80" | tee "$SCRATCH/dead-citations.txt"
```

Expected: a scan summary near 74 pages and 128 rooted citations, and a non-empty finding list. The audit found 17 dead citations by hand; this sweep covers every page, so a higher count is expected and is not an error.

- [ ] **Step 3: Sanity-check the output against the audit**

The list must contain at least these, all named in audit finding 1:

- `app/Http/Requests/Settings/Category.php` (real directory is singular `Setting/`)
- `app/Http/Requests/Settings/Tax.php`
- `config/Kernel.php`
- `config/oauth.php`, `config/tax.php`
- `app/Policies/`, `app/Services/`
- `resources/views/layouts/app.blade.php`
- `resources/assets/js/app.js`
- `tests/Feature/Banking/AccountsTest.php`

If any is missing, the regex is under-matching — widen it and re-run before continuing. If the list contains `modules/OfflinePayments/**` entries, the waivers are not firing.

- [ ] **Step 4: Resolve each dead citation to its real path**

For every entry, find what the page meant. Record the correction next to it in `dead-citations.txt`, as `page:line -> cited -> REPLACEMENT` or `-> DELETE` where nothing real corresponds. Two examples from the audit:

```
openwiki/workflows/permissions-workflow.md:NN -> app/Http/Requests/Settings/Category.php -> app/Http/Requests/Setting/Category.php
openwiki/workflows/permissions-workflow.md:NN -> config/Kernel.php -> app/Http/Kernel.php:197
```

Use `ls` and `git ls-files` to confirm each replacement exists. Do not guess: an unresolvable citation is marked `DELETE`, not replaced with a plausible-looking path.

- [ ] **Step 5: No commit**

Nothing from this task enters the repository. Confirm:

```bash
git status --short
```

Expected: clean.

---

### Task 8: Correct the OpenWiki bundle

A single Sonnet 5 subagent applies the Task 7 list and repairs the four prose defects the audit names. One agent rather than several, because `testing.md` and `permissions-workflow.md` both need the same picture of what actually exists and parallel agents would re-derive it separately and could disagree.

**Files:**
- Modify: `openwiki/testing.md`
- Modify: `openwiki/workflows/permissions-workflow.md`
- Modify: `openwiki/workflows/invoice-workflow.md`
- Modify: `openwiki/systems/modules/overview.md`
- Modify: every page listed in `dead-citations.txt`
- Modify: `openwiki/log.md`
- **Do not touch:** `openwiki/.last-update.json`

**Interfaces:**
- Consumes: `dead-citations.txt` from Task 7 (as established fact); the rebuilt graph from Task 3.
- Produces: a bundle where the Task 7 sweep reports zero unresolved citations.

- [ ] **Step 1: Gather the facts the subagent must be given rather than asked**

Run these and keep the output; the subagent receives it as input:

```bash
find tests -name '*Test.php' | sort && echo "---" && ls tests/Feature/ && echo "---" && sed -n '55,62p' app/Providers/Route.php && echo "---" && sed -n '10,14p' routes/signed.php && echo "---" && sed -n '195,199p' app/Http/Kernel.php
```

Expected: 36 `*Test.php` files across 12 `tests/Feature/*` subdirectories; the `{company_id}/` prefix; the `Portal\Invoices@signed` binding; the `permission` middleware alias at `app/Http/Kernel.php:197`.

- [ ] **Step 2: Dispatch the correction subagent**

Use the Agent tool with `subagent_type: general-purpose` and `model: sonnet`. Prompt:

```
You are correcting factual errors in a generated documentation bundle at
openwiki/ in the repository at <REPO_ROOT>. Work only inside openwiki/.

HARD RULES
- Never modify openwiki/.last-update.json.
- Never run the openwiki CLI.
- Every path you write must exist on disk. Verify with Read or ls before
  writing it. If you cannot verify a claim, delete the claim rather than
  writing a plausible-looking one. Fabricated-but-plausible content is the
  exact defect you are fixing.
- Do not invent code samples. Only show APIs you have confirmed exist in
  this repository or its composer.json dependencies.
- Preserve each page's existing structure, frontmatter and heading levels.

TASK 1 — apply this dead-citation list. Each line is
page:line -> cited-path -> REPLACEMENT (or DELETE). These have already been
verified against disk; treat them as fact, do not re-derive them.
<PASTE dead-citations.txt>

TASK 2 — repair four pages.

(a) openwiki/testing.md
  - Lines ~75-87 render the whole tests/ tree as four files. That is false
    by omission: the repository has 36 *Test.php files across 12
    tests/Feature/* subdirectories. Replace with an accurate tree. Here is
    the real listing, verified:
    <PASTE the find/ls output from Step 1>
  - Delete these five fabricated APIs and any surrounding narrative that
    depends on them: Illuminate\Testing\Benchmark\Benchmark (~:566, :574),
    assertGreater() (~:158), dumpSql() (~:594), ray() (~:607),
    CurrencyService::convert() (~:461). None exist in this project or its
    dependencies. Do not substitute replacements you have not verified.
  - The page says CI runs `php artisan test --coverage`. It runs
    `php artisan test --parallel` (.github/workflows/tests.yml:52), and
    phpunit.xml has no <coverage> element. Correct both claims.

(b) openwiki/workflows/permissions-workflow.md
  - Four of its seven Source Map rows are wrong; the list in TASK 1 covers
    them. Additionally the page never states where the `permission`
    middleware alias is registered. It is app/Http/Kernel.php:197 — add it.

(c) openwiki/workflows/invoice-workflow.md
  - The `/admin/` URL prefix appears in eight places and does not exist.
    app/Providers/Route.php:57-60 sets the prefix to `{company_id}/`.
    Correct every occurrence.
  - `GET /signed/invoices/{id}` is mapped to Portal\Invoices@show. It binds
    to Portal\Invoices@signed (routes/signed.php:12).
  - The controller, request class and job names on this page are correct.
    Leave them alone.

(d) openwiki/systems/modules/overview.md
  - The page frames app/Traits/Modules.php as the module-registration
    mechanism. It is not: read it and you will find checkToken(),
    getModules(), getModuleReviews(), getModuleTestimonials(),
    getBannersOfModules(), built on App\Traits\SiteApi. It is the Akaunting
    App Store HTTP API client. Say so.
  - Registration actually runs through the vendor package
    akaunting/laravel-module, composer.json's installer-paths,
    config/module.php, and the command overrides in
    overrides/akaunting/laravel-module/Commands/. Verify each of these
    before describing it, then rewrite the page around them.
  - Correct the page's openwiki.source_paths frontmatter block to match.

TASK 3 — append a dated entry to openwiki/log.md recording that this was a
manual correction pass (not a generator run), listing the pages changed and
naming specs/northstar/OPENWIKI-GRAPHIFY-AUDIT.md as the source.

Report back: which pages you changed, and any citation from TASK 1 you could
not resolve.
```

- [ ] **Step 3: Re-run the sweep as an independent check**

```bash
pwsh -File "$SCRATCH/Find-DeadCitations.ps1" -RepoRoot "C:/Users/ayrto/projects/akaunting/.claude/worktrees/openwiki-graphify-improvements-f24f80"
```

Expected: `0 unresolved`. Any remaining entry means the subagent missed it or introduced a new one — fix and re-run.

- [ ] **Step 4: Verify the fabricated APIs are gone and none returned**

```bash
grep -rn "Benchmark\|assertGreater\|dumpSql\|ray(\|CurrencyService" openwiki/
```

Expected: no output.

- [ ] **Step 5: Verify the invented URL prefix is gone**

```bash
grep -rn "/admin/" openwiki/ && echo "STILL PRESENT"
```

Expected: no output (no `STILL PRESENT`).

- [ ] **Step 6: Verify the generator's state file is untouched**

```bash
git status --short openwiki/
```

Expected: `openwiki/.last-update.json` does **not** appear. If it does, restore it: `git checkout -- openwiki/.last-update.json`.

- [ ] **Step 7: Read the diff before committing**

```bash
git diff --stat openwiki/ && git diff openwiki/testing.md
```

The subagent's own failure mode is inventing plausible APIs — the same defect being fixed. Read the `testing.md` diff in full and spot-check the other three pages for any API or path you cannot place.

- [ ] **Step 8: Commit**

```bash
git add openwiki/
git commit -m "docs: correct factual errors in the OpenWiki bundle

Applies the audit's findings directly rather than regenerating, since the
generator is what produced them. Fixes every unresolved rooted citation
across all 74 pages, plus the four pages the audit graded worst:

- testing.md rendered the whole tests/ tree as four files when there are
  36 across 12 Feature subdirectories, and documented five APIs that do
  not exist (Benchmark, assertGreater, dumpSql, ray, CurrencyService).
  It also claimed CI runs --coverage; it runs --parallel.
- permissions-workflow.md had four of seven Source Map rows wrong and
  never named the middleware alias at app/Http/Kernel.php:197.
- invoice-workflow.md invented an /admin/ URL prefix; the real prefix is
  {company_id}/, and the signed route binds to @signed not @show.
- systems/modules/overview.md framed app/Traits/Modules.php as module
  registration when it is the App Store HTTP client — the most expensive
  failure in the bundle, because the cited path exists and the graph
  confirms the wrong answer.

.last-update.json is deliberately untouched: it is the generator's diff
anchor, and moving it would degrade the next update run.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 9: Verify the remediation

Throwaway verification, run once. No harness is committed.

**Files:**
- None modified. This task only runs checks.

**Interfaces:**
- Consumes: everything from Tasks 1-8.

- [ ] **Step 1: All six validation scripts green**

```bash
pwsh -File tools/graphify/Test-GraphifyConfig.ps1 && pwsh -File tools/graphify/Test-GraphifyGuidance.ps1 && pwsh -File tools/graphify/Test-GraphifyOutput.ps1 && pwsh -File tools/graphify/Test-GraphifyOutputRegression.ps1 && pwsh -File tools/graphify/Test-GraphifyWrapper.ps1 && pwsh -File tools/agents/Test-AgentHarness.ps1
```

Expected: all six pass. Two (`Test-GraphifyOutput`, `Test-GraphifyOutputRegression`) were red before Task 5, and `Test-AgentHarness` was red before Task 1.

- [ ] **Step 2: Verify the verifier passes without `modules/` present**

The point of Task 5 is a clean checkout. Temporarily move the copied modules aside:

```bash
mv modules /tmp/modules-parked && pwsh -File tools/graphify/Test-GraphifyOutput.ps1; mv /tmp/modules-parked modules
```

Expected: PASS while `modules/` is absent. Restore it either way — the trailing `mv` runs regardless because of the `;`.

- [ ] **Step 3: Citation sweep at zero**

```bash
pwsh -File "$SCRATCH/Find-DeadCitations.ps1" -RepoRoot "C:/Users/ayrto/projects/akaunting/.claude/worktrees/openwiki-graphify-improvements-f24f80"
```

Expected: `0 unresolved`.

- [ ] **Step 4: Re-run the five latent probes**

These are the audit's MISLEADING results that survived source verification — the only real evidence the pass worked. For each, follow the evidence order in `AGENTS.md` (read the relevant `openwiki/` page, then query the graph, then check source) and record whether the answer is now correct.

| Probe | Question | Now expected |
|---|---|---|
| P01 | Trace invoice create from request to DB write | `{company_id}/` prefix, not `/admin/` |
| P04 | Write a feature test for a banking domain | Finds the existing `tests/Feature/Banking/` siblings rather than inventing a base class |
| P07 | How do I register a new module? | `akaunting/laravel-module` + `installer-paths` + `config/module.php`, not `app/Traits/Modules.php` |
| P09 | Benchmark totals and assert query count | No `Benchmark::measure` or `assertGreater`; only real PHPUnit assertions |
| P12 | Open `createApplication()` and add a step | Lands at `tests/CreatesApplication.php:17`, not L14 |

The four self-limiting failures (P03, P05, P08, P11) should clear as a side effect and are not separately graded. The two MISS results (P06, P10) are capability boundaries — Task 4 documents them; they are not expected to become hits.

- [ ] **Step 5: Confirm no scratchpad artifact leaked into the repository**

```bash
git status --short && git log --oneline -8
```

Expected: a clean tree, and seven task commits (Tasks 1-6 and 8) on top of the three documentation commits that precede them. No `Find-DeadCitations.ps1`, no `dead-citations.txt`, and no `modules/` path in any commit:

```bash
git log --name-only --oneline -10 | grep -c "^modules/"
```

Expected: `0`.

- [ ] **Step 6: Surface the deferred decision**

No commit. Report to the user that `.github/workflows/openwiki-update.yml` still fires at `0 8 * * *` with `add-paths: openwiki`, so the next scheduled run can overwrite Task 8. The three options are recorded in the design document's "Deferred decision" section. This is a decision to take, not a defect to fix here.

---

## Self-Review

**Spec coverage.** Prerequisites → Task 1 (audit port), Task 3 Steps 1-2 (`modules/`), Task 3 ordering (rebuild before wiki). A1 → Task 4 Step 3. A2 → Task 4 Steps 1-2. A3 → Task 2. A4 → Task 5. A5 → Task 6. B1 → Task 7. B2 → Task 8 Step 2. B3 → Task 8 Step 6 (`.last-update.json` untouched). Verification → Task 9. Commit order matches the spec's list, with the spec's commit 1 covering the port. Non-goals are enforced in Global Constraints and Task 7 Step 5.

**Known gap, deliberate.** The spec's residual risk stands: nothing here catches a *new* fabricated API or a new false-complete listing introduced by the Task 8 subagent. Task 8 Steps 4 and 7 are the only defense, and they are a grep and a human read, not a check. That is the accepted trade of declining a permanent harness.
