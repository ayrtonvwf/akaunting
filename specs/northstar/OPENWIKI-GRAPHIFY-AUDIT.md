# Audit: the OpenWiki bundle and the Graphify graph as agent evidence

`AGENTS.md` tells an agent to trust two generated layers in a fixed order — read `openwiki/`, run
the locked Graphify query, then verify in source. Three project skills are built on that contract.
Until now nothing had ever checked whether the two layers hold up.

Audited on 2026-08-11 against `9dd32e349`, with `openwiki/` at `gitHead 1a03c3ee5` and
`graphify-out/graph.json` at `built_at_commit 4fc6d5662`.

## Summary

| Layer | Verdict |
|---|---|
| Graphify graph — structure | **Sound.** 7034 nodes, 15360 edges, zero dangling references, zero self-loops, 99.7% coverage of in-scope PHP |
| Graphify graph — resolution | **Bounded.** Routes and config are file-level only; `overrides/` and root manifests are outside scope entirely |
| OpenWiki — navigation | **Sound.** 314 internal links, zero broken |
| OpenWiki — citations | **Unreliable.** 17 of 128 rooted source citations point at files that have never existed |
| OpenWiki — code samples | **Unreliable.** `testing.md` documents at least five APIs that do not exist in this project or its dependencies |
| Validation scripts | **2 of 6 red** before this audit; both now understood, one fixed |

The headline is not that the artifacts are stale. Staleness is small and bounded: both predate the
same five-file parallel-test-isolation change and nothing else. The headline is that **the
OpenWiki bundle's failures are concentrated in confident falsehoods rather than gaps**, and that
roughly half of them survive the source-verification step the skills already mandate.

A gap costs an agent one grep. A confident falsehood costs it a wrong answer.

## What is sound, and worth saying plainly

The graph is in good structural health. Every one of the 15,360 edges resolves to a real node on
both ends; there are no self-loops; 1,157 of the 1,160 in-scope PHP files on disk appear as a
`source_file`. Of edges, 86.9% are `EXTRACTED` with a confidence of exactly 1.0. When the graph
answers, it answers accurately.

The OpenWiki bundle's *structure* is also sound: all 314 relative links between its 74 pages
resolve. As a table of contents it works. Every page carries `type`, `title`, `description` and
`tags`.

And in one probe the graph actively rescued the wiki — see P02 below. The two layers are not
redundant, and the evidence order in `AGENTS.md` is the right one.

## Defects, ordered by what they cost the agent

### 1. OpenWiki cites paths that have never existed

Seventeen rooted citations do not resolve, and they are not evenly distributed — they cluster in
the Source Map tables that an agent is most likely to act on.

| Cited | Reality |
|---|---|
| `app/Http/Requests/Settings/Category.php` | `app/Http/Requests/Setting/Category.php` — directory is singular |
| `app/Http/Requests/Settings/Tax.php` | `app/Http/Requests/Setting/Tax.php` — same |
| `config/Kernel.php` | `app/Http/Kernel.php:197` holds the `permission` alias |
| `app/Models/Auth/Traits/LaratrustUserTrait` | No such path. It is a vendor trait, `Laratrust\Traits\LaratrustUserTrait` |
| `tests/Feature/Auth/Permissions*.php` | `tests/Feature/Auth/` contains exactly one file, `UsersTest.php` |
| `config/oauth.php`, `config/tax.php`, `config/throttle` | None exist |
| `app/Policies/`, `app/Services/` | Neither directory exists |
| `resources/views/layouts/app.blade.php` | `resources/views/layouts/` is empty |
| `resources/assets/js/app.js`, `App.vue`, `css/app.css` | None exist; real entries are `install.js`, `bootstrap.js` |
| `database/seeds/Database/Seeders` | Not a path |
| `tests/Feature/Banking/AccountsTest.php` | Does not exist |

`openwiki/workflows/permissions-workflow.md` is the worst single page: **four of its seven Source
Map rows are wrong.** An agent reading it to answer "how are permissions enforced?" gets three
dead paths and one non-existent config file, and still does not learn that the middleware alias
lives at `app/Http/Kernel.php:197`.

Excluded from that count as non-defects: `modules/OfflinePayments/**` and `modules/PaypalStandard/**`
(Composer-installed, gitignored, absent from a clean checkout by design); deliberate tutorial
placeholders (`modules/MyModule/…`, `modules/YourModule`, `App/Console/Commands/MyCommand.php`);
and extensionless symbol references such as `app/Jobs/Document/CreateDocument`, which do resolve
once `.php` is appended.

### 2. `openwiki/testing.md` is wrong in the two ways that matter most

This is the highest-cost page in the bundle, because `akaunting-test-coverage` sends every agent
to it first.

**It presents an incomplete picture as a complete one.** Lines 75–87 render the whole `tests/`
tree as four files — `Feature/FeatureTestCase.php`, `Feature/PaymentTestCase.php`,
`Unit/ExampleTest.php`, `Unit/UpdatesTest.php`. The repository actually has **36** `*Test.php`
files across 12 `tests/Feature/*` subdirectories. An agent trusting the page concludes there is no
`tests/Feature/Banking/`, and creates a new directory and base class instead of extending the seven
existing siblings. No path-existence check can ever catch this: every path the page names is real.
The falsehood is the omission.

**It documents APIs that do not exist.** These are code samples, not citations, so no structural
validation reaches them:

| `testing.md` | Reality |
|---|---|
| `use Illuminate\Testing\Benchmark\Benchmark;` (:566, :574) | Not a Laravel class |
| `$this->assertGreater(...)` (:158) | Not a PHPUnit assertion |
| `dumpSql()` (:594) | Does not exist |
| `ray($invoice->toArray())` (:607) | Not a dependency of this project |
| `CurrencyService::convert(...)` (:461) | No such class |

An agent copying `Benchmark::measure(...)` gets a fatal error at runtime.

It also states CI runs `php artisan test --coverage`; `.github/workflows/tests.yml:52` runs
`php artisan test --parallel`, and `phpunit.xml` has no `<coverage>` element at all.

### 3. `openwiki/systems/modules/overview.md` points at the wrong subsystem

The page declares `openwiki.source_paths: [modules, app/Traits/Modules.php]`, framing
`app/Traits/Modules.php` as the module-registration mechanism. It is not. Reading it: `checkToken()`,
`getModules()`, `getModuleReviews()`, `getModuleTestimonials()`, `getBannersOfModules()`, built on
`App\Traits\SiteApi` — it is the **Akaunting App Store HTTP API client**.

This is the most expensive failure mode in the bundle, because the cited path *exists*, has 44
graph nodes, and the graph will enthusiastically confirm the wrong answer. Source verification
does not catch it. Actual registration runs through the vendor package `akaunting/laravel-module`,
`composer.json`'s `installer-paths`, `config/module.php`, and the command overrides in
`overrides/akaunting/laravel-module/Commands/`.

### 4. `openwiki/workflows/invoice-workflow.md` invents a URL prefix

The page uses `/admin/` in eight places (`POST /admin/sales/invoices`, etc.). That prefix does not
exist. `app/Providers/Route.php:57-60` sets the prefix to `{company_id}/`. The page also maps
`GET /signed/invoices/{id}` to `Portal\Invoices@show`; `routes/signed.php:12` binds
`Portal\Invoices@signed`.

The controller, request class and job the page names are all correct, which is what makes this
dangerous — an agent verifying those three finds the page consistent and has no reason to doubt
the URLs, then writes a test against a route that 404s.

### 5. The graph cannot answer route or config questions

Every one of the 12 `routes/*.php` files is a single node at `loc=L1` with no symbols and no edges
to controllers. All 45 `config/*.php` files are one node each, with no keys. Route→controller
resolution and config-key lookup are structurally impossible.

This is a capability boundary, not a bug — but it is undocumented, so an agent spends a query
discovering it. Worse, querying `"routes/admin.php"` returns
`modules/OfflinePayments/Routes/admin.php`, not the root file.

`overrides/**` and the root `composer.json` / `package.json` are outside the five scope roots
entirely — zero nodes. The string `overrides` also appears **zero times** across all 74 OpenWiki
pages. So for a dependency question like "what is coupled to `laravel/framework` internals?",
*both* evidence layers are structurally incapable of answering, and only step 2 of the
`akaunting-dependency-upgrade` skill ("inspect `overrides/`") saves the agent. That is a
skill-routing save, not an evidence-layer one.

### 6. Query seeding is bag-of-words, and fails loudly

`graphify query` seeds by token-matching against node labels, not semantically. The probe
`"IsolatesParallelTestState testToken compiled views"` seeded on **`Reviews`** — matching the token
`views` — and returned `app/View/Components/Layouts/Modules/Reviews.php` and two Blade templates.
Six nodes, all irrelevant, presented with the same confidence as a correct result.

Phrasing a query as the natural-language question the skills suggest makes this worse, not better.
Symbol-name queries work; prose queries misfire silently.

Separately, truncation fires readily: `--budget 6000` still cut 165 of 368 nodes on P02 and 607 of
787 on P06. At the default `--budget 2000` a correct answer is routinely truncated away, which
reads to the agent as absence.

### 7. Stale line numbers attached to live symbols

The three parallel-isolation files are simply absent from the graph, which is honest — the agent
gets nothing and falls back to grep. But `tests/CreatesApplication.php` *was* modified, and the
graph kept the old node: it reports `createApplication() loc=L14` when the method is now at L17.
An agent jumping to L14 lands inside the docblock.

Absence is honest. A stale line number on a live symbol is not, and it is the one failure mode a
"does the cited file exist?" check will never find.

### 8. Documented-but-dead guidance

- `AGENTS.md` instructs the agent to treat `AMBIGUOUS` Graphify edges as requiring source
  inspection. **Zero edges carry that label.** The split is 86.9% `EXTRACTED` / 13.1% `INFERRED` /
  0% `AMBIGUOUS`. `Test-GraphifyGuidance.ps1` asserts the word appears in `AGENTS.md`, so the
  guidance is enforced but never exercised.
- `AGENTS.md` line 9 refers to "a brief's unknowns and review items". That vocabulary does not
  exist anywhere in the bundle; the nearest thing is `openwiki/log.md`'s "Outstanding Critic Items".
  The instruction is unactionable.
- `AGENTS.md` claims the graph scope excludes frontend and generated assets. Six non-PHP files are
  graphed anyway, because `.graphifyignore`'s `!modules/**` admits them:
  `offline-payments.min.js`, `offline-payments.js`, `webpack.mix.js`, `package.json`, and both
  module `composer.json` files. A minified bundle became a `rationale` node.
- All 586 communities are named `"Community N"` — the wrapper passes `--no-label`, so community
  structure carries no semantic signal for the agent.

### 9. The graphify skill conflicts with the repository workflow

`.claude/skills/graphify/SKILL.md` and `.agents/skills/graphify/SKILL.md` are byte-identical copies
of the **upstream generic** skill (40,775 bytes). It prescribes `uv tool install graphifyy`, LLM
semantic extraction, and community labeling — all of which contradict this repo's locked,
wrapper-only, `--no-label` workflow. The reconciliation exists only as prose in `AGENTS.md`. An
agent that loads the skill without also reading `AGENTS.md` follows the wrong procedure.

## Probe results

Twelve realistic tasks, each run through the exact evidence path its skill prescribes, then graded
against verified source.

**Recovered?** distinguishes a falsehood the skills' own step-3 source check kills loudly
(`self-limiting`) from one that survives verification because the cited path exists but means
something else (`latent`). Latent is the expensive kind.

| # | Task | Verdict | Recovered? | Attribution |
|---|---|---|---|---|
| P01 | Trace invoice create from request to DB write | MISLEADING | latent | openwiki |
| P02 | Why isn't my new model company-scoped? | PARTIAL | n/a | openwiki |
| P03 | Where is reconciliation input validated? | PARTIAL | self-limiting | openwiki |
| P04 | Write a feature test for a banking domain | MISLEADING | latent | openwiki |
| P05 | How are permissions enforced? | MISLEADING | self-limiting | openwiki |
| P06 | Which controller handles the invoice email route? | MISS | n/a | graph |
| P07 | How do I register a new module? | MISLEADING | latent | openwiki |
| P08 | What does a test writing to disk need under `--parallel`? | MISLEADING | self-limiting | graph |
| P09 | Benchmark totals and assert query count | MISLEADING | latent | openwiki |
| P10 | What is coupled to `laravel/framework` internals? | MISS | n/a | skill-routing |
| P11 | Where is a category's `type` validation rule? | MISLEADING | self-limiting | openwiki |
| P12 | Open `createApplication()` and add a step | MISLEADING | latent | graph |

Distribution: 7 MISLEADING (5 latent), 2 MISS, 2 PARTIAL, 0 clean HIT.

Two results are worth pulling out.

**P02 is the case for keeping both layers.** `workflows/multi-tenancy.md`'s Source Map lists six
rows, all of which resolve — but it omits `app/Traits/Tenants.php` and `app/Abstracts/Model.php`,
which are what actually install the global scope, and it never mentions that
`Tenants::isTenantable()` requires `company_id` to be in `$fillable` — the actual answer to "what
did I miss?". The graph supplied what the wiki omitted: the query returned
`bootTenants() [src=app/Traits/Tenants.php loc=L14]` and `Model [src=app/Abstracts/Model.php]` in
the first four nodes. Wiki incomplete, graph correct, evidence order worked.

**P08 was predicted MISS and graded MISLEADING.** The expectation was that the graph would return
nothing for the three post-build files. Instead the query seeded on `Reviews` and returned six
confidently-formatted nodes about an unrelated View Component. Silence would have been better.

## Remediation

Split by what actually fixes each class, because the three fixes are unrelated.

**Fix the source, let OpenWiki regenerate.** The dead citations, the `/admin/` prefix, the
four-file `tests/` tree, and the fabricated `Benchmark`/`ray()`/`dumpSql()` samples are all
generator output. Do not hand-edit `openwiki/` — `AGENTS.md` forbids it and the daily workflow
would overwrite it. The generator ran at `claude-haiku-4-5`; the fabricated-API cluster in
`testing.md` is characteristic of a small model asked to write example code rather than cite it.
Consider a stronger `OPENWIKI_MODEL_ID` and re-running `openwiki code --update`, then re-checking
`testing.md` and `permissions-workflow.md` specifically.

**Rebuild the graph.** `pwsh -File tools/graphify/Invoke-Graphify.ps1` clears the three absent
files and the stale `createApplication()` line number in one pass. Cheap — the graph builds with
zero token cost. Consider whether `.graphifyignore` should narrow `!modules/**` to `!modules/**/*.php`
to stop admitting minified JS.

**Fix the guidance files.** These are hand-maintained and independent of both rebuilds:
- Document the graph's capability boundary in `AGENTS.md`: routes and config are file-level only;
  grep `routes/` directly. `overrides/` and root manifests are out of scope.
- Note that `graphify query` seeds on symbol names, not prose, and that `--budget 6000` is a
  sensible floor.
- Either drop `AMBIGUOUS` from `AGENTS.md` and `Test-GraphifyGuidance.ps1`, or state that it is
  currently unexercised.
- Fix or drop the "unknowns and review items" sentence.
- Reconcile the upstream graphify `SKILL.md` with the repo's locked workflow.

**Already fixed by this audit.** `AGENTS.md` and `CLAUDE.md` had diverged — commit `645a9bef0`
added a "Parallel test isolation" section to `CLAUDE.md` only, and `Test-AgentHarness.ps1` had
been red ever since with nothing in CI to report it. `AGENTS.md` now carries the section, and
`tools/agents/Sync-ProjectSkills.ps1` generates `CLAUDE.md` from it, so the two cannot drift again.
Both `Test-AgentHarness.ps1` and `Test-GraphifyGuidance.ps1` are green, with `AGENTS.md` at 42
lines against its 120-line ceiling.

Note that `.github/workflows/openwiki-update.yml` lists both `AGENTS.md` and `CLAUDE.md` in its
`add-paths`, so an automated OpenWiki PR can still overwrite either file. Re-run
`Sync-ProjectSkills.ps1` after merging one.

**Still red:** `tools/graphify/Test-GraphifyOutput.ps1:149` throws unless
`modules/OfflinePayments/composer.json` and `modules/PaypalStandard/composer.json` exist. It never
reads them, and `modules/` is gitignored, so the script fails on any clean checkout that has not
run `composer install`. The precondition should be dropped or made conditional. Left unfixed here
because it is a change to a validation script rather than an audit finding, and was outside the
approved scope.

## Scope and limits of this audit

This was a one-time check. **No CI harness was built**, no new validation scripts were committed,
and no staleness policy was added. Analysis was done with throwaway scripts.

Not checked: the factual accuracy of prose in the 60 pages outside the ones the three skills name;
whether `manifest.json`'s 1,229-file list agrees with the graph; the `gods`/`surprises`/`questions`
content of `.graphify_analysis.json`; and whether the 54 pages lacking an `openwiki.source_paths`
block would benefit from one. Page-level staleness cannot currently be computed automatically,
because only 20 of 74 pages declare their sources.

If a permanent harness is ever wanted, the checks that would have caught the most here are, in
order: rooted-citation existence with a waiver list for gitignored and placeholder paths; graph
`built_at_commit` vs `HEAD` over the five scope roots; and a probe set like the one above run as a
retrieval scorer. The two failures those would *not* have caught — `testing.md`'s false-complete
file tree, and `systems/modules/overview.md` pointing at a real file that means something else —
are the two most expensive findings in this report, which is the argument against relying on
structural validation alone.
