---
type: system-reference
title: Document Calculations - Amounts, Taxes & Discounts
description: Line item calculations, tax computation, discount application, rounding, and total aggregation for invoices and bills in Akaunting.
tags: [documents, calculations, taxes, discounts, amounts]
---

# Document Calculations

Document totals are calculated from line items, applying taxes, discounts, and rounding rules. The calculation logic is deterministic and follows accounting standards.

## Calculation Flow

When a document is created, the system calculates totals in this sequence:

1. **Create line items** – Dispatch `CreateDocumentItem` for each item
2. **Calculate item amounts** – quantity × price, apply item-level discounts
3. **Calculate item taxes** – Apply tax rates to item amounts
4. **Aggregate taxes** – Combine all taxes by tax type
5. **Apply document-level discount** – Percentage or fixed amount
6. **Add extra totals** – Shipping, fees, etc.
7. **Compute grand total** – Sum all components

**Job**: `App\Jobs\Document\CreateDocumentItemsAndTotals`

## Line Item Calculation

### DocumentItem Model

**File**: `App\Models\Document\DocumentItem`

Each line item represents one product/service on the document.

**Attributes**:
```
id, document_id, item_id, name, description, quantity, unit, price, tax_total, amount
```

**Calculation**:
```
item.amount = quantity × price  (before tax and item discount)
```

### Item-Level Discounts

Items can have individual discounts (e.g., bulk discount on specific line):

```php
[
    'item_id' => 1,
    'quantity' => 5,
    'price' => 100.00,
    'discount' => 10,              // Item discount
    'discount_type' => 'percentage' // or 'fixed'
]
```

**Calculation**:
```
if discount_type == 'percentage':
    item_discount_amount = (quantity × price) × (discount / 100)
else:
    item_discount_amount = discount

item_subtotal = (quantity × price) - item_discount_amount
```

### Item Taxes

**Model**: `App\Models\Document\DocumentItemTax`

Taxes are applied to the item **after** item-level discount but **before** document-level discount.

**Tax types**:
- **Percentage**: rate applied to item amount
- **Fixed**: flat amount per unit or per item

**Calculation for percentage tax**:
```
item_tax_amount = item_subtotal × (tax_rate / 100)
```

**Calculation for fixed tax**:
```
item_tax_amount = tax_rate × quantity
```

**Aggregate**: All taxes for an item sum in `item.tax_total`:

```php
$item->tax_total = $item->item_taxes->sum('amount');
```

## Document-Level Calculations

### Document Totals Model

**File**: `App\Models\Document\DocumentTotal`
**Table**: `document_totals`

Totals are aggregated rows representing:

```php
[
    ['code' => 'sub_total', 'amount' => 1000.00],
    ['code' => 'item_discount', 'amount' => -50.00],
    ['code' => 'discount', 'amount' => -100.00],
    ['code' => 'tax', 'amount' => 115.50],
    ['code' => 'tax', 'amount' => 57.75],
    ['code' => 'extra', 'amount' => 25.00],     // shipping
    ['code' => 'total', 'amount' => 1048.25],
]
```

### Calculation Order

#### 1. Subtotal

**Code**: `sub_total`

Sum of all item amounts before discounts and taxes:

```
subtotal = sum(quantity × price for all items)
```

#### 2. Item-Level Discounts

**Code**: `item_discount`

Sum of all item-specific discounts:

```
item_discount_total = sum(item discounts for all items)
```

If present, shown as separate total row with negative amount.

#### 3. Document-Level Discount

**Code**: `discount`

Global discount applied to subtotal or all items:

```php
// If percentage:
discount_amount = subtotal × (discount_rate / 100)

// If fixed:
discount_amount = discount_rate

// Final amount subtracted from total
```

#### 4. Taxes

**Code**: `tax` (one row per tax type)

Aggregate of all item taxes, grouped by tax type:

```
tax_total_by_type = sum(item taxes of same type)
```

**Important**: Taxes typically apply to subtotal **minus item discounts**, but **before** document-level discount (depends on tax rules).

#### 5. Extra Totals

**Code**: `extra` (or custom)

Additional line items like shipping, service fees, etc.:

```php
[
    'code' => 'shipping',
    'name' => 'Shipping',
    'amount' => 25.00,
    'operator' => 'addition',  // or 'subtraction'
]
```

Operators control whether amount is added or subtracted from total.

#### 6. Grand Total

**Code**: `total`

```
total = subtotal 
    - item_discount_total 
    - document_discount 
    + total_taxes 
    + extra_amounts
```

## Discount Types

### Percentage Discount

Discount expressed as percent of subtotal:

```
discount_amount = subtotal × (discount_rate / 100)
```

**Example**: 10% off $1000 = $100 discount

### Fixed Amount Discount

Discount is a fixed dollar/currency amount:

```
discount_amount = discount_rate
```

**Example**: $50 off

## Rounding

Calculations are rounded to currency precision (typically 2 decimal places):

**Currency precision**:
```php
$precision = currency($document->currency_code)->getPrecision();
// Returns 2 for USD, 0 for JPY, etc.
```

**Rounding applied**:
- Per-line item amounts
- Per tax calculation
- Per total row
- Grand total

**Why**: Prevents floating-point errors and ensures financial accuracy.

## Multi-Currency Calculations

When document is in non-base currency:

```php
[
    'currency_code' => 'EUR',
    'currency_rate' => 1.10,  // EUR to company base (USD) rate
]
```

**Calculation**: Amounts stored and displayed in document currency (EUR). When converting for reporting or payment, multiplied by `currency_rate`.

```
amount_in_base = amount_in_document_currency × currency_rate
```

## Global Discount Handling

**Important**: Global discount calculation has a known issue ([GitHub #2797](https://github.com/akaunting/akaunting/issues/2797)) where discount distribution across items must be weighted.

**Current implementation**:
- For fixed global discounts, system calculates proportional reduction per item based on item amount
- For percentage discounts, applied uniformly to all items

```php
// Fixed discount distribution
for_fixed_discount = calculateFixedDiscountPerItem();

foreach items:
    item['global_discount'] = (for_fixed_discount[i] / total) * (discount / 100)
```

## Tax Calculation Modes

### Inclusive vs Exclusive

**Exclusive tax**: Tax added to price
```
price_before_tax = 100
tax_rate = 10%
total = 100 + 10 = 110
```

**Inclusive tax**: Tax included in price
```
price_with_tax = 110
tax_rate = 10%
actual_price = 110 / 1.10 = 100
tax = 10
```

Configuration: Company settings (via Setting model) or tax definitions in Tax model

### Compound Tax

Some jurisdictions use compound tax (tax on tax):

```
subtotal = 100
tax1 = 100 × 5% = 5
tax2 = (100 + 5) × 3% = 3.15
total = 100 + 5 + 3.15 = 108.15
```

## Source Map

| Concept | File |
|---------|------|
| Totals model | `app/Models/Document/DocumentTotal.php` |
| Item model | `app/Models/Document/DocumentItem.php` |
| Item tax model | `app/Models/Document/DocumentItemTax.php` |
| Calculation job | `app/Jobs/Document/CreateDocumentItemsAndTotals.php` |
| Document model | `app/Models/Document/Document.php` |
| Config | `config/money.php`, `config/type.php` |

## Calculation Example

**Scenario**: Invoice with 2 items, percentage discount, and tax

**Input**:
```json
{
  "items": [
    {
      "quantity": 10,
      "price": 100,
      "tax_id": 1,
      "discount": 0
    },
    {
      "quantity": 5,
      "price": 50,
      "tax_id": 1,
      "discount": 5,
      "discount_type": "percentage"
    }
  ],
  "discount": 10,
  "discount_type": "percentage"
}
```

**Calculation**:

1. **Item 1**: 10 × $100 = $1000 (no item discount)
2. **Item 2**: 5 × $50 = $250, item discount = $250 × 5% = $12.50 → **$237.50**
3. **Subtotal**: $1000 + $237.50 = **$1237.50**
4. **Item discounts total**: $12.50
5. **Document discount**: $1237.50 × 10% = **$123.75**
6. **Amount before tax**: $1237.50 - $123.75 = **$1113.75**
7. **Tax** (10% on $1113.75): **$111.38**
8. **Grand Total**: $1113.75 + $111.38 = **$1225.13**

**Totals rows**:
```
sub_total:      $1237.50
item_discount:  -$12.50
discount:       -$123.75
tax:            $111.38
total:          $1225.13
```

## Testing

**Unit tests**: `/tests/Unit/Utilities/CalculationToQuantityTest.php`

Test cases:
- Single item, single tax
- Multiple items, multiple taxes
- Percentage discount
- Fixed discount
- Item-level and document-level discounts
- Multi-currency conversion
- Compound tax
- Rounding at each step

---

## Related Pages

- [Invoices](invoices.md) – Invoice creation and lifecycle
- [Bills](bills.md) – Bill creation and lifecycle
- [Items (Products/Services)](../common/items.md) – Product/service catalog
- [Taxes](../settings/taxes.md) – Tax rules and definitions
