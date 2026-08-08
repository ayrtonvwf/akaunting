---
type: system-reference
title: Transaction Categories
description: Income and expense category configuration, classification, and reporting in Akaunting.
tags: [categories, income, expenses, classification, reporting]
---

# Transaction Categories

Categories classify income and expense transactions for organization and reporting. They enable profit & loss analysis, budget tracking, and financial statement generation.

## Category Model

**File**: `App\Models\Setting\Category`
**Table**: `categories`

### Attributes

```
id, company_id, type (income|expense), name, enabled, created_at, updated_at, deleted_at
```

### Key Fields

- **type**: `income` (revenue) or `expense` (costs)
- **name**: Category name (e.g., "Sales", "Utilities", "Consulting")
- **enabled**: Whether category is active

## Category Types

### Income Categories

Classify revenue sources:

- Sales
- Consulting
- Subscription Revenue
- Interest Income
- Grants
- Refunds Received
- etc.

### Expense Categories

Classify costs:

- Utilities (Electricity, Gas, Water)
- Salaries & Payroll
- Office Supplies
- Travel
- Rent
- Insurance
- Marketing
- Maintenance
- Professional Fees
- etc.

## Creating Categories

### Via API

```json
POST /api/settings/categories

{
  "type": "expense",
  "name": "Office Supplies",
  "enabled": true
}
```

### Via Controller

```php
Category::create([
    'company_id' => auth()->user()->currentCompany()->id,
    'type' => 'income',
    'name' => 'Consulting Revenue',
    'enabled' => true,
]);
```

## Using Categories in Transactions

When recording transaction, select category:

```php
[
    'type' => 'expense',
    'category_id' => $utilities_category->id,
    'amount' => -150.00,
    'description' => 'Electric bill',
]
```

## Category-Based Reporting

### Profit & Loss Statement

Revenue and expenses aggregated by category:

```
Income:
  Sales              $50,000
  Consulting         $15,000
  Interest            $2,000
─────────────────
Total Income:       $67,000

Expenses:
  Salaries          $30,000
  Rent               $3,000
  Utilities          $1,200
  Office Supplies      $500
─────────────────
Total Expenses:    $34,700

Net Income:        $32,300
```

### Budget vs. Actual

Track spending against budget:

```
Utilities:
  Budget:        $1,500/month
  Actual (Jan):  $1,823
  Variance:      +$323 (over)

Supplies:
  Budget:        $500/month
  Actual (Jan):  $312
  Variance:      -$188 (under)
```

### Expense Analysis

Percentage breakdown of expenses:

```
Total Expenses: $34,700

Salaries:           86.5%
Rent:               8.6%
Utilities:          3.5%
Office Supplies:    1.4%
```

## Default Categories

Most installations include default categories:

**Income**:
- Sales
- Services
- Refunds

**Expense**:
- General
- Utilities
- Salaries
- Travel

## Managing Categories

### Add Category

```php
Category::create([
    'company_id' => $company->id,
    'type' => 'expense',
    'name' => 'Professional Development',
]);
```

### Edit Category

```php
$category->update(['name' => 'Training & Development']);
```

### Disable Category

```php
$category->update(['enabled' => false]);

// Hidden from UI but existing transactions remain
```

### Delete Category

```php
$category->delete();  // Soft delete

// Existing transactions retain reference
```

## Category Hierarchy (Future Feature)

Potential for hierarchical categories:

```
Income
├─ Sales
│  ├─ Product Sales
│  └─ Service Sales
├─ Consulting
└─ Other Income

Expense
├─ Personnel
│  ├─ Salaries
│  └─ Benefits
├─ Operations
│  ├─ Utilities
│  └─ Supplies
└─ Professional
   └─ Consulting
```

Currently flat structure; hierarchy may be added in future versions.

## API Operations

**REST Endpoints**:

```
GET    /api/settings/categories                 – List categories
GET    /api/settings/categories?type=expense    – Filter by type
POST   /api/settings/categories                 – Create category
PUT    /api/settings/categories/{id}            – Update category
DELETE /api/settings/categories/{id}            – Delete category
```

## Authorization

**Permissions**:
- `read-settings-categories` – View categories
- `update-settings-categories` – Edit categories

Typically restricted to company owner/admin.

## Source Map

| Concept | File |
|---------|------|
| Category model | `app/Models/Setting/Category.php` |
| Settings controller | `app/Http/Controllers/Settings/Categories.php` |
| Request validation | `app/Http/Requests/Settings/Category.php` |

---

## Related Pages

- [Settings Overview](overview.md) – Configuration management
- [Banking Transactions](../banking/transactions.md) – Transaction recording
- [Configuration](../../configuration.md) – Application-wide settings
