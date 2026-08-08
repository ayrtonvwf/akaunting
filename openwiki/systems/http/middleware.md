---
type: system-reference
title: Middleware & Routing
description: Request lifecycle, company identification middleware, authentication, and core HTTP middleware stack in Akaunting.
tags: [middleware, routing, request-lifecycle, company-identification]
---

# Middleware & Routing

The Middleware stack handles request processing, company context, authentication, authorization, and cross-cutting concerns. Middleware runs before controllers and shapes the request environment.

## Request Lifecycle

```
HTTP Request
    │
    ├─ Routes Matched (routes/admin.php, routes/api.php, etc.)
    │
    ├─ Middleware Stack (before)
    │  ├─ Global middleware (all requests)
    │  ├─ Route-specific middleware
    │  └─ Controller middleware
    │
    ├─ Controller Action
    │
    └─ Middleware Stack (after)
       ├─ Response modification
       └─ HTTP Response
```

## Core Middleware

### Company Context Middleware

**Purpose**: Identify and set current company for the request

**Flow**:
1. Extract company ID from URL/session/default
2. Verify user has access to company
3. Set `auth()->user()->authenticated_company_id`
4. Apply global scope to queries (all models filtered by company_id)

**Location**: `app/Http/Middleware/IdentifyCompany.php`

**Usage in routes**:
```php
Route::prefix('companies/{company_id}')->middleware('company')->group(function () {
    Route::get('invoices', [InvoiceController::class, 'index']);
    // All requests scoped to {company_id}
});
```

**Effect**:
```php
// Inside controller
$company = auth()->user()->currentCompany();
// Returns the identified company

Document::all();  // Auto-scoped to currentCompany()->id
```

### Authentication Middleware

**Purpose**: Verify user is logged in

**Name**: `auth`

```php
Route::group(['middleware' => 'auth'], function () {
    Route::get('/dashboard', [DashboardController::class, 'show']);
});
```

**Unauthenticated request**: Redirects to login page

### Permission Middleware

**Purpose**: Check user has specific permission in current company

**Name**: `permission`

```php
Route::post('/invoices', [InvoiceController::class, 'store'])
    ->middleware('permission:create-sales-invoices');
```

**Unauthorized**: Returns 403 Forbidden

See [RBAC Integration](../auth/rbac.md) for permission system.

### API Token Middleware

**Purpose**: Authenticate API requests via Bearer token

**Name**: `auth:api` or `auth:sanctum`

```php
Route::group(['middleware' => 'auth:sanctum'], function () {
    Route::get('/api/invoices', [Api\InvoiceController::class, 'index']);
});
```

**Token validation**:
1. Extract Bearer token from Authorization header
2. Find corresponding API token record
3. Load associated user
4. Set auth()->user()

See [API Authentication](../api/authentication.md).

## Route Groups

### Admin Routes

**File**: `routes/admin.php`

Web-based administrative interface for authenticated users.

```php
// All admin routes require authentication and company context
Route::group([
    'prefix' => 'admin',
    'middleware' => ['auth', 'company'],
], function () {
    Route::resource('invoices', InvoiceController::class);
});

// URL: /admin/companies/1/invoices
```

**Middleware stack**:
- `auth` – Require login
- `company` – Set company context
- CSRF protection (web)
- Session

### API Routes

**File**: `routes/api.php`

REST API for programmatic access.

```php
Route::group([
    'prefix' => 'api',
    'middleware' => ['auth:sanctum'],
], function () {
    Route::get('/invoices', [Api\InvoiceController::class, 'index']);
});

// URL: /api/invoices
// Header: Authorization: Bearer {token}
```

**Middleware stack**:
- `auth:sanctum` – Require valid API token
- No CSRF (stateless)
- No session

### Portal Routes

**File**: `routes/portal.php`

Customer/vendor portal for limited access.

```php
Route::group([
    'prefix' => 'portal',
    'middleware' => ['auth:web'],
], function () {
    Route::get('/invoices', [Portal\InvoiceController::class, 'index']);
});

// URL: /portal/invoices
// Authenticated via web session (customers)
```

### Wizard Routes

**File**: `routes/wizard.php`

Installation/setup wizard (no auth required initially).

```php
Route::group([
    'prefix' => 'wizard',
], function () {
    Route::get('/step1', [WizardController::class, 'step1']);
    Route::post('/step1', [WizardController::class, 'storeStep1']);
});
```

## Global Middleware

Applied to all requests:

**File**: `app/Http/Kernel.php`

```php
protected $middleware = [
    // Check for HTTPS
    \Illuminate\Foundation\Http\Middleware\CheckForMaintenanceMode::class,
    
    // Encryption/security headers
    \Illuminate\Http\Middleware\ValidatePostSize::class,
    \App\Http\Middleware\ConvertEmptyStringsToNull::class,
    \App\Http\Middleware\TrustProxies::class,
];
```

## Route-Specific Middleware

Applied only to matching routes:

**In routes file**:
```php
Route::post('/invoices', [InvoiceController::class, 'store'])
    ->middleware(['auth', 'permission:create-sales-invoices']);
```

**In controller constructor**:
```php
class InvoiceController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth');
        $this->middleware('permission:update-sales-invoices')->only('update');
    }
}
```

## Common Middleware Patterns

### Multi-Step Permission Check

Some operations require multiple permissions:

```php
// Check both invoice read and document delete
Route::delete('/invoices/{id}', [InvoiceController::class, 'destroy'])
    ->middleware('permission:read-sales-invoices')
    ->middleware('permission:delete-sales-invoices');
```

### Conditional Middleware

Apply middleware conditionally:

```php
if (request()->isApi()) {
    $middlewares = ['auth:sanctum'];
} else {
    $middlewares = ['auth', 'company'];
}

Route::group(['middleware' => $middlewares], function () {
    // Routes
});
```

### Middleware Aliases

Define commonly-used middleware combinations:

**In Kernel.php**:
```php
protected $middlewareAliases = [
    'auth' => \App\Http\Middleware\Authenticate::class,
    'company.identify' => \App\Http\Middleware\IdentifyCompany::class,
    'permission' => \Laratrust\Middleware\LaratrustPermission::class,
    // ... other middleware
];
```

## Testing with Middleware

**Feature tests** automatically respect middleware:

```php
// Without auth – 401 Unauthenticated
$response = $this->get('/admin/invoices');
$response->assertRedirect('/login');

// With auth – 200 Success
$response = $this->actingAs($user)->get('/admin/invoices');
$response->assertOk();
```

## Source Map

| Concept | File |
|---------|------|
| Middleware | `app/Http/Middleware/` |
| Kernel | `app/Http/Kernel.php` |
| Admin routes | `routes/admin.php` |
| API routes | `routes/api.php` |
| Portal routes | `routes/portal.php` |

## Related Pages

- [RBAC Integration](../auth/rbac.md) – Permission checking
- [API Authentication](../api/authentication.md) – API token validation
- [Controllers Overview](controllers.md) – Request handlers
