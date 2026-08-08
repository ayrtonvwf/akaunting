---
type: system-reference
title: Module System - Built-in & Third-Party Extensions
description: Modular architecture for extending Akaunting with plugins, modules, and custom functionality.
tags: [modules, extensions, plugins, extensibility]
openwiki:
  source_paths: [modules, app/Traits/Modules.php]
---

# Module System - Built-in & Third-Party Extensions

The module system enables extending Akaunting with built-in and third-party modules. Modules are full Laravel applications with their own routes, controllers, models, and views.

## Module Architecture

```
Module
├─ Routes/
│  ├─ admin.php          # Admin panel routes
│  ├─ api.php            # API routes
│  └─ portal.php         # Customer portal routes
├─ Http/
│  └─ Controllers/       # Module controllers
├─ Models/               # Module models
├─ Database/
│  ├─ Migrations/        # Database schema
│  └─ Seeders/           # Demo data
├─ Views/                # Blade templates
├─ Assets/               # Styles, scripts
├─ Tests/                # Module tests
├─ Resources/
│  └─ lang/              # Translations
├─ module.json           # Module metadata
└─ composer.json         # PHP dependencies
```

## Built-in Modules

Akaunting includes several built-in modules:

### OfflinePayments

Payment processing for offline payment methods.

**Location**: `modules/OfflinePayments/`

**Features**:
- Bank transfer
- Check payments
- Cash payments
- Custom payment instructions

### PaypalStandard

PayPal payment integration.

**Location**: `modules/PaypalStandard/`

**Features**:
- PayPal Standard checkout
- Payment confirmation
- Transaction logging

## Module Structure

### module.json

**File**: `modules/{ModuleName}/module.json`

```json
{
  "alias": "offline-payments",
  "name": "Offline Payments",
  "description": "Accept offline payment methods",
  "version": "1.0.0",
  "author": "Akaunting",
  "category": "payment",
  "icon": "offline-payments-icon.png",
  "permission": [
    "create-sales-documents",
    "read-sales-documents"
  ],
  "enabled": true,
  "installed": true,
  "active": true,
  "config": {
    "instructions": {
      "bank_transfer": "Bank transfer instructions here...",
      "check": "Send check to..."
    }
  }
}
```

### Routes

**File**: `modules/{ModuleName}/Routes/admin.php`

```php
<?php

Route::group([
    'prefix' => 'settings',
    'middleware' => ['web', 'auth'],
], function () {
    Route::resource('offline-payments', 'OfflinePaymentController');
});
```

### Controller

**File**: `modules/{ModuleName}/Http/Controllers/OfflinePaymentController.php`

```php
<?php

namespace Modules\OfflinePayments\Http\Controllers;

use App\Abstracts\Http\Controller;

class OfflinePaymentController extends Controller
{
    public function index()
    {
        return view('offline-payments::index');
    }
    
    public function store(Request $request)
    {
        // Handle payment
    }
}
```

### View

**File**: `modules/{ModuleName}/Resources/views/index.blade.php`

```blade
<div class="container">
    <h1>Offline Payments</h1>
    <!-- Module content -->
</div>
```

## Module Installation

### From App Store

1. Admin → Apps → App Store
2. Search for module
3. Click "Install"
4. Enable module
5. Configure settings

### From Composer

```bash
composer require akaunting/module-name
php artisan module:discover
php artisan module:install module-name
```

### Manually

1. Download module
2. Extract to `modules/ModuleName/`
3. Run `php artisan module:discover`
4. Run `php artisan module:install module-name`

## Module Commands

```bash
# List all modules
php artisan module:list

# Install module
php artisan module:install offline-payments

# Enable module
php artisan module:enable offline-payments

# Disable module
php artisan module:disable offline-payments

# Update module
php artisan module:update offline-payments

# Uninstall module
php artisan module:uninstall offline-payments

# Generate new module
php artisan make:module MyModule
```

## Module File Structure

```
modules/OfflinePayments/
├─ Config/
│  └─ offline-payments.php          # Module config
├─ Database/
│  ├─ Migrations/
│  │  └─ 2024_01_01_000000_create_offline_payments_table.php
│  └─ Seeders/
│     └─ OfflinePaymentSeeder.php
├─ Http/
│  └─ Controllers/
│     └─ OfflinePaymentController.php
├─ Models/
│  └─ OfflinePayment.php
├─ Routes/
│  ├─ admin.php
│  ├─ api.php
│  └─ portal.php
├─ Resources/
│  ├─ lang/
│  │  └─ en/
│  │     └─ offline-payments.php
│  └─ views/
│     ├─ settings.blade.php
│     └─ payment.blade.php
├─ Tests/
│  ├─ Feature/
│  │  └─ OfflinePaymentTest.php
│  └─ Unit/
│     └─ OfflinePaymentUnitTest.php
├─ Assets/
│  ├─ css/
│  │  └─ offline-payments.css
│  └─ js/
│     └─ offline-payments.js
├─ composer.json
├─ module.json
└─ README.md
```

## Module Events

Modules can listen to and fire events:

### Listening to Events

```php
// In service provider
Event::listen(DocumentCreated::class, function ($event) {
    // React to document creation
    // Maybe send to payment processor
});
```

### Broadcasting Events

```php
// In module
event(new CustomModuleEvent($data));
```

## Module Database Migrations

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateOfflinePaymentsTable extends Migration
{
    public function up()
    {
        Schema::create('offline_payments', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('company_id');
            $table->string('name');
            $table->text('instructions')->nullable();
            $table->timestamps();
            
            $table->foreign('company_id')
                ->references('id')
                ->on('companies')
                ->onDelete('cascade');
        });
    }
    
    public function down()
    {
        Schema::dropIfExists('offline_payments');
    }
}
```

## Module Configuration

### Accessing Module Config

```php
// In module
config('offline-payments.instructions');

// From outside
config('modules.offline-payments.instructions');
```

### Module Settings

Modules typically store settings:

```php
// Save setting
Setting::set('offline_payments_bank_info', 'Bank details...');

// Retrieve setting
$bank_info = Setting::get('offline_payments_bank_info');
```

## Module API

### Routes

**File**: `modules/{ModuleName}/Routes/api.php`

```php
<?php

Route::group(['prefix' => 'offline-payments'], function () {
    Route::get('/', 'OfflinePaymentController@index');
    Route::post('/', 'OfflinePaymentController@store');
});
```

### API Response

```json
GET /api/offline-payments/1

{
  "id": 1,
  "name": "Bank Transfer",
  "instructions": "Send payment to...",
  "enabled": true
}
```

## Module Dashboard Widgets

Modules can provide dashboard widgets:

```php
// Register widget
Widget::register('offline-payments', OfflinePaymentWidget::class);

// Widget class
class OfflinePaymentWidget extends Widget
{
    public function render()
    {
        return view('offline-payments::widget', [
            'recent_payments' => OfflinePayment::latest()->take(5)->get()
        ]);
    }
}
```

## Module Permissions

Modules define their own permissions:

```json
{
  "permission": [
    "create-offline-payments",
    "read-offline-payments",
    "update-offline-payments",
    "delete-offline-payments"
  ]
}
```

## Creating Custom Module

### 1. Generate Module Scaffolding

```bash
php artisan make:module PaymentGateway
```

### 2. Create Module Structure

```bash
cd modules/PaymentGateway
mkdir -p Http/Controllers Models Routes Resources/views
touch module.json composer.json
```

### 3. Create module.json

```json
{
  "alias": "payment-gateway",
  "name": "Payment Gateway",
  "description": "Custom payment processing",
  "version": "1.0.0",
  "author": "Your Name",
  "category": "payment"
}
```

### 4. Create Routes

```php
// Routes/admin.php
Route::resource('payment-settings', 'PaymentSettingController')
    ->middleware('auth', 'permission:manage-payments');
```

### 5. Create Controller

```php
namespace Modules\PaymentGateway\Http\Controllers;

class PaymentSettingController extends Controller
{
    public function index()
    {
        return view('payment-gateway::settings');
    }
}
```

### 6. Create Views

```blade
<!-- Resources/views/settings.blade.php -->
<div class="card">
    <h2>Payment Gateway Settings</h2>
    <!-- Settings form -->
</div>
```

### 7. Create Service Provider

```php
// Providers/PaymentGatewayServiceProvider.php
class PaymentGatewayServiceProvider extends ServiceProvider
{
    public function register()
    {
        // Register bindings
    }
    
    public function boot()
    {
        $this->loadRoutesFrom(__DIR__ . '/../Routes/admin.php');
        $this->loadViewsFrom(__DIR__ . '/../Resources/views', 'payment-gateway');
    }
}
```

## Module Multi-Tenancy

Modules should respect multi-tenancy:

```php
// Automatically scoped to company
OfflinePayment::where('company_id', auth()->user()->currentCompany()->id)->get();

// All models use Tenants trait
use App\Traits\Tenants;

class OfflinePayment extends Model
{
    use Tenants;
}
```

## Module Testing

```php
// Tests/Feature/OfflinePaymentTest.php
class OfflinePaymentTest extends TestCase
{
    public function test_offline_payment_creation()
    {
        $payment = OfflinePayment::factory()->create();
        
        $this->assertDatabaseHas('offline_payments', [
            'id' => $payment->id
        ]);
    }
}
```

## Module Publishing to App Store

1. Create GitHub repository
2. Add `module.json` with metadata
3. Submit to Akaunting App Store
4. Community votes and feedback
5. Approved modules listed in app store

## Related Pages

- [Module Development](development.md) – Detailed module development guide
- [Extensibility](../../quickstart.md#extensibility) – Extension points
- [Console Commands](../console-commands.md) – Artisan commands

## Source Map

```
modules/
├─ OfflinePayments/
├─ PaypalStandard/
└─ {CustomModule}/
   ├─ Http/Controllers/
   ├─ Models/
   ├─ Routes/
   ├─ Resources/views/
   ├─ Database/Migrations/
   ├─ Tests/
   ├─ module.json
   └─ composer.json

app/Traits/Modules.php
```

## Resources

- [Akaunting App Store](https://akaunting.com/apps)
- [Module Development Guide](development.md)
- [Akaunting Module Package](https://github.com/akaunting/module)

## Best Practices

1. **Multi-tenancy first**: Always scope data to company
2. **Follow conventions**: Match Akaunting code style
3. **Proper testing**: Include feature and unit tests
4. **Documentation**: Include README with setup
5. **Clean up**: Remove module data on uninstall
6. **Permissions**: Define module-specific permissions
7. **Events**: Use events for integration points
