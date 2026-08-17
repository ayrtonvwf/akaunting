# Remediating the OpenWiki bundle and the Graphify graph

`specs/northstar/OPENWIKI-GRAPHIFY-AUDIT.md` graded the two generated evidence layers against twelve
realistic agent tasks and returned seven MISLEADING, two MISS, two PARTIAL and no clean hit. This
document specifies the one-time remediation of those findings.

The audit's own framing sets the priority: the bundle's failures are concentrated in **confident
falsehoods rather than gaps**, and roughly half survive the source-verification step the project
skills already mandate. A gap costs an agent one grep. A confident falsehood costs it a wrong answer.

## Goal

Every defect the audit names is fixed, and the guidance files stop instructing agents to do things
the tooling cannot do.

## Non-goals

Stated up front because the audit recommends several of them and this project deliberately declines:

- **No permanent CI harness.** No committed citation checker, no graph-versus-`HEAD` staleness gate,
  no probe-set retrieval scorer. Verification here is throwaway and run once.
- **No prose re-verification of the 60 pages the audit did not examine.** Their citations are swept
  mechanically; their claims are not read.
- **No OpenWiki CLI run.** Corrections are made directly to the bundle's files by a Sonnet 5
  subagent. This contradicts the current `AGENTS.md` rule and collides with the scheduled generator;
  see "Deferred decision" below.
- **No model change to the generator.** `OPENWIKI_MODEL_ID` stays `claude-haiku-4-5`.
- The audit's own unchecked items stay unchecked: whether `manifest.json`'s 1,229-file list agrees
  with the graph, the `gods`/`surprises`/`questions` content of `.graphify_analysis.json`, and
  whether the 54 pages lacking an `openwiki.source_paths` block should gain one.

## Prerequisites

Three conditions, each a genuine dependency rather than housekeeping.

**The audit is not on this branch.** `specs/northstar/OPENWIKI-GRAPHIFY-AUDIT.md` is untracked in the
`test-openwiki-graphify-agent-0ec8aa` worktree, alongside uncommitted edits to `AGENTS.md` and
`tools/agents/Sync-ProjectSkills.ps1` that the audit describes as already applied. The divergence
those edits fix is live here: `CLAUDE.md` carries a "Parallel test isolation" section that
`AGENTS.md` does not, and `Sync-ProjectSkills.ps1` in this worktree references neither file, so
nothing generates one from the other. All four changes are ported onto this branch first, in one
commit attributed to the audit. Both worktrees sit on `9dd32e349`, so the port is a copy rather than
a merge.

**The graph is rebuilt before the wiki is corrected.** The subagent doing prose repair uses the graph
as one of its checks. The committed baseline is stale by five files and reports
`createApplication() loc=L14` for a method now at L17. Correcting prose against a stale graph
launders staleness into text that then reads as verified.

**`modules/` must be populated for the rebuild.** It is a gitignored post-install path, empty in this
worktree and populated in the main checkout at `C:\Users\ayrto\projects\akaunting`. There is no
`composer` or `php` on `PATH`; only the Docker environment in `compose.local.yml`. Both
`Invoke-Graphify.ps1` and `Test-GraphifyOutput.ps1` hard-throw without
`modules/OfflinePayments/composer.json` and `modules/PaypalStandard/composer.json`. The two
directories are therefore copied in from the main checkout before rebuilding. They are gitignored, so
nothing enters a commit. Skipping this does not fail loudly — it produces a graph missing every
module node the current baseline has.

Sequence: port the audit → populate `modules/` → rebuild the graph → correct guidance → correct the
wiki.

## Workstream A — guidance and tooling

No model is involved. Every change is checkable by reading.

### A1. `AGENTS.md` gains the graph's capability boundary

Undocumented today, so an agent spends a query discovering it (audit finding 5).

- Routes and config resolve at **file level only**. All 12 `routes/*.php` files are single nodes at
  `loc=L1` with no symbols and no edges to controllers; all 45 `config/*.php` files are one node each
  with no keys. Route-to-controller resolution and config-key lookup are structurally impossible —
  grep those directories directly. Note also that querying `"routes/admin.php"` returns
  `modules/OfflinePayments/Routes/admin.php`, not the root file.
- `overrides/**` and the root `composer.json` / `package.json` are **outside the five scope roots**
  and have zero nodes. The string `overrides` appears zero times across all 74 OpenWiki pages. For a
  dependency-coupling question, neither evidence layer can answer; inspect `overrides/` directly.
- `graphify query` seeds by **token-matching node labels, not semantically**. Symbol-name queries
  work; prose questions misfire silently and return irrelevant nodes with full confidence.
- **`--budget 6000` is the floor.** At the default 2000 a correct answer is routinely truncated away,
  which reads to the agent as absence.

### A2. Two pieces of dead guidance are removed

- **`AMBIGUOUS`.** Zero edges carry the label; the real split is 86.9% `EXTRACTED` / 13.1%
  `INFERRED`. `AGENTS.md` stops instructing agents to treat `AMBIGUOUS` edges as requiring source
  inspection, and instead states the real distribution and that no edge currently carries the label.
  This is the audit's second option ("state that it is currently unexercised") rather than its first
  ("drop it from `AGENTS.md` and `Test-GraphifyGuidance.ps1`), chosen after finding that
  `tools/agents/Test-AgentHarness.ps1:21` asserts the token as well: deletion is a three-file change
  that leaves an agent with no guidance at all if the label ever fires, while the replacement
  sentence keeps both scripts green and carries more information.
- **"a brief's unknowns and review items"** (`AGENTS.md` line 9). That vocabulary exists nowhere in
  the bundle; the nearest real thing is `openwiki/log.md`'s "Outstanding Critic Items". The sentence
  is rewritten to name that, or dropped.

`Test-GraphifyGuidance.ps1` enforces a 120-line ceiling on `AGENTS.md`, which sits well under it both
before and after the port (59 lines here, 42 in the audit's revised version). There is room for A1
and A2, but the ceiling caps how much boundary detail belongs in `AGENTS.md` rather than in the
skill, and the exact budget depends on which version the port lands.

### A3. `.graphifyignore` narrows

`!modules/**` currently admits six non-PHP files — `offline-payments.min.js`, `offline-payments.js`,
`webpack.mix.js`, `package.json`, and both module `composer.json` files — contradicting `AGENTS.md`'s
claim that frontend and generated assets are excluded. A minified bundle became a `rationale` node.

The rule becomes `!modules/**/*.php` **plus an explicit `!modules/**/composer.json`**. The audit's
suggested `*.php`-only narrowing overshoots: the module manifests are neither frontend nor generated
assets, and both validation scripts depend on them existing. This change lands before the rebuild so
one rebuild covers it.

`tools/graphify/Test-GraphifyConfig.ps1` pins `.graphifyignore` byte-for-byte against an
`$expectedIgnoreEntries` list, so that list changes in the same commit or the script goes red.

### A4. The manifest precondition is split, not deleted

`Test-GraphifyOutput.ps1` throws unless both module manifests exist. It never reads them, and
`modules/` is gitignored, so it fails on any clean checkout that has not run `composer install`. It
also fails `Test-GraphifyOutputRegression.ps1`, which copies the verifier into a temp fixture
containing only `graphify-out/` — so one fix clears both red scripts.

- `Test-GraphifyOutput.ps1` **loses** the precondition. It validates a committed artifact and should
  pass on a clean checkout.
- `Invoke-Graphify.ps1` **keeps** it. A rebuild without `modules/` genuinely produces a degraded graph
  and does so silently, which is exactly what a hard precondition is for.

### A5. Both `SKILL.md` copies are replaced

`.claude/skills/graphify/SKILL.md` and `.agents/skills/graphify/SKILL.md` are byte-identical 40,775-byte
copies of the upstream generic skill, prescribing `uv tool install graphifyy`, LLM semantic extraction
and community labeling — all of which contradict this repository's locked, wrapper-only, `--no-label`
workflow. An agent that loads the skill without also reading `AGENTS.md` follows the wrong procedure.

Both are replaced with a short repo-locked skill covering: the locked query command, the committed
baseline under `graphify-out/`, the rebuild wrapper and its prerequisites, the capability boundaries
from A1, and the `--budget` floor. Upstream guidance on the `query`, `path` and `explain` subcommands
is carried over deliberately rather than lost by accident — **inline, not by keeping
`references/query.md`**, because that file is itself contradictory here: it documents `save-result`,
`reflect`, `LESSONS.md` and a `graphify-out/.graphify_python` interpreter path, none of which this
repository uses. The whole `references/` directory is removed from both copies.

The two copies stay byte-identical to each other, and `Test-GraphifyGuidance.ps1`'s existence check
for the Claude Code path must still pass. `graphify` is added to the `$projectSkills` list in
`tools/agents/Sync-ProjectSkills.ps1` so the mirror is generated rather than hand-maintained.

## Workstream B — the wiki correction pass

Executed as a deterministic defect list followed by a single Sonnet 5 subagent. The split is
deliberate: path existence is a computable fact and is supplied as established input, never as a
question. Blurring computed input with model judgment is the mechanism that produced these defects.

### B1. Citation sweep (deterministic)

A throwaway script extracts every rooted source citation from all 74 pages and tests it against disk.
Waived as non-defects, per the audit:

- `modules/OfflinePayments/**` and `modules/PaypalStandard/**` — Composer-installed, gitignored,
  absent from a clean checkout by design.
- Tutorial placeholders: `modules/MyModule/…`, `modules/YourModule`,
  `App/Console/Commands/MyCommand.php`.
- Extensionless symbol references such as `app/Jobs/Document/CreateDocument`, which resolve once
  `.php` is appended.

Output is a reviewable list of dead paths. The audit found 17; the sweep covers all 128 rooted
citations, so it may find more.

### B2. Subagent corrections

One Sonnet 5 subagent applies the B1 list and repairs the four prose defects the audit names.

**`openwiki/testing.md`** — the highest-cost page, because `akaunting-test-coverage` sends every agent
to it first.

- Lines 75–87 render the whole `tests/` tree as four files. The repository has **36 `*Test.php` files
  across 12 `tests/Feature/*` subdirectories**. Every path the page names is real; the falsehood is
  the omission, and no path check can catch it.
- Five fabricated APIs are removed: `Illuminate\Testing\Benchmark\Benchmark` (:566, :574),
  `assertGreater(...)` (:158), `dumpSql()` (:594), `ray(...)` (:607), `CurrencyService::convert(...)`
  (:461).
- The page states CI runs `php artisan test --coverage`. `.github/workflows/tests.yml:52` runs
  `php artisan test --parallel`, and `phpunit.xml` has no `<coverage>` element.

**`openwiki/workflows/permissions-workflow.md`** — four of seven Source Map rows are wrong
(`app/Http/Requests/Settings/*` is singular `Setting/`; `config/Kernel.php`, `config/oauth.php`,
`config/throttle` do not exist; `LaratrustUserTrait` is the vendor trait `Laratrust\Traits\…`;
`tests/Feature/Auth/` holds only `UsersTest.php`). It must also gain the fact it omits: the
`permission` middleware alias lives at `app/Http/Kernel.php:197`.

**`openwiki/workflows/invoice-workflow.md`** — `/admin/` appears in eight places and does not exist.
`app/Providers/Route.php:57-60` sets the prefix to `{company_id}/`. `GET /signed/invoices/{id}` maps
to `Portal\Invoices@signed` per `routes/signed.php:12`, not `@show`. The controller, request class and
job the page names are correct, which is what makes the URLs dangerous.

**`openwiki/systems/modules/overview.md`** — the most expensive failure in the bundle, because the
cited path exists, has 44 graph nodes, and the graph confirms the wrong answer. The page frames
`app/Traits/Modules.php` as the module-registration mechanism; reading it (`checkToken()`,
`getModules()`, `getModuleReviews()`, built on `App\Traits\SiteApi`) shows it is the Akaunting App
Store HTTP API client. Registration actually runs through the vendor package
`akaunting/laravel-module`, `composer.json`'s `installer-paths`, `config/module.php`, and the command
overrides in `overrides/akaunting/laravel-module/Commands/`. The page's `openwiki.source_paths` block
is corrected alongside the prose.

### B3. One deliberate non-change

**`openwiki/.last-update.json` is not touched.** It is the generator's own diff anchor
(`gitHead: 1a03c3ee5`). Editing it to claim a newer documented commit would make the next
`openwiki code --update` run worse, not better, by hiding real changes from its diff. The manual
correction pass is recorded in `openwiki/log.md` instead.

## Verification

Throwaway, run once, since no harness is being committed.

1. All six validation scripts green: `Test-GraphifyConfig`, `Test-GraphifyGuidance`,
   `Test-GraphifyOutput`, `Test-GraphifyOutputRegression`, `Test-GraphifyWrapper`,
   `tools/agents/Test-AgentHarness.ps1`. Two are red today (A4).
2. The B1 extractor re-run after the subagent pass, expecting zero unwaived dead citations.
3. Manual re-run of the five **latent** probes — P01 (invoice create trace), P04 (banking feature
   test), P07 (module registration), P09 (benchmark and assert query count), P12
   (`createApplication()`). Latent failures are the ones that survived source verification, so they
   are the only real evidence the pass worked. The self-limiting failures (P03, P05, P08, P11) are
   expected to clear as a side effect and are not separately graded. The two MISS results (P06, P10)
   are capability boundaries rather than defects; A1 documents them so an agent stops paying a query
   to rediscover them, and they are not expected to become hits.

**Residual risk, accepted rather than solved.** The subagent's own failure mode is the one that
produced these defects: a model asked to write documentation invents plausible APIs. The mitigation is
that every claim it writes carries a path it verified, and the B1 extractor runs after it as an
independent check. That catches fabricated *paths*. It does not catch a fabricated *API* or another
false-complete listing — precisely the audit's argument against relying on structural validation
alone. Nothing in this scope closes that gap.

## Commits

Each independently reviewable, in order:

1. Port the audit document plus its `AGENTS.md` and `Sync-ProjectSkills.ps1` fixes.
2. Narrow `.graphifyignore` (A3).
3. Rebuild the graph (`graphify-out/`, including `.graphify_analysis.json`).
4. `AGENTS.md` guidance together with the `Test-GraphifyGuidance.ps1` pattern change (A1 + A2 — must
   move as one).
5. `Test-GraphifyOutput.ps1` precondition (A4).
6. `SKILL.md` replacement, both copies (A5).
7. Wiki corrections and `openwiki/log.md` (B).

## Deferred decision

Hand-correcting the bundle contradicts two things currently in force: `AGENTS.md` says "Do not edit
the OpenWiki bundle", and `.github/workflows/openwiki-update.yml` runs `openwiki code --update` on a
`0 8 * * *` cron with `add-paths: openwiki`. **The next scheduled run after this work lands can
overwrite Workstream B with haiku-generated text.**

This was raised and deliberately deferred. It is recorded here as an open decision, not a solved
problem. The options identified, none chosen:

- Drop the cron trigger (keeping `workflow_dispatch`) and flip the `AGENTS.md` rule to
  "edit and verify against source", making staleness the accepted risk instead of fabrication.
- Keep the schedule and raise `OPENWIKI_MODEL_ID`, accepting that the corrections have a known expiry.
- Keep the schedule and exclude the corrected pages, accepting mixed provenance that `AGENTS.md` would
  then have to describe.

Note also that the workflow lists `AGENTS.md` and `CLAUDE.md` in its `add-paths`, so an automated
OpenWiki PR can overwrite either file; `Sync-ProjectSkills.ps1` must be re-run after merging one.
