# Reading the Ch1 audit (PR #8)

A guide to [PR #8, "Ch1 — The audit"](https://github.com/ayrtonvwf/akaunting/pull/8): what it
measured, how it measured it, what it concluded, and which of its conclusions are load-bearing.

The PR itself adds no production code. It produces one written artefact, `AUDIT.md`, on top of
committed generated evidence in `audit-out/` and rerunnable scripts in `tools/audit/`. Everything
below is a reading of that artefact, not a re-derivation of it.

---

## 1. What the chapter was for

Ch1 exists because Ch2 (test coverage) and Ch3 (the Laravel upgrade) are undecidable without it. Ch2
cannot argue about what to test first without knowing where the test net already reaches; Ch3 cannot
be scheduled without knowing which packages actually move. So the chapter's job was to establish a
baseline and then write one judgment on top of it: **is the 10 → 11 → 12 upgrade an upgrade, or a plan
for one?**

The design (`docs/superpowers/specs/2026-08-11-ch1-audit-design.md`) deliberately refused a
pre-committed decision rule. The verdict is written judgment over assembled evidence, not the output
of a threshold.

### 1.1 Scope: Laravel, not PHP

The audit is asymmetric, deliberately. It evaluates the **framework** upgrade in depth and only
*positions* the **runtime** one.

What it says about PHP: §1 records `^8.1` as 7 months past end-of-life and notes the constraint is a
**floor, not a ceiling** — 8.4 already installs today, and what `^8.1` really buys is that 8.1-only
idioms stay legal in the codebase. §2 names the CI gap: the matrix tops out at 8.3, so 8.4 is the one
runtime never exercised. §5 step 9 prices PHP 8.2 as required — but only as a consequence of Laravel
11 demanding it.

What it does not do: no PHP ceiling per dependency (`ceilings.php` excludes `php` from its scope
entirely, so every direct dependency has a recorded *Laravel* ceiling and none has a *PHP* one), no
resolver probe against 8.4, no scan for 8.1 → 8.4 deprecations in application code, and no 8.4 CI
lane — an explicit design non-goal, handed to Ch2.

The reason is the chapter split in `PLAN.md`. **Ch3 Half A** is the PHP work — Rector-assisted,
constraint `^8.1` → `^8.2`, CI matrix to `8.2/8.3/8.4`, suite green on 8.4 — and **Half B** is the
Laravel work. Note the target is subtler than "upgrade to 8.4": Half A raises the *floor* to `^8.2`
and *tests* on 8.4 rather than bumping the constraint to it. Half A comes first because Laravel 11
requires 8.2. The plan's own framing is that *"Half A is a weekend. Half B is unschedulable until Ch1
reports, and that is the point of it."* Ch1 was scoped to the half that was undecidable without it.

**One gap worth flagging:** the absence of a per-dependency PHP ceiling is not disclosed in §6's
limits, unlike every other blind spot in the chapter. Given how carefully §6 discloses the rest, that
reads as an oversight rather than a decision — and it means nothing here establishes that the 57
direct dependencies admit 8.4.

## 2. Methodology

The audit separates its claims by **provenance**, and every section of `AUDIT.md` carries a one-line
note saying which kind it is. This is the single most important thing to understand about the
document, because it tells you how much weight each section can bear.

| Tier | Sections | Meaning |
|---|---|---|
| Hand-verified | 1 (runtime/framework), 2 (CI gap) | One primary source per claim, cited |
| Generated | 3 (dependencies), 4 (coverage) | Script output, committed under `audit-out/`, rerunnable |
| Judgment | 5 (the verdict) | Reasoning over sections 3 and 4 |
| Hand-written | 6 (limits) | What the audit deliberately does not establish |

Sections 3 and 4 present and do not argue. Section 5 is the only place a conclusion is drawn. That
separation is what lets a later chapter disagree with the verdict without having to redo the
measurement.

### 2.1 The dependency ceiling table — what packages *declare*

`tools/audit/ceilings.php` walks the 57 direct dependencies from `composer.json` (49 in `require`, 8
in `require-dev`, excluding `php` and `ext-*`), and for each one fetches Packagist metadata to record
the installed version, the latest stable release and its date, the declared `laravel/framework` and
`illuminate/*` constraints, and a derived **ceiling** — the highest Laravel major those constraints
admit.

Every package lands in exactly one of four classifications, with no default bucket and no blank
state: `supports-12`, `framework-agnostic`, `ceiling-below`, `abandoned`. A package the script cannot
place stops the run rather than being guessed at.

**Three vocabulary traps the audit flags in its own table**, because each one is easy to misread:

- `framework-agnostic` means the release declares no Laravel constraint at all. These are **not
  unknowns and not blockers** — they are packages the framework version cannot affect.
- `supports-12` means "ceiling at or above 12", **not** "the latest release runs on 12". The two
  `staudenmeir/*` packages classify `supports-12` with ceiling 13, yet their latest releases require
  `illuminate/database ^13.0` and will not install on 12 at all. On Laravel 12 they need a release
  that is neither the locked one nor the latest one.
- `abandoned` takes precedence over `ceiling-below`. `intervention/imagecache` has a ceiling of 10 —
  as low as anything in the table — but classifies `abandoned`, so it is absent from the
  `ceiling-below` count of 2.

The classifier also has one known blind spot, disclosed rather than patched: it reads `require` and
not `conflict`. `nunomaduro/collision` v7.12.0 declares `conflict: laravel/framework >=11.0.0`, a hard
resolver stop, yet reads as `framework-agnostic` in the table. It is the only such case among the 57 —
and it is exactly the class of blocker the resolver probes exist to catch.

### 2.2 The resolver probes — what Composer *does*

Declarations are not behaviour, so the audit runs Composer against the real lockfile on a throwaway
branch (discarded afterwards; only the transcripts are committed):

```bash
composer update --dry-run --no-scripts --no-audit --no-interaction -W laravel/framework
```

against an edited root constraint of `^11` and then `^12`. The Laravel 12 transcript additionally
carries a non-mutating `composer why-not laravel/framework 12` cross-check.

The probes are also the only instrument in the chapter that can see the third kind of blocker: a
**transitive** dependency holding a direct one back. Those are invisible to `ceilings.json` by
construction, since it only enumerates direct packages.

Where the table and the probes disagree, the audit's rule is that **both readings are kept and the
disagreement gets its own line**. It is not reconciled away. Section 3's declared-versus-actual list
is that reconciliation refused.

### 2.3 The coverage map — two axes over one run

`phpunit.xml` was not modified. PCOV was added to `Dockerfile.local` (installed but disabled by
default) and enabled per invocation, so the human-facing configuration keeps its shape and the audit
leaves no residue in it. The run is **serial**, not `php artisan test --parallel` — merging coverage
across workers adds a failure mode and buys nothing on a one-shot run. The exact command is recorded
verbatim in `AUDIT.md` §4, on the principle that a measurement nobody can reproduce is not evidence.

`tools/audit/coverage-map.php` then labels every file on two axes:

- **Surface** — the leading path segment under `app/`, with `Http/` split so `Http/Middleware` and
  `Http/Controllers` are separate buckets, because middleware is upgrade-sensitive in a way
  controllers are not. 31 buckets.
- **Domain** — the product area from `docs/product/`, `cross-cutting` otherwise. 9 buckets. The
  `cross-cutting` file count is reported precisely so that bucket cannot quietly absorb the codebase;
  it holds 502 of 1,062 files, which is a lot, and the audit shows you that rather than hiding it.

Each bucket reports **untested files** — files with executable statements but none covered — alongside
its percentage. That column is the design's deliberate concession to usefulness: a percentage is a
headline, a count of untouched files is a worklist for Ch2. Files with no executable statements at all
(an interface with no method bodies) are excluded, since there is nothing there to cover.

### 2.4 Verification — layered, so nothing is load-bearing alone

- **Hard-fail self-checks.** Five conditions stop a script and write no output: a failed Packagist
  request, an unclassifiable package, a file that cannot be assigned exactly one surface and domain,
  bucketed totals that do not sum to the Clover total, and a file in the report absent from disk. The
  failure mode engineered against is a partial artefact that looks complete.
- **The reconciliation guard was proved to fire**, by deliberately corrupting a copy of the report —
  the guard was tested, not merely written.
- **Determinism.** `ceilings.php` reruns byte-identical apart from its `generated_at` timestamp.
- **Hand spot-checks.** Five packages verified against their release tags, two re-verified
  independently in review. All five agreed with the script, so no correction was made.
- **One unit test**, `tests/Unit/Audit/PathClassifierTest.php` (9 tests), covering the path classifier
  — the one place in the chapter where a wrong answer is invisible, since a misfiled path just shifts
  a percentage rather than failing anything.
- Suite green at 242 tests.

---

## 3. The findings

### 3.1 Position

| | declared | supported until | status |
|---|---|---|---|
| PHP | `^8.1` | 31 Dec 2025 | end-of-life for 7 months |
| Laravel | `^10.0` | 4 Feb 2025 (security) | unsupported for 18 months |

The CI matrix is `['8.1', '8.2', '8.3']` — so the runtime the project *should* run on (8.4) is the one
runtime CI never exercises, and the bottom of the matrix has been end-of-life since December 2025.
Every lane sets `coverage: none`, which is why Ch1 needed a local instrumented run at all.

### 3.2 The numbers

| | |
|---|---|
| Line coverage over `app/` | **44.81%** — 12,070 of 26,935 statements, 1,062 files |
| Suite | 37 files / 232 methods / 494 assertion calls |
| Direct dependencies | 57 — `supports-12` 30, `framework-agnostic` 23, `abandoned` 2, `ceiling-below` 2 |
| Laravel 11 / 12 resolution | neither resolves |

### 3.3 The finding that carries the verdict

**Both resolver probes fail, and the obvious reading of that failure is wrong.**

The probes name seven locked direct packages as blocking. The naive conclusion — "seven packages
cannot move to Laravel 11" — does not survive reading the transcripts. Two things are going on:

1. **The `-W` flag never had permission to move them.** `-W` (`--with-all-dependencies`) widens an
   update to the named package's *dependencies*. The seven packages are `laravel/framework`'s
   *dependents*. Nothing short of naming them, or updating everything, moves them.
2. **Composer's own two phrasings partition the seven exactly.** Four —
   `akaunting/laravel-firewall`, `-language`, `-setting`, `-version` — read only *"an update of this
   package was not requested"*: their locked constraints already admit 11 and 12, and the lock, not
   the package, is what needs to move. Three — `akaunting/laravel-mutable-observer`, `-sortable`,
   `santigarcor/laratrust` — read *"conflicts with your root composer.json require"* and genuinely cap
   below 11 at their locked version. All three have a published later release that does not.

Not one of the eight `Problem` blocks is a package with **no** release supporting the target. So the
probes measure **lock state**, not capability. They prove this fork cannot *drift* onto 12. They do
not show it cannot be *moved* there.

### 3.4 The real blockers

The genuine ceilings come from the table, not the probes, and there are four. All MIT, all
single-purpose, none carrying an architectural commitment:

| package | why | path out |
|---|---|---|
| `akaunting/laravel-menu` | first-party, ceiling 10, nothing released since 2023-10-25; compounded by `laravelcollective/html`, itself abandoned | the hardest — fork or replace, and it clears two dead things at once |
| `genealabs/laravel-model-caching` | marked abandoned | **not** a package swap — Packagist still publishes 13.1.7 under the same name; likely a version bump, with the risk in verification not resolution |
| `intervention/imagecache` | abandoned, ceiling 10, no replacement named | pins `intervention/image` to 2.x; clearing it means taking the `image` 2 → 4 rewrite too |
| `lorisleiva/laravel-search-string` | ceiling 10, dormant rather than abandoned | low — plausibly a widened constraint and a test pass |

### 3.5 Where the actual risk lives

Coverage of 44.81% is not itself disqualifying. **The distribution is the problem.** Coverage is
thinnest exactly on the surfaces a major upgrade disturbs:

- `Imports` 0.42% (39 of 40 files untested), `Classifiers` 0.00%, `BulkActions` 3.91%, `Exceptions`
  5.71%
- `Http/Livewire` 18.53%, `Http/Controllers` 27.38% (58 of 88 files untested), `Listeners` 28.57%,
  `Console` 33.77%
- On the domain axis, `Purchases` 25.06% and `Sales` 27.35% — the product's transactional core

The net will not catch a framework regression where a framework regression is most likely. The audit
classes that as a **Ch2 precondition, not a Ch3 blocker**, which is why its step ordering puts test
coverage *before* the 10 → 11 move.

---

## 4. The verdict

**Feasible, with named costs.** The target holds at Laravel 12, per the plan's own non-goal, and the
cost of stopping there is stated rather than argued away.

The verdict rests on **no blocker being unclearable**, not on the blocker list being exhaustive — a
distinction §6 makes explicitly, and one worth holding onto, because it is what makes the verdict
survive the discovery of further blockers later.

`AUDIT.md` §5 orders ten steps, usable directly as Ch3's `UPGRADE.md` skeleton:

1. Test coverage on upgrade-sensitive surfaces — Ch2's entire deliverable; gates verification of
   everything after it
2. The dev-tooling floor — `collision` v8, dragging PHPUnit 10 → 11+. Must be first among the package
   work or the suite cannot run on the new framework
3. `akaunting/laravel-menu` — start earliest, since the fork option needs an owner decided first
4. `genealabs/laravel-model-caching` — low dependency cost, medium verification cost
5. `intervention/imagecache` (+ the `image` migration)
6. `lorisleiva/laravel-search-string`
7. The lock-state bumps — low per package, except `laratrust` 7 → 8 on the authorisation layer, where
   `Auth` sits at 45.49% with 27 of 55 files untested
8. The two `staudenmeir/*` packages — must be pinned explicitly, since 12 sits between locked and
   latest
9. `laravel/framework` 10 → 11
10. `laravel/framework` 11 → 12

Steps 2–8 can be interleaved. Step 1 gates verification of everything. Steps 9 and 10 are strictly
sequential and strictly last.

### 4.1 The cost of stopping at 12

Stated plainly so nobody later mistakes it for an oversight. Laravel 12's bug-fix window closed
13 August 2026; security support ends 24 February 2027; upstream is already on 13.25.0. **Ch3 will
land this fork on a release already leaving active support, with most of the clock spent.** In the
audit's own words, Half B moves the fork from 18 months past end-of-life to a few months short of it.
A large improvement, and not a durable position — it buys a supported-enough platform to do the PHP
and code work on, not a place to stay.

The audit put the case for retargeting to 13 and the human partner ruled against it: a two-major
upgrade is the exercise, a third is scope creep. The 13 analysis survives as forward-looking
intelligence rather than a recommendation — 27 of the 30 `supports-12` packages already carry a
ceiling of 13, and the two that do not are first-party and last released before 13 shipped.

---

## 5. Corrections the audit makes to `PLAN.md`

These matter more than they look, because `specs/northstar/PLAN.md` is what a future chapter reads
first.

- **The Laravel 11 skeleton migration is optional, not required.** The plan states Ch3 must collapse
  `app/Console/Kernel.php` and `app/Http/Kernel.php` into `bootstrap/app.php`. Laravel's 11 upgrade
  guide explicitly *recommends against* migrating an existing application's structure, and heads the
  whole guide *Estimated Upgrade Time: 15 Minutes*. `AUDIT.md` carries the correction, and the plan
  was initially left as-is by the author's decision. **`PLAN.md` has since been corrected** in all
  three places that carried the error — the extension-surface paragraph, the Ch3 Rector section, and
  the chapter's *Exercises* line — so it can now be read on its own. Note that `AUDIT.md` §5 step 9
  still describes the plan as carrying the error, which was true when the audit was written.
- **Removing that false cost exposed the real one.** With the skeleton migration priced out, what
  remains on the 10 → 11 High Impact list is: PHP 8.2 required, 6 `->change()` calls that must now
  restate every modifier (silent and data-destructive if missed), **38 float/double migration
  columns** — money columns on a double-entry accounting application — SQLite 3.26+, and Sanctum
  3 → 4, which is a rename *and* a retarget of overridden middleware and so does not belong in the
  routine-bump bucket. No amount of `app/` coverage guards a migration column.
- **There are 13 first-party `akaunting/*` packages, not twelve.**
- **The suite baseline moved.** The plan's 2026-08-05 figures (34 / 213 / 179) were correct when
  measured and are stale now. Both rows are kept with their dates and the counting rule stated;
  anything downstream should use the 2026-08-12 row.

---

## 6. What the audit does not establish

Reading §6 is not optional — several of its limits bound how far the rest can be pushed.

- **`modules/` is unmeasured.** `phpunit.xml` scopes `<source>` to `./app`, so the two bundled modules
  execute but contribute no coverage data. The map is silent about the extension surface, which is
  precisely the surface Ch3 must keep working. Both modules classify `framework-agnostic`, and that
  says nothing about the Laravel service providers they register.
- **The coverage figure was cross-checked only against its own source.** The plan called for a second
  independently instrumented run; what happened was a check that `coverage.json` agrees with the
  `clover.xml` it came from. A stale or mis-scoped Clover file, or a PCOV misconfiguration, passes that
  check unnoticed. 44.81% is one measurement reconciled with itself.
- **Assertion counts are non-deterministic** — four runs of the same 242 tests reported 673/674/675/676,
  all green, not root-caused. Recorded because treating assertion count as a Ch2 metric would be a
  temptation, and it moves on its own.
- **The classifier reads `require`, not `conflict`** — `collision` is the one package this misses
  today; any future conflict-declaring blocker would be invisible the same way.
- **Declared support is not proven support, and nothing here narrows that gap.** Neither probe
  resolved, so no install was produced and **no line of this application's code has run on 11 or 12**.
  Proven support starts when something installs and the suite runs against it.
- **The blocker set may be incomplete.** This is the symmetric caveat to §5's central argument.
  Because neither probe resolved, Composer stopped at the first unsatisfiable set and never explored
  past it — so `why-not` output is **one failure frontier, not an enumeration of blockers**. Clearing
  the named packages is very likely to reveal more behind them. The step list is a starting order, not
  a complete inventory.

---

## 7. Recommended next steps

Ordered. Items marked *(reading)* are additions from this document rather than recommendations the
audit makes itself.

### 7.1 Immediate — before any code

- ~~**Fix `PLAN.md`.**~~ **Done.** The audit found the plan wrongly treats the Laravel 11 skeleton
  migration as required, wrote the correction into `AUDIT.md`, and initially left the plan
  uncorrected. `PLAN.md` now carries the correction in all three affected places, and the Ch3 section
  states what the High Impact work actually is — the 38 float/double columns, the 6 `->change()`
  calls, and the Sanctum middleware retarget — in place of the skeleton collapse.
- **Decide the `akaunting/laravel-menu` disposition.** §5 step 3 says start earliest — not because the
  work is slow but because the fork option *needs a home and a maintenance owner decided before it is
  used*. A human decision with lead time, parallelisable with everything else.
- **Decide whether the model-caching layer is wanted at all.** §5 step 4 notes removing it is a
  legitimate and possibly cheaper answer than porting it.

### 7.2 Ch2 — coverage, which gates everything

Step 1, and the audit is unambiguous that it comes first: *"Doing Half B without it is possible; doing
it without it and knowing whether it worked is not."*

Target the intersection of thin coverage and upgrade sensitivity, in roughly this order: `Imports`
(0.42%, 39 of 40 files untested), `Http/Controllers` (58 of 88 untested), `Listeners`,
`Http/Livewire`, `Console`, `BulkActions`, `Exceptions` — plus the `Purchases` and `Sales` domains.
§4's untested-file column is the worklist.

Ch2 also owns three things Ch1 explicitly deferred to it: a CI coverage lane, a coverage delta gate,
and the PHP 8.4 allowed-failure lane.

*(reading)* **The 38 float/double migration columns are the highest-consequence item in the audit and
`app/` coverage does not guard them at all.** Ch2 should decide what does — schema assertions, or a
migration-output diff — because that risk is invisible to the metric Ch2 is otherwise optimising.
Same for the 6 `->change()` calls, whose failure mode is silent and data-destructive.

### 7.3 Ch3 Half A — the PHP floor

Constraint `^8.1` → `^8.2`, CI matrix to `8.2/8.3/8.4`, suite green on 8.4. Must precede Half B, since
Laravel 11 requires 8.2.

*(reading)* This is the half Ch1 never audited (see §1.1), so the plan's "a weekend" is an estimate,
not a measured finding.

### 7.4 Ch3 Half B — the ten steps

Step 2 (`collision` v8, dragging PHPUnit 10 → 11+) must lead the package work, or the suite cannot run
on the new framework and every later step is unverifiable. Steps 3–8 are the four real blockers plus
the lock-state bumps and the two `staudenmeir/*` pins; interleavable. Steps 9 and 10 are strictly
sequential and last, with 10 → 11 landing alone on its own branch.

Two bumps in step 7 that are not free: `laratrust` 7 → 8 is a major on the authorisation layer, where
`Auth` sits at 45.49% with 27 of 55 files untested — the bump most likely to break something quietly.
Sanctum 3 → 4 is a rename *and* a retarget of overridden middleware, so it lands with the framework
rather than ahead of it.

Expect the list to grow. §6 is explicit that a failed probe yields one failure frontier, not an
enumeration.

### 7.5 Schedule the 12 → 13 chapter now

The audit's own recommendation, and time-sensitive: *"the sooner it is scheduled the less this
costs."* Laravel 12's bug-fix window closed 13 August 2026 and security support ends 24 February 2027,
so Ch3 has roughly six months to land before the destination itself leaves support.

The move is small at the dependency layer — 27 of the 30 `supports-12` packages already carry a
ceiling of 13 — and turns on two first-party packages, `akaunting/laravel-language` and
`akaunting/laravel-mutable-observer`, both last released before 13 shipped. Whoever picks it up should
start by checking whether the vendor has released for 13 since.

### 7.6 Standing guidance

- **Ch3** should read §5 as the `UPGRADE.md` skeleton and expect to extend it, and should rerun
  `tools/audit/` before starting — every figure carries a `generated_at` timestamp, and the diff is
  the news.
- *(reading)* **Waiting on `laravel-menu` and re-auditing are not the same option.** §5's "On waiting"
  shows waiting buys nothing: the vendor releases actively for everything except the one package that
  blocks. But rerunning `ceilings.php` is nearly free, so re-measuring before Ch3 starts is worth
  doing regardless of the wait decision.
- **`PLAN.md` still carries two other stale figures** that Ch1 corrected and this pass did not touch,
  since both are narrower than the skeleton error and neither changes a schedule: it says twelve
  first-party `akaunting/*` packages where there are **13**, and its suite baseline (34 / 213 / 179,
  measured 2026-08-05) has moved to 37 / 232 / 494. Worth a follow-up sweep rather than a separate
  chapter.
