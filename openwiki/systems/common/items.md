---
type: system-domain
title: Items (Products/Services)
description: Item catalog, product and service definitions, taxes, pricing, and line item management in Akaunting.
tags: [items, products, services, catalog, pricing]
---

# Items (Products/Services)

The Items system provides a reusable catalog of products and services. Items are referenced in document line items, avoiding data duplication and ensuring consistent pricing and tax treatment across documents.

## Core Model: Item

**File**: `App\Models\Common\Item`
**Table**: `items`

### Attributes

```
id, company_id, name, sku, description, 
sale_price, purchase_price, quantity, category_id,
enabled, created_at, updated_at, deleted_at
```

### Key Fields

- **name**: Product/service name
- **sku**: Stock keeping unit (unique identifier per company)
- **description**: Detailed description
- **sale_price**: Selling price (used in invoices)
- **purchase_price**: Cost price (used in bills)
- **quantity**: Stock quantity (if tracking inventory)
- **category_id**: Item category for organization
- **enabled**: Whether item is available for use

### Relationships

```php
$item->tax_types;      // BelongsToMany: Applicable taxes
$item->items_tax;      // HasMany: Tax configurations for item
$item->category;       // BelongsTo: Item category
$item->documents;      // BelongsToMany through DocumentItem
```

## Item Categories

**Model**: `App\Models\Setting\Category`

Items organized by category:

```php
$item->category;  // E.g., "Services", "Software", "Consulting"
```

Categories help organize catalog and enable bulk operations.

## Item Taxes

**Model**: `App\Models\Common\ItemTax`
**Table**: `item_taxes`

Defines which taxes apply to each item:

```php
[
    'item_id' => 1,
    'tax_id' => 1,  // Tax type (e.g., VAT 10%)
]
```

### Multiple Taxes per Item

Single item can have multiple taxes:

```php
$item->tax_types;  // Collection of Tax models

// Example: Item with VAT 10% + City Tax 2%
[Tax::find(1), Tax::find(5)]
```

When line item created, all item taxes automatically applied.

## Item Creation

**Controller**: `App\Http\Controllers\Common\Items`
**Job**: `App\Jobs\Common\CreateItem`

### Flow

1. User submits item form
2. Controller validates with `App\Http\Requests\Common\Item`
3. Controller dispatches `CreateItem` job
4. Job creates `Item` record
5. Job attaches taxes
6. Job fires `ItemCreated` event

### Minimum Required Fields

```php
[
    'name' => 'Consulting Services',
    'sale_price' => 150.00,
    'category_id' => 1,
]
```

### Full Item Creation

```php
[
    'name' => 'Premium Consulting',
    'sku' => 'CONS-001',
    'description' => 'Custom software consulting, hourly rate',
    'sale_price' => 150.00,
    'purchase_price' => 75.00,
    'category_id' => 1,
    'tax_ids' => [1, 5],  // VAT + City Tax
    'enabled' => true,
]
```

## API Operations

**REST Endpoints**:

```
GET    /api/items                       – List items
GET    /api/items/{id}                  – Get item details
POST   /api/items                       – Create item
PUT    /api/items/{id}                  – Update item
DELETE /api/items/{id}                  – Delete (soft delete)
```

**Query parameters**:
```
?category_id=1       – Filter by category
?enabled=true        – Filter by status
?search=consulting   – Search by name/description
```

**Response**: Returns `Item` resource with taxes, category, pricing.

## Line Item Usage

When creating invoice/bill, items are referenced in line items:

**DocumentItem**: Line item in document

```php
[
    'item_id' => 1,              // Reference to Item
    'quantity' => 3,
    'price' => 150.00,           // Override item price (optional)
    'tax_ids' => [1, 5],         // Override item taxes (optional)
]
```

When line item created, the system:
1. Fetches item from `Item` model
2. Copies name, description
3. Applies item taxes (unless overridden)
4. Uses provided quantity and price
5. Calculates taxes and totals

### Override Item Data

Line items allow overriding item data for special cases:

```php
[
    'item_id' => 1,
    'name' => 'Custom Name',     // Override name
    'price' => 200.00,           // Different price
    'tax_ids' => [1],            // Different taxes
]
```

When item is updated later, existing line items preserve their values.

### Inline Item Creation

If item doesn't exist, create on-the-fly during document creation:

```php
[
    // No item_id
    'name' => 'One-off Service',
    'description' => 'Unique service',
    'price' => 500.00,
    'tax_ids' => [1],
]
```

System creates new item automatically.

## Authorization

**Permissions**:
- `read-common-items` – View items
- `create-common-items` – Create new item
- `update-common-items` – Edit item
- `delete-common-items` – Delete item

## Item Pricing

### Sale Price

Used as default in invoices:

```php
$item->sale_price;  // Default invoice line item price
```

Can be overridden per document.

### Purchase Price

Used as default in bills:

```php
$item->purchase_price;  // Default bill line item cost
```

Typically different from sale price (cost margin).

### Dynamic Pricing

Prices can be volume-based (enterprise feature):

- 1-10 units: $100 each
- 11-50 units: $90 each
- 50+ units: $80 each

Configured per item (when feature enabled).

## Item Management

### Enable/Disable

```php
$item->enabled = false;
$item->save();
```

Disabled items don't appear in UI but remain in database.

### Bulk Operations

**Update multiple items**:
- Change tax assignment
- Update prices
- Modify category
- Enable/disable

**Export/Import**:
```bash
php artisan export:items --company-id=1
php artisan import:items --file=items.csv
```

### Item History

Track price changes and modifications (with audit trail):

```php
$item->histories;  // All historical changes
```

## Inventory Management

Items can track stock quantity:

```php
$item->quantity = 50;  // Current stock
$item->save();
```

When line item created, optionally decrement:

```php
// In DocumentItem creation
$item->decrement('quantity', $quantity);
```

**Note**: Inventory tracking is optional; not all installations use it.

## Source Map

| Concept | File |
|---------|------|
| Item model | `app/Models/Common/Item.php` |
| Item tax model | `app\Models\Common\ItemTax.php` |
| Item controller | `app/Http/Controllers/Common/Items.php` |
| Create job | `app/Jobs/Common/CreateItem.php` |
| Request validation | `app/Http/Requests/Common/Item.php` |
| API resource | `app/Http/Resources/Common/Item.php` |
| Events | `app/Events/Common/Item*.php` |

## Common Workflows

### Create Item with Taxes

```php
$item = $this->dispatch(new CreateItem(
    auth()->user(),
    [
        'name' => 'Consulting Hours',
        'sku' => 'CONS-001',
        'sale_price' => 150.00,
        'purchase_price' => 75.00,
        'category_id' => 1,
        'tax_ids' => [1],  // VAT
    ],
    auth()->user()->currentCompany()
));
```

### Use Item in Invoice

```php
// In invoice creation
[
    'items' => [
        [
            'item_id' => $item->id,
            'quantity' => 5,
            // price and taxes inherited from item
        ]
    ]
]
```

### Update Item Pricing

```php
$item->update([
    'sale_price' => 175.00,
    'purchase_price' => 85.00,
]);

// Only affects future line items; existing documents unchanged
```

### Import Items

```php
// CSV structure:
// name,sku,sale_price,purchase_price,category,taxes
// Consulting,CONS-001,150,75,Services,"1,5"

$import = new ItemsImport();
Excel::import($import, 'items.csv');
```

## Testing

**Feature tests**: `/tests/Feature/Common/Items.php`

Key test cases:
- Create item with single/multiple taxes
- Use item in document line
- Override item data in line item
- Update item (affects future documents)
- Delete item (soft delete)

---

## Related Pages

- [Document Calculations](../documents/totals.md) – Tax calculation for line items
- [Taxes](../settings/taxes.md) – Tax types and rules
- [Invoices](../documents/invoices.md) – Document line item creation
- [Bills](../documents/bills.md) – Purchase document line items
