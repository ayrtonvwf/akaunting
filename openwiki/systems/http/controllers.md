---
type: system-reference
title: Controllers Overview
description: Request handlers for web and API routes, controller structure, and request dispatching patterns in Akaunting.
tags: [http, controllers, request-handlers, mvc]
openwiki:
  source_paths: [app/Http/Controllers]
  symbols: [BaseController, ApiController]
---

# Controllers Overview

Controllers are the entry point for HTTP requests. They receive requests, dispatch jobs for business logic, and return responses.

## Architecture

### Controller Hierarchy

```
App\Abstracts\Http\BaseController
├─ Web Controllers (Blade templates)
│  ├─ App\Http\Controllers\Sales\Invoices
│  ├─ App\Http\Controllers\Banking\Accounts
│  ├─ App\Http\Controllers\Common\Contacts
│  └─ App\Http\Controllers\Settings\*
│
└─ API Controllers (JSON responses)
   ├─ App\Http\Controllers\Api\Document\Documents
   ├─ App\Http\Controllers\Api\Banking\Accounts
   └─ App\Http\Controllers\Api\Settings\*
```

### Core Base Class

**File**: `App\Abstracts\Http\BaseController`

All controllers extend this base class, providing:

- Automatic job dispatching via `$this->dispatch(new JobClass($data))`
- Authorization checking via `$this->authorize('action', Model::class)`
- Response formatting
- Exception handling

## Web Controllers

**Namespace**: `App\Http\Controllers\{Domain}\*`

**Pattern**:
1. Receive form data from Blade view
2. Validate using `App\Http\Requests\{Domain}\*`
3. Dispatch job to execute business logic
4. Return view with results or redirect

**Example**:

```php
// app/Http/Controllers/Sales/Invoices.php
public function store(CreateInvoice $request)
{
    $this->authorize('create', Document::class);
    
    $response = $this->dispatch(
        new CreateDocument($request->validated())
    );
    
    return redirect()
        ->route('invoices.show', $response->id)
        ->with('success', 'Invoice created.');
}
```

## API Controllers

**Namespace**: `App\Http\Controllers\Api\{Domain}\*`

**Pattern**:
1. Receive JSON data
2. Validate using `App\Http\Requests\{Domain}\*`
3. Dispatch job
4. Return API resource (JSON)

**Example**:

```php
// app/Http/Controllers/Api/Document/Documents.php
public function store(CreateInvoice $request)
{
    $this->authorize('create', Document::class);
    
    $response = $this->dispatch(
        new CreateDocument($request->validated())
    );
    
    return new DocumentResource($response);
}
```

## Key Directories

| Directory | Purpose |
|-----------|---------|
| `app/Http/Controllers/Auth/` | User login, logout, password reset |
| `app/Http/Controllers/Sales/` | Invoice creation and management |
| `app/Http/Controllers/Purchases/` | Bill creation and management |
| `app/Http/Controllers/Banking/` | Bank accounts, transactions, transfers |
| `app/Http/Controllers/Common/` | Contacts, items, companies, reports |
| `app/Http/Controllers/Settings/` | Currency, tax, category configuration |
| `app/Http/Controllers/Api/` | RESTful endpoints for all domains |
| `app/Http/Controllers/Modals/` | Modal dialogs (small forms) |
| `app/Http/Controllers/Portal/` | Customer portal (public-facing) |

## Controller Method Conventions

Most controllers follow standard REST conventions:

```php
class InvoiceController extends BaseController {
    public function index()              // GET /invoices
    public function show($id)            // GET /invoices/{id}
    public function create()             // GET /invoices/create (show form)
    public function store(Request $req)  // POST /invoices (save form data)
    public function edit($id)            // GET /invoices/{id}/edit
    public function update(Request $req) // PATCH /invoices/{id}
    public function destroy($id)         // DELETE /invoices/{id}
}
```

## Common Controller Methods

Many controllers also implement:

- **enable/disable**: Toggle model active status
- **received**: Mark document as received (bills)
- **bulk actions**: Batch operations on multiple records

## Request Dispatch Pattern

**The Standard Flow**:

```
Request → Controller validation → dispatch(Job) → Job (business logic) → Response
```

```php
public function store(StoreInvoiceRequest $request)
{
    // $request validated automatically by FormRequest
    $document = $this->dispatch(
        new CreateDocument($request->validated())
    );
    
    return view('invoices.show', ['invoice' => $document]);
}
```

See [Business Logic & Jobs](../jobs/overview.md) for job implementation.

## Related Pages

- [Middleware & Routing](middleware.md) – Request lifecycle before controllers
- [Form Validation](validation.md) – Request validation rules
- [API Resources](resources.md) – JSON response transformation
- [Jobs & Dispatching](../jobs/overview.md) – Business logic execution

## Source Map

```
app/
├─ Http/
│  ├─ Controllers/
│  │  ├─ {Domain}/  (web controllers)
│  │  └─ Api/       (API controllers)
│  └─ Requests/     (form request validation)
└─ Abstracts/
   └─ Http/BaseController.php
```

## Testing & Validation

```bash
# Test a controller action
php artisan test tests/Feature/Auth/

# Run all HTTP tests
php artisan test tests/Feature/
```
