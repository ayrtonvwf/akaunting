---
type: system-reference
title: Tax Rules & Definitions
description: Tax configuration, tax types, tax calculation modes, and tax application in Akaunting.
tags: [taxes, tax-rates, tax-calculation, compliance]
---

# Tax Rules & Definitions

The Tax system defines tax rules applied to documents and transactions. Taxes can be percentage-based or fixed amounts, applied to specific items or entire documents.

## Tax Model

**File**: `App\Models\Setting\Tax`
**Table**: `taxes`

### Attributes

```
id, company_id, name, type (percentage|fixed), rate, enabled, created_at, updated_at, deleted_at
```

### Key Fields

- **name**: Tax name (e.g., "VAT 20%", "Sales Tax", "Consumption Tax")
- **type**: `percentage` (e.g., 10%) or `fixed` (e.g., $2.50)
- **rate**: Tax rate/amount
- **enabled**: Whether tax is available for use

## Tax Types

### Percentage Tax

Rate as percentage of item/document amount:

```php
[
    'name' => 'VAT',
    'type' => 'percentage',
    'rate' => 20,  // 20%
]
```

Calculation:
```
tax_amount = item_amount × (rate / 100)
```

### Fixed Tax

Flat amount per unit or item:

```php
[
    'name' => 'Environmental Fee',
    'type' => 'fixed',
    'rate' => 2.50,  // $2.50 per unit
]
```

Calculation:
```
tax_amount = rate × quantity
```

## Tax Application

### To Items

Taxes assigned to items (catalog level):

```php
$item->tax_types;  // Collection of Tax models

// Associate tax with item
$item->taxes()->attach($tax->id);
```

When item used in document, its taxes automatically applied.

### To Document Line Items

Override at line-item level:

```php
[
    'item_id' => 1,
    'tax_ids' => [1, 5],  // Specific taxes for this line
]
```

### Compound Tax

Some jurisdictions apply tax on tax (compound):

```
Subtotal: 100
Tax 1 (5%): 100 × 0.05 = 5
Tax 2 (3% on subtotal + tax1): (100 + 5) × 0.03 = 3.15
Total: 100 + 5 + 3.15 = 108.15
```

Enable via setting: `tax.compound_mode = true`

## Tax Calculation Modes

### Inclusive (Tax Included in Price)

Tax already included in price:

```
Price shown: $110
Actual price: $100
Tax (10%): $10
```

Customer pays $110 total.

### Exclusive (Tax Added to Price)

Tax added on top of price:

```
Price shown: $100
Tax (10%): $10
Total: $110
```

Customer pays $110 total.

**Setting**: `tax.default_calculation = 'inclusive'` or `'exclusive'`

## Creating Taxes

### Via API

```json
POST /api/settings/taxes

{
  "name": "VAT 20%",
  "type": "percentage",
  "rate": 20,
  "enabled": true
}
```

### Via Controller

```php
Tax::create([
    'company_id' => auth()->user()->currentCompany()->id,
    'name' => 'Sales Tax 8%',
    'type' => 'percentage',
    'rate' => 8,
    'enabled' => true,
]);
```

## Tax Assignment to Items

**In item creation**:

```php
Item::create([
    'name' => 'Taxable Product',
    'sale_price' => 100,
])->taxes()->attach([1, 3]);  // Attach tax IDs
```

**In API request**:

```json
{
  "name": "Taxable Product",
  "sale_price": 100,
  "tax_ids": [1, 3]
}
```

## Tax Reporting

Taxes are aggregated for reporting:

```
Sales Tax Report
Q1 2024

VAT 20% Collected:    $5,234.50
Sales Tax 8% Collected: $1,200.00
Environmental Fee:     $450.00
────────────────
Total Tax Liability:  $6,884.50
```

## Jurisdictional Compliance

Tax system supports different tax regimes:

### EU VAT

Intra-EU transactions use customer's tax ID:

```php
'contact_tax_number' => 'DE123456789'  // German VAT number
```

### US Sales Tax

State-based sales tax:

```php
Tax::create([
    'name' => 'California Sales Tax 7.25%',
    'type' => 'percentage',
    'rate' => 7.25,
]);
```

### GST (Australia/Canada)

Standard Goods and Services Tax:

```php
Tax::create([
    'name' => 'GST 10%',
    'type' => 'percentage',
    'rate' => 10,
]);
```

## Common Workflows

### Add New Tax Rate

```php
$tax = Tax::create([
    'company_id' => $company->id,
    'name' => 'VAT 20%',
    'type' => 'percentage',
    'rate' => 20,
    'enabled' => true,
]);
```

### Apply Tax to Product Category

```
// Multiple products in "Electronics"
foreach ($electronics as $item) {
    $item->taxes()->sync([TAX_ELECTRONICS_VAT_ID]);
}
```

### Disable Tax

```php
Tax::find($id)->update(['enabled' => false]);

// Items can still use it but not selectable for new documents
```

### Create Fixed Tax (Environmental)

```php
Tax::create([
    'name' => 'Environmental Fee',
    'type' => 'fixed',
    'rate' => 5.00,  // $5 per item regardless of price
]);
```

## Source Map

| Concept | File |
|---------|------|
| Tax model | `app/Models/Setting/Tax.php` |
| Settings controller | `app/Http/Controllers/Settings/Taxes.php` |
| Request validation | `app/Http/Requests/Settings/Tax.php` |
| Config | `config/money.php`, `config/type.php` |

---

## Related Pages

- [Settings Overview](overview.md) – Configuration management
- [Items](../common/items.md) – Product/service catalog
- [Document Calculations](../documents/totals.md) – Tax calculation logic
- [Currencies](currencies.md) – Multi-currency support
