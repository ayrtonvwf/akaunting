---
type: workflow
title: Multi-Tenancy & Company Switching
description: Company isolation, multi-company user management, data scoping, and switching between companies.
tags: [workflow, multi-tenancy, companies, users, data-scoping]
---

# Multi-Tenancy & Company Switching

Akaunting supports multi-tenancy at the company level, allowing a single user to manage multiple independent businesses with completely isolated data. This workflow describes how companies are created, users manage multiple companies, and data remains properly scoped.

## Multi-Tenancy Architecture

### Single Company View

Most applications show one company's data:

```
User's Dashboard
└─ Company: "Acme Corp"
   ├─ Invoices: 5
   ├─ Customers: 3
   ├─ Bank Balance: $10,000
   └─ etc.
```

### Akaunting Multi-Tenancy

Akaunting supports multiple companies per user:

```
User: john@example.com
├─ Company 1: "Acme Corp"
│  ├─ Invoices: 5
│  ├─ Customers: 3
│  └─ Bank Balance: $10,000
│
├─ Company 2: "Freelance Business"
│  ├─ Invoices: 12
│  ├─ Customers: 8
│  └─ Bank Balance: $3,500
│
└─ Company 3: "Consulting Firm"
   ├─ Invoices: 2
   ├─ Customers: 1
   └─ Bank Balance: $500
```

Each company is completely independent.

## User & Company Relationships

### User Company Assignment

Users are assigned to companies via the `user_companies` pivot table:

```
Users Table:
├─ John (id=1)
├─ Sarah (id=2)
└─ Mike (id=3)

user_companies Pivot:
├─ john (1) -> Acme Corp (1)
├─ john (1) -> Freelance (2)
├─ sarah (2) -> Acme Corp (1)
└─ mike (3) -> Consulting (3)
```

**Result**:
- John has access to 2 companies
- Sarah has access to 1 company (Acme, alongside John)
- Mike has access to 1 company (Consulting)

### Company Ownership

Companies are owned by one or more users. Owners have full control:

```
is_admin field in user_companies:

John (is_admin=true) -> Acme Corp    (Owner)
Sarah (is_admin=false) -> Acme Corp  (User, but not owner)

john (is_admin=true) -> Freelance    (Owner)
```

**Permissions inherit from is_admin**:
- Owner: Full access, can add/remove users
- User: Limited to assigned permissions

## Workflow: Creating a Company

### Step 1: User Creates Company

**Action**: New Company > Fill Details

```
Company Name:    "Acme Corp"
Email:           "billing@acme.com"
Phone:           "+1-555-0100"
Tax Number:      "123456789"
Currency:        "USD"
Timezone:        "America/New_York"
Address:         "123 Main St, Springfield, IL"
```

**System creates**:
- Company record
- UserCompany pivot (user as owner, is_admin=true)
- Default roles (Owner, Manager, Accountant)
- Default settings (currency, timezone, categories)
- Default categories (Income, Expense)

### Step 2: System Sets Company Context

New company becomes user's active company:

```
URL: /admin/companies/1/dashboard
Session: authenticated_company_id = 1
```

### Step 3: User Invites Collaborators

**Action**: Settings > Users > Invite

```
Email:      john@acme.com
Role:       Manager
Company:    Acme Corp
```

**System**:
1. Sends invitation link
2. Invitee creates account (if new)
3. User accepts invitation
4. UserCompany pivot created
5. Invitee assigned role

**Result**: Collaborator now sees Acme Corp in their company list

## Workflow: Switching Companies

### From UI

**Action**: Click company dropdown in sidebar

```
┌─ Your Companies
├─ Acme Corp ←
├─ Freelance
└─ Consulting
```

Click "Freelance":

```
URL changed: /admin/companies/2/dashboard
Session updated: authenticated_company_id = 2

Freelance data now displayed
├─ Invoices: 12
├─ Customers: 8
└─ Bank Balance: $3,500
```

### From API

Specify company in request or header:

```
GET /api/companies/2/invoices

Response: Invoices from Company 2 only
```

## Data Scoping

### Global Scope Applied

All queries automatically scope to current company:

```php
// Inside controller for Company 2
$invoices = Document::all();

// Translated by global scope:
// SELECT * FROM documents 
// WHERE company_id = 2 
// AND deleted_at IS NULL
```

**Scope applied to**:
- All models with `company_id` column
- API queries
- Controller queries
- Admin interface

### Explicit Scoping

Bypass scope when needed (rare):

```php
// Get all documents across ALL companies
Document::withoutGlobalScope(\App\Scopes\Company::class)->get();

// Get specific company's documents
Document::where('company_id', $companyId)->get();
```

### Isolation Guaranteed

User from Company 1 **cannot** access Company 2 data:

```php
// User in Company 2 requests Company 1 data
GET /api/companies/1/invoices
// Middleware verifies access
// 403 Forbidden (user not assigned to Company 1)
```

## Multi-Company Roles & Permissions

### Per-Company Role Assignment

Same user has different roles in different companies:

```
John:
├─ Acme Corp:       Owner (all permissions)
├─ Freelance:       Manager (most permissions)
└─ Consulting:      Accountant (limited permissions)
```

**Role by company**:
- Acme: create/read/update/delete everything
- Freelance: limited editing, no deletion
- Consulting: read-only access

### Permission Checking

Permission checks happen in company context:

```php
// In Acme Corp context
$user->hasPermission('create-sales-invoices', $acme_company)
// true (Owner has all permissions)

// In Freelance context
$user->hasPermission('delete-sales-invoices', $freelance_company)
// false (Manager cannot delete)

// In Consulting context
$user->hasPermission('read-sales-invoices', $consulting_company)
// true (Accountant can read)
```

## Multi-Company Workflows

### Consolidating Companies

Scenario: User manages separate entities that should merge

**Option 1: Manual Consolidation**
1. Create consolidated company
2. Transfer documents/contacts from other companies (manual)
3. Archive old companies

**Option 2: Keep Separate**
1. Keep as separate companies
2. Generate consolidated reports from multiple companies (if feature enabled)

### Sharing Customer Base

Scenario: Multiple companies serve same customer

**Setup**:
- Create customer in Company 1
- Cannot directly reference in Company 2
- Solution: Create duplicate customer in Company 2 with company-scoped data

**Alternative**: White-label portal allows customer to see invoices from linked company

### Consolidated Reporting

**If feature enabled**:
- View revenue across all companies
- Compare performance
- Merged dashboards

**Current limitation**: Reporting typically per-company

## Company User Management

### Add User to Company

**Action**: Settings > Users > Assign User

```
Select:  Sarah Chen
Role:    Manager
Company: Acme Corp
```

**System**:
1. Verifies Sarah has account
2. Creates UserCompany pivot
3. Assigns Manager role
4. Sarah sees Acme Corp in her company list

### Remove User from Company

**Action**: Settings > Users > Remove

```
Select: Sarah Chen
```

**System**:
1. Deletes UserCompany pivot
2. Sarah no longer sees company
3. Sarah loses all access to company's data

**Important**: Sarah's personal account remains; only access to this company is removed

### Change User Role

**Action**: Settings > Users > Edit Role

```
Sarah's Role: Manager → Accountant
```

**System**:
1. Updates user's roles in this company
2. Sarah immediately loses elevated permissions
3. Sarah retains read-only access (Accountant)

## Source Map

| Concept | File |
|---------|------|
| Company model | `app/Models/Common/Company.php` |
| UserCompany pivot | `app/Models/Auth/UserCompany.php` |
| Company scope | `app/Scopes/Company.php` |
| Company controller | `app/Http/Controllers/Common/Companies.php` |
| Create company job | `app/Jobs/Common/CreateCompany.php` |
| Middleware | `app/Http/Middleware/IdentifyCompany.php` |

## Related Pages

- [Companies & Multi-Tenancy](../systems/common/companies.md) – Company model and API
- [RBAC Integration](../systems/auth/rbac.md) – Roles and permissions
- [Middleware & Routing](../systems/http/middleware.md) – Company identification
