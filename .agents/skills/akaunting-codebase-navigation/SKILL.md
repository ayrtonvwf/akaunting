---
name: akaunting-codebase-navigation
description: Navigate unfamiliar Akaunting behavior, Laravel request flows, source relationships, or project structure by combining the OpenWiki bundle, the locked Graphify query, and current source verification.
---

# Akaunting Codebase Navigation

1. Read `openwiki/index.md` and `openwiki/quickstart.md`. Read the relevant system or workflow page before naming code paths.
2. Run `uv run --project tools/graphify --locked graphify query "<specific question>" --graph graphify-out/graph.json` for structural evidence.
3. Inspect the cited current route, controller, request, job, model, configuration, manifest, and nearest test as applicable. Treat `EXTRACTED` graph edges as source-derived; validate `INFERRED` and `AMBIGUOUS` edges in source.
4. State the OpenWiki page, Graphify query, and source locations used. If OpenWiki is absent, stale, or contradictory, report its page and the contradicting local evidence; do not edit OpenWiki.
