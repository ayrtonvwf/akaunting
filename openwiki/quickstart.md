---
type: wiki-entry
title: Akaunting Wiki - Quickstart
description: Navigate Akaunting's architecture, systems, APIs, and workflows for developing, extending, and understanding the accounting software.
---

# Akaunting Wiki - Quickstart

Welcome to the Akaunting code wiki. This guide helps you navigate the repository architecture, understand system boundaries, and find the source code, tests, and validation paths for any feature or change.

## What is Akaunting?

**Akaunting** is a modern, open-source accounting software built with Laravel 10, VueJS 2, and Tailwind CSS. It enables small businesses and freelancers to:

- Create and manage invoices, bills, and recurring documents
- Track income and expenses through bank transactions
- Reconcile bank accounts
- Generate financial reports and dashboards
- Manage contacts, items/products, and company settings
- Extend functionality through a modular app store

The system is **multi-tenant at the company level** (multiple independent companies per user), supports **role-based access control**, and provides both **web and RESTful API** interfaces.

---

## Core Architecture at a Glance

```
┌─────────────────────────────────────────────────────────────────┐
│                     HTTP & API Layer                             │
│  Routes (admin, api, portal, wizard) → Controllers → Jobs        │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│              Business Logic & Services                           │
│  Jobs (Create/Update/Delete) → Events → Listeners & Observers   │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                    Data Models & Traits                          │
│  Company | Document | Transaction | Contact | Account | Item    │
│  + Shared traits: Documents, Transactions, Media, DateTime       │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│               Database (MySQL/PostgreSQL/SQLite)                 │
│  Multi-tenancy via company_id, soft deletes, audit trails       │
└─────────────────────────────────────────────────────────────────┘
```

### Key Principles

1. **Multi-Tenancy**: All data scoped by `company_id`; users own multiple companies
2. **Event-Driven**: Jobs dispatch events; listeners create side effects (audit trails, notifications)
3. **Job-Dispatch Pattern**: Controllers dispatch jobs instead of direct model manipulation
4. **Trait-Based Composition**: Reusable behavior via traits (Documents, Transactions, Media, etc.)
5. **API-First**: Web forms and API endpoints share identical validation and job logic

---

## Navigation Map

### By Intent

| Intent | Primary Pages | Key Code |
|--------|---------------|----------|
| **Create an invoice** | [Invoices & Documents](systems/documents/invoices.md) | `App\Http\Controllers\Sales\Invoices`, `App\Jobs\Document\CreateDocument` |
| **Record a bank transaction** | [Banking](systems/banking/overview.md) | `App\Http\Controllers\Banking\Transactions`, `App\Jobs\Banking\CreateTransaction` |
| **Reconcile bank accounts** | [Bank Reconciliation](systems/banking/reconciliation.md) | `App\Models\Banking\Reconciliation`, `App\Jobs\Banking\CreateReconciliation` |
| **Manage customers/vendors** | [Contacts](systems/common/contacts.md) | `App\Http\Controllers\Common\Contacts`, `App\Models\Common\Contact` |
| **Add a company** | [Companies & Multi-Tenancy](systems/common/companies.md) | `App\Http\Controllers\Common\Companies`, `App\Jobs\Common\CreateCompany` |
| **Configure taxes & categories** | [Settings](systems/settings/overview.md) | `App\Http\Controllers\Settings\*`, `App\Models\Setting\*` |
| **Build a report** | [Reports & Dashboards](systems/reports.md) | `App\Models\Common\Report`, `App\Http\Controllers\Common\Reports` |
| **Create custom invoice template** | [Documents](systems/documents/overview.md) | `App\Models\Document\Document` templates & styling |
| **Extend via API** | [RESTful API](systems/api/overview.md) | `routes/api.php`, `App\Http\Controllers\Api\*` |
| **Build a module** | [Module Development](systems/modules/development.md) | `modules/OfflinePayments/`, Akaunting\Module base |
| **Handle user roles & permissions** | [RBAC & Auth](systems/auth/rbac.md) | `App\Models\Auth\Role`, Laratrust integration |
| **Send email notifications** | [Events & Listeners](systems/events.md) | `App\Events\*`, `App\Listeners\*` |
| **Bulk import data** | [Import System](systems/data/imports.md) | `App\Traits\Import`, Maatwebsite Excel |
| **Export to Excel/CSV** | [Export System](systems/data/exports.md) | `App\Exports\*`, `App\Jobs\Common\CreateMediableForExport` |

---

## System Guide

### Foundations
- **[Configuration](configuration.md)** – Application settings, currencies, taxes, and feature flags
- **[Testing](testing.md)** – Test infrastructure, patterns, and running the test suite
- **[Middleware & Routing](systems/http/middleware.md)** – Request lifecycle, company identification, authentication

### Data Domains

- **[Auth System](systems/auth/overview.md)** – Users, roles, permissions, API tokens
  - [RBAC Integration](systems/auth/rbac.md) – Permission checking, policy authorization
  - [API Authentication](systems/api/authentication.md) – Bearer tokens, Basic auth, OAuth

- **[Common Domain](systems/common/overview.md)** – Shared entities: companies, contacts, items, reports, dashboards
  - [Companies & Multi-Tenancy](systems/common/companies.md) – Multi-company architecture, company switching
  - [Contacts](systems/common/contacts.md) – Customers and vendors as polymorphic contacts
  - [Items (Products/Services)](systems/common/items.md) – Line item catalog with taxes

- **[Documents](systems/documents/overview.md)** – Invoices, bills, recurring documents
  - [Invoices & Sales](systems/documents/invoices.md) – Creating, sending, paying invoices
  - [Bills & Purchases](systems/documents/bills.md) – Bills, purchase orders, payment tracking
  - [Recurring Documents](systems/documents/recurring.md) – Auto-generation schedule and lifecycle
  - [Document Calculations](systems/documents/totals.md) – Amounts, taxes, discounts, rounding

- **[Banking](systems/banking/overview.md)** – Bank accounts, transactions, transfers, reconciliation
  - [Accounts](systems/banking/accounts.md) – Bank account management
  - [Transactions](systems/banking/transactions.md) – Income and expense entries
  - [Transfers](systems/banking/transfers.md) – Inter-account transfers
  - [Reconciliation](systems/banking/reconciliation.md) – Bank statement matching
  - [Recurring Transactions](systems/banking/recurring.md) – Automated recurring entries

- **[Settings](systems/settings/overview.md)** – Currencies, taxes, categories, email templates
  - [Currencies](systems/settings/currencies.md) – Multi-currency configuration
  - [Taxes](systems/settings/taxes.md) – Tax rules and definitions
  - [Categories](systems/settings/categories.md) – Transaction categories

### HTTP & API

- **[Middleware & Routing](systems/http/middleware.md)** – Request lifecycle, company identification, authentication
- **[Controllers Overview](systems/http/controllers.md)** – Request handlers for web and API
- **[Form Validation](systems/http/validation.md)** – Request validation rules and custom validators
- **[API Resources](systems/http/resources.md)** – Data transformation for API responses
- **[Livewire Components](systems/http/livewire.md)** – Real-time, serverless UI components
- **[RESTful API](systems/api/overview.md)** – Complete API reference
  - [Endpoints Reference](systems/api/endpoints.md) – All routes, methods, parameters, examples
  - [Authentication](systems/api/authentication.md) – API token and OAuth setup
  - [Response Formats](systems/api/responses.md) – Success/error response structures

### Business Logic

- **[Jobs & Dispatching](systems/jobs/overview.md)** – Async/sync job processing for create/update/delete operations
  - [Auth Jobs](systems/jobs/auth-jobs.md) – User and permission management
  - [Document Jobs](systems/jobs/document-jobs.md) – Document lifecycle operations
  - [Banking Jobs](systems/jobs/banking-jobs.md) – Transaction and account operations

- **[Events & Listeners](systems/events.md)** – Event-driven architecture, audit trails, side effects
- **[Traits & Mixins](systems/traits/overview.md)** – Reusable behaviors across models
  - [Document Traits](systems/traits/document-traits.md) – Document-specific operations
  - [Business Logic Traits](systems/traits/business-logic-traits.md) – Permissions, transactions, categories

### Data Processing

- **[Data Processing Overview](systems/data/overview.md)** – Import/export infrastructure and pipelines
  - [Bulk Import](systems/data/imports.md) – CSV/Excel import pipeline with validation
  - [Bulk Export](systems/data/exports.md) – Document and report exports
- **[Reports & Analytics](systems/reports.md)** – Custom report builder, saved reports, widgets

### Frontend & Styling

- **[Frontend Overview](systems/frontend/overview.md)** – Vue.js, Tailwind, component architecture
- **[Vue Components](systems/frontend/vue-components.md)** – Form handling, validation, date/money pickers
- **[Styling Guide](systems/frontend/tailwind-styles.md)** – Custom Tailwind configuration, themes

### Extensibility

- **[Module System](systems/modules/overview.md)** – Built-in and third-party extensions
- **[Module Development](systems/modules/development.md)** – Creating custom modules with routes, controllers, events

---

## Cross-System Workflows

- **[Invoice Workflow](workflows/invoice-workflow.md)** – Create → Send → Receive Payment → Reconcile
- **[Expense Workflow](workflows/expense-workflow.md)** – Record Expense → Match Bill → Pay
- **[Bank Reconciliation Workflow](workflows/bank-reconciliation.md)** – Import Transactions → Match → Reconcile
- **[Multi-Tenancy & Company Switching](workflows/multi-tenancy.md)** – Company isolation, data scoping, user permissions
- **[Permission Checking Workflow](workflows/permissions-workflow.md)** – RBAC enforcement, policy-based authorization

---

## Common Development Tasks

### Adding a New API Endpoint

1. Define route in `routes/api.php`
2. Create or extend controller in `App\Http\Controllers\Api\*`
3. Create form request validation in `App\Http\Requests\*`
4. Create or extend API resource in `App\Http\Resources\*`
5. Write tests in `tests/Feature/` or `tests/Unit/`
6. Reference: [API Endpoints](systems/api/endpoints.md)

### Creating a New Document Type

1. Define type in `config/type.php`
2. Extend document creation/display in `App\Http\Controllers\Sales\*` or `Purchases\*`
3. Create custom job classes if needed
4. Add event listeners for document lifecycle
5. Reference: [Documents](systems/documents/overview.md)

### Adding a New Job (Business Operation)

1. Create job class in `App\Jobs\*` extending `App\Abstracts\Job`
2. Dispatch from controller via `$this->dispatch(new MyJob($data))`
3. Fire events for audit trail and side effects
4. Add event listeners in `App\Providers\Event`
5. Reference: [Jobs](systems/jobs/overview.md)

### Building a Module

1. Create module directory under `modules/YourModule`
2. Define routes in `Routes/admin.php` or `Routes/portal.php`
3. Create controllers, models, jobs following same patterns as core
4. Register in `module.json`
5. Reference: [Module Development](systems/modules/development.md)

### Adding Permission Checks

1. Define permission constants in `config/type.php` under `permission` key
2. Use in middleware: `'permission:create-common-companies'`
3. Check in controllers: `$this->authorize('create', Company::class)`
4. Reference: [RBAC Integration](systems/auth/rbac.md)

---

## File Navigation Cheat Sheet

| Purpose | Path | Example |
|---------|------|---------|
| Models | `/app/Models/{Domain}/` | `Model\Document`, `Auth\User`, `Banking\Account` |
| Controllers (Web) | `/app/Http/Controllers/{Domain}/` | `Sales\Invoices`, `Banking\Accounts` |
| Controllers (API) | `/app/Http/Controllers/Api/{Domain}/` | `Api\Document\Documents`, `Api\Banking\Accounts` |
| Requests | `/app/Http/Requests/{Domain}/` | `Document\Document`, `Banking\Account` |
| Resources (API) | `/app/Http/Resources/{Domain}/` | `Document\Document`, `Banking\Account` |
| Jobs | `/app/Jobs/{Domain}/` | `Document\CreateDocument`, `Banking\CreateAccount` |
| Events | `/app/Events/{Domain}/` | `Document\DocumentCreated`, `Banking\TransactionCreated` |
| Listeners | `/app/Listeners/{Domain}/` | `Document\CreateDocumentCreatedHistory` |
| Traits | `/app/Traits/` | `Documents`, `Transactions`, `Permissions` |
| Views (Blade) | `/resources/views/` | `sales/invoices/index.blade.php` |
| Vue Components | `/resources/assets/js/` | Various form components |
| Routes | `/routes/` | `admin.php` (web), `api.php` (REST) |
| Config | `/config/` | `type.php`, `money.php`, `laratrust.php` |
| Tests | `/tests/Feature/` or `/Unit/` | Feature and unit test suites |
| Migrations | `/database/migrations/` | Schema changes |
| Modules | `/modules/` | `OfflinePayments/`, `PaypalStandard/` |

---

## Testing & Validation

### Running Tests

```bash
# All tests
php artisan test

# Feature tests only
php artisan test tests/Feature

# With coverage
php artisan test --coverage
```

### Test Structure

- **Feature Tests**: Test complete workflows (user creates invoice, payment recorded)
- **Unit Tests**: Test isolated components (model calculations, utility functions)
- **Module Tests**: Each module has its own test suite in `modules/*/Tests/`

Reference: [Testing Guide](testing.md)

---

## Terminology & Glossary

| Term | Meaning |
|------|---------|
| **Document** | Generic invoice or bill; concrete type determined by `type` field (`invoice`, `bill`, `invoice-recurring`, `bill-recurring`) |
| **Contact** | Customer or vendor; polymorphic entity with optional person details |
| **Transaction** | Bank entry (income/expense/transfer); distinct from document payments |
| **Company** | Tenant/business entity; user can own multiple companies, each with isolated data |
| **Account** | Bank account; holds transactions |
| **Reconciliation** | Matching bank statement transactions to recorded transactions |
| **Recurring** | Auto-generated based on schedule (documents or transactions) |
| **Job** | Dispatchable class for create/update/delete operations; fires events |
| **Event** | Fired by jobs and models to trigger listeners and audit trails |
| **Listener** | Handles events; side effects include notifications, history creation |
| **Module** | Third-party or bundled extension; full Laravel module with routes, controllers, models |
| **Permission** | RBAC primitive; `create-common-companies`, `read-sales-invoices`, etc. |
| **Role** | Named group of permissions; assigned to users per company |

---

## Useful Commands

```bash
# Clear all caches
php artisan cache:clear

# Run migrations
php artisan migrate

# Seed sample data
php artisan sample-data:seed

# Generate IDE helper for autocomplete
php artisan ide-helper:generate

# List all routes
php artisan route:list

# Install/update modules
php artisan module:install {alias}
php artisan module:enable {alias}
php artisan module:disable {alias}

# Export data
php artisan export:documents --type=invoice

# Import data
php artisan import:documents --file=import.xlsx
```

---

## Getting Help

- **Wiki Pages**: Navigate the [systems guide](#system-guide) for detailed documentation
- **Source Code**: Models, controllers, jobs, and tests are the source of truth
- **Tests**: Look for focused tests demonstrating expected behavior
- **Configuration**: `config/type.php`, `config/laratrust.php` define document types, permissions

---

## Quick Links

- [GitHub Repository](https://github.com/akaunting/akaunting)
- [Official Documentation](https://akaunting.com/hc/docs)
- [Developer Portal](https://developer.akaunting.com)
- [Forum Support](https://akaunting.com/forum)

---

*Generated by OpenWiki. Last updated: 2024*
