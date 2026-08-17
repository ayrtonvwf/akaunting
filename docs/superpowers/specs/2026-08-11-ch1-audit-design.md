# Ch1 — The Audit: Design

**Date:** 2026-08-11

## Purpose

Produce `AUDIT.md`: the record of where this fork actually stands before anything is changed. It
carries the runtime and framework end-of-life positions, the gap between those and what CI tests, a
Laravel ceiling for every direct dependency with the reason behind it, a coverage map cut along two
axes, and a written verdict on whether Ch3 Half B is an upgrade or a plan for one.

Ch1 exists because the two chapters after it are undecidable without it. Ch2 cannot argue about what
to cover first without knowing where the net already reaches, and Ch3 Half B cannot be scheduled
without knowing what moves. The chapter changes no production code.

`DOCS-DRIFT-AUDIT.md` already covers the documentation half of the audit and is not revisited here.

## Goals

- Give every direct Composer dependency a recorded Laravel ceiling with a stated reason.
- Establish, from the resolver rather than from declarations alone, what actually blocks Laravel 11
  and 12.
- Produce a coverage map over `app/` on two axes: framework surface and product domain.
- Write the Ch3 Half B feasibility call, with its evidence, in a form that doubles as the skeleton of
  `UPGRADE.md` if the answer is negative.
- Leave the mechanical parts rerunnable, so Ch3 and Ch4 read the data rather than regenerate the
  research.

## Non-goals

- No production code changes. The only edit outside `tools/` and the audit outputs is adding PCOV to
  `Dockerfile.local`, which is dev tooling.
- No CI coverage lane, no coverage delta gate, no PHP 8.4 lane. Ch2 owns all three.
- No fixes for anything the audit finds. Findings are recorded, not acted on.
- No upstream issue. It follows Ch1 rather than being part of it.
- No coverage measurement of `modules/`. Out of scope and stated as a limitation.
- No pre-committed decision rule for the feasibility verdict. The call is written judgment over the
  assembled evidence.

## Architecture

Four artefacts, separated by who produced them, following the provenance tiering the northstar plan
already uses.

| Path | Produced by | Committed |
|---|---|---|
| `AUDIT.md` | Written by hand over the generated data | Yes, repository root |
| `audit-out/` | The two scripts and the resolver probes | Yes, sibling to `graphify-out/` and `openwiki/` |
| `tools/audit/` | The two scripts themselves | Yes, sibling to `tools/graphify/` and `tools/ci/` |
| `Dockerfile.local` | One added extension | Yes |

`audit-out/` holds `ceilings.json`, `clover.xml`, `coverage.json`, `probe-l11.txt` and
`probe-l12.txt`. The generated data is committed because Ch2, Ch3 and Ch4 are meant to read it rather
than reproduce it.

`tools/audit/` holds `ceilings.php` and `coverage-map.php`. Both are PHP, both run inside the Docker
local environment, and both take no arguments — one command, deterministic output, the same shape as
the graphify wrapper.

### The dependency ceiling pipeline

`tools/audit/ceilings.php` reads the direct dependencies from `composer.json`, skipping `php` and the
`ext-*` entries. As of 2026-08-11 that is 49 in `require` and 8 in `require-dev`. Transitive packages
are not enumerated; one appears in the table only when it is named as the reason a direct package is
stuck.

For each package the script fetches Packagist metadata and records:

- the currently installed version, from `composer.lock`;
- the latest stable release and its release date;
- the `laravel/framework` and `illuminate/*` constraints that release declares;
- the highest Laravel major those constraints satisfy;
- a classification.

The release date is recorded because it answers, at no extra cost, the plan's question about how
actively the vendor maintains its own twelve `akaunting/*` packages.

Every package lands in exactly one classification:

- `supports-12` — the latest release declares Laravel 12 or higher. Laravel 13 is out of scope, so
  anything at or above 12 classifies the same way.
- `framework-agnostic` — the release declares no `laravel/framework` or `illuminate/*` constraint at
  all. These are not blockers and must not read as unknowns.
- `ceiling-below` — the release declares a maximum below 12, recorded with that maximum.
- `abandoned` — Packagist's own abandoned flag is set.

There is no blank state and no default bucket. A package the script cannot classify stops the run.

### The resolver probes

Two probes run on a throwaway branch, which is discarded afterwards — only their captured output is
committed, and no lockfile change from the probes reaches the branch this chapter lands on:

```
composer update --dry-run -W laravel/framework:^11   →  audit-out/probe-l11.txt
composer update --dry-run -W laravel/framework:^12   →  audit-out/probe-l12.txt
```

The probes are the only thing in the chapter that answers what actually blocks, as opposed to what is
declared. They also supply the third reason the plan asks for: a transitive dependency holding a
direct one back is visible in probe output and nowhere in the table.

Every package a probe names must appear in `ceilings.json` as `ceiling-below` or `abandoned`. Where
the probe and the table disagree — a package declaring support that still fails to resolve, or the
reverse — the disagreement gets its own line in `AUDIT.md` and is not reconciled away.

The probes inform the verdict. They do not decide it.

### The coverage map pipeline

PCOV is added to `Dockerfile.local`, disabled by default and enabled per invocation. `phpunit.xml` is
not modified: coverage is requested on the command line, so the human-facing configuration keeps its
current shape and the audit leaves no residue in it.

The run is serial rather than `php artisan test --parallel`. Merging coverage across workers adds a
failure mode and buys nothing on a one-shot run, and Ch0 already argues that attributable output beats
fast output when something has to read it. The exact command used is recorded verbatim in the coverage
section of `AUDIT.md`, since a measurement nobody can reproduce is not evidence.

`phpunit.xml` scopes `<source>` to `./app`, so the two bundled modules are executed by the suite but
not measured. That is correct for this chapter, since `modules/` is a post-install path that is not
tracked in git, and it means the map is silent about the extension surface that Ch3 has to keep
working. It is recorded as a limitation, not fixed.

`tools/audit/coverage-map.php` reads `clover.xml` and assigns every file two labels.

**Surface** is the first path segment under `app/` — `Providers`, `Console`, `Jobs`, `Listeners`,
`Models`, `Observers`, and the rest — with one refinement: `Http/` is split so that `Http/Middleware`
and `Http/Controllers` are distinct surfaces, because middleware is upgrade-sensitive in a way
controllers are not.

**Domain** is the next path segment when it matches an explicit list written out in the script and
derived from the Ch0 product documentation, and `cross-cutting` otherwise. The list is reviewed by
hand once; guessing at it is how a domain axis quietly becomes a directory listing. The
`cross-cutting` file count appears in the table so that bucket cannot absorb the codebase unnoticed.

`coverage.json` carries a per-file record (path, surface, domain, total lines, covered lines) plus the
two aggregates. Each bucket reports its count of files with zero covered lines alongside its
percentage, because for choosing what Ch2 writes first, a count of untouched files is more actionable
than a ratio.

The script also recounts test files, test methods and assertion calls. The plan's baseline of 34 files,
213 methods and 179 assertions was measured on 2026-08-05, and Ch0's own parallel-isolation work has
since moved it to 41 files. `AUDIT.md` records both figures with their dates rather than replacing one
with the other.

### `AUDIT.md`

Written in reading order rather than production order, with each section carrying a one-line note on
how it was produced — hand-verified, generated, or judgment:

1. **Runtime and framework position.** Hand-written, one source URL per claim: `php: ^8.1` against a
   security window that closed in December 2025, `laravel/framework: ^10.0` against one that closed in
   February 2025, both dated.
2. **The CI gap.** Read from `.github/workflows/tests.yml`: a matrix topping out at 8.3, `coverage:
   none` on every lane, no 8.4 anywhere.
3. **The dependency gate.** The generated table, plus the probe-disagreement list.
4. **The coverage map.** The two axis tables with their untested-file counts, plus the suite counts.
5. **The verdict on Ch3 Half B.** Written judgment citing sections 3 and 4 rather than restating them.
6. **Known limits of this audit.** Modules unmeasured, declared-versus-actual gap, snapshot date.

Sections 3 and 4 present and do not argue. Section 5 is the only place a conclusion is drawn.

### The verdict

No pre-committed decision rule. The call is made from the assembled evidence and the reasoning is
written down.

It does commit to one thing regardless of which way it goes: for each blocker, what clearing it would
cost and in what order. If the answer is that Half B is not feasible, that section is already the
skeleton of Ch3's `UPGRADE.md` rather than a dead end.

## Error handling

The scripts fail hard rather than degrade. A partial artefact that looks complete is the failure mode
worth engineering against, because everything downstream is supposed to trust this data without
re-deriving it.

Any of the following stops the run and writes no output file:

- a Packagist request that does not return a successful response;
- a package the classifier cannot place in exactly one of the four classifications;
- a file in the coverage report that cannot be assigned exactly one surface and one domain;
- bucketed line totals that do not sum to the Clover total;
- a file named in the coverage report that is absent from `app/` on disk.

A file in `<source>` scope missing from the coverage output is not a hard failure: Clover legitimately
omits files with no executable statements, so those are recorded in `files_without_coverage_data`
rather than treated as an error.

## Verification

Layered, so no single mechanism is load-bearing.

- **Self-checks.** The five hard failures above are the scripts checking their own output.
- **Resolver cross-check.** The probes independently test the ceiling table, as described above.
- **Determinism.** `ceilings.php` run twice in one day produces byte-identical output apart from the
  `generated_at` timestamp. Checked once.
- **Hand spot-check.** Five packages are verified by hand against their release tags and named in
  `AUDIT.md` as having been spot-checked. If any of the five disagrees with the script, the script is
  wrong and is fixed before the table is trusted at all.
- **Coverage sanity.** The map's overall line coverage matches what PHPUnit reports for the same run.

## Testing

One test, for the path-to-surface-and-domain classifier in `coverage-map.php`. It is pure, cheap to
test, and the only place in the chapter where a wrong answer is invisible — a misfiled path just
shifts a percentage rather than failing anything.

Nothing else gets tests. These are one-shot analysis tools, not application code, and the hard-fail
self-checks cover the rest.

## Done means

- Every direct dependency carries a recorded Laravel ceiling with a stated reason.
- Both resolver probes have run and their output is committed, with any disagreement against the table
  written up.
- The coverage map exists on both axes, with untested-file counts per bucket.
- The Ch3 Half B call is written down with its evidence.
- `AUDIT.md`, `audit-out/` and `tools/audit/` are committed, and the PCOV addition to
  `Dockerfile.local` is the only change outside them.
