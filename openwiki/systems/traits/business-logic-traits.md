---
type: system-reference
title: Business Logic Traits - Permissions, Tenants, Categories
description: Traits providing authentication, authorization, multi-tenancy, and categorization behaviors.
tags: [traits, permissions, multi-tenancy, categories, authorization]
openwiki:
  source_paths: [app/Traits/Permissions.php, app/Traits/Tenants.php, app/Traits/Categories.php]
---

# Business Logic Traits

Business logic traits provide cross-cutting concerns like permissions, multi-tenancy, and categorization that are shared across many models.

## Permissions Trait

**File**: `App\Traits\Permissions`

Provides authorization and permission checking on User models.

### Methods

```php
$user->can($action, $model_class);        // Check permission for action/model
$user->cannot($action, $model_class);     // Inverse of can()
$user->hasRole($role_name);               // Check if user has role
$user->inRole($role_name);                // Alias for hasRole()
$user->hasAnyRole($roles_array);          // Check multiple roles
$user->roles();                           // Get user's roles (per company)
$user->permissions();                     // Get all permissions for user
$user->abilities();                       // Alias for permissions()
```

### Permission Checking Examples

```php
// In controller
if ($this->authorize('create', Document::class)) {
    $document = $this->dispatch(new CreateDocument($data));
}

// In condition
if (auth()->user()->can('read', $invoice)) {
    $this->show($invoice);
}

// In request
public function authorize()
{
    return auth()->user()->can('delete', $this->model);
}

// In policy
public function update(User $user, Document $document)
{
    return $user->can('update', Document::class);
}
```

### Role Checking

```php
// Current user's roles in current company
auth()->user()->hasRole('accountant');     // true/false
auth()->user()->hasRole('admin');         // true/false

// Check if user has any of multiple roles
auth()->user()->hasAnyRole(['admin', 'accountant', 'manager']);

// Get all roles for user (company-scoped)
$roles = auth()->user()->roles();
```

### Permission Constants

Standard permissions defined in `config/type.php`:

```php
'permission' => [
    'create-common-companies' => 'Create Company',
    'read-common-companies' => 'Read Company',
    'update-common-companies' => 'Update Company',
    'delete-common-companies' => 'Delete Company',
    
    'create-sales-invoices' => 'Create Invoice',
    'read-sales-invoices' => 'Read Invoice',
    'update-sales-invoices' => 'Update Invoice',
    'delete-sales-invoices' => 'Delete Invoice',
    
    // ... more permissions
]
```

### Permission Integration

```php
// In controller route
Route::post('/invoices', [InvoiceController::class, 'store'])
    ->middleware('permission:create-sales-invoices');

// In controller method
public function store(Request $request)
{
    $this->authorize('create', Document::class);
    // ...
}

// In job
public function authorize()
{
    return auth()->user()->can('create', Document::class);
}
```

## Tenants Trait

**File**: `App\Traits\Tenants`

Implements multi-tenancy by automatically scoping all queries to current company.

### Global Scope

```php
trait Tenants
{
    protected static function bootTenants()
    {
        static::addGlobalScope('tenant', function ($query) {
            $query->whereCompanyId(
                auth()->user()->currentCompany()->id
            );
        });
    }
}
```

**Effect**: Every query automatically filters by `company_id` of authenticated user's current company.

### Automatic Scoping

```php
// Before: SELECT * FROM documents
// Automatically becomes: SELECT * FROM documents WHERE company_id = 1

Document::all();                           // Only company 1's documents

// Different company
auth()->user()->setCurrentCompany($other_company);
Document::all();                           // Now returns company 2's documents
```

### Bypassing Global Scope

When needed (admin only):

```php
// Get all documents from all companies
Document::withoutGlobalScopes()->get();

// Get all documents except tenant scope
Document::withoutGlobalScope('tenant')->get();

// Temporarily disable
Document::withoutGlobalScopes(function ($query) {
    return $query->where('status', 'paid');
});
```

### Models Using Tenants Trait

```php
// All these models are automatically scoped to company
Document, Contact, Item, Account, Transaction,
Category, Tax, Currency, User, Report, Dashboard, Role
```

### Tenancy in Relationships

```php
// When loading related data
$document->contact;     // Automatically same company

// But relationship queries are NOT auto-scoped
// Must manually scope related queries
$document->contact()
    ->where('company_id', auth()->user()->currentCompany()->id)
    ->first();
```

### Company Switching

```php
// User switches company
auth()->user()->setCurrentCompany($other_company_id);

// All subsequent queries use new company
Document::all();        // Now returns other_company's documents
Contact::all();         // Now returns other_company's contacts
```

## Categories Trait

**File**: `App\Traits\Categories`

Provides category relationship and categorization queries for transactions and documents.

### Relationships

```php
$transaction->category();      // BelongsTo: Category
$transaction->categories();    // BelongsToMany: Multiple categories (if applicable)
```

### Query Methods

```php
Transaction::byCategory($category_id)->get();
Transaction::byCategories($category_ids)->get();
Document::byCategory($category_id)->get();
```

### Categories Available

Categories are typically organized by type:

```php
// Expense categories
Bank Fees, Office Supplies, Travel, Meals, Utilities, Payroll

// Income categories
Service Revenue, Product Sales, Consulting, Interest

// Transfer (none)
```

### Categorizing Transactions

```php
// Create transaction with category
$transaction = $this->dispatch(new CreateTransaction([
    'type' => 'expense',
    'account_id' => $account->id,
    'category_id' => $travel_category->id,  // Required
    'amount' => '500.00',
    'description' => 'Business travel',
]));

// Query by category
Transaction::byCategory($travel_category->id)->sum('amount');
// Total expense for travel category
```

### Reports by Category

```php
// Expense breakdown by category
$expenses = Transaction::where('type', 'expense')
    ->groupBy('category_id')
    ->selectRaw('category_id, SUM(amount) as total')
    ->get();

foreach ($expenses as $expense) {
    echo $expense->category->name . ": " . $expense->total;
}
```

## Other Business Logic Traits

### Companies Trait

Manages company-level operations:

```php
$company->owner();              // User who owns company
$company->users();              // All users with access
$company->settings();           // Company settings
$company->logo();               // Company logo
```

### Contacts Trait

Polymorphic contact handling:

```php
$contact->type;                 // 'customer' or 'vendor'
$contact->documents();          // All documents (invoices/bills)
$contact->transactions();       // All payments
$contact->enable();             // Activate contact
$contact->disable();            // Deactivate contact
```

### Settings Trait

Access to system and company settings:

```php
setting('company.name');        // Get setting
setting()->put('company.name', 'New Name');  // Set setting
```

### Jobs Trait

Job dispatching utilities:

```php
$this->dispatch(new JobClass($data));  // Dispatch synchronously
$this->dispatchAsync(new JobClass($data));  // Dispatch async (queue)
```

## Combining Traits

Traits work together seamlessly:

```php
class Document extends Model
{
    use Tenants;        // Scope to company
    use Permissions;    // Auth checking
    use Categories;     // Categorization
    use Documents;      // Relationships
}

// All work together
Document::all();                           // Scoped to company
if (auth()->user()->can('read', Document::class)) {
    $documents = Document::byCategory($cat_id)->get();
}
```

## Real-World Examples

### Multi-company authorization

```php
public function show(Document $document)
{
    // Automatically in current company (Tenants trait)
    // Check authorization (Permissions trait)
    $this->authorize('read', $document);
    
    return view('documents.show', ['document' => $document]);
}
```

### Category-based expense reporting

```php
public function expenseReport()
{
    // Get all expense transactions (scoped to company)
    $expenses = Transaction::where('type', 'expense')
        ->byCategory(request('category_id'))
        ->get();
    
    // Only shows current company's data
    return $expenses;
}
```

### Permission-gated feature

```php
if (auth()->user()->can('create', Document::class)) {
    // Show create invoice button
}

if (auth()->user()->hasRole('accountant')) {
    // Show accounting features
}
```

### Company isolation verification

```php
// In test or admin verification
$company1 = Company::first();
$company2 = Company::skip(1)->first();

auth()->user()->setCurrentCompany($company1);
$company1_docs = Document::all()->count();

auth()->user()->setCurrentCompany($company2);
$company2_docs = Document::all()->count();

// Queries return different data based on company
// No data leakage between companies
```

## Related Pages

- [Traits Overview](overview.md) – All traits
- [RBAC Integration](../auth/rbac.md) – Permission system details
- [Multi-Tenancy Workflow](../../workflows/multi-tenancy.md) – Company isolation workflow

## Source Map

```
app/Traits/
├─ Permissions.php       # Authorization checking
├─ Tenants.php          # Multi-tenancy scoping
├─ Categories.php       # Categorization
├─ Companies.php        # Company operations
├─ Contacts.php         # Polymorphic contacts
└─ Settings.php         # Settings access

config/type.php         # Permission definitions
```

## Testing & Validation

```bash
# Test permission trait
php artisan test tests/Feature/Auth/PermissionTraitTest.php

# Test tenants trait
php artisan test tests/Feature/Traits/TenantsTraitTest.php

# Test multi-company isolation
php artisan test tests/Feature/MultiTenancy/IsolationTest.php

# Test category filtering
php artisan test tests/Feature/Traits/CategoriesTraitTest.php
```

## Common Patterns

### Verify company isolation

```php
// User A in Company 1
$company1_invoice = Invoice::first();

// User B in Company 2
auth()->user()->setCurrentCompany($company2_id);
$invoices = Invoice::all();
// Should NOT include User A's invoices
```

### Permission-based UI rendering

```blade
@can('create', App\Models\Document\Document::class)
    <button>Create Invoice</button>
@endcan

@if(auth()->user()->hasRole('admin'))
    <a href="/admin/settings">Settings</a>
@endif
```

### Safe querying across companies (admin only)

```php
// Only for admins
if (auth()->user()->hasRole('admin')) {
    Document::withoutGlobalScopes()
        ->where('company_id', $target_company)
        ->get();
}
```
