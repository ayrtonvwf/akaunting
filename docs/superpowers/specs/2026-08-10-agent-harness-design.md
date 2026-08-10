# Agent Harness Design

**Date:** 2026-08-10

## Purpose

Create a compact, reproducible development harness for Codex and Claude agents working on Akaunting maintenance. The harness targets three recurring activities: navigating an unfamiliar Laravel/Akaunting area, improving automated test coverage, and upgrading dependencies. It does not add application features, modify dependencies, or update documentation as part of this work.

## Goals

- Give Codex and Claude the same repository operating contract.
- Make shared external skills reproducible and version-pinned in the repository.
- Use the committed OpenWiki bundle for source-grounded orientation without treating it as a substitute for current source code.
- Retain Graphify as the structural code-navigation capability.
- Add only the custom skills that are specific to Akaunting maintenance.
- Report, but do not edit, OpenWiki drift discovered during maintenance work.

## Non-goals

- Creating or modifying Akaunting modules.
- Adding a broad catalog of overlapping framework, frontend, Docker, release, or style skills.
- Changing application code, tests, dependencies, lockfiles, or OpenWiki content while implementing the harness.
- Rebuilding the committed Graphify baseline automatically.

## Architecture

### Repository instructions

`AGENTS.md` is the concise project operating guide. A root-level `CLAUDE.md` is an exact copy, so Codex and Claude receive the same instructions without client-specific divergence. A validation check must detect any difference between the two files.

The guide will contain only project-specific operating information:

- the Laravel/Akaunting source map and key commands;
- the evidence order for maintenance work;
- the OpenWiki and Graphify navigation rules;
- test and dependency-upgrade safety expectations;
- the OpenWiki-drift reporting contract; and
- the existing Graphify constraints, commands, and validation requirements.

It will not restate the README, contain credentials, or encode generic agent behavior that belongs in reusable skills.

### Evidence order

Agents use the following order when orienting a change:

1. `openwiki/index.md`, `openwiki/quickstart.md`, then the relevant OpenWiki system or workflow page for architectural and domain orientation.
2. The locked local Graphify query command for source relationships and call paths.
3. Current source, configuration, manifests/lockfiles, and focused tests as the implementation authority.
4. External documentation only when a current fact cannot be established locally.

OpenWiki is a primary navigation layer, not a source-of-truth override. If it conflicts with code, configuration, or a test, the agent follows the local implementation and reports the documentation drift. The report names the OpenWiki page, the contradictory source location, and why it appears outdated. Agents do not edit the bundle unless the user explicitly asks.

### Skills and distribution

`apm.yml` and `apm.lock.yaml` are committed as the authoritative inventory of shared external capabilities. APM is chosen because it supports both Codex and Claude and pins the resolved contents in a lockfile. The Vercel `skills` CLI remains a discovery and evaluation tool, not the project source of truth.

The shared external baseline is deliberately limited to:

- the existing project-scoped `graphify` skill;
- `test-driven-development` from `obra/superpowers`;
- `systematic-debugging` from `obra/superpowers`; and
- `verification-before-completion` from `obra/superpowers`.

Project-owned skills are authored under `.agents/skills/<name>/SKILL.md`, use portable Agent Skills frontmatter, and are deployed for Codex and Claude through the selected package process. Generated or deployed copies are not edited independently.

Three custom skills are required:

#### `akaunting-codebase-navigation`

Triggers for unfamiliar code paths, architecture questions, request-flow tracing, or locating the implementation of a product behavior. It directs agents to OpenWiki before Graphify and source inspection. It produces a small evidence trail: relevant OpenWiki page, Graphify query, source locations, and any documentation drift.

#### `akaunting-test-coverage`

Triggers when adding or improving tests. It uses `openwiki/testing.md` and the relevant domain/workflow page to identify the intended behavior, then locates the route, controller, job, model, and nearest existing test. It respects the PHPUnit in-memory SQLite test configuration and module test locations, selects the narrowest relevant command first, and widens verification only as needed. Documentation drift is reported without changing the bundle.

#### `akaunting-dependency-upgrade`

Triggers for Composer, NPM, or lockfile dependency updates. It reads the relevant OpenWiki configuration or architecture page to identify impacted surfaces, then establishes actual ownership from root and module manifests, lockfiles, and `overrides/`. It scopes updates deliberately, examines compatibility/migration/configuration effects, and requires targeted then broader verification. Documentation drift is reported without changing the bundle.

## Workflow contracts

### Navigation

The navigation workflow is: identify intent; read the OpenWiki index/quickstart and relevant leaf page; query Graphify using the locked project command; inspect current source and tests; state the evidence boundary; report any wiki drift.

If no relevant OpenWiki page exists, the agent starts from the index, uses Graphify and source search, and identifies the documentation gap in its handoff. If Graphify is unavailable or stale, source inspection is the fallback and the limitation is reported.

### Test coverage

The coverage workflow is: determine behavior from OpenWiki and existing tests; trace the implementation; select a feature or unit test boundary based on the code path; use existing factories, helpers, and base test classes; create the narrowest behavior-focused regression test; run it; then run proportionate broader checks. It does not treat a wiki example as evidence that a behavior currently exists.

### Dependency upgrades

The upgrade workflow is: identify the package owner and current constraint; identify direct, transitive, module, override, configuration, and migration impact; make a scoped update only after the change is understood; verify targeted behavior and a proportionate broad suite; report incompatibilities or documentation drift with evidence.

## Validation and acceptance criteria

The harness implementation must provide a repeatable validation check that confirms:

- `AGENTS.md` and `CLAUDE.md` are byte-identical;
- required OpenWiki and Graphify references are present in the guidance;
- every project skill has valid frontmatter and expected discovery metadata;
- the APM manifest and lockfile reflect the approved inventory;
- the existing Graphify requirements remain represented; and
- each custom skill references only real, safe commands and paths.

The final verification runs the project-specific harness check plus the appropriate APM integrity/audit check. It reports any generated deployment artifacts explicitly, and it leaves application files, dependency constraints, lockfiles, and OpenWiki content untouched.

## Bootstrap and maintenance

The normal setup sequence is: clone the repository, install APM, run `apm install`, then work with the pinned shared skills and project-owned skills. Updating an external skill is intentional: change its approved source/version, regenerate the lockfile and deployments, run validation and APM audit, then commit the manifest, lockfile, and intended generated changes together.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Generic skills conflict with local conventions | Keep their scope procedural; put Akaunting-specific facts in instructions and custom skills. |
| OpenWiki has stale generated information | Use it for orientation only; verify source facts and flag exact drift. |
| Codex and Claude guidance drifts | Maintain an exact copy and enforce parity in validation. |
| External skill updates change behavior unexpectedly | Pin them in `apm.lock.yaml`, review changes, and validate before committing. |
| Skills become a broad, overlapping catalog | Begin with three external process skills and three maintenance-specific project skills; add more only after a repeated need is demonstrated. |
