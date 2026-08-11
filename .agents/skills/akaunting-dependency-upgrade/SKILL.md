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
6. Report any OpenWiki discrepancy with its page and the contradicting local source, manifest, lockfile, or test; Do not edit OpenWiki.
