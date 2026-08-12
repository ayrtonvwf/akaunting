---
type: system-reference
title: API Resources
description: Data transformation for API responses, resource classes, and JSON response structure.
tags: [http, api-resources, json-transformation, api-response]
openwiki:
  source_paths: [app/Http/Resources]
---

# API Resources

API Resources transform models into JSON responses. Each resource class defines which fields are exposed and how nested data is formatted.

## What Are Resources?

Resources are data transformation classes that convert Eloquent models into API-safe JSON.

**Location**: `App\Http\Resources\{Domain}\*`

**Base Class**: `Illuminate\Http\Resources\Json\JsonResource`

## Creating a Resource

```php
namespace App\Http\Resources\Banking;

use Illuminate\Http\Resources\Json\JsonResource;

class Account extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'type' => $this->type,
            'name' => $this->name,
            'number' => $this->number,
            'currency_code' => $this->currency_code,
            'opening_balance' => $this->opening_balance,
            'opening_balance_formatted' => money($this->opening_balance, $this->currency_code)->format(),
            'current_balance' => $this->balance,
            'current_balance_formatted' => money($this->balance, $this->currency_code)->format(),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
```

## Using Resources in Controllers

### Single Resource

```php
namespace App\Http\Controllers\Api\Banking;

class Accounts extends Controller
{
    public function show(Account $account)
    {
        return new AccountResource($account);
    }
}
```

**Response**:
```json
{
  "id": 1,
  "type": "bank",
  "name": "Main Account",
  "number": "1234567890",
  "currency_code": "USD",
  "current_balance": "5000.00",
  "current_balance_formatted": "$5,000.00"
}
```

### Collection of Resources

```php
public function index()
{
    $accounts = Account::all();
    return AccountResource::collection($accounts);
}
```

**Response**:
```json
{
  "data": [
    {
      "id": 1,
      "name": "Main Account",
      ...
    },
    {
      "id": 2,
      "name": "Savings Account",
      ...
    }
  ]
}
```

## Common Resource Patterns

### Nested Resources

```php
class DocumentResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'document_number' => $this->document_number,
            'type' => $this->type,
            'contact' => new ContactResource($this->contact),  // Nested
            'items' => ItemResource::collection($this->items),  // Collection
            'totals' => TotalResource::collection($this->totals),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
```

### Conditional Fields

```php
public function toArray($request)
{
    return [
        'id' => $this->id,
        'name' => $this->name,
        // Only include if user has permission
        'internal_notes' => $this->when(
            auth()->user()->isAdmin(),
            $this->internal_notes
        ),
        // Only include sensitive data in detail view
        'created_by' => $this->whenLoaded('creator'),
    ];
}
```

### Field Aliases

```php
public function toArray($request)
{
    return [
        'id' => $this->id,
        'account_number' => $this->number,  // Alias 'number' as 'account_number'
        'bank' => $this->bank_name,         // Alias 'bank_name' as 'bank'
    ];
}
```

### Computed Fields

```php
public function toArray($request)
{
    return [
        'id' => $this->id,
        'name' => $this->name,
        'balance' => $this->balance,
        'balance_formatted' => money($this->balance, $this->currency_code)->format(),
        'is_active' => (bool) $this->enabled,
    ];
}
```

## Key Resources by Domain

| Resource | File | Returns |
|----------|------|---------|
| **Document** | `Http\Resources\Document\Document.php` | Invoice/Bill with items, totals, contact |
| **Contact** | `Http\Resources\Common\Contact.php` | Customer/Vendor with name, email, address |
| **Account** | `Http\Resources\Banking\Account.php` | Bank account with balance |
| **Transaction** | `Http\Resources\Banking\Transaction.php` | Income/Expense/Transfer entry |
| **Item** | `Http\Resources\Common\Item.php` | Product/Service with name, price, tax |
| **User** | `Http\Resources\Auth\User.php` | User with role and company access |
| **Company** | `Http\Resources\Common\Company.php` | Business entity with settings |

## Response Formats

All API endpoints return consistent response formats:

### Success (200/201)

Single resource:
```json
{
  "id": 1,
  "name": "...",
  ...
}
```

Collection:
```json
{
  "data": [
    { "id": 1, ... },
    { "id": 2, ... }
  ],
  "links": {
    "first": "/api/documents?page=1",
    "last": "/api/documents?page=10"
  },
  "meta": {
    "current_page": 1,
    "total": 100,
    "per_page": 10
  }
}
```

### Validation Error (422)

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "contact_id": ["The contact id field is required."]
  }
}
```

### Not Found (404)

```json
{
  "message": "Resource not found."
}
```

### Unauthorized (401/403)

```json
{
  "message": "Unauthorized access."
}
```

## Pagination with Resources

```php
public function index()
{
    $documents = Document::paginate(20);
    return DocumentResource::collection($documents);
}
```

Response includes `data`, `links`, and `meta` with pagination info.

## Filtering and Including

Resources often work with query parameters:

```
GET /api/documents?include=contact,items&sort=-created_at&filter[status]=paid

Returns:
{
  "id": 1,
  "document_number": "INV-001",
  "contact": { "id": 1, "name": "..." },      // Included via parameter
  "items": [{ "id": 1, ... }],                // Included via parameter
}
```

## Transformation vs Business Logic

**Resources**: Data formatting only
- Field renaming
- Currency formatting
- Date formatting
- Conditional inclusion

**Never in Resources**:
- Database queries
- Complex calculations
- Business logic
- Side effects

## Related Pages

- [Controllers Overview](controllers.md) – Where resources are returned
- [Form Validation](validation.md) – Input to API
- [API Overview](../api/overview.md) – API architecture

## Source Map

```
app/Http/Resources/
├─ Auth/
│  ├─ User.php
│  ├─ Role.php
│  └─ Owner.php
├─ Banking/
│  ├─ Account.php
│  ├─ Transaction.php
│  └─ Reconciliation.php
├─ Common/
│  ├─ Contact.php
│  ├─ Item.php
│  └─ Company.php
├─ Document/
│  ├─ Document.php
│  ├─ Item.php
│  └─ Total.php
└─ Settings/
   ├─ Category.php
   ├─ Currency.php
   └─ Tax.php
```

## Testing & Validation

```bash
# Validate resource transformation
php artisan test --filter=DocumentResourceTest
```
