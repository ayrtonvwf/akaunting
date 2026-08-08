---
type: system-reference
title: Module Development
description: Creating custom modules, module structure, registration, routing, controllers, and module lifecycle in Akaunting.
tags: [modules, extensions, development, modularity]
---

# Module Development

The Module system allows developers to create custom extensions for Akaunting. Modules are self-contained packages with their own routes, controllers, models, views, and event listeners.

## Module Structure

Modules are located in `/modules/{ModuleName}/` directory.

**Typical module structure**:

```
modules/MyModule/
├── Http/
│  ├── Controllers/
│  │  └── MyController.php
│  └── Requests/
│     └── MyRequest.php
├── Models/
│  └── MyModel.php
├── Views/
│  └── myview.blade.php
├── Routes/
│  ├── admin.php
│  ├── api.php
│  └── portal.php
├── Events/
├── Listeners/
├── Providers/
│  └── ModuleServiceProvider.php
├── Tests/
│  └── Feature/
├── Resources/
│  └── views/
├── Public/
├── Config/
│  └── module.json
└── database/
   └── migrations/
```

## Module Configuration

**File**: `module.json` (in module root)

**Example**:

```json
{
  "name": "My Custom Module",
  "alias": "mymodule",
  "description": "Custom functionality for Akaunting",
  "version": "1.0.0",
  "author": "Your Name",
  "order": 1,
  "providers": [
    "Modules\\MyModule\\Providers\\ModuleServiceProvider"
  ],
  "permissions": [
    "create-mymodule-items",
    "read-mymodule-items",
    "update-mymodule-items",
    "delete-mymodule-items"
  ]
}
```

## Module Entry Point

**File**: `Providers/ModuleServiceProvider.php`

```php
namespace Modules\MyModule\Providers;

use Illuminate\Support\ServiceProvider;

class ModuleServiceProvider extends ServiceProvider
{
    public function register()
    {
        // Register bindings in container
    }

    public function boot()
    {
        // Boot module: load migrations, publish assets, register routes
        $this->loadMigrationsFrom(__DIR__ . '/../database/migrations');
        $this->loadRoutesFrom(__DIR__ . '/../Routes/admin.php');
        $this->loadViewsFrom(__DIR__ . '/../Views', 'mymodule');
    }
}
```

## Module Routes

**File**: `Routes/admin.php`

```php
Route::group([
    'prefix' => 'modules/mymodule',
    'middleware' => ['auth', 'company'],
], function () {
    Route::resource('items', \Modules\MyModule\Http\Controllers\ItemsController::class);
});
```

**File**: `Routes/api.php`

```php
Route::group([
    'prefix' => 'api/mymodule',
    'middleware' => ['auth:sanctum'],
], function () {
    Route::resource('items', \Modules\MyModule\Http\Controllers\Api\ItemsController::class);
});
```

## Module Controllers

**File**: `Http/Controllers/ItemsController.php`

```php
namespace Modules\MyModule\Http\Controllers;

use App\Abstracts\Http\Controller;
use Modules\MyModule\Models\Item;

class ItemsController extends Controller
{
    public function index()
    {
        $items = Item::collect();
        return $this->response('mymodule::items.index', compact('items'));
    }

    public function show(Item $item)
    {
        return response()->json($item);
    }
}
```

## Module Models

**File**: `Models/Item.php`

```php
namespace Modules\MyModule\Models;

use App\Abstracts\Model;

class Item extends Model
{
    protected $table = 'mymodule_items';
    protected $fillable = ['company_id', 'name', 'description'];
}
```

## Module Permissions

Define permissions in `module.json`:

```json
"permissions": [
    "create-mymodule-items",
    "read-mymodule-items",
    "update-mymodule-items",
    "delete-mymodule-items"
]
```

Permissions automatically registered when module is installed.

## Module Events & Listeners

**File**: `Events/ItemCreated.php`

```php
namespace Modules\MyModule\Events;

class ItemCreated
{
    public function __construct(public $item) {}
}
```

**File**: `Listeners/SendItemNotification.php`

```php
namespace Modules\MyModule\Listeners;

class SendItemNotification
{
    public function handle(ItemCreated $event)
    {
        // Send notification about item creation
    }
}
```

Register in service provider:

```php
Event::listen(
    \Modules\MyModule\Events\ItemCreated::class,
    \Modules\MyModule\Listeners\SendItemNotification::class
);
```

## Module Lifecycle

### Installation

1. Module registered in modules directory
2. Service provider auto-discovered
3. Migrations run (if any)
4. Seeds executed (if any)
5. Permissions created
6. Published assets (if any)

### Activation/Deactivation

Modules can be enabled/disabled in system settings (if UI provided).

### Uninstallation

1. Service provider removed
2. Migrations rolled back
3. Permissions deleted
4. Assets removed

## Module Dependencies

Module can depend on other modules:

```json
{
  "requires": [
    "core:core-module",
    "acme:helper-module:1.0"
  ]
}
```

## Publishing Module Assets

In service provider:

```php
$this->publishes([
    __DIR__ . '/../Public' => public_path('modules/mymodule'),
], 'public');
```

Publish via command:

```bash
php artisan vendor:publish --tag=mymodule-public
```

## Testing Modules

**File**: `Tests/Feature/ItemsTest.php`

```php
namespace Modules\MyModule\Tests\Feature;

use Tests\TestCase;

class ItemsTest extends TestCase
{
    public function test_can_create_item()
    {
        $this->actingAs($this->user)
            ->post('/modules/mymodule/items', [
                'name' => 'Test Item',
            ])
            ->assertCreated();
    }
}
```

## Best Practices

1. **Follow Akaunting conventions**: Use same patterns as core (jobs, traits, events)
2. **Namespace properly**: Use `Modules\YourModule\*`
3. **Add documentation**: Include README.md
4. **Version properly**: Follow semantic versioning
5. **Test thoroughly**: Write feature and unit tests
6. **Register permissions**: Define all permissions in module.json
7. **Handle migrations**: Provide upgrade path for versions
8. **Provide examples**: Include example API responses

## Related Pages

- [Module System](overview.md) – Built-in and third-party extensions overview
