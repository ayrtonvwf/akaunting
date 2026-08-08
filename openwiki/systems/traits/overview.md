---
type: system-reference
title: Traits & Mixins - Reusable Behaviors
description: Reusable trait composition system for models, providing cross-cutting concerns and shared behavior.
tags: [traits, mixins, reusable-behavior, composition]
openwiki:
  source_paths: [app/Traits]
---

# Traits & Mixins - Reusable Behaviors

Traits provide composable, reusable behaviors that are mixed into models without inheritance. They handle cross-cutting concerns and shared functionality.

## Trait Categories

### Document-Related Traits

| Trait | Purpose | Used By |
|-------|---------|---------|
| **Documents** | Document model relationships and scopes | Document model |
| **Recurring** | Recurring document generation schedule | Document model |
| **Transactions** | Transaction relationships and calculations | Document, Transaction models |

See [Document Traits](document-traits.md) for detailed documentation.

### Business Logic Traits

| Trait | Purpose | Used By |
|-------|---------|---------|
| **Permissions** | Permission checking and authorization | User model |
| **Categories** | Category relationship and filtering | Transaction, Document models |
| **Tenants** | Multi-tenancy scoping and company isolation | All models |
| **Scopes** | Query scopes and filtering | Various models |

See [Business Logic Traits](business-logic-traits.md) for detailed documentation.

### Data Management Traits

| Trait | Purpose |
|-------|---------|
| **Import** | CSV/Excel import pipeline and validation |
| **Uploads** | File handling and storage |
| **Media** | Polymorphic attachment system |

### User & Security Traits

| Trait | Purpose |
|-------|---------|
| **HasApiTokens** | API token generation and validation |
| **Users** | User-related relationships |
| **Owners** | Model ownership and creation tracking |
| **Sources** | Track data source (web, api, module) |

### Utility Traits

| Trait | Purpose |
|-------|---------|
| **DateTime** | Date/time formatting and manipulation |
| **Currencies** | Currency conversion and formatting |
| **Charts** | Chart data preparation |
| **Jobs** | Job dispatching utilities |
| **Relationships** | Common relationship definitions |

### System Traits

| Trait | Purpose |
|-------|---------|
| **Companies** | Company multi-tenancy operations |
| **Contacts** | Contact polymorphism |
| **Settings** | Application settings access |
| **Updates** | Update checking and installation |
| **Modules** | Module system integration |

## Using Traits in Models

### Basic Usage

```php
namespace App\Models\Document;

use App\Traits\Documents;
use App\Traits\Recurring;
use App\Traits\Transactions;

class Document extends Model
{
    use Documents;
    use Recurring;
    use Transactions;
    
    // Model implementation
}
```

### Method Resolution

When multiple traits define the same method, use `insteadof`:

```php
use TraitA {
    methodName insteadof TraitB;
}
use TraitB {
    TraitB::methodName as methodNameB;
}
```

## Trait Composition Patterns

### Shared Scopes

```php
// In trait
trait Documents
{
    public function scopeInvoice($query)
    {
        return $query->where('type', 'invoice');
    }
    
    public function scopeBill($query)
    {
        return $query->where('type', 'bill');
    }
}

// In model
Document::invoice()->get();
Document::bill()->get();
```

### Shared Relationships

```php
trait Transactions
{
    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }
}

// Relationships automatically available
$document->transactions;
```

### Shared Calculations

```php
trait Transactions
{
    public function getTotalAmountAttribute()
    {
        return $this->transactions()->sum('amount');
    }
}

// Accessors automatically available
$document->total_amount;
```

## Core Trait: Tenants (Multi-Tenancy)

The **Tenants** trait is fundamental to Akaunting and ensures all models are properly scoped to companies:

```php
trait Tenants
{
    protected static function bootTenants()
    {
        // Automatically scope all queries to current company
        static::addGlobalScope('tenant', function ($query) {
            $query->whereCompanyId(auth()->user()->currentCompany()->id);
        });
    }
}
```

**Effect**: All model queries automatically filtered by `company_id`

```php
// Without explicit scope, only returns current company's documents
Document::all();

// To bypass and query all companies (admin only)
Document::withoutGlobalScopes()->get();
```

## Core Trait: Owners

Tracks who created and last modified each model:

```php
trait Owners
{
    public function owner()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
    
    public function updatedBy()
    {
        return $this->belongsTo(User::class, 'updated_by');
    }
}
```

Automatically sets on creation:
```php
$document->created_by = auth()->id();
$document->created_from = 'web';  // or 'api', 'module'
```

## Trait Dependencies

Some traits depend on others or Laravel features:

```
Documents
  ├─ Tenants (multi-tenancy)
  ├─ Owners (creation tracking)
  └─ Recurring (schedule logic)

Transactions
  ├─ Tenants
  └─ Categories (categorization)

Permissions
  ├─ Laratrust (RBAC package)
  └─ Users
```

## Creating Custom Traits

When adding shared behavior:

```php
namespace App\Traits;

trait CustomBehavior
{
    public function scopeActive($query)
    {
        return $query->where('enabled', true);
    }
    
    public function isActive()
    {
        return $this->enabled;
    }
}

// Then use in model
use CustomBehavior;
```

**Best Practices**:
- One trait per concern
- Keep traits small and focused
- Document dependencies
- Test traits in isolation

## Available Trait Methods

### Documents Trait

```php
$document->contact();      // Relationship
$document->items();        // Relationship
$document->totals();       // Relationship
$document->transactions(); // Relationship
$document->histories();    // Relationship

Document::invoice();       // Scope: invoices only
Document::bill();          // Scope: bills only
Document::status('paid');  // Scope: by status
```

### Recurring Trait

```php
$document->recurring();         // Parent recurring doc
$document->children();          // Auto-generated children
$document->nextRecurringDate(); // When to generate next
$document->generateNext();      // Create next instance
```

### Transactions Trait

```php
$document->transactions();      // Payments received
$document->totalPaid();         // Sum of payments
$document->remainingAmount();   // Still owed
```

### Permissions Trait

```php
$user->can('create', Document::class);
$user->hasRole('accountant');
$user->inRole('admin');
$user->abilities();             // All permissions
```

### Tenants Trait

```php
Model::withoutGlobalScopes()->get();  // All companies
Model::withoutGlobalScope('tenant')->get();  // Specific scope
```

## Related Pages

- [Document Traits](document-traits.md) – Document-specific trait behaviors
- [Business Logic Traits](business-logic-traits.md) – Auth, categories, tenants
- [Models & Relationships](../common/overview.md) – Where traits are used

## Source Map

```
app/Traits/
├─ Documents.php          # Document relationships
├─ Recurring.php          # Recurring schedule
├─ Transactions.php       # Payment tracking
├─ Permissions.php        # RBAC
├─ Categories.php         # Categorization
├─ Tenants.php            # Multi-tenancy
├─ Owners.php             # Creation tracking
├─ HasApiTokens.php       # API auth
├─ Import.php             # Data import
└─ ... (other traits)
```

## Testing & Validation

```bash
# Test trait behavior
php artisan test tests/Feature/Traits/

# Test document trait
php artisan test tests/Feature/Traits/DocumentsTraitTest.php

# Test multi-tenancy
php artisan test tests/Feature/Traits/TenantsTraitTest.php
```

## Common Patterns

### Adding a trait to existing model

1. Add `use TraitName;` to model class
2. Run tests to verify no conflicts
3. Add documentation to related pages

### Testing trait behavior

```php
public function testDocumentScopeWorks()
{
    $invoice = Document::factory()->create(['type' => 'invoice']);
    $bill = Document::factory()->create(['type' => 'bill']);
    
    // Scope works
    $this->assertCount(1, Document::invoice());
    $this->assertCount(1, Document::bill());
}
```

### Multi-trait composition

```php
class Document extends Model
{
    // All these work together
    use Tenants;        // Scope to company
    use Owners;         // Track creator
    use Documents;      // Document relations
    use Recurring;      // Schedule
    use Transactions;   // Payments
}
```
