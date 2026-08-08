---
type: system-overview
title: Common Domain - Shared Entities
description: Core shared entities in Akaunting including companies, contacts, items, dashboards, and reports.
tags: [common, domain, entities, multi-tenancy]
---

# Common Domain Overview

The Common Domain contains core, multi-tenant entities shared across all business functions: companies, contacts, items, dashboards, and reports. These entities provide the foundational data structures for invoicing, banking, and other accounting operations.

## Core Models

### Company (App\Models\Common\Company)

The primary tenant entity. Represents a business or organization. All other entities are scoped to company_id.

**Attributes**:
```
id, domain, name, email, phone, tax_number, address, country, state, city, zip_code, 
currency, timezone, created_at, updated_at, deleted_at
```

**Key Relationships**:
```php
$company->users;              // HasMany users with access
$company->documents;          // HasMany documents (invoices/bills)
$company->transactions;       // HasMany banking transactions
$company->accounts;           // HasMany bank accounts
$company->contacts;           // HasMany customers/vendors
$company->items;              // HasMany products/services
$company->reports;            // HasMany saved reports
$company->dashboards;         // HasMany custom dashboards
```

**Company Settings**:
Settings stored in `settings` table with company_id scope.
```php
$company->setting('company.default_currency');  // USD, EUR, etc.
$company->setting('tax.default_calculation');   // exclusive, inclusive, compound
```

### Contact (App\Models\Common\Contact)

Represents a customer or vendor. Polymorphic to support both types.

**Attributes**:
```
id, company_id, type (customer|vendor), name, email, phone, website, 
tax_number, currency_code, enabled, created_at, updated_at
```

**Address Fields** (stored as attributes):
- address, country, state, city, zip_code

**Key Relationships**:
```php
$contact->contact_persons;    // HasMany: People (names) at this contact
$contact->documents;          // HasMany: Invoices/bills for/from this contact
$contact->transactions;       // HasMany: Banking transactions
$contact->user;               // BelongsTo: Linked user account (if vendor/customer is also a user)
```

**Scopes**:
```php
Contact::customer();          // Only customers
Contact::vendor();            // Only vendors
```

### ContactPerson (App\Models\Common\ContactPerson)

Individual people at a contact (e.g., sales manager, accountant).

**Attributes**:
```
id, contact_id, name, email, phone
```

**Usage**: When sending invoices/bills, specific contact persons can be CC'd or notified.

### Item (App\Models\Common\Item)

Products or services used in document line items. Catalog entry.

**Attributes**:
```
id, company_id, name, description, quantity, unit, price, 
category_id, tax_id, enabled, created_at, updated_at
```

**Key Relationships**:
```php
$item->document_items;        // HasMany: Document line items using this item
$item->taxes;                 // BelongsToMany: Applied taxes
```

**Scopes**:
```php
Item::enabled();              // Only active items
```

When creating a document, items can be selected from catalog or created inline. If from catalog, price and taxes are pre-filled from item definition.

### Dashboard (App\Models\Common\Dashboard)

Customizable dashboard with user-selected widgets.

**Attributes**:
```
id, company_id, name, user_id, enabled, created_at, updated_at
```

**Key Relationships**:
```php
$dashboard->widgets;          // HasMany: Widget configurations
$dashboard->users;            // BelongsToMany: Users assigned to dashboard
```

**Widget Definition**: Widgets are UI components (charts, stats) configured in dashboard.
```php
$dashboard->widgets()->create([
    'name' => 'revenue_chart',
    'position' => 1,
    'options' => ['period' => 'monthly'],
]);
```

### Widget (App\Models\Common\Widget)

Individual dashboard component. Can be a chart, stat card, list, etc.

**Attributes**:
```
id, dashboard_id, name, position, options (JSON), data, created_at, updated_at
```

**Widget Types** (defined in code):
- Revenue, expense charts
- Account balance stats
- Invoice summary (paid/unpaid)
- Transaction list
- Custom HTML

**Data Rendering**: Widget `getData()` method fetches and caches data.

### Report (App\Models\Common\Report)

Saved report definition with filters, grouping, and columns.

**Attributes**:
```
id, company_id, name, class (report type), columns, filter (JSON), 
group (JSON), enabled, created_at, updated_at
```

**Report Classes** (in `App\Reports\`):
- IncomeReport
- ExpenseReport
- ProfitLossReport
- BalanceSheetReport
- CashFlowReport
- TransactionReport
- Custom reports

**Flow**:
1. User selects report class and filters
2. Report class queries database with filters
3. Results grouped and totaled per config
4. HTML, PDF, or CSV output generated

---

## Controllers

### Companies Controller

**Routes** (in `routes/admin.php`):
```
GET    /admin/common/companies           – List all companies
GET    /admin/common/companies/create    – Create form
POST   /admin/common/companies           – Store new company
GET    /admin/common/companies/{id}      – View company
GET    /admin/common/companies/{id}/edit – Edit form
PATCH  /admin/common/companies/{id}      – Update
DELETE /admin/common/companies/{id}      – Delete
GET    /admin/common/companies/{id}/switch – Switch to company
GET    /admin/common/companies/{id}/enable – Enable company
GET    /admin/common/companies/{id}/disable – Disable company
```

**Jobs**:
- `CreateCompany`: Creates company record and assigns to user
- `UpdateCompany`: Updates company settings
- `DeleteCompany`: Soft-deletes company and related data

### Contacts Controller

**Routes** (in `routes/admin.php`):
```
GET    /admin/common/contacts             – List contacts
POST   /admin/common/contacts             – Store contact
PATCH  /admin/common/contacts/{id}        – Update contact
DELETE /admin/common/contacts/{id}        – Delete contact
GET    /admin/common/contacts/autocomplete – AJAX autocomplete
```

**Features**:
- Autocomplete for contact lookup
- Bulk import/export of contacts
- Duplicate contact for quick creation

### Items Controller

**Routes** (in `routes/admin.php`):
```
GET    /admin/common/items             – List items
POST   /admin/common/items             – Store item
PATCH  /admin/common/items/{id}        – Update item
DELETE /admin/common/items/{id}        – Delete item
GET    /admin/common/items/autocomplete – AJAX autocomplete
```

**Features**:
- Item catalog management
- Tax pre-assignment
- Enable/disable items
- Bulk import/export

### Dashboards Controller

**Routes**:
```
GET    /admin/common/dashboards         – List dashboards
POST   /admin/common/dashboards         – Create dashboard
PATCH  /admin/common/dashboards/{id}    – Update dashboard
DELETE /admin/common/dashboards/{id}    – Delete dashboard
GET    /admin/common/dashboards/{id}/enable – Make default
```

**Features**:
- Multiple dashboards per company
- Drag-and-drop widget layout
- Share dashboards with team members

### Reports Controller

**Routes**:
```
GET    /admin/common/reports            – List saved reports
POST   /admin/common/reports            – Save new report
GET    /admin/common/reports/{id}       – View report
GET    /admin/common/reports/{id}/pdf   – Export PDF
GET    /admin/common/reports/{id}/export – Export Excel
PATCH  /admin/common/reports/{id}       – Update report filters
DELETE /admin/common/reports/{id}       – Delete report
```

**Features**:
- Dynamic report builder UI
- Save frequently-used report filters
- Export to PDF, Excel, CSV
- Scheduled report delivery (via jobs)

---

## Key Traits

### Contacts Trait

Shared behavior for models with contact relationships.

```php
use App\Traits\Contacts;

// Provides methods:
$model->contact();            // Relationship to contact
$model->getContactName();     // Get contact display name
$model->scopeContact($query, $contact_id);  // Filter by contact
```

### Companies Trait

Behavior for company management.

```php
use App\Traits\Companies;

// Provides methods:
$model->company();            // Relationship to company
$model->makeCurrent();        // Set as current company in session
$model->scopeCompany($query); // Filter to current company
```

---

## Multi-Tenancy Architecture

All Common Domain entities are scoped to company_id via global scope `App\Scopes\Company`:

```php
// Automatically filters to current company
$contacts = Contact::all();  // Only current company's contacts

// Bypass scope if needed (careful!)
$all_contacts = Contact::allCompanies()->get();
```

**Company Identification Middleware** (`App\Http\Middleware\IdentifyCompany`):
1. Extracts company_id from URL or session
2. Sets current company context
3. Validates user has access to company

---

## Events & Listeners

Common Domain fires events for side effects:

```php
CompanyCreated -> [CreateDefaultSettings, SetupDefaultCurrency]
CompanyUpdated -> [UpdateCompanySettings]
ContactCreated -> [CreateContactHistory]
ItemCreated -> [CreateItemHistory]
DashboardCreated -> [CreateDefaultWidgets]
```

Listeners handle:
- Audit trail creation
- Settings initialization
- Notification sending
- Side-effect workflows

---

## Bulk Operations

### Import

Import contacts, items, or companies from CSV/Excel:

```php
POST /admin/common/{resource}/import
```

**Process**:
1. Upload CSV file
2. Map columns to fields
3. Validate data
4. Batch create records

### Export

Export contacts, items, reports to Excel/CSV:

```php
GET /admin/common/{resource}/export
```

**Process**:
1. Query records
2. Transform to spreadsheet format
3. Generate file download
4. Store export history (optional)

---

## API Resources

API responses transform models via Resource classes:

```php
// App\Http\Resources\Common\Company
return CompanyResource::make($company);

// Response structure:
{
  "data": {
    "id": 1,
    "name": "Acme Corp",
    "email": "info@acme.com",
    "currency": "USD",
    "created_at": "2024-01-01T00:00:00Z",
    "relationships": { ... }
  }
}
```

---

## Best Practices

1. **Always Filter by Company**: Use global scope or explicit where clause
2. **Soft Delete**: Archive entities instead of permanent delete
3. **Validate Contacts**: Ensure email and tax_number are valid
4. **Item Pricing**: Update catalog prices carefully; old documents preserve historical prices
5. **Report Performance**: Use eager loading for complex reports; cache results

---

## Testing Common Domain

```php
// Factory usage
$company = Company::factory()->create();
$contact = Contact::factory()->for($company)->customer()->create();
$item = Item::factory()->for($company)->create();
$dashboard = Dashboard::factory()->for($company)->create();

// Test company switching
$this->loginAs($user, $company);
$this->assertEquals(company_id(), $company->id);

// Test contact filtering
$response = $this->getJson(route('api.contacts.index'));
$this->assertCount($company->contacts()->count(), $response['data']);
```

---

*Reference: /app/Models/Common, /app/Http/Controllers/Common, /app/Jobs/Common*
