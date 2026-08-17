# Making an aging Laravel monolith safe to change

A public, chaptered exercise on a real, actively used Laravel application that has drifted several
years behind its runtime and framework. Build the test net first, then use it to attempt a
two-major-version upgrade and either land it or establish exactly what stands in the way, then
automate the dependency stream so it does not drift again, and put a report on top of that automation
so the stream stays readable.

One thesis holds the chapters together: **a codebase is only as changeable as its ability to tell
you what you broke.** Everything here serves that. Coverage is the instrument, the upgrade is the
first hard change measured against it, and the dependency work closes the loop by turning every
incoming change into a demand for the next test. The net stops being something you build once and
becomes something the work itself keeps extending.

Every chapter is finished and published on its own. The fork is the artefact rather than a
release: the point is the method and what it costs, not a shipped product.

## Why I'm doing this

**1. Laravel internals.** I want time inside the parts of the framework most people never open:
service providers, the console kernel, the queue layer. A major-version upgrade forces all three,
because they are the parts that actually break, and reading them under pressure teaches more than
reading them at leisure.

**2. Building a test net from near zero, on code I did not write.** I think coverage is far more
useful as a gate on the delta than as a percentage target, and I want to test that view somewhere it
is under real strain. Starting at 34 test files across 1062 application files and deciding what to
cover first, when you cannot cover everything and you wrote none of it, is a different problem from
maintaining a net that already exists.

**3. Whether a bump can be usefully assessed before it is merged.** I have built a version of this
before: a workflow that takes a dependency bump, pulls the changelog between the two versions, reads
how the package is actually used in the codebase, and produces a written assessment of how risky the
upgrade is, what it could break, and how to test it. This is not a port of that; nothing is being
carried over but the idea. The open question is whether it survives being rebuilt small, in a
different package ecosystem and on a different foundation: that one was built on Mastra, this one on
the Vercel AI SDK, which is its own reason to do it.

**4. Where AI-assisted tooling actually helps.** I want to know what I can delegate to coding agents
during a framework upgrade, and more usefully, what I cannot.

## Why this codebase

Akaunting is open-core accounting software with a core team committing daily. It is not abandoned.
It is maintained but has drifted, which is the common and more interesting case.

This document is the fork's own plan: written to be read by anyone who finds the repository, and used
as the working sequence. Measured against `master` on 2026-08-05, with dependency ceilings verified
2026-08-06:

| | state |
|---|---|
| Popularity | 10027 stars, 2957 forks, 8 open issues |
| PHP constraint | `^8.1` (security support ended Dec 2025) |
| Laravel | `^10.0` (security support ended Feb 2025) |
| CI | one workflow, matrix `['8.1','8.2','8.3']` |
| Dependency automation | none (no Dependabot, no Renovate) |
| Service providers | 12, including its own `Queue`, `Binding` and `Macro` providers |
| Application files | 1062 PHP files under `app/` |
| Tests | 34 files, 213 test methods, 179 assertion calls |
| PHPUnit | `^10.5.63` |
| First-party Composer packages | 12 `akaunting/*` packages plus a module system |

The CI matrix tops out one minor version below where the project would need to go, and there are 34
test files standing between 1062 application files and a two-major-version framework upgrade. That
combination is the whole exercise in one line.

**Alternatives considered.** I profiled ten Laravel applications: Snipe-IT, InvoiceNinja, Koel,
BookStack, Pelican, Pixelfed, FreeScout, Monica, Cachet and Akaunting. The first five are current and
well tested, so there is nothing to rescue. Monica has not been committed to since August 2025 and
Cachet is mid-rewrite with a single test file, so neither is a live codebase to work against.
Pixelfed has by
far the most interesting queue surface, 119 job classes driving ActivityPub federation, but it is
already on Laravel 12 and PHP 8.4, so there is no runtime story. FreeScout is the extreme case,
pinned to Laravel `v5.5.40` on PHP `>=7.1`, but seven major versions is a rewrite rather than an
upgrade. Akaunting sits in the band where the work is real and finishable.

## The fork and its licence

All of this lives in one fork. Akaunting is licensed under **BSL 1.1**, not an OSI open-source
licence, with GPLv3 as the change licence after four years. The Additional Use Grant permits
production use up to two users, one company, or one thousand invoices, forbids rebranding, and
forbids offering it as an accounting service. Modifying and republishing source is permitted.
`LICENSE.txt` and all Akaunting branding stay untouched. Reading the licence before forking is part
of the exercise.

## Chapters

### Ch0 - The harness

*A weekend for the first version. After that it grows with every chapter rather than being finished.*

Before working through a thousand files I did not write, build the thing that makes them navigable.
Four artefacts, separated along two axes that both matter. **How each was produced** sets how far it
can be trusted. **What each is for** matters just as much, because they answer different questions
and none of them substitutes for another: a graph cannot tell you what an invoice is, and product
documentation cannot tell you what calls what. An agent handed all four cannot see either distinction
unless it is told.

Two of them come from existing third-party tools rather than from anything built here, which is what
makes a weekend plausible. **graphify** is a CLI that parses a repository with tree-sitter into a
queryable code graph, deterministically and with no model involved in the code path. **openwiki** is a
CLI that writes and maintains a documentation wiki for a codebase using an agent, emitting the **Open
Knowledge Format (OKF)**, a structured markdown convention meant to be read by agents rather than
rendered for people. Neither is mine and neither gets built here; the work is configuring them,
scoping them, and deciding how far to trust each.

| Layer | Produced by | Answers | How far to trust it |
|---|---|---|---|
| Product documentation | Synthesised once from published material, not copied from it | What the product does, what its words mean, where one domain ends and the next begins, and what it exposes to people building against it | Low stakes, because it is never load-bearing for a code change |
| A code graph (`graphify`) | Tree-sitter AST extraction, no model in the loop | What references what, and where a symbol is used | Citable as fact. Edges it marks as inferred rather than extracted are weaker, and it says which is which |
| A generated wiki (`openwiki`, OKF) | Model synthesis over current source, regenerated daily | How a given subsystem actually works | The documentation layer, because there is no other. Cannot go stale, can be wrong about what it read. Structural claims get checked against the graph |
| `AGENTS.md` and a few skills | Me, verified | How to work in this repository: conventions, commands, what is out of scope | Authoritative |

**The product documentation comes first, and it is the only one-shot artefact here.** It covers two
things: what the product does, and the extension surface it exposes to people building against it.
Both are synthesised from the vendor's live help centre, which runs to twenty categories and includes
a maintained developer section. Not from the code, and not from the abandoned documentation
repository, which is superseded and whose failure mode is catalogued in `DOCS-DRIFT-AUDIT.md`.

**Synthesised, not mirrored, and the distinction is deliberate.** The obvious move is to copy the
help centre into the fork as markdown and be done. That documentation carries no licence, and
republishing it verbatim inside a fork of the same vendor's commercially licensed product is not a
risk worth taking for a convenience. Writing it from scratch reaches the same place: current, local,
committed, never fetched again. It also produces something better shaped, because a help centre is
organised for a navigation sidebar and this can be organised for whatever actually gets read.

**The domain half cannot go stale, and that is structural rather than optimistic:** the non-goals
rule out touching functionality. Invoices, bills, reconciliation and the chart of accounts will mean
exactly what they mean today when Ch3 finishes. A framework upgrade does not move the domain.

**The extension-surface half can, and that is worth saying out loud.** Module registration, service
providers and `module.json` are code-adjacent, and they rest on framework bootstrapping that a major
upgrade disturbs: Sanctum 4 retargets middleware this application overrides, and the bundled modules
register providers against whatever the framework major expects. (An earlier version of this
paragraph said Ch3 collapses `app/Console/Kernel.php` and `app/Http/Kernel.php` into
`bootstrap/app.php`. Ch1 corrected that — the migration is optional and Ch3 does not plan it. See
`AUDIT.md` §5 step 9.) That is still exactly the surface that moves. So it gets one revisit at the end of Ch3, which
makes it the first real test of whether tiering by provenance actually helps: the half that could not
drift will not have, and the half that could will show where.

**It carries the least risk of anything in the table**, because it is never load-bearing for a code
change. Nobody upgrades Laravel on the strength of what an invoice is. It is orientation, not
instruction, which is why one careful pass is enough where the source documentation needs a daily
refresh and a verification story.

**What makes it worth doing before anything else is that it names the directories.** The published
material is organised as banking, sales, purchases, settings, reports and items, and
`resources/views/` is organised as banking, sales, purchases, settings, reports and widgets. Almost
one to one. Reading code cheaply tells you how something works and expensively tells you what it is
for, and this supplies the second half directly.

**It also draws the domain boundaries, which the code does not.** Published material is organised by
what the business does, so it states plainly where invoicing ends and banking begins, what separates
a bill from an invoice, and which concepts are shared across everything rather than owned by one
area. In a monolith those lines are blurred by shared models, cross-cutting providers and a decade of
convenience, and recovering them from the source is expensive guesswork. Having them stated up front
pays off immediately in Ch2, where deciding what to cover first is much easier once you know which
areas are genuinely separate and which only look it. The source wiki generated afterwards is meaningfully
better for having it, because describing `app/Models/Common/Item.php` is a different exercise once
you know what an Item is to a user.

Two disciplines while writing it. **Cite the source URL per claim**, which costs nothing at write
time and is the only thing that makes a wrong claim traceable later. And **correct the known drift
inline rather than reproducing it**: the extension-surface material is the one published thing that
touches code, and the live version is fresher without being right. Its `module.json` field list omits
`extra-modules` and `routes`, both of which the shipped Offline Payments module carries, and it still
links to the pre-rename `akaunting/module` wiki. Those are checked against the code as they are
written down.

**Everything downstream reads from the repository, never from the web.** Once this exists, no part of
the work fetches a page mid-task. That is partly determinism and partly cost, but mostly it is that a
fetched page arrives unverified into the middle of a task, which is precisely how the stale
documentation would have done its damage in the first place.

The skills cover the operations that recur: running the test suite and reading its output cheaply,
running Rector once it arrives in Ch3, navigating the module system.

**What already exists, because it changes what is worth generating.** The repository ships a README
and a security policy and nothing else: no `docs/` directory, no wiki, and a contributing section
whose entire guidance on conventions is to imitate the surrounding code. A separate documentation
repository carries a nine-file developer manual covering the extension surface: modules, model hooks,
permissions, settings, menus, output overriding, and the API.

That manual has been audited against the current code, file by file, in `DOCS-DRIFT-AUDIT.md`. The
short version: it is five to six years stale rather than three, roughly a third is still accurate, a
third describes a real mechanism with at least one detail that no longer resolves, and a third
describes a stack that has been replaced outright. The obsolete third includes the API document,
which is larger than the other eight combined.

**That audit is itself the first entry in the verified tier**, and it settles what to do with the
manual: nothing further. The audit extracted the three facts worth keeping, which go straight into
`AGENTS.md`, and left one open question flagged as open. Everything else in those nine files is
either already true elsewhere or wrong. The manual is superseded rather than ignored; ignoring it
costs nothing only because the extraction has been done.

**Which promotes the generated wiki from optional to the documentation layer**, because after that
audit there is no other. Generated from current source and regenerated daily, scoped to `app/`,
`modules/`, `config/` and `routes/`, emitted as an OKF bundle.

One wrinkle that follows from how modules work here. `modules/` is a **post-install path**: it is not
tracked in git, and it only exists once Composer has mapped the module packages into place. So the
generation job runs `composer install` first, or it documents an empty directory. It also means
module code changes arrive as a `composer.lock` bump rather than a source diff, which is what the
daily gate sees, so lockfile changes have to count as a reason to regenerate.

The promotion is defensible because it changes the failure mode rather than inheriting it. The manual
failed by **drifting**: it was accurate once and the code moved out from under it. A wiki regenerated
from current source structurally cannot drift. What it can do is be **wrong about what it read**,
which is a different problem needing a different answer.

Regeneration handles staleness and is already wired. The graph handles part of the rest, and the
split between them is the useful thing to be precise about, because the two layers do not overlap
evenly:

- **Where both reach** (imports, calls, inheritance, and the declarative `$bindings` array, which in this
  codebase is a static property rather than closures) the graph is a check on the wiki. A structural claim
  the graph contradicts is a correction-log entry.
- **Where only the wiki reaches** the graph cannot check anything, and this is a narrower and more
  specific region than "runtime wiring" suggests. It is essentially three things: the 25 macros in
  `app/Providers/Macro.php`, which define methods at runtime that no parser can link to their call
  sites; facade accessors; and module discovery, which happens through `module.json` files and
  Composer path mapping rather than through anything in the source tree.

That second region is where the wiki earns its promotion and also where nothing mechanical can check
it. Reading the code, in Ch1 and whenever an agent gets it wrong, is what reaches there. That is a
real limit and a small one.

Keeping it current should be cheap enough to run **daily** on a schedule, and the mechanism is why,
though this is a reading of the tool's source rather than a bill I have paid yet. Its update mode gates on
git before spending anything: it records the commit it last documented, and if `HEAD` has not moved or
every changed path is ignored, it exits without a model call. Quiet days cost nothing at all. When it
does run, it is guided by the diff since that commit rather than starting cold, so cost tracks the
size of the change. Two configuration details make or break this: the checkout needs full history,
because a shallow clone hides the last-documented commit and the update then runs against an empty
diff, and the ignore file needs to cover the frontend, translations and vendor so churn there never
triggers a run.

Ch3 is the one place where that economy breaks down, because a two-major-version upgrade lands across
the whole codebase over many commits and delta-awareness buys nothing when the delta is everything.
Whether to pause the schedule for that chapter is a decision to take once the daily runs have shown
what one actually costs, which is also when the expectation above stops being an expectation.

**Agent-readable tool output is part of the harness, not a nicety.** Every tool here defaults to
output shaped for a human staring at a terminal, and an agent pays tokens for all of it. `phpunit.xml`
sets `colors="true"`, so every run carries ANSI escape sequences that mean nothing to a model.
Collision is installed, and its entire job is pretty failure rendering with source excerpts.
CI runs `php artisan test --parallel`, so failures interleave across workers and become harder to
attribute. None of that is wrong for people; all of it is waste for an agent.

So the tooling gets two modes. Human mode stays as it is. Agent mode emits no colour, no progress
chatter, failures only, each one as file, line, assertion and diff, and nothing else. The project is
on PHPUnit `^10.5`, where printers were removed in favour of an event system, so this is an
**Extension subscribing to those events**. Worth knowing that Ch3 will very likely carry PHPUnit to 11
or 12, whose event API has moved, so this artefact has a rework cost that belongs in Ch3's budget
rather than being discovered there. Static analysis and Rector both take `--output-format=json` once
they exist. Serial
execution is often the better trade for an agent loop even though it is slower, because attributable
output beats fast output when something has to read it and act.

Three things make this a chapter rather than setup.

**It is the other half of the thesis.** Everything else here makes the codebase safe to change. This
makes it navigable to change, and I am the developer carrying the friction: no institutional
knowledge, no author to ask, and a module system somebody else designed.

**The harness is versioned alongside the work, and the diff is the artifact.** The first version is
written before Ch1's audit and is mostly guesses. Every chapter afterwards corrects something. What
`AGENTS.md` knows at hour one versus hour forty is a more honest record of what it takes to learn an
unfamiliar codebase than any retrospective could be.

**The tiers are the argument.** Generated documentation being wrong in places is not a defect in the
generator; it is the raw material for the layer that counts. Correcting a claim is what promotes it
from the lower tiers into the verified one, and that only ever happens as a by-product of doing the
work and hitting the wrong answer.

**No attempt to measure whether any of this helped.** The obvious temptation is to instrument the
harness so its value can be proven, and that would be a mistake here: it costs real time, the numbers
would be soft anyway, and worst of all it would bend the sequencing toward what is measurable instead
of toward what gets the work done. The rule is simpler. When an agent gets something wrong about this
codebase, fix `AGENTS.md` so the next one does not. That is not measurement, it is just working, and
it costs nothing beyond the correction itself. What the harness ends up containing is a more honest
record than any before-and-after number would have been. Ch4 is not a departure from this: noticing
that a report missed a breakage is reading an outcome that arrived on its own, not running a study.

**The failure mode to avoid** is the recency trap: a rule written because one session stumbled becomes
permanent guidance, and every future session steps around a pothole that is not there. The test
before adding a rule is whether it would have helped most sessions or only the one that wrote it.

**Done means:** the product documentation exists, the graph and the wiki both generate, and an agent
can find and run the test suite from `AGENTS.md` alone.

*Exercises:* writing agent-facing documentation for code I did not write, and treating the agent as a
first-class consumer of tooling output rather than an afterthought.
*Still untested afterwards:* whether any of it helped, which is not something this project sets out to
establish.

### Ch1 - The audit

*Roughly one evening. No production code, though the coverage map needs one instrumented local run.*

`AUDIT.md` in the fork: runtime and framework EOL positions with dates; the CI matrix gap; the
dependency gate below; and a **coverage map showing which areas are tested rather than only the
ratio**, since 34 test files carrying 213 test methods and 179 assertion calls is a set of numbers
that says nothing about where the net has holes.

**The dependency gate is this chapter's most valuable output, and it decides whether Ch3 Half B is an
upgrade or a plan for one.** One line in `AUDIT.md` per dependency recording the highest Laravel
version its latest release supports, and for anything that stops short, why: no release yet, a
transitive dependency holding it back, or an abandoned package underneath. Twelve of these are
first-party to Akaunting, so the answer is partly a question about how actively the vendor maintains
its own supporting packages.

An evening spent here is worth several weekends of finding the same thing out from a failing
`composer update`.

The coverage map is the other half, because it decides what Ch2 does. A ratio is a headline. A map
tells you whether those 213 test methods sit where the upgrade is going to hurt, which would be
lucky, or somewhere else entirely, which is more likely. Producing it needs Xdebug or PCOV locally,
since CI generates no coverage at all today.

**Done means:** every dependency has a recorded Laravel ceiling with a reason, the feasibility call on
Ch3 Half B is made and written down, and the coverage map exists.

*Exercises:* reading an unfamiliar large codebase and producing a sequenced plan from it.
*Still untested afterwards:* everything, since nothing has been fixed.

### Ch2 - The safety net

*Roughly one weekend, possibly two.*

Characterization tests on the paths the upgrade will touch. Not coverage as a goal, coverage as a
tripwire. The selection problem is the real content of this chapter: 34 test files carrying 213 test
methods and 179 assertion calls, against 1062 application files, means you cannot cover everything.
So the chapter is an argument about what to cover first and why, made against the map from Ch1. Under
one assertion per test method is itself the finding that sets the starting point.

Plus the two CI changes that make the upgrade legible instead of guessed at:

- **coverage produced at all**, which today it is not: CI sets `coverage: none` on the PHP setup step,
  so no coverage data exists anywhere. A lane that emits a machine-readable report is a precondition
  for both the gate below and the Ch4 report;
- a **coverage delta gate** on line coverage, measured against the value stored for the base branch,
  blocking any change that reduces it. A delta gate is a different and in my experience far more
  effective instrument than a percentage target. Ch3 is the obvious exception, because a
  codebase-wide restructure can trip a naive gate or slip past it while absolute coverage falls, so
  upgrade pull requests are exempt and rely on the characterization tests instead;
- **PHP 8.4 added as an allowed-failure lane**, turning the unknown breakage surface into a shrinking
  checklist visible on every commit.

**Done means:** CI emits a machine-readable coverage report, the delta gate blocks a deliberately
coverage-reducing test pull request, and the 8.4 lane runs with a known failure count rather than an
unknown one.

*Exercises:* PHPUnit at scale, CI design, characterization testing, and deciding where to spend a
fixed testing budget on code I did not write.
*Still untested afterwards:* whether the net actually catches anything, which Ch3 answers.

### Ch3 - The upgrade

*Half A is a weekend. Half B is unschedulable until Ch1 reports, and that is the point of it.*

**Half A: raise the PHP floor**, Rector-assisted, independent of the framework. The constraint is
`^8.1` today, which already permits 8.4 at install time, so this is not about making a newer runtime
possible. It is about raising the declared floor to `^8.2`, which Laravel 11 requires, and moving the
CI matrix from `8.1/8.2/8.3` to `8.2/8.3/8.4` so the runtime the project should actually be running on
is one that gets tested. 8.4 is the target because it is the supported runtime, not because any
dependency demands it.

**Half B: Laravel 10 to 11 to 12, if it turns out to be feasible.** Half A comes first because
Laravel 11 requires PHP 8.2 or later.

**Half B is a question before it is a task, and the plan says so rather than assuming an answer.** A
Laravel major upgrade is only as movable as its least movable dependency, and this application carries
twelve first-party packages plus a module system, none of which I control. Whether it can move at all
is unknown until the ceilings in Ch1 are established. Treating that as settled in advance is how a
two-weekend estimate becomes a two-month one.

**If it is feasible, do it.** Package majors first, then the framework, one reviewable step at a
time.

**If it is not,** the deliverable is `UPGRADE.md`: what blocks the move, what each blocker would cost
to clear, in what order, and the evidence behind each claim.

**Rector has to be added first, because the project has none.** There is no `rector.php` and no
Rector in `require-dev`, and there is no static analysis of any kind either: no PHPStan, no Larastan,
no Pint, no PHP-CS-Fixer. The README asks contributors to follow PSR standards and nothing checks
that they did. Introducing Rector scoped to `app/` is therefore step zero of this chapter.

Two disciplines make it useful rather than dangerous. **One rule set at a time, one commit each**: a
single Rector run across 1062 files produces a diff nobody can review, including me, and a reviewable
history is the entire value of doing this in public. And **dry run first, always**, reading the
proposed changes before applying them. The PHP level sets carry the bulk of Half A; Laravel-specific
rules help in Half B.

**Ch1 corrected what the hand work in Half B actually is, and this section carried the error until it
did.** The Laravel 11 slim skeleton is what *new* applications get. The upgrade guide states under
Application Structure that it does **not recommend** migrating a Laravel 10 application's structure,
because 11 was tuned to support the 10 structure as-is, and the whole 10 → 11 guide is headed
*Estimated Upgrade Time: 15 Minutes*. So collapsing `app/Console/Kernel.php` and
`app/Http/Kernel.php` into `bootstrap/app.php` is **optional work, not required work**. The 28
middleware files and 12 service providers stay where they are, and any schedule built on the collapse
being mandatory is budgeting for something upstream advises against doing.

What Rector will not do is the work that does apply, and it is mostly migrations. The guide's High
Impact list, filtered to this codebase by `AUDIT.md` §5 step 9: PHP 8.2, which Half A already covers;
6 `->change()` calls across 3 migration files, each of which must now restate every modifier it wants
to keep, since anything omitted is silently dropped; **38 `double`/`float` migration columns** across
6 files, all using the `(total, places)` argument form that Laravel 11 rewrote — on a double-entry
accounting application these are the money columns, which makes this the highest-consequence item in
the chapter; SQLite 3.26+, which lands on the test environment rather than production; and
Sanctum 3 → 4, which needs its migrations published and the middleware keys in `config/sanctum.php`
rewritten against overridden `App\Http\Middleware` classes. Worth budgeting alongside them: Carbon 3's
`diffIn*` now returns floating-point and signed values, a real hazard in a codebase with recurring
transactions, and it stops being optional at 12.

The internals still stop being optional here, for a different reason than this section used to give.
This codebase has 12 service providers and a module autoloading system layered on top of the
framework's own bootstrapping, and that layering is what the extension surface rests on. Nothing in
Ch1's coverage map guards it — `modules/` is unmeasured. There is no way through that does not
involve understanding what those providers are doing.

Every breakage gets documented as it is found, including the ones that turn out to be my mistake.
This chapter is also the first real verdict on Ch2: the interesting failures are the ones the test
net did not catch.

**Done means**, for Half A: the constraint is `^8.2`, the CI matrix runs 8.2/8.3/8.4, and the suite is
green on 8.4.

For Half B, whichever ending arrives: either `composer install` resolves on Laravel 12, the suite is
green, the application boots and the Offline Payments module installs and enables, or `UPGRADE.md`
exists and names every blocker with its cost and the evidence behind it. The module installing is the
condition that matters most in the first case, because anything short of it means the upgrade broke
the extension surface.

*Exercises:* service providers, module bootstrapping, schema migration semantics, Rector, deprecation
triage.

### Ch4 - Renovate, and a report on top of it

*Two parts with Ch3 between them, so they are estimated separately. The report: one weekend, before
Ch3 starts. Renovate and its triage policy: half a weekend, after Ch3 ends. They publish as two
write-ups rather than one.*

**Renovate for Composer**, configured with real grouping and scheduling rather than defaults, plus a
written triage document describing what gets batched, what gets automerged, and what always needs
eyes. This part comes after Ch3, because turning dependency automation on before stabilising produces
two hundred failing pull requests in a week and teaches everyone on the project to ignore the bot,
which is worse than having no automation at all. Stabilise, then automate.

Renovate over Dependabot for a reason specific to this repository: the dependency graph here has
natural groups that want to move together. The 12 first-party `akaunting/*` packages are one unit,
the framework's own packages are another, and Renovate's package rules can express that while
Dependabot's grouping largely cannot. A codebase whose dependency problem is partly self-authored
needs a policy surface that can say so. The dependency dashboard is a second reason: a single issue
listing everything pending is a better shape for triage than a wall of individual pull requests.

**A workflow that posts an assessment onto each Renovate pull request.** Given the package and the
two versions, it comments a report with three things: what this bump could break, why, and **which
tests should be written or strengthened before merging it**.

Three stages, built on the Vercel AI SDK in TypeScript:

1. **The codebase stage** is the only one that needs an agent loop. It is handed the call sites for
   the dependency, discovered deterministically, and read-only tools to explore from there: how the
   package is actually used, which tests exercise those paths, where the gaps are. It emits a partial
   report against a schema.
2. **The package stage** takes deterministic input (the two versions, the changelog between them) and
   emits a partial report about the change itself. No exploration required if the changelog is
   fetched up front.
3. **The synthesis stage** takes both partial reports and produces the report that gets posted.

Stages one and two are independent and run in parallel. The choice of the AI SDK over the provider
SDK is deliberate and buys something practical: the three stages do not want the same model, and
swapping one is a single line. The codebase stage explores and needs the strongest thing available;
the package stage summarises a changelog and does not. Being able to move each one independently,
without rewriting the workflow, is worth the dependency on its own.

That third output is the one that makes the whole project cohere. At 213 test methods against 1062
application files, coverage can never be finished, so the only sane strategy is to grow the net
where changes actually
arrive rather than where I guessed they might. Every bump knows exactly which uncovered call sites it
is about to touch. Letting the incoming change nominate the next test is a coverage strategy rather
than a coverage target, and it is an argument I want to test rather than assert.

Five design notes that are the actual engineering in this chapter:

- **The deterministic part and the judgment part must not blur.** Which call sites a package has in
  this codebase, and which of those lines the existing suite does not cover, are facts computable
  from the coverage data produced in Ch2 intersected with the code graph from Ch0, which is already an
  AST-derived call index and means no new analysis tooling is needed here. Those go into the prompt as
  established input, never as a question. What might break, and what a test should assert, is
  judgment and is what the model is actually for. A report that guesses at the first category to
  reason about the second is a report that sounds authoritative and is wrong for reasons nobody can
  see.

- **Which Renovate deployment is a decision, not a detail.** The Mend-hosted app and a self-hosted
  Action differ in who opens the branch, what token the report workflow runs under, and whether
  workflows on those pull requests see repository secrets at all. The self-hosted Action keeps all
  three in the
  repository and under version control, which is the reason to prefer it here. That choice gets made
  and written down before the report workflow is built, because the whole security discussion below depends
  on it.

- **The real risk is the prompt, not the plumbing.** A workflow holding an API key is reading content
  a third party controls.
  Release notes, changelogs, and the bumped package's own source are all attacker-influenceable text
  flowing into a prompt. The mitigations are to keep the codebase stage out of `vendor/` entirely, to
  frame fetched changelog text as data rather than instructions, and to grant the workflow no write
  scope beyond posting its own comment. Writing that reasoning down is the security work here.

- The report has to be **built and validated before Renovate is switched on**, against
  manually-opened bump pull requests during Ch3. An assessment is only a prediction if it exists
  before the outcome is known.

- **The codebase stage reads first-party paths only, through narrow read-only tools, never a shell.**
  `vendor/` is out of scope for it, so the only attacker-influenceable text reaching a prompt is the
  changelog. Path canonicalisation exists precisely because the checkout does contain vendor code
  that a curious model might try to reach, not because reading it is intended. Its exploration budget
  is capped for the same reason: an agent given a shell and a patch-version bump will read the entire
  tree.

- **Dependency automation opens pull requests in batches, which makes prompt caching the main cost
  lever.** The system prompt and tool definitions are byte-identical across every pull request in a
  batch, so they go first behind a cache breakpoint with the per-package payload after. First run
  pays; the rest of the batch reads the prefix at a fraction of the price. Two things to verify early
  rather than assume, because either one sinks the saving: that the abstraction lets the breakpoint
  land where it should, since provider-specific request fields arrive through a passthrough rather
  than as first-class parameters; and that a batch actually lands inside the cache lifetime, which
  depends on the schedule and on how many pull requests open at once. A batch spread over hours pays
  full price every time.

Ch3 is what makes this worth attempting here rather than anywhere else, because a two-major-version
upgrade means dozens of real bumps whose outcomes arrive on their own. No scoring harness and no
tallying: when something breaks, glance at what the report said about it. Two things are worth
noticing when they happen, and neither costs anything to notice.

The first is a breakage the report **never mentioned at all**. Misses matter more than hits, because
a tool that is right when it speaks but silent on the thing that bit you is not one to lean on. The
second is a recommended test that **would have passed anyway**. That is worse than no recommendation,
because it buys confidence without buying coverage.

If either happens often, the tool needs work or does not deserve trust, and that judgement can be
made from a handful of instances without counting any of them.

**Done means:** Renovate opens grouped pull requests on schedule, and each one carries a report whose
deterministic section is correct on inspection. The judgement section is judged by reading it, not by
a threshold.

*Exercises:* dependency policy design against a repository I did not write, GitHub Actions
permissions and the trust boundary around a bot-opened pull request, drawing a hard line between
computed input and model judgment, and building evaluation into a tool rather than trusting how
confident its output sounds.
*Still untested afterwards:* whether the policy or the report survive months of real traffic, which
no short project can show.

## Running through all of it: three jobs for tooling

Three distinct things, easy to collapse into one vague claim about AI being useful, so they stay
apart. None of them is a study; each is work the tooling either does or fails to do, and the failures
are what the build log records.

- **Navigating a codebase nobody explained.** Ch0. When it gets something wrong, `AGENTS.md` gains a
  line.
- **Assessing a change before it lands.** Ch4. When it misses a breakage, that is the signal.
- **Doing the work itself.** Ch2 and Ch3: what got delegated during a framework upgrade, what did
  not, and where it produced confident nonsense. An unfamiliar codebase plus a largely mechanical
  transformation is close to the ideal case for this tooling, which is exactly why the failures are
  the part worth writing down.

The bias throughout is toward finishing the work well and quickly. Where a tool helps it stays, where
it does not it goes, and that call gets made from working with it rather than from instrumenting it.

## Non-goals

- Not fixing product bugs. This is foundational work, not feature work.
- Not touching Vue components or frontend behaviour. Build-tooling changes forced by the upgrade are
  in scope.
- **No Kubernetes, no deployment tooling, no observability work.** All three are interesting and none
  of them serve the thesis. They would turn a finishable project into a sprawling one.
- Target is Laravel 12, not 13. One horizon at a time.
- Not making the fork production-ready for anyone. It is not maintained for anyone else, and the
  Additional Use Grant covers only small-scale use in any case.
- Not a full test suite. Characterization coverage on upgrade-touched paths only.
- **No copies of the vendor's documentation.** Product documentation here is written from published
  material, with sources cited. Nothing is republished verbatim.

## Sequencing

The order is driven by dependencies, not by preference:

1. **Ch0 is never finished**, so it does not block anything. A thin first version comes before Ch1 to
   make exploration possible, and every chapter afterwards corrects it. Waiting until the harness is
   good would mean writing it entirely from guesses. The one ordering that matters inside it: the
   product documentation is written before the source wiki is first generated, so the wiki has the
   domain vocabulary in hand rather than inferring purpose from property names.
2. **Ch1 before the rest**, because a plan made before reading the codebase is fiction.
3. **Ch2 before Ch3**, because you cannot upgrade what you cannot verify.
4. **Ch3 Half A before Half B**, because Laravel 11 requires PHP 8.2 or later. Half B additionally
   waits on Ch1's feasibility call, which is the one decision in this plan that could change the
   shape of a whole chapter.
5. **Part of Ch1 is already done.** `DOCS-DRIFT-AUDIT.md` was written before this plan was finished,
   so the documentation half of the audit is already in hand. Ch1 is smaller than it looks.
6. **Ch4 straddles Ch3.** The report workflow has to exist before the upgrade starts, because its
   output is only a prediction if it is written before the outcome is known. Renovate itself comes
   after, because automating a drifted repository generates noise instead of signal.
7. **The upstream issue goes out right after Ch1**, since what it describes is the audit's findings.
   Later than that and it reads as a summary of work already done rather than a question.
8. **Ch4's report depends on Ch2's coverage data**, not just on Ch2 finishing. The workflow cannot
   tell you which uncovered lines a bump touches until coverage is being produced in CI as a
   machine-readable artefact, so that has to be an output of Ch2 rather than an afterthought.

## Upstream

The fork is the deliverable. Upstream pull requests are a byproduct, not the plan.

Looking at the last thirty closed pull requests upstream, most merges come from the core team.
Outside contributors do get merged, but the successful ones are consistently small, single-behaviour,
behaviour-preserving fixes. The one CI workflow contribution in the history was closed, and open pull
requests can sit for five months or more. So infrastructure, policy and framework-upgrade changes are
bets against the observed record, and sending them unsolicited would waste a small team's time.

What is worth sending home: the upgrade will surface **genuine bugs that exist today** independent of
any upgrade, deprecations and latent breakage that are wrong right now. Those are small and
bug-shaped and belong upstream.

One issue opened early, describing the audit findings and asking whether contributions in that
direction are wanted, is better citizenship than eight unsolicited pull requests. Either answer is
useful.

## Build log

One write-up per chapter, published as it finishes. Each carries what the chapter exercised and what
it left untested, because a public build log that only reports wins is not worth reading.
