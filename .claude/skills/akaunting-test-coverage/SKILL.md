---
name: akaunting-test-coverage
description: Improve Akaunting automated test coverage by deriving behavior from OpenWiki and existing tests, tracing the current implementation, and running the narrowest relevant PHPUnit checks first.
---

# Akaunting Test Coverage

1. Read `openwiki/testing.md` and the relevant OpenWiki system or workflow page. Use them to identify behavior, not to override source.
2. Trace the behavior through routes, controllers, requests, jobs, models, events, and current tests. Start navigation with `akaunting-codebase-navigation` when the path is unfamiliar.
3. Place an HTTP/business workflow in `tests/Feature` or `modules/*/Tests/Feature`; place isolated logic in `tests/Unit` or `modules/*/Tests/Unit`. Reuse `FeatureTestCase`, `PaymentTestCase`, factories, and existing helpers before creating test-only infrastructure.
4. Respect `phpunit.xml`: tests use the in-memory SQLite connection, synchronous queues, and array mail. Run the most specific test file or test name first with `php artisan test <path-or-filter>`, then run the proportionate feature, unit, module, or full suite.
5. Report any OpenWiki page that is missing, stale, or contradicted by source/tests. Include the page and source locations; Do not edit OpenWiki.
