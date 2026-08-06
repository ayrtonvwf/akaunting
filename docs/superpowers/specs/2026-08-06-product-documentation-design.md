# Product documentation design

## Purpose

Create the first Northstar deliverable: a complete, local, agent-readable
reference to Akaunting's product vocabulary. It enables later code-audit and
test work to distinguish domains and describe them consistently. It is
orientation, not implementation guidance or a copy of the vendor's help
centre.

## Scope

The documentation covers every product area represented in the live Akaunting
Help Centre as checked on 2026-08-06, plus the published developer-facing
extension surface.

Core product domains receive concise, practical references:

- shared concepts;
- sales;
- purchases;
- banking;
- reporting; and
- administration.

Optional app domains, including CRM, Projects, HR, Inventory, and Double-Entry
Accounting, receive light vocabulary entries. They state what each capability
is and what it primarily does, while explicitly saying that its implementation
is not included in this checkout. This avoids treating an installed product
feature as source owned by this repository.

The extension-surface reference covers product-facing integration concepts such
as modules, menus, settings, and APIs. It cross-checks published developer
guidance against local source and records material discrepancies rather than
silently repeating them.

The documentation does not include task walkthroughs, source-code architecture,
or implementation instructions outside the extension reference.

## Information architecture

```text
docs/product/
  README.md              # purpose, scope, provenance, reading guide
  concepts.md            # shared vocabulary and cross-domain relationships
  sales.md               # customers, invoices, payments, estimates
  purchases.md           # vendors, bills, bill payments
  banking.md             # accounts, transactions, transfers, feeds, reconciliation
  reporting.md           # standard reports, report basis, exports
  administration.md      # dashboard, users/roles, settings, imports, apps
  optional-apps.md       # optional capabilities absent from this checkout
  extensions.md          # documented integration concepts and verified corrections
```

Each domain page uses the same compact shape: **What it is**, **Main
capabilities**, **Related concepts**, and **Sources**. The index explains the
documentation's limits and links the pages by domain rather than imitating the
Help Centre's navigation.

## Provenance and wording

All prose is newly written. The source of a factual statement is cited with the
specific Help Centre URL that supports it; the extension page also identifies
where a local-source check corrected or qualified published material. Each page
records that the source inventory was checked on 2026-08-06. Downstream work
uses this committed set rather than fetching Help Centre pages during a task.

The docs use three explicit labels where needed:

- **Core in this checkout** for product concepts represented by local source.
- **Optional; not included in this checkout** for installed or purchasable app
  capabilities that are absent here.
- **Verified against source** for extension-surface claims checked locally.

## Production flow

1. Inventory the live Help Centre and map every product area to a local page.
2. Draft the concise product references from that inventory, in original
   language, with exact citations.
3. Compare core-domain terminology with local routes and views only to confirm
   that the core/optional labels are accurate.
4. Compare developer-facing claims with the module/provider source and the
   existing drift audit.
5. Review for uncited claims, duplicated or conflicting terminology, accidental
   tutorial-like copying, and optional features presented as bundled source.

## Acceptance criteria

- Every live Help Centre product area has a home in the local set.
- Every factual section has a direct source citation.
- Optional capabilities are prominently identified as absent from this
  checkout.
- The extension page distinguishes published guidance from locally verified
  facts and identifies material disagreement.
- An agent can look up a product term and understand its domain and important
  relationships without treating this documentation as implementation
  authority.

## Verification

Review the source inventory against the Help Centre category index; scan all
pages for source links and the optional-feature label; inspect local route/view
names used for core labels; and compare extension corrections with
`specs/northstar/DOCS-DRIFT-AUDIT.md`.
