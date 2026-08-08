---
type: system-reference
title: RBAC Integration & Permission Checking
description: Role-based access control, permission enforcement, authorization policies, and permission checking patterns in Akaunting.
tags: [authentication, authorization, rbac, permissions, policies]
---

# RBAC Integration & Permission Checking

Akaunting uses **Laratrust** for role-based access control (RBAC). Permissions are checked at multiple layers: middleware, controller authorization, and request validation. All RBAC is scoped per company—users have different roles and permissions in different companies.

## Permission Naming Convention

Permissions follow the pattern: `{action}-{domain}-{resource}`

**Action**: create, read, update, delete
**Domain**: common, sales, purchases, banking, auth, settings, modules
**Resource**: companies, contacts, invoices, bills, accounts, transactions, etc.

**Examples**:
- `create-common-companies` – Create a new company
- `read-sales-invoices` – View invoices
- `update-banking-accounts` – Modify bank accounts
- `delete-common-contacts` – Remove contacts

## Permission Definitions

Permissions are defined in **`config/type.php`** under the `permission` key. This is the canonical list of all system permissions.

**Example structure**:
```php
'permission' => [
    'create' => [
        'common' => ['companies', 'contacts', 'items', ...],
        'sales' => ['invoices', ...],
        'banking' => ['accounts', 'transactions', ...],
    ],
    'read' => [...],
    'update' => [...],
    'delete' => [...],
],
```

**Reading permissions from config**:
```php
// Get all permissions for a domain
$permissions = config('type.permission.read.sales');

// Check if permission exists
collect(config('type.permission'))->has('create.common.companies');
```

## Permission Checking in Controllers

### Using Laratrust Middleware

The `permission` middleware checks if the authenticated user has the required permission in their current company.

**Syntax in routes**:
```php
Route::get('/invoices', [InvoiceController::class, 'index'])
    ->middleware('permission:read-sales-invoices');

Route::post('/invoices', [InvoiceController::class, 'store'])
    ->middleware('permission:create-sales-invoices');
```

**Multiple permissions** (OR logic):
```php
->middleware('permission:create-sales-invoices|create-sales-quotes')
```

### Using Authorization in Controllers

In controller methods, use Laravel's authorization gates:

```php
// Inside controller method
public function store(Request $request)
{
    // Using authorize() helper with action and model
    $this->authorize('create', Invoice::class);
    
    // Proceed with business logic
}

public function update(Request $request, Invoice $invoice)
{
    // Check permission on specific model
    $this->authorize('update', $invoice);
}
```

### Using Gate Checks

Direct gate checks in code:

```php
if (Gate::denies('read-sales-invoices')) {
    abort(403, 'Unauthorized');
}

// Or the inverse
if (Gate::allows('create-common-companies')) {
    // User has permission
}
```

## Permission Checking in Requests

Form request classes can define authorization rules:

**Example: `app/Http/Requests/Document/Document.php`**
```php
public function authorize()
{
    // Check if user can create/update document
    $action = $this->isMethod('post') ? 'create' : 'update';
    $permission = "{$action}-sales-invoices";
    
    return auth()->user()->hasPermission($permission, auth()->user()->currentCompany());
}
```

## User Methods for Permission Checking

The `User` model provides several permission-checking methods (via `LaratrustUserTrait`):

### hasPermission()

Check if user has a specific permission in a company:

```php
$user->hasPermission('create-sales-invoices', $company);
// Returns: true/false

// Without company parameter (uses current company context)
$user->hasPermission('create-sales-invoices');
```

### hasRole()

Check if user has a role in a company:

```php
$user->hasRole('Manager', $company);
$user->hasRole(['Manager', 'Accountant'], $company);
```

### hasAnyRole()

Check if user has at least one role:

```php
$user->hasAnyRole(['Manager', 'Accountant'], $company);
```

### getAllPermissions()

Get all permissions assigned to user in a company:

```php
$permissions = $user->getAllPermissions($company);
// Returns collection of Permission models
```

## Roles & Role Assignment

### Core Roles

Akaunting ships with default roles:

- **Owner** – Full system access, can create companies
- **Manager** – Full control within company
- **Accountant** – Can create and manage accounting documents
- **Vendor** – Limited access; can view own documents

### Assigning Roles to Users

Roles are assigned per company via the `UserRole` pivot table:

```php
// Assign role in specific company
$user->attachRole('Manager', $company->id);

// Detach role
$user->detachRole('Manager', $company->id);

// Get user's roles in company
$roles = $user->roles($company->id);
```

### Permission Inheritance

When a role is assigned to a user, all permissions for that role are inherited. The permission relationship is:

```
User --[UserRole]---> Role --[RolePermission]---> Permission
      (per company)
```

## Common Authorization Patterns

### 1. Check Permission in Controller

```php
class InvoiceController extends Controller
{
    public function show(Invoice $invoice)
    {
        $this->authorize('read', $invoice);
        
        return response()->json($invoice);
    }
}
```

### 2. Check Permission in Request Validation

```php
class StoreInvoiceRequest extends Request
{
    public function authorize()
    {
        return auth()->user()->hasPermission(
            'create-sales-invoices',
            auth()->user()->currentCompany()
        );
    }
}
```

### 3. Hide UI Elements Based on Permission

In Blade templates:

```blade
@if(auth()->user()->hasPermission('create-sales-invoices'))
    <a href="{{ route('invoices.create') }}">Create Invoice</a>
@endif
```

### 4. Skip Permission Check for Owner

Owner role always has all permissions. To explicitly check:

```php
if (auth()->user()->hasRole('Owner', $company)) {
    // Owner-only logic
}
```

## API Authorization

API endpoints use the same permission checking system via middleware:

**`routes/api.php` example**:
```php
Route::group(['middleware' => ['permission:read-sales-invoices']], function () {
    Route::get('/invoices', [Api\Document\Documents::class, 'index']);
});
```

API authentication is handled by Bearer tokens. See [API Authentication](../api/authentication.md) for token setup.

## Database Schema

### Permissions Table

```
permissions
├── id (int)
├── name (string) – Permission key like 'create-sales-invoices'
├── display_name (string) – 'Create Sales Invoices'
├── description (text)
├── created_at (timestamp)
└── updated_at (timestamp)
```

### Roles Table

```
roles
├── id (int)
├── name (string) – 'manager'
├── display_name (string) – 'Manager'
├── description (text)
├── created_from (string) – 'core' or module name
├── created_by (int) – User ID
├── created_at (timestamp)
├── updated_at (timestamp)
└── deleted_at (timestamp)
```

### Role Permissions (Pivot)

```
role_permission (pivot)
├── role_id (int)
└── permission_id (int)
```

### User Roles (Pivot)

```
user_role (pivot)
├── user_id (int)
├── role_id (int)
└── company_id (int) – Company context
```

## Permission Checks in Jobs

Jobs often check permissions when dispatched:

```php
class CreateInvoiceJob extends Job
{
    public function handle()
    {
        // Check permission was already done in controller
        // Jobs assume caller was authorized
        
        // Create invoice...
    }
}
```

## Extension: Custom Permissions

Third-party modules can register custom permissions via service providers:

**Example**: `modules/MyModule/Providers/ModuleServiceProvider.php` (illustrative path structure)
```php
public function boot()
{
    Permission::firstOrCreate([
        'name' => 'create-mymodule-items',
        'display_name' => 'Create MyModule Items',
        'description' => 'Allow users to create custom items',
    ]);
}
```

## Testing Authorization

In feature tests, check authorization:

```php
$this->actingAs($user)->post('/api/invoices', [...])->assertForbidden();

$user->attachRole('Manager', $company->id);
$this->actingAs($user)->post('/api/invoices', [...])->assertCreated();
```

---

## Related Pages

- [Auth System Overview](overview.md) – User and role models
- [API Authentication](../api/authentication.md) – API token setup and validation
