# Product Documentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a complete, original-language, locally committed Akaunting product reference that gives later Northstar work stable domain vocabulary without copying vendor documentation or becoming implementation documentation.

**Architecture:** A compact `docs/product/` set is organized by product domain, not by Help Centre navigation. A root index defines its provenance and maps every live Help Centre area to exactly one local home; core domain pages describe concepts represented in this checkout; optional-app entries describe absent capabilities lightly; and the extension page separates verified source facts from published guidance.

**Tech Stack:** Markdown, Git, Akaunting Help Centre as a one-time source inventory, local route/view/provider inspection, ripgrep, PowerShell.

## Global Constraints

- All prose is original synthesis; do not reproduce help-centre instructions, examples, images, or extended phrasing.
- Treat `https://akaunting.com/hc/docs/` as a source snapshot checked on 2026-08-06; downstream tasks use the committed documentation rather than fetching the web.
- Every factual section contains direct Help Centre source links; only the extension page also cites local files.
- Apply **Core in this checkout**, **Optional; not included in this checkout**, and **Verified against source** labels exactly as defined in the approved design.
- Core product documentation explains product meaning and relationships, not Laravel internals or task walkthroughs.
- Optional app entries contain two to five original sentences that state purpose, principal capabilities, important vocabulary, and that the implementation is absent from this checkout.
- Keep `LICENSE.txt`, Akaunting branding, and vendor documentation untouched.

---

## File structure

| File | Responsibility |
| --- | --- |
| `docs/product/README.md` | Scope, provenance, label legend, navigation, and Help Centre coverage matrix. |
| `docs/product/concepts.md` | Cross-domain vocabulary and relationships shared by the core product. |
| `docs/product/sales.md` | Sales-side customer, estimate, invoice, and payment vocabulary. |
| `docs/product/purchases.md` | Purchase-side vendor, bill, and payment vocabulary. |
| `docs/product/banking.md` | Accounts, transactions, feeds, transfers, and reconciliation vocabulary. |
| `docs/product/reporting.md` | Standard reports, report configuration, accounting basis, and export vocabulary. |
| `docs/product/administration.md` | UI, company setup, settings, taxes, users, apps, import/export, hosting, and support-adjacent concepts. |
| `docs/product/optional-apps.md` | Deliberately light reference to unbundled app domains and their relationships to core concepts. |
| `docs/product/extensions.md` | Developer-facing integration vocabulary, provenance boundaries, and verified corrections. |

## Task 1: Create the documentation index and shared vocabulary

**Files:**
- Create: `docs/product/README.md`
- Create: `docs/product/concepts.md`
- Test: manual source-coverage and link checks for both files

**Interfaces:**
- Consumes: the Help Centre category index at `https://akaunting.com/hc/docs/`; local core-domain directory names under `resources/views/` and routes in `routes/admin.php`.
- Produces: the label legend and coverage matrix that every later page must follow; canonical definitions for `company`, `dashboard`, `item`, `contact`, `category`, `currency`, `tax`, `document`, `payment`, and `app`.

- [ ] **Step 1: Create `docs/product/README.md` with the shared contract**

  Write the title `# Akaunting product reference`, followed by: purpose; snapshot date `2026-08-06`; an original-language/no-mirroring statement; a rule that downstream work reads this committed set rather than the web; and this label legend:

  ```markdown
  - **Core in this checkout** — the product concept has related source in this repository.
  - **Optional; not included in this checkout** — the capability may be installed or purchased but its implementation is not source owned by this checkout.
  - **Verified against source** — an extension-surface statement checked against a named local file.
  ```

- [ ] **Step 2: Add the complete source-coverage matrix to `README.md`**

  Add a table with these exact source-category-to-local-home mappings. Cite the category index in the table preamble and link each local file.

  | Help Centre area | Local home |
  | --- | --- |
  | Getting Started; The User Interface | `administration.md` |
  | Invoices and Estimates; Payments | `sales.md` |
  | Bills | `purchases.md` |
  | Banking, Feeds, and Reconciliations | `banking.md` |
  | Settings; Taxes and Filing; Users and Roles; Apps and Integrations; Import and Export; On-Premise; Frequently Asked Questions | `administration.md` |
  | Reports | `reporting.md` |
  | Human Resource Management; Customer Relationship Management; Project Management; Inventory Management; Double-Entry Accounting; Helpdesk; Receipts | `optional-apps.md` |
  | Developers | `extensions.md` |

  End with a short navigation list linking all eight topic files.

- [ ] **Step 3: Create `docs/product/concepts.md`**

  Use the four required headings: `## What it is`, `## Main capabilities`, `## Related concepts`, and `## Sources`. Begin with **Core in this checkout**. Define each canonical term in one or two original sentences, with these relationships explicit:

  ```text
  company owns the working data context
  customer -> invoice -> payment
  vendor -> bill -> payment
  item can appear on sales and purchase documents
  account records banking activity
  category, currency, and tax classify or value activity across domains
  dashboard and reports summarize the recorded activity
  ```

  Link the relevant local domain pages rather than repeating their detail. Cite the Help Centre category index, the navigation-menu page, the settings page, and the roles-and-permissions page.

- [ ] **Step 4: Verify Task 1**

  Run:

  ```powershell
  $files = @('docs/product/README.md', 'docs/product/concepts.md')
  foreach ($file in $files) {
    if (-not (Test-Path $file)) { throw "Missing $file" }
    if (-not (Select-String -LiteralPath $file -Pattern 'https://akaunting.com/hc/docs/' -Quiet)) { throw "No Help Centre citation in $file" }
  }
  rg -n "Core in this checkout|Optional; not included in this checkout|Verified against source|TBD|TODO|FIXME" docs/product/README.md docs/product/concepts.md
  ```

  Expected: both files exist and contain Help Centre citations; the first three labels appear in `README.md`; no placeholder match is returned.

- [ ] **Step 5: Commit Task 1**

  ```bash
  git add docs/product/README.md docs/product/concepts.md
  git commit -m "docs: add product reference index and concepts"
  ```

## Task 2: Document the sales and purchases domains

**Files:**
- Create: `docs/product/sales.md`
- Create: `docs/product/purchases.md`
- Test: manual terminology, citation, and boundary check

**Interfaces:**
- Consumes: canonical terms and label rules in `docs/product/concepts.md`.
- Produces: concise, linked definitions of sales and purchase documents for the banking and reporting pages.

- [ ] **Step 1: Create `docs/product/sales.md`**

  Start with **Core in this checkout** and use the required four headings. Define customer, estimate, invoice, invoice lifecycle, recurring invoice, payment, split payment, and online payment in original language. State that sales records money owed or received from customers and link `banking.md` for transaction connection and `reporting.md` for analysis. Do not prescribe click paths or copy invoice-management procedures. Cite:

  ```text
  https://akaunting.com/hc/docs/invoices-estimates/
  https://akaunting.com/hc/docs/payments/
  https://akaunting.com/hc/docs/the-user-interface/navigation-menu/
  ```

- [ ] **Step 2: Create `docs/product/purchases.md`**

  Start with **Core in this checkout** and use the required four headings. Define vendor, bill, bill payment, recurring bill, and expense-side obligation. State the boundary in one explicit sentence: invoices represent the customer-facing sales side; bills represent vendor-facing purchases. Link `sales.md`, `banking.md`, and `reporting.md`; do not write user procedures. Cite:

  ```text
  https://akaunting.com/hc/docs/bills/
  https://akaunting.com/hc/docs/the-user-interface/navigation-menu/
  ```

- [ ] **Step 3: Check cross-domain terminology**

  Inspect the local source names solely to confirm that the documentation uses current domain terms:

  ```powershell
  rg --files resources/views/sales resources/views/purchases
  rg -n "Route::resource\('invoices'|Route::resource\('bills'|Route::resource\('customers'|Route::resource\('vendors'" routes/admin.php
  ```

  Expected: `sales` and `purchases` are the current local terms; no `incomes` terminology is introduced.

- [ ] **Step 4: Verify Task 2**

  Run:

  ```powershell
  rg -n "^## (What it is|Main capabilities|Related concepts|Sources)$|https://akaunting.com/hc/docs/|TBD|TODO|FIXME" docs/product/sales.md docs/product/purchases.md
  ```

  Expected: all four required headings and citations appear in both files; no placeholder match is returned.

- [ ] **Step 5: Commit Task 2**

  ```bash
  git add docs/product/sales.md docs/product/purchases.md
  git commit -m "docs: add sales and purchases reference"
  ```

## Task 3: Document banking and reporting

**Files:**
- Create: `docs/product/banking.md`
- Create: `docs/product/reporting.md`
- Test: source-link, domain-boundary, and terminology checks

**Interfaces:**
- Consumes: `sales.md` and `purchases.md` document/payment terminology.
- Produces: the vocabulary that relates operational records to reports.

- [ ] **Step 1: Create `docs/product/banking.md`**

  Start with **Core in this checkout** and use the required headings. Define account, transaction, income, expense, transfer, bank feed, reconciliation, split transaction, and document connection. Make the relationship explicit: banking records money movement; sales and purchase documents describe what money is owed; reconciliation relates account activity to those records. Link sales, purchases, and reporting pages. Cite:

  ```text
  https://akaunting.com/hc/docs/banking-feeds-reconciliations/
  https://akaunting.com/hc/docs/banking-feeds-reconciliations/managing-transactions/
  ```

- [ ] **Step 2: Create `docs/product/reporting.md`**

  Start with **Core in this checkout** and use the required headings. Describe reports as views over recorded product data; define report type, period, grouping, cash basis, accrual basis, filtering, pinning, printing, and export. Identify the standard income/expense, profit-and-loss, and tax-summary vocabulary without presenting every report as core source. Link banking, sales, purchases, concepts, and optional-apps for installed report types. Cite:

  ```text
  https://akaunting.com/hc/docs/reports/
  https://akaunting.com/hc/docs/reports/accessing-and-viewing-reports/
  https://akaunting.com/hc/docs/reports/creating-a-new-report/
  ```

- [ ] **Step 3: Check local banking and report terminology**

  Run:

  ```powershell
  rg --files resources/views/banking resources/views/reports
  rg -n "Route::resource\('(accounts|transactions|transfers|reconciliations|reports)'" routes/admin.php routes/api.php
  ```

  Expected: current local domains match the page names and no unverified implementation claim is added.

- [ ] **Step 4: Verify Task 3**

  Run:

  ```powershell
  rg -n "^## (What it is|Main capabilities|Related concepts|Sources)$|https://akaunting.com/hc/docs/|TBD|TODO|FIXME" docs/product/banking.md docs/product/reporting.md
  ```

  Expected: all required headings and citations appear in both files; no placeholder match is returned.

- [ ] **Step 5: Commit Task 3**

  ```bash
  git add docs/product/banking.md docs/product/reporting.md
  git commit -m "docs: add banking and reporting reference"
  ```

## Task 4: Document administration and optional application vocabulary

**Files:**
- Create: `docs/product/administration.md`
- Create: `docs/product/optional-apps.md`
- Test: category coverage and optional-feature-label checks

**Interfaces:**
- Consumes: the complete coverage matrix in `README.md` and shared terms in `concepts.md`.
- Produces: vocabulary for cross-cutting administration and capabilities absent from this checkout.

- [ ] **Step 1: Create `docs/product/administration.md`**

  Start with **Core in this checkout** and use the required headings. Cover the following compact concept groups, linking instead of duplicating domain detail:

  ```text
  company setup and dashboard widgets
  navigation, sidebar, search, favorites, and quick creation
  company, localization, defaults, invoice, email-template, schedule, category, currency, and tax settings
  users, roles, permissions, and client portal
  apps: discovery, installation, subscription, and update vocabulary
  import/export as data interchange
  on-premise installation/API-key vocabulary and FAQ distinctions such as cash versus accrual
  ```

  State only product-level effects, not procedures. Cite the category pages and these direct sources:

  ```text
  https://akaunting.com/hc/docs/the-user-interface/navigation-menu/
  https://akaunting.com/hc/docs/the-user-interface/the-sidebar/
  https://akaunting.com/hc/docs/settings/
  https://akaunting.com/hc/docs/users-and-roles/roles-and-permission-levels/
  ```

- [ ] **Step 2: Create `docs/product/optional-apps.md`**

  Begin with a prominently placed **Optional; not included in this checkout** notice explaining that the page is vocabulary only and none of these implementations should be assumed present in local source. Give two to five original sentences and sources for each of these entries:

  | Entry | Main vocabulary and relationship to core |
  | --- | --- |
  | Human Resource Management | employees, payroll, payslips; connects people/payroll activity to administration. |
  | CRM | contacts, companies, deals, customer journey; distinguish CRM contacts from core sales customers where context requires it. |
  | Project Management | projects, tasks, milestones, time, billing; can lead to customer-facing work and invoices. |
  | Inventory Management | stock, warehouses, item groups, variants, adjustments, transfer orders; extends core items. |
  | Double-Entry Accounting | chart of accounts, manual journals, ledger, balance sheet, trial balance; supplements operational records and reports. |
  | Helpdesk | tickets, import, search/filter/status, replies; support vocabulary. |
  | Receipts | receipt creation and editing; evidence vocabulary associated with transactions/expenses. |

  Cite the Help Centre category index plus these exact category sources; do not write source-path claims for these capabilities:

  ```text
  https://akaunting.com/hc/docs/human-resource-management/
  https://akaunting.com/hc/docs/crm/
  https://akaunting.com/hc/docs/project-management/
  https://akaunting.com/hc/docs/inventory-management/
  https://akaunting.com/hc/docs/double-entry-accounting/
  https://akaunting.com/hc/docs/helpdesk/
  https://akaunting.com/hc/docs/receipts/
  ```

- [ ] **Step 3: Verify every Help Centre category has a documented home**

  Run:

  ```powershell
  $required = @(
    'Getting Started', 'The User Interface', 'Invoices and Estimates', 'Bills',
    'Banking, Feeds, and Reconciliations', 'Settings', 'Payments',
    'Apps and Integrations', 'Taxes and Filing', 'Users and Roles',
    'Human Resource Management', 'Reports', 'Customer Relationship Management',
    'Project Management', 'Inventory Management', 'Double-Entry Accounting',
    'Import and Export', 'Frequently Asked Questions', 'On-Premise', 'Developers',
    'Helpdesk', 'Receipts'
  )
  foreach ($area in $required) {
    if (-not (Select-String -LiteralPath 'docs/product/README.md' -SimpleMatch $area -Quiet)) {
      throw "Coverage matrix omits: $area"
    }
  }
  if (-not (Select-String -LiteralPath 'docs/product/optional-apps.md' -SimpleMatch 'Optional; not included in this checkout' -Quiet)) {
    throw 'Optional-app label is missing'
  }
  Write-Output 'Category coverage and optional-app label: PASS'
  ```

  Expected: the command prints the PASS line without an exception.

- [ ] **Step 4: Commit Task 4**

  ```bash
  git add docs/product/administration.md docs/product/optional-apps.md
  git commit -m "docs: add administration and optional app reference"
  ```

## Task 5: Document the extension surface and reconcile known drift

**Files:**
- Create: `docs/product/extensions.md`
- Read: `specs/northstar/DOCS-DRIFT-AUDIT.md`
- Read: `composer.json`
- Read: `app/Providers/Route.php`, `app/Providers/Macro.php`, `app/Events/Menu/SettingsCreated.php`
- Read: `modules/OfflinePayments/module.json`, `modules/PaypalStandard/module.json` when Composer has installed the module paths
- Test: source-citation and verified-claim checks

**Interfaces:**
- Consumes: publication-versus-source distinction in the README, the developer Help Centre category, and the drift audit.
- Produces: non-tutorial extension vocabulary, clear provenance, and corrections later agents can rely on.

- [ ] **Step 1: Establish the local evidence before drafting**

  If `modules/OfflinePayments/module.json` or
  `modules/PaypalStandard/module.json` is absent, first materialize the
  Composer-installed module paths without changing dependency constraints:

  ```bash
  composer install --no-interaction --prefer-dist --no-progress
  ```

  Then run the following read-only checks and record only facts confirmed by their output:

  ```powershell
  rg -n 'akaunting/laravel-module|module-offline-payments|module-paypal-standard|"installer-paths"' composer.json
  rg -n 'Facade::macro\(|function module|module\(' app/Providers/Route.php app/Providers/Macro.php
  Test-Path app/Events/Menu/SettingsCreated.php
  Test-Path modules/OfflinePayments/module.json
  Test-Path modules/PaypalStandard/module.json
  ```

  Expected: `composer.json` identifies the module packages and path mappings; provider checks identify module routing/macro evidence; missing module manifests are treated as a post-install condition, not an absence of the module system.

- [ ] **Step 2: Create `docs/product/extensions.md`**

  Open with an explicit scope statement: this is product-facing extension vocabulary, not an API contract or implementation tutorial. Use **Verified against source** beside every locally checked statement. Cover concise definitions of module, `module.json`, provider, menu extension, module settings, model hooks/observers, bulk actions, search strings, output overriding, payment method, API, and version compatibility. Cite the developer index and relevant direct developer pages, beginning with:

  ```text
  https://akaunting.com/hc/docs/developers/
  https://akaunting.com/hc/docs/developers/settings/
  https://akaunting.com/hc/docs/developers/bulk-actions/
  ```

  Include a `## Published guidance checked against this checkout` section with these exact corrections from the drift audit:

  ```text
  The module package is akaunting/laravel-module, not the former akaunting/module name.
  Modules are Composer-installed and path-mapped; modules/ is not a source-tracked core directory.
  The shipped module manifest surface includes extra-modules and routes in addition to the published field list.
  SettingsCreated exists; do not state that the vanished SettingShowing event exists.
  The API is plain Laravel with app/Http/Resources; do not describe the retired Dingo/transformer stack as current.
  ```

  For every correction, link `specs/northstar/DOCS-DRIFT-AUDIT.md` and name the local evidence file. Preserve the audit's open question: do not state that `SettingsCreated` is a behavioral replacement for `SettingShowing` unless code evidence proves it.

- [ ] **Step 3: Verify Task 5**

  Run:

  ```powershell
  $file = 'docs/product/extensions.md'
  $mustContain = @(
    'Verified against source', 'https://akaunting.com/hc/docs/developers/',
    'akaunting/laravel-module', 'Composer-installed and path-mapped',
    'SettingsCreated', 'app/Http/Resources', 'DOCS-DRIFT-AUDIT.md'
  )
  foreach ($text in $mustContain) {
    if (-not (Select-String -LiteralPath $file -SimpleMatch $text -Quiet)) { throw "Missing extension fact: $text" }
  }
  if (Select-String -LiteralPath $file -Pattern 'TBD|TODO|FIXME' -Quiet) { throw 'Placeholder found in extensions.md' }
  Write-Output 'Extension reference checks: PASS'
  ```

  Expected: the command prints the PASS line without an exception.

- [ ] **Step 4: Commit Task 5**

  ```bash
  git add docs/product/extensions.md
  git commit -m "docs: add verified extension reference"
  ```

## Task 6: Run the documentation acceptance review

**Files:**
- Modify if needed: every file under `docs/product/`
- Test: full documentation-set acceptance review

**Interfaces:**
- Consumes: all eight produced reference pages and the approved design at `docs/superpowers/specs/2026-08-06-product-documentation-design.md`.
- Produces: a self-consistent, navigable, source-cited documentation set ready for the wider Ch0 harness.

- [ ] **Step 1: Run structural and citation checks**

  ```powershell
  $files = @(
    'docs/product/README.md', 'docs/product/concepts.md', 'docs/product/sales.md',
    'docs/product/purchases.md', 'docs/product/banking.md', 'docs/product/reporting.md',
    'docs/product/administration.md', 'docs/product/optional-apps.md',
    'docs/product/extensions.md'
  )
  foreach ($file in $files) {
    if (-not (Test-Path $file)) { throw "Missing required product document: $file" }
    if (-not (Select-String -LiteralPath $file -Pattern 'https://akaunting.com/hc/docs/' -Quiet)) {
      throw "Missing Help Centre citation: $file"
    }
  }
  rg -n "TBD|TODO|FIXME|docs/user-manual|akaunting/module/wiki|Dingo\\Api|app/Transformers" docs/product
  ```

  Expected: every required page exists and has a Help Centre citation; the final scan returns no matches.

- [ ] **Step 2: Review design coverage line by line**

  Compare the produced set with `docs/superpowers/specs/2026-08-06-product-documentation-design.md`. Confirm: every Help Centre area appears in the README matrix; core and optional labels are correct; optional apps are light; extension claims state verification provenance; no page gives step-by-step vendor instructions; and every page links related concepts without contradicting their canonical definition. Correct the affected document immediately if any check fails.

- [ ] **Step 3: Verify the final working tree**

  Run:

  ```powershell
  git diff --check
  git status --short
  ```

  Expected: `git diff --check` exits successfully; `git status --short` shows only the intended `docs/product/` changes, if Task 6 required corrections.

- [ ] **Step 4: Commit the acceptance-review corrections if present**

  ```bash
  git add docs/product
  git diff --cached --quiet || git commit -m "docs: verify product reference coverage"
  ```

## Plan self-review

- The approved design's scope, information architecture, provenance rules, production flow, acceptance criteria, and verification requirements each map to Tasks 1 through 6.
- The plan assigns every listed `docs/product/` file exactly one primary authoring task and one shared acceptance review.
- The coverage matrix includes all 22 Help Centre areas observed on 2026-08-06 and maps each to a local home.
- Searches for `TBD`, `TODO`, and `FIXME` must return no result in the completed document set or this plan.
