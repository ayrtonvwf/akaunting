---
type: system-reference
title: Auth Jobs - User & Permission Management
description: Job classes for user creation, updates, role management, and permission operations in Akaunting.
tags: [jobs, auth, users, roles, permissions]
openwiki:
  source_paths: [app/Jobs/Auth]
  symbols: [CreateUser, UpdateUser, DeleteUser, CreateRole, UpdateRole, DeleteRole, CreatePermission, CreateInvitation]
---

# Auth Jobs

Auth jobs handle all user account and permission management operations. These are the canonical places for user lifecycle, role assignment, and permission changes.

## User Management Jobs

### CreateUser

**File**: `App\Jobs\Auth\CreateUser`

**Purpose**: Create a new user account

**Input**:
```php
$data = [
    'email' => 'user@example.com',
    'password' => 'hashed_password',
    'name' => 'John Doe',
    'locale' => 'en',          // Optional
]
```

**Process**:
1. Validate email is unique
2. Hash password if plain text
3. Create User model
4. Set user locale/timezone
5. Fire `UserCreated` event
6. Return User instance

**Usage**:
```php
$user = $this->dispatch(
    new CreateUser($request->validated())
);

return new UserResource($user);
```

**Events Fired**:
- `App\Events\Auth\UserCreated` – User account created

### UpdateUser

**File**: `App\Jobs\Auth\UpdateUser`

**Purpose**: Update user profile or password

**Input**:
```php
$data = [
    'name' => 'New Name',       // Optional
    'email' => 'newemail@...',  // Optional
    'password' => 'new_pass',   // Optional
    'locale' => 'es',           // Optional
]
```

**Process**:
1. Verify user has permission
2. Update editable fields
3. Hash password if provided
4. Fire `UserUpdated` event
5. Return User instance

**Usage**:
```php
$user = $this->dispatch(
    new UpdateUser($existing_user, $request->validated())
);
```

**Events Fired**:
- `App\Events\Auth\UserUpdated` – User profile changed

### DeleteUser

**File**: `App\Jobs\Auth\DeleteUser`

**Purpose**: Delete user account and revoke all access

**Input**:
```php
$user_instance  // The User to delete
```

**Process**:
1. Verify user is not the last admin
2. Revoke all API tokens
3. Remove from all companies/roles
4. Soft delete user record
5. Fire `UserDeleted` event
6. Return success

**Usage**:
```php
$this->dispatch(new DeleteUser($user));
```

**Events Fired**:
- `App\Events\Auth\UserDeleted` – User deleted

**Validation**:
- Cannot delete if only admin user remains
- Cannot delete currently authenticated user

## Role Management Jobs

### CreateRole

**File**: `App\Jobs\Auth\CreateRole`

**Purpose**: Create a new role with permissions

**Input**:
```php
$data = [
    'name' => 'Accountant',
    'display_name' => 'Accountant Role',
    'description' => 'Can manage invoices and reports',
    'permissions' => ['create-sales-invoices', 'read-reports'],  // Optional
]
```

**Process**:
1. Create Role model
2. Attach permissions if provided
3. Make role available for company assignment
4. Fire `RoleCreated` event
5. Return Role instance

**Usage**:
```php
$role = $this->dispatch(
    new CreateRole($request->validated())
);
```

**Events Fired**:
- `App\Events\Auth\RoleCreated`

### UpdateRole

**File**: `App\Jobs\Auth\UpdateRole`

**Purpose**: Update role name, description, or permissions

**Input**:
```php
$data = [
    'display_name' => 'Senior Accountant',
    'description' => 'Updated role...',
    'permissions' => ['create-sales-invoices', 'read-reports'],
]
```

**Process**:
1. Verify role is not system role (e.g., Admin, Owner)
2. Update role metadata
3. Sync permissions (replace all)
4. Fire `RoleUpdated` event
5. Return Role instance

**Usage**:
```php
$role = $this->dispatch(
    new UpdateRole($existing_role, $request->validated())
);
```

**Validation**:
- System roles (Admin, Owner) cannot be modified
- All supplied permissions must exist

### DeleteRole

**File**: `App\Jobs\Auth\DeleteRole`

**Purpose**: Delete a role and reassign users to another role

**Input**:
```php
$role_instance  // The Role to delete
```

**Process**:
1. Check role is not system role
2. Check no users are still assigned
3. Delete role and permissions
4. Fire `RoleDeleted` event
5. Return success

**Usage**:
```php
$this->dispatch(new DeleteRole($role));
```

**Validation**:
- Cannot delete system roles
- Cannot delete if users are still assigned

## Permission Management Jobs

### CreatePermission

**File**: `App\Jobs\Auth\CreatePermission`

**Purpose**: Create a new permission

**Input**:
```php
$data = [
    'name' => 'create-sales-invoices',
    'display_name' => 'Create Invoices',
    'description' => 'Ability to create sales invoices',
]
```

**Process**:
1. Create Permission model
2. Register in system
3. Fire `PermissionCreated` event
4. Return Permission instance

**Usage**:
```php
$permission = $this->dispatch(
    new CreatePermission($request->validated())
);
```

### UpdatePermission

**File**: `App\Jobs\Auth\UpdatePermission`

**Purpose**: Update permission name or description

**Input**:
```php
$data = [
    'display_name' => 'Updated Name',
    'description' => 'Updated description',
]
```

**Process**:
1. Update permission metadata
2. Fire `PermissionUpdated` event
3. Return Permission instance

### DeletePermission

**File**: `App\Jobs\Auth\DeletePermission`

**Purpose**: Delete permission and remove from all roles

**Input**:
```php
$permission_instance  // The Permission to delete
```

**Process**:
1. Remove from all roles
2. Delete permission
3. Fire `PermissionDeleted` event

## Invitation Jobs

### CreateInvitation

**File**: `App\Jobs\Auth\CreateInvitation`

**Purpose**: Invite user to join company with specific role

**Input**:
```php
$data = [
    'email' => 'newuser@example.com',
    'company_id' => 1,
    'role_id' => 5,             // Role in that company
]
```

**Process**:
1. Create invitation token
2. Send invitation email (async)
3. Fire `UserInvited` event
4. Return Invitation instance

**Usage**:
```php
$invitation = $this->dispatch(
    new CreateInvitation($request->validated())
);
```

**Events Fired**:
- `App\Events\Auth\UserInvited` – Invitation sent

### DeleteInvitation

**File**: `App\Jobs\Auth\DeleteInvitation`

**Purpose**: Cancel pending invitation

**Input**:
```php
$invitation_instance  // The Invitation to cancel
```

**Process**:
1. Invalidate token
2. Delete invitation record
3. Fire `InvitationCancelled` event

## Related Pages

- [Jobs Overview](overview.md) – Job architecture and patterns
- [RBAC Integration](../auth/rbac.md) – Permission system
- [Auth System](../auth/overview.md) – User and auth architecture

## Source Map

```
app/Jobs/Auth/
├─ CreateUser.php
├─ UpdateUser.php
├─ DeleteUser.php
├─ CreateRole.php
├─ UpdateRole.php
├─ DeleteRole.php
├─ CreatePermission.php
├─ UpdatePermission.php
├─ DeletePermission.php
├─ CreateInvitation.php
└─ DeleteInvitation.php
```

## Testing & Validation

```bash
# Test auth jobs
php artisan test tests/Feature/Auth/

# Test specific job
php artisan test tests/Feature/Auth/CreateUserTest.php

# Test permission checking
php artisan test tests/Feature/Auth/PermissionTest.php
```

## Common Patterns

### Creating a user and assigning to company with role

```php
// Create user
$user = $this->dispatch(new CreateUser([
    'email' => 'user@example.com',
    'password' => bcrypt('password'),
    'name' => 'John Doe',
]));

// Assign to company (usually done via separate relationship)
$user->attachCompany($company_id, $role_id);
```

### Checking permissions in jobs

```php
public function authorize()
{
    return auth()->user()->can('create', User::class);
}
```

### User lifecycle with company assignment

```
CreateUser → assign to company with role → send invitation → user confirms
```
