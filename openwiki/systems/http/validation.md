---
type: system-reference
title: Form Validation
description: Request validation rules, custom validators, and form request classes for web and API endpoints.
tags: [http, validation, form-requests, input-validation]
openwiki:
  source_paths: [app/Http/Requests, app/Abstracts/Http/FormRequest.php]
---

# Form Validation

Form validation occurs at the HTTP boundary through Laravel's form request pattern. All form data (web and API) is validated before reaching controllers.

## Form Request Classes

**Location**: `App\Http\Requests\{Domain}\*`

**Base Class**: `App\Abstracts\Http\FormRequest` (extends `Illuminate\Foundation\Http\FormRequest`)

### Creating a Form Request

```php
namespace App\Http\Requests\Document;

use App\Abstracts\Http\FormRequest;
use App\Models\Document\Document as Model;

class Document extends FormRequest
{
    /**
     * Get the validation rules.
     */
    public function rules()
    {
        $rules = [
            'contact_id' => 'required|integer|exists:contacts,id',
            'currency_code' => 'required|string|size:3|exists:currencies,code',
            'issued_at' => 'required|date_format:Y-m-d',
            'due_at' => 'nullable|date_format:Y-m-d|after:issued_at',
            'items' => 'required|array|min:1',
            'items.*.item_id' => 'required|integer|exists:items,id',
            'items.*.quantity' => 'required|numeric|min:0.01',
            'items.*.price' => 'required|numeric|min:0',
        ];
        
        return $rules;
    }

    /**
     * Get custom error messages (optional).
     */
    public function messages()
    {
        return [
            'contact_id.required' => 'Customer is required.',
            'items.min' => 'Add at least one line item.',
        ];
    }

    /**
     * Modify inputs before validation (optional).
     */
    public function prepareForValidation()
    {
        // Normalize data
        $this->merge([
            'currency_code' => strtoupper($this->currency_code),
        ]);
    }
}
```

## Standard Validation Rules

### Document

```php
rules() {
    return [
        'type' => 'required|in:invoice,bill,invoice-recurring,bill-recurring',
        'document_number' => 'nullable|string',
        'contact_id' => 'required|integer|exists:contacts,id',
        'currency_code' => 'required|string|size:3',
        'issued_at' => 'required|date_format:Y-m-d',
        'due_at' => 'nullable|date_format:Y-m-d',
        'discount_type' => 'nullable|in:percent,fixed',
        'discount_rate' => 'nullable|numeric|min:0',
        'notes' => 'nullable|string',
        'items' => 'required|array|min:1',
        'items.*.item_id' => 'required|integer',
        'items.*.quantity' => 'required|numeric|min:0.01',
        'items.*.price' => 'required|numeric|min:0',
    ];
}
```

### Banking Transaction

```php
rules() {
    return [
        'type' => 'required|in:income,expense,transfer',
        'account_id' => 'required|integer|exists:accounts,id',
        'contact_id' => 'nullable|integer|exists:contacts,id',
        'category_id' => 'required|integer|exists:categories,id',
        'amount' => 'required|numeric|min:0.01',
        'description' => 'nullable|string|max:255',
        'transaction_date' => 'required|date_format:Y-m-d',
        'reference' => 'nullable|string|max:50',
    ];
}
```

### Contact

```php
rules() {
    return [
        'type' => 'required|in:customer,vendor',
        'name' => 'required|string|max:255',
        'email' => 'nullable|email|max:255',
        'phone' => 'nullable|string|max:20',
        'tax_number' => 'nullable|string|max:50',
        'address' => 'nullable|string|max:255',
        'city' => 'nullable|string|max:100',
        'state' => 'nullable|string|max:100',
        'country' => 'nullable|string|size:2',
        'zip_code' => 'nullable|string|max:20',
    ];
}
```

## Custom Validators

Custom validation rules are registered in service providers or inline:

### Inline Custom Rule

```php
'email' => [
    'required',
    'email',
    // Custom closure rule
    function ($attribute, $value, $fail) {
        if (Contact::where('email', $value)->exists()) {
            $fail("The {$attribute} is already in use.");
        }
    }
]
```

### Custom Validator Class

```php
use Illuminate\Contracts\Validation\Rule;

class ValidateUniqueCode implements Rule
{
    private $model;
    
    public function __construct($model)
    {
        $this->model = $model;
    }
    
    public function passes($attribute, $value)
    {
        return !$this->model::where('code', $value)->exists();
    }
    
    public function message()
    {
        return 'The code must be unique.';
    }
}

// Usage in rules()
'code' => ['required', new ValidateUniqueCode(Item::class)]
```

## Multi-Tenant Scoping

Form requests automatically scope validation to the current company:

```php
// Validates that contact_id belongs to current company
'contact_id' => 'required|integer|exists:contacts,id'
// The model is scoped by company_id automatically via Eloquent scope
```

## Authorization Within Requests

```php
use Illuminate\Auth\Access\AuthorizationException;

public function authorize()
{
    // This request is only allowed if user can create documents
    return auth()->user()->can('create', Document::class);
}
```

## API vs Web Validation

Both use the same form request class:

```php
// Sent as JSON
POST /api/documents
Content-Type: application/json
{ "contact_id": 1, "currency_code": "USD" }

// Sent as form data
POST /documents
Form-Data: contact_id=1&currency_code=USD

// Both validated by same App\Http\Requests\Document\Document class
```

## Validation Errors

**Web Response**:
```
Redirect with errors flashed to session
Session key: 'errors'
```

**API Response**:
```json
HTTP 422
{
  "message": "The given data was invalid.",
  "errors": {
    "contact_id": ["The contact_id field is required."],
    "items": ["At least one item is required."]
  }
}
```

## Common Validation Scenarios

### Unique Per Company

```php
'document_number' => [
    'nullable',
    Rule::unique('documents', 'document_number')
        ->where('company_id', auth()->user()->currentCompany()->id)
        ->where('type', $this->type)
        ->ignore($this->document?->id),
]
```

### Conditional Rules

```php
public function rules()
{
    $rules = [
        'type' => 'required|in:income,expense,transfer',
        'amount' => 'required|numeric|min:0.01',
    ];
    
    // Extra validation for transfers
    if ($this->type === 'transfer') {
        $rules['transfer_account_id'] = 'required|integer|different:account_id';
    }
    
    return $rules;
}
```

### Dependent Field Validation

```php
'due_at' => 'required_if:type,invoice|after:issued_at',
// due_at is required if type is 'invoice'
```

## Related Pages

- [Controllers Overview](controllers.md) – Request reception and dispatching
- [API Resources](resources.md) – Response transformation
- [Jobs & Dispatching](../jobs/overview.md) – Business logic after validation

## Source Map

```
app/
├─ Http/Requests/
│  ├─ Document/
│  │  └─ Document.php
│  ├─ Banking/
│  │  ├─ Account.php
│  │  └─ Transaction.php
│  └─ Common/
│     └─ Contact.php
└─ Abstracts/Http/
   └─ FormRequest.php
```

## Testing & Validation

```bash
# Test validation rules
php artisan test tests/Feature/Document/

# Test specific validation
php artisan test --filter=DocumentValidation
```
