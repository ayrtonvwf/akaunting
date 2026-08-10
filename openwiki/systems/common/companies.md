---
type: system-domain
title: Companies & Multi-Tenancy
description: Multi-company architecture, company isolation, company switching, and user-company relationships in Akaunting.
tags: [multi-tenancy, companies, data-scoping, users]
---

# Companies & Multi-Tenancy

Akaunting is **multi-tenant at the company level**. A single user can own and manage multiple independent companies, each with isolated data (documents, contacts, accounts, etc.). All data is scoped by `company_id`.

## Core Model: Company

**File**: `App\Models\Common\Company`
**Table**: `companies`

### Attributes

```
id, domain, name, email, phone, tax_number, address, 
country, state, city, zip_code, currency, timezone,
created_at, updated_at, deleted_at
```

### Key Fields

- **domain**: Subdomain or company identifier (for white-label deployments)
- **name**: Company legal name
- **email**: Company contact email
- **tax_number**: VAT or tax ID
- **currency**: Default currency code (USD, EUR, GBP)
- **timezone**: Company timezone for date/time calculations

### Relationships

```php
$company->users;              // BelongsToMany: Users with access
$company->documents;          // HasMany: Invoices/bills
$company->transactions;       // HasMany: Banking transactions
$company->accounts;           // HasMany: Bank accounts
$company->contacts;           // HasMany: Customers/vendors
$company->items;              // HasMany: Products/services
$company->reports;            // HasMany: Saved reports
$company->dashboards;         // HasMany: Custom dashboards
$company->settings;           // HasMany: Company-specific settings
```

## User-Company Relationships

### UserCompany Pivot

**Model**: `App\Models\Auth\UserCompany`
**Table**: `user_companies` (pivot)

**Fields**:
```
id, user_id, company_id, is_admin, created_at, updated_at
```

Associates users to companies. The `is_admin` flag indicates if user is owner/admin of the company.

### Querying User's Companies

```php
$user->companies;           // All companies user has access to
$user->companies()->get();  // Eager-loaded relationships

// Get a specific company
$company = $user->companies()->find($companyId);
```

### Current Company Context

During a request, the system maintains current company context:

```php
auth()->user()->currentCompany();     // Active company
auth()->user()->company_id;           // Shortcut to ID
```

**How determined**:
1. From route parameter (e.g., `/admin/companies/{company_id}/invoices`)
2. From session (persisted when user switches company)
3. First company in user's list (default)

## Company Switching

Users can switch between their companies in the UI:

1. Dropdown menu in sidebar: "Switch Company"
2. Click desired company
3. Session updated with new `company_id`
4. Data scoped to new company

**URL pattern**: `/admin/companies/{company_id}/dashboard`

**Session key**: `authenticated_company_id` or similar (framework-dependent)

## Data Scoping

### Global Scope

All queries are scoped by company via Eloquent global scope:

**Scope class**: `App\Scopes\Company` (or similar)

When you query:
```php
Document::all();
```

It automatically filters to:
```php
Document::where('company_id', auth()->user()->currentCompany()->id)->get();
```

**Where applied**:
- Models with `company_id` column automatically filtered
- API endpoints inherit scope
- Controllers inherit scope

**Exception**: Queries from console commands or background jobs may need explicit company context.

### Removing Scope

If needed, bypass scope:

```php
Document::withoutGlobalScope(\App\Scopes\Company::class)->all();
```

## Company Creation

**Controller**: `App\Http\Controllers\Common\Companies`
**Job**: `App\Jobs\Common\CreateCompany`

### Flow

1. User submits company creation form
2. Controller validates with `App\Http\Requests\Common\Company`
3. Controller dispatches `CreateCompany` job
4. Job creates `Company` record
5. Job creates `UserCompany` pivot (sets creator as owner)
6. Job initializes company settings (currency, timezone, defaults)
7. Job fires `CompanyCreated` event
8. Listeners create default roles, permissions, categories, etc.

### Minimum Required Fields

```php
[
    'name' => 'My Business',
    'email' => 'business@example.com',
    'currency' => 'USD',
]
```

### API Endpoint

```
POST /api/companies

{
  "name": "My Business",
  "email": "business@example.com",
  "phone": "+1234567890",
  "tax_number": "123456789",
  "address": "123 Main St",
  "city": "New York",
  "state": "NY",
  "zip_code": "10001",
  "country": "US",
  "currency": "USD",
  "timezone": "America/New_York"
}
```

## Company Settings

Company-level settings are stored in the `settings` table, scoped by `company_id`:

```php
$company->setting('company.default_currency');  // USD
$company->setting('tax.default_calculation');   // exclusive
$company->setting('localisation.date_format');  // YYYY-MM-DD
```

**Common settings**:
- `company.default_currency` – Default currency
- `company.timezone` – Company timezone
- `company.tax_number` – Tax ID
- `tax.default_calculation` – inclusive/exclusive
- `localisation.*` – Date/number/language formats

## Authorization

**Permissions**:
- `read-common-companies` – View companies
- `create-common-companies` – Create new company
- `update-common-companies` – Edit company details
- `delete-common-companies` – Delete company

**User ownership**: Only company owner (or admin with permission) can access/edit company.

## API Operations

**REST Endpoints**:

```
GET    /api/companies                    – List user's companies
GET    /api/companies/{id}               – Get company details
POST   /api/companies                    – Create company
PUT    /api/companies/{id}               – Update company
DELETE /api/companies/{id}               – Delete (soft delete)
```

**Response**: Returns `Company` resource with all company details.

## Company Deletion

Companies are soft-deleted, preserving audit trails:

```php
$company->delete();  // Sets deleted_at
$company->restore(); // Restores company
```

**Impact**:
- Company hidden from user's company list
- All related documents/transactions preserved
- Can be permanently purged if needed

## Multi-Company Features

### Cross-Company Reporting

Users with multiple companies can view consolidated reports:
- Total revenue across companies
- Comparison reports
- Merged dashboards

### Company-Level User Management

Each company has its own set of users and roles:

```php
// Users in Company A
$companyA->users;

// Users in Company B
$companyB->users;

// Same user can have different roles in different companies
$user->hasRole('Owner', $companyA);      // Owner in A
$user->hasRole('Accountant', $companyB); // Accountant in B
```

## Source Map

| Concept | File |
|---------|------|
| Company model | `app/Models/Common/Company.php` |
| Company controller | `app/Http/Controllers/Common/Companies.php` |
| Create job | `app/Jobs/Common/CreateCompany.php` |
| Company scope | `app/Scopes/Company.php` |
| Request validation | `app/Http/Requests/Common/Company.php` |
| API resource | `app/Http/Resources/Common/Company.php` |
| Events | `app/Events/Common/Company*.php` |

## Common Workflows

### Create Company and Set Up

```php
// 1. Create company
$company = $this->dispatch(new CreateCompany(
    auth()->user(),
    [
        'name' => 'My Business',
        'email' => 'business@example.com',
        'currency' => 'USD',
    ],
    auth()->user()
));

// 2. System automatically creates:
// - Default roles (Owner, Manager, Accountant)
// - Default settings
// - Linking user as owner

// 3. Switch to company
auth()->user()->update(['company_id' => $company->id]);
```

### Add User to Company

```php
// In company user management
$company->users()->attach($user->id, ['is_admin' => false]);

// Assign role in company
$user->attachRole('Accountant', $company->id);
```

### Switch Company Context

```php
// In user preferences or route
auth()->user()->update(['authenticated_company_id' => $company->id]);

// Or set in session
session(['authenticated_company_id' => $company->id]);
```

## Testing

**Feature tests**: `/tests/Feature/Common/CompaniesTest.php`

Key test cases:
- Create company
- Switch between companies
- Data isolation (invoice in company A not visible in company B)
- User permissions per company
- Delete company (soft delete)

---

## Related Pages

- [Contacts](contacts.md) – Customer/vendor management
- [RBAC Integration](../auth/rbac.md) – Role and permission assignment
- [Multi-Tenancy Workflow](../../workflows/multi-tenancy.md) – Complete multi-tenancy flow
