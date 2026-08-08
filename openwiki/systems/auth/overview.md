---
type: system-overview
title: Auth System - Users, Roles & Permissions
description: Authentication, authorization, role-based access control (RBAC), and API token management in Akaunting.
tags: [authentication, authorization, rbac, users, roles, permissions]
---

# Auth System Overview

The Auth system manages user authentication, authorization via role-based access control (RBAC), and API token-based authentication. All auth data is multi-tenant at the company level—users have roles per company, not globally.

## Core Components

### Models

#### User (App\Models\Auth\User)

The primary authentication entity. Uses Laravel's standard `Authenticatable` and Laratrust's `LaratrustUserTrait`.

**Attributes**:
- `name`: Display name
- `email`: Unique email address
- `password`: Bcrypt-hashed password
- `locale`: User's language preference
- `enabled`: Whether user can login
- `landing_page`: Default dashboard on login
- `created_at`, `updated_at`, `deleted_at`

**Key Methods**:
```php
$user->companies();          // BelongsToMany: companies user owns/has access to
$user->roles($company_id);   // Get roles in specific company
$user->hasPermission('create-sales-invoices', $company);  // RBAC check
$user->dashboards();         // Assigned dashboards
$user->contact();            // Linked contact (if user is also a vendor/customer)
```

**Hidden Attributes**: password, remember_token

#### Role (App\Models\Auth\Role)

Named group of permissions. Assigned to users per company via `UserRole` pivot.

**Attributes**:
- `name`: Role name (e.g., "Manager", "Accountant")
- `display_name`: Human-readable name
- `description`: Role purpose
- `enabled`: Active/inactive

**Key Methods**:
```php
$role->permissions();        // HasMany: permissions in role
$role->users($company_id);   // Get users with this role in company
```

#### Permission (App\Models\Auth\Permission)

Individual action permission. Defined in `config/type.php` and referenced in middleware/policies.

**Attributes**:
- `name`: Permission key (e.g., `create-common-companies`)
- `display_name`: Human-readable label
- `description`: What the permission grants

**Format**: `{action}-{domain}-{resource}`
- Actions: create, read, update, delete
- Domains: common, sales, banking, auth, settings
- Resources: invoices, companies, contacts, accounts, etc.

#### UserRole (App\Models\Auth\UserRole)

Pivot table associating users to roles per company.

**Key Fields**:
- `user_id`: User ID
- `role_id`: Role ID
- `company_id`: Company context

This enables per-company role assignment. Same user can be "Manager" in Company A and "Accountant" in Company B.

#### UserCompany (App\Models\Auth\UserCompany)

Pivot table associating users to companies they have access to.

**Key Fields**:
- `user_id`: User ID
- `company_id`: Company ID
- Additional per-company user settings (stored as attributes)

### Traits

**HasApiTokens** (`App\Traits\HasApiTokens`):
Provides API token management for the User model.

**Methods**:
```php
$user->createToken('token-name');     // Generate new API token
$user->tokens();                        // Get all tokens for user
```

Tokens stored in `personal_access_tokens` table (Laravel Sanctum).

**LaratrustUserTrait**:
From package `santigarcor/laratrust`. Provides:
```php
$user->attachRole($role, $company_id);          // Assign role in company
$user->detachRole($role, $company_id);          // Remove role
$user->hasRole('Manager', $company_id);         // Check role
$user->hasPermission('update-sales-invoices');  // Check permission
```

---

## Authentication Flow

### Login Process

1. **Route**: POST `/admin/auth/login` (from `routes/admin.php` or guest routes)
2. **Controller**: `App\Http\Controllers\Auth\Login@store`
3. **Validation**: Email and password via form request
4. **Check**: User exists, enabled, password correct
5. **Session**: Auth session created; cookies set
6. **Redirect**: User dashboard or configured landing page

### Session Management

**Middleware**:
- `Authenticate`: Verify session exists (`app/Http/Middleware/Authenticate.php`)
- `RedirectIfAuthenticated`: Prevent logged-in users accessing login page
- `LogoutIfUserDisabled`: Auto-logout if user disabled in admin

**Helper Functions**:
```php
user()                      // Get current authenticated user
auth()->check()            // Check if authenticated
auth()->logout()           // Logout current user
auth()->guard('web')       // Explicit guard access
```

### Password Reset

Flow via Laravel Fortify or custom reset controller:
1. User requests password reset link via email
2. Link contains signed token with expiry
3. User enters new password
4. Token validated, password hashed and updated
5. User redirected to login

---

## Authorization: RBAC (Role-Based Access Control)

### Permission Definition

All permissions defined in `config/type.php`:

```php
'permission' => [
    'create-common-companies' => 'Create Companies',
    'read-common-companies' => 'Read Companies',
    'update-common-companies' => 'Update Companies',
    'delete-common-companies' => 'Delete Companies',
    'create-sales-invoices' => 'Create Invoices',
    'read-sales-invoices' => 'Read Invoices',
    // ... 50+ more permissions across domains
]
```

### Permission Checking

#### Middleware

```php
// In routes
Route::post('invoices', 'Sales\Invoices@store')
    ->middleware('permission:create-sales-invoices');

// In controller constructor
$this->middleware('permission:read-sales-invoices')
    ->only('index', 'show');
```

**Middleware**: `\Laratrust\Middleware\LaratrustPermission` (alias: `permission` in `app/Http/Kernel.php`)

#### Policy-Based

```php
// In controller
$this->authorize('create', Invoice::class);

// In policy
public function create(User $user)
{
    return $user->hasPermission('create-sales-invoices');
}
```

#### Trait Method

```php
// In Permissions trait
if ($this->user->cannot('read-sales-invoices')) {
    abort(403);
}
```

#### Helper Function

```php
// Direct permission check
if (! user()->hasPermission('create-sales-invoices')) {
    abort(403);
}
```

### Role Assignment

**Creating Role**:
```php
$role = Role::create([
    'name' => 'accountant',
    'display_name' => 'Accountant',
    'description' => 'Can manage invoices and bills',
]);

// Attach permissions
$role->attachPermission('create-sales-invoices');
$role->attachPermission('read-sales-invoices');
$role->attachPermission('create-banking-transactions');
```

**Assigning User to Role** (per company):
```php
$user->attachRole('accountant', $company->id);  // Laratrust

// Or via job
dispatch(new AssignRole($user, $role, $company));
```

### Checking Permissions

```php
// Check single permission
$user->hasPermission('create-sales-invoices');  // Boolean

// Check multiple permissions (any)
$user->hasAnyPermission(['create-sales-invoices', 'update-sales-invoices']);

// Check multiple permissions (all)
$user->hasAllPermissions(['create-sales-invoices', 'read-sales-invoices']);

// Check role
$user->hasRole('manager', $company_id);
```

---

## API Token Authentication

### Token Generation

```php
// Create token with scopes
$token = $user->createToken('MyAppToken', ['read', 'write']);
$accessToken = $token->plainTextToken;  // Share with API consumer
```

Tokens stored encrypted in `personal_access_tokens` table.

### Using API Token

**Request Header**:
```
Authorization: Bearer {plainTextToken}
```

**Middleware**: `auth.dynamic.once` authenticates via:
1. Bearer token (Laravel Sanctum)
2. Basic auth (username:password base64)

Reference: [API Authentication](../api/authentication.md)

### Token Scopes

Scopes control API access granularity:
- `read`: Read-only operations (GET)
- `write`: Write operations (POST, PUT, DELETE)
- Custom scopes for specific domains: `read-invoices`, `write-transactions`

Checked in routes via `can` middleware.

---

## User Management

### Creating Users

**Route**: POST `/admin/auth/users` (admin panel)

**Controller**: `App\Http\Controllers\Auth\Users@store`

**Job**: `App\Jobs\Auth\CreateUser`

**Flow**:
1. Form validates email uniqueness, password strength
2. Job creates user record
3. Job fires `UserCreated` event
4. Listeners send invitation email if needed
5. User can reset password via email link

**Validation Rules**:
```php
'name' => 'required|string',
'email' => 'required|email|unique:users',
'password' => 'required|min:8|confirmed',
```

### Enabling/Disabling Users

Users can be disabled without deletion (soft delete).

```php
// Disable user
$user->update(['enabled' => false]);

// Logout automatically on next request via LogoutIfUserDisabled middleware
```

### Inviting Users

**API**: `GET /admin/auth/users/{user}/invite`

Sends invitation email with reset link to new users.

**Job**: `App\Jobs\Auth\NotifyUser`

### Deleting Users

**Soft Delete**: User record marked as deleted but data preserved.

```php
$user->delete();         // Soft delete
$user->forceDelete();    // Permanent delete
$user->restore();        // Restore soft-deleted user
```

Related data may be reassigned to other users or marked with `deleted_at`.

---

## User Invitations

### UserInvitation Model

Tracks user invitations before acceptance.

**Fields**:
- `user_id`: User being invited
- `invitation_code`: Unique code for email link
- `expires_at`: Invitation expiry date

### Invitation Flow

1. Admin invites user via `/auth/users/{user}/invite`
2. Invitation record created with unique code
3. Email sent with reset link containing code
4. User clicks link, sets password
5. Invitation marked as accepted, user enabled

---

## User Dashboard & Landing Pages

### Landing Pages

Different user types can have different landing pages on login.

**Setting**: User `landing_page` attribute

**Types**:
- `/` (dashboard)
- `/sales/invoices` (invoices list)
- `/banking/accounts` (accounts list)
- Custom module pages

### User Dashboards

Each user can assign custom dashboards to their profile.

**Model**: `App\Models\Auth\UserDashboard` (pivot)

**Usage**: Render dashboard widgets based on user's selection

---

## User Profile & Settings

### Profile Controller

**Routes**:
- GET `/admin/auth/profile/{user}/edit` – Edit profile form
- PATCH `/admin/auth/profile/{user}` – Update profile

**Editable Fields**:
- name
- email
- password
- locale (language)
- landing_page
- avatar (media)

### Locale Preference

User's language preference respected throughout application.

**Implementation**: User model implements `HasLocalePreference`

```php
public function preferredLocale()
{
    return $this->locale;
}
```

Laravel respects this when sending notifications, validating dates, formatting.

---

## Guest & Portal Access

### Portal Routes

Customers/vendors can view invoices and bills via portal (read-only).

**Routes**: `routes/portal.php`

**Access**: Signed URL or session-based if customer email matches

**Permissions**: Portal users have no RBAC roles; limited view-only access

**Models Visible**:
- Documents they're on (invoices as customer, bills as vendor)
- Contact information
- Payment history

---

## Integration with Multi-Tenancy

### Company Scoping

Users don't have global permissions; permissions are per-company.

```php
// User's roles vary per company
$user->roles(company_id: 1);  // "Manager" in Company 1
$user->roles(company_id: 2);  // "Accountant" in Company 2
```

### Company Identification Middleware

**Middleware**: `App\Http\Middleware\IdentifyCompany`

Extracts company_id from URL and validates user has access:

```php
// Validates current user has access to company before proceeding
if (! $user->companies()->find(company_id())) {
    abort(403);
}
```

### Default Company

```php
// Get user's default/current company
company()               // Returns current company instance
company_id()            // Returns current company ID
$user->companies()->first()  // First company user owns
```

---

## Extension Points

### Custom Permission

Add to `config/type.php` and use in middleware/policies.

### Custom Role

Create via seeder or admin panel; attach permissions via pivot.

### Custom Policy

Create policy class in `app/Policies/`, authorize in controller.

### Custom Guards

Additional auth guards can be defined in `config/auth.php` for special scenarios (e.g., API-only).

---

## Best Practices

1. **Check Permissions**: Always use middleware or `authorize()` for sensitive actions
2. **Scope to Company**: Ensure all queries scoped to current company_id
3. **Soft Delete Users**: Delete instead of hard-delete to preserve data linkage
4. **Token Expiry**: Implement token rotation and expiry for security
5. **Activity Logging**: Log successful logins and permission denials for audit

---

## Testing Auth

```php
// Feature test: Login flow
public function test_user_can_login()
{
    $user = User::factory()->create(['password' => 'password']);
    
    $response = $this->post('/login', [
        'email' => $user->email,
        'password' => 'password',
    ]);
    
    $this->assertAuthenticatedAs($user);
}

// Feature test: Permission check
public function test_user_without_permission_denied_access()
{
    $user = User::factory()->create();
    $user->detachAllPermissions();  // Remove all permissions
    
    $response = $this->actingAs($user)->get(route('invoices.index'));
    
    $response->assertForbidden();
}

// Feature test: API token
public function test_api_endpoint_rejects_invalid_token()
{
    $response = $this->getJson(route('api.documents.index'), [
        'Authorization' => 'Bearer invalid-token',
    ]);
    
    $response->assertUnauthorized();
}
```

---

*Reference: /app/Models/Auth, /app/Http/Controllers/Auth, /app/Traits/HasApiTokens, /config/laratrust.php, /config/type.php (permissions)*
