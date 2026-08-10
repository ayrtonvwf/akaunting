---
type: workflow
title: Permission Checking Workflow
description: RBAC enforcement, authorization decisions, permission checking flow, and policy-based authorization in Akaunting.
tags: [workflow, rbac, permissions, authorization, access-control]
---

# Permission Checking Workflow

The Permission Checking workflow describes how Akaunting enforces role-based access control (RBAC). At every step—routing, form validation, controller action, and API call—the system verifies the user has required permissions in the current company context.

## Permission System Overview

Akaunting uses Laratrust for RBAC with company-level scope:

```
Role (e.g., "Manager")
  ├─ Has Permissions (create-sales-invoices, etc.)
  ├─ Assigned to User in Company A
  └─ Assigned to User in Company B (same role, same permissions)

User
  ├─ Has Roles in Company A (Manager)
  ├─ Has Roles in Company B (Accountant)
  └─ Different permissions per company
```

## Permission Naming Convention

All permissions follow: `{action}-{domain}-{resource}`

**Example breakdown**: `create-sales-invoices`
- **Action**: create (also: read, update, delete)
- **Domain**: sales, banking, common, settings, auth (also: purchases for bills)
- **Resource**: invoices, companies, contacts, accounts

## Multi-Layer Permission Checking

Permission enforcement happens at multiple layers:

```
HTTP Request
    │
    ├─ Route Middleware
    │  └─ Check: permission:create-sales-invoices
    │
    ├─ Form Request
    │  └─ Check: authorize()
    │
    ├─ Controller Action
    │  └─ Check: $this->authorize('create', Invoice::class)
    │
    └─ Database Query
       └─ Scope: where company_id = current_company
```

## Workflow: Request Permission Checking

### Step 1: Route-Level Check

**In routes file**:

```php
Route::post('/invoices', [InvoiceController::class, 'store'])
    ->middleware('permission:create-sales-invoices');
```

**When request arrives**:

```
Request: POST /invoices
Middleware: permission:create-sales-invoices

Check: Does user have 'create-sales-invoices' 
       in current company?

YES: Continue to controller
NO:  403 Forbidden - Permission Denied
```

### Step 2: Form Request Validation

**In InvoiceRequest class**:

```php
class StoreInvoiceRequest extends FormRequest
{
    public function authorize()
    {
        return auth()->user()->hasPermission(
            'create-sales-invoices',
            auth()->user()->currentCompany()
        );
    }

    public function rules()
    {
        return [
            'document_number' => 'required|unique:documents',
            'contact_id' => 'required|exists:contacts,id',
            // ... more rules
        ];
    }
}
```

**When form validates**:

```
1. Check business rules (required fields, etc.)
2. Check: authorize()
   Does user have 'create-sales-invoices'?
   YES: Proceed to controller
   NO:  403 Forbidden
```

### Step 3: Controller Authorization

**In controller action**:

```php
public function store(StoreInvoiceRequest $request)
{
    // Form already authorized at Step 2
    
    // Additional check (rarely needed, form covered it)
    $this->authorize('create', Invoice::class);
    
    // Dispatch job to create invoice
    $invoice = $this->dispatch(new CreateInvoice(
        auth()->user(),
        $request->validated(),
        auth()->user()->currentCompany()
    ));
    
    return response()->json($invoice);
}
```

### Step 4: Job Execution

Jobs don't re-check permissions; they trust the caller:

```php
class CreateDocument extends Job
{
    public function handle(): Document
    {
        // Permission already verified by caller
        // Create and return document
        
        $document = Document::create($this->request->all());
        // ...
        return $document;
    }
}
```

### Step 5: Database Scope

Query automatically scoped to current company:

```php
// Inside any model query
$invoices = Document::all();

// Global scope applied:
// Only returns documents where company_id = current_company_id
```

**Effect**: Even if authorization layer missed a check, user can't access other companies' data.

## Workflow: API Permission Checking

### API Request Flow

```
API Request
  │
  ├─ Bearer Token Validation
  │  └─ Token -> User lookup
  │
  ├─ Company Context
  │  └─ Determine company (usually from URL)
  │
  ├─ Permission Middleware
  │  └─ Check permission:create-sales-invoices
  │
  ├─ Request Validation
  │  └─ Form request authorize()
  │
  └─ Controller Action
     └─ Execute with verified permissions
```

**Example**: Create invoice via API

```bash
curl -X POST https://api.akaunting.com/invoices \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "contact_id": 1,
    "items": [...],
    "amount": 1000
  }'
```

**Permission checking**:

1. **Token validation**: Bearer token → User lookup
2. **Route permission**: permission:create-sales-invoices
3. **User check**: `user->hasPermission('create-sales-invoices', company)`
4. **Result**: 
   - YES: 201 Created
   - NO: 403 Forbidden

## Permission Hierarchies

### Role-Based Permissions

**Owner role**: All permissions

```
Owner (is_admin=true)
  ├─ create-sales-invoices ✓
  ├─ read-sales-invoices ✓
  ├─ update-sales-invoices ✓
  ├─ delete-sales-invoices ✓
  ├─ create-common-companies ✓
  └─ delete-common-companies ✓
```

**Manager role**: Most permissions (no delete)

```
Manager
  ├─ create-sales-invoices ✓
  ├─ read-sales-invoices ✓
  ├─ update-sales-invoices ✓
  ├─ delete-sales-invoices ✗
  ├─ create-common-companies ✗
  └─ delete-common-companies ✗
```

**Accountant role**: Limited permissions (read + create invoices)

```
Accountant
  ├─ read-sales-invoices ✓
  ├─ create-sales-invoices ✓
  ├─ update-sales-invoices ✗ (view only)
  ├─ delete-sales-invoices ✗
  └─ read-banking-transactions ✓
```

## Deny-by-Default

Akaunting uses **deny-by-default** model:

```
If permission not explicitly granted → DENIED
```

**Example**:

```
User: John
Role: Manager in Acme Corp

Check: John create-billing-reports?
Manager role doesn't have this permission
Result: DENIED (403 Forbidden)
```

Only explicitly granted permissions are allowed.

## Permission Checking Examples

### Web Form

```php
// In Blade template
@if(auth()->user()->hasPermission('create-sales-invoices'))
    <a href="/invoices/create" class="btn btn-primary">Create Invoice</a>
@endif

// Only show button if user has permission
```

### Controller Method

```php
public function destroy(Invoice $invoice)
{
    // Check delete permission
    $this->authorize('delete', $invoice);
    
    // If here, permission granted
    $invoice->delete();
    return response()->json(['success' => true]);
}
```

### Request Validation

```php
public function authorize()
{
    // Check in context of current company
    return auth()->user()->hasPermission(
        'update-sales-invoices',
        auth()->user()->currentCompany()
    );
}
```

### Custom Gate

```php
Gate::define('send-invoice', function (User $user, Invoice $invoice) {
    return $user->hasPermission('update-sales-invoices', $invoice->company);
});

// Usage
if (Gate::allows('send-invoice', $invoice)) {
    Mail::to($invoice->contact->email)->send(new InvoiceMail($invoice));
}
```

## Troubleshooting Permission Issues

### User Getting 403 Forbidden

**Check**:
1. Is user assigned to correct company?
   ```php
   $user->companies; // Should include current company
   ```
2. Does user have role in company?
   ```php
   $user->roles($company->id); // Should return roles
   ```
3. Does role have permission?
   ```php
   $user->hasPermission('create-sales-invoices', $company); // true?
   ```

### Unexpected Permission Granted

**Check**:
1. Is user Owner? (Owner has all permissions)
   ```php
   $user->hasRole('Owner', $company); // Returns true?
   ```
2. Are permissions defined correctly?
   ```php
   config('type.permission.create.sales'); // Should include 'invoices'
   ```

## Source Map

| Concept | File |
|---------|------|
| Permission model | `app/Models/Auth/Permission.php` |
| Role model | `app/Models/Auth/Role.php` |
| User model | `app/Models/Auth/User.php` |
| Permission middleware | `\Laratrust\Middleware\LaratrustPermission` (via `config/Kernel.php` alias) |
| RBAC integration | `app/Models/Auth/Traits/LaratrustUserTrait` |
| Config | `config/type.php` (permission key) |
| Tests | `tests/Feature/Auth/Permissions*.php` |

## Related Pages

- [RBAC Integration](../systems/auth/rbac.md) – Permission system details
- [Auth System](../systems/auth/overview.md) – User and role models
- [Middleware & Routing](../systems/http/middleware.md) – Permission middleware
