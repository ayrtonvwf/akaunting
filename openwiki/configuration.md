---
type: system-overview
title: Configuration & Settings
description: Key configuration files, currency and monetary settings, document types, permissions, and feature toggles in Akaunting.
tags: [configuration, settings, feature-flags]
---

# Configuration & Settings

Akaunting's behavior is controlled through Laravel configuration files, environment variables, and settings stored in the database. This page documents the essential configuration surfaces.

## Configuration Files

### config/type.php

Defines all document types, permission constants, and type-related metadata. This file is the single source of truth for the accounting domain model.

**Document Types**:
```php
'document' => [
    'invoice' => [
        'translation' => [
            'prefix' => 'documents.invoice',
            'singular' => 'documents.invoice',
            'plural' => 'documents.invoices',
        ],
        // ...
    ],
    'bill' => [ /* ... */ ],
    'invoice-recurring' => [ /* ... */ ],
    'bill-recurring' => [ /* ... */ ],
]
```

Each document type can have:
- Translation prefixes for UI labels
- Custom status lists
- Alias for modules to override
- Default settings

**Permission Types**:
```php
'permission' => [
    'create-common-companies' => 'Create Companies',
    'read-common-companies' => 'Read Companies',
    'update-common-companies' => 'Update Companies',
    'delete-common-companies' => 'Delete Companies',
    
    'create-sales-invoices' => 'Create Invoices',
    'read-sales-invoices' => 'Read Invoices',
    // ... more permissions for banking, documents, etc.
]
```

All RBAC checks use these constants. Permissions follow the pattern: `{action}-{domain}-{resource}`.

### config/money.php

Currency, monetary amount formatting, and localization settings.

**Key Settings**:
- **Currencies**: Complete list of ISO 4217 codes with names and symbols
- **Currency Conversion**: Enable/disable currency conversion
- **Decimal Places**: Default decimal precision for amounts (typically 2)
- **Thousand Separator**: Formatting for large numbers
- **Locale-Specific Formatting**: Currency symbol position, separator placement

**Usage in Models**:
```php
// Models cast amounts as doubles
protected $casts = [
    'amount' => 'double',
    'currency_rate' => 'double',
];
```

The frontend uses `v-money` Vue component for money formatting with rules from this config.

### config/laratrust.php

Role-based access control (RBAC) configuration using the Laratrust package.

**Key Settings**:
- **User Model**: `App\Models\Auth\User`
- **Role Model**: `App\Models\Auth\Role`
- **Permission Model**: `App\Models\Auth\Permission`
- **UserRole Pivot**: `App\Models\Auth\UserRole`

Multi-tenancy is handled by company_id in the pivot tables. Users have roles per company, not globally.

### config/module.php

Module system configuration using akaunting/laravel-module.

**Key Settings**:
- **Module Paths**: Where to scan for modules (`modules/`)
- **Namespaces**: PSR-4 autoload namespace (`Modules\`)
- **Caching**: Whether to cache module manifest
- **Migrations**: Scan module migration directories

Built-in modules defined in `composer.json` extra.installer-paths:
- `modules/OfflinePayments/`: Offline payment method support
- `modules/PaypalStandard/`: PayPal integration

### config/api.php

API behavior and response formatting.

**Key Settings**:
- **Pagination**: Default page size, max results
- **Request/Response Format**: JSON envelope structure
- **Rate Limiting**: API rate limit per user/IP
- **CORS**: Allowed origins for cross-origin requests

### config/setting.php

Database-backed settings for application behavior and feature flags.

**Sample Settings Keys**:
- `company.default_currency`: Default currency code
- `default.invoice_status`: Initial status for new invoices
- `default.bill_status`: Initial status for new bills
- `email.*`: Email configuration
- `tax.default_calculation`: Tax calculation method

Settings are stored in `settings` table with `key` and `value` fields, scoped by company_id.

---

## Environment Variables (.env)

Critical environment configuration:

```bash
# Database
DB_CONNECTION=mysql
DB_HOST=localhost
DB_USERNAME=root
DB_PASSWORD=secret
DB_DATABASE=akaunting

# Cache & Queue
CACHE_DRIVER=redis
QUEUE_CONNECTION=database

# Mail
MAIL_MAILER=smtp
MAIL_FROM_ADDRESS=noreply@akaunting.local

# File Storage
FILESYSTEM_DISK=local

# Sentry Error Tracking
SENTRY_LARAVEL_DSN=https://...

# API Keys for Third-Party Services
PAYPAL_API_USERNAME=
PAYPAL_API_PASSWORD=
PAYPAL_API_SIGNATURE=

# Feature Flags
APP_DEBUG=true
APP_ENV=production
```

---

## Currency & Money Configuration

### Multi-Currency Support

Akaunting supports transactions in multiple currencies with real-time conversion rates.

**Key Models**:
- `App\Models\Setting\Currency`: Defined currencies
- `Document::currency_code` and `currency_rate`: Document base currency
- `Transaction::currency_code` and `currency_rate`: Transaction currency
- `Account::currency_code`: Account base currency

**Conversion Rules**:
- If transaction currency ≠ account currency, rate is required
- Rates are stored per-transaction for historical accuracy
- Default currency from company settings is used for new entries

**Frontend**: `v-money` component formats based on:
```javascript
currency_code: 'USD', // ISO code
locale: 'en-US',      // Intl.NumberFormat locale
```

---

## Taxes Configuration

### Tax Definitions

Tax rules are defined in the `App\Models\Setting\Tax` model and applied to:
- Document items (line-item tax)
- Document totals (compound tax)
- Transactions (if applicable)

**Tax Calculation Methods** (in `config/type.php`):
1. **Exclusive**: Tax added to base price (price + tax)
2. **Inclusive**: Tax included in price (price includes tax)
3. **Compound**: Tax on tax (cascading)

**Application**:
- `DocumentItem` has `pivot->tax_rate` and linked taxes
- `DocumentItemTax` stores tax amount for each item-tax pair
- `DocumentTotal` aggregates all taxes

### Tax Rate Management

```php
// Tax stored with rate and name
$tax = Tax::create([
    'company_id' => company_id(),
    'name' => 'VAT 20%',
    'rate' => 20.00, // Percentage
    'enabled' => true,
]);
```

Taxes applied in `App\Jobs\Document\CreateDocumentItemsAndTotals`.

---

## Categories Configuration

Expense and income categories are managed via `App\Models\Setting\Category`.

**Usage**:
- `Transaction::category_id`: Transaction categorization
- `Document::category_id`: Optional document categorization (for reports/filters)

Categories are company-scoped and can be enabled/disabled for organization.

---

## Feature Flags & Plan Limits

The `App\Traits\Plans` trait checks plan-based feature limits.

**Usage in Jobs**:
```php
// In CreateDocument job
$limit = $this->getAnyActionLimitOfPlan();
if (! $limit->action_status && $this->request['type'] == 'invoice') {
    throw new \Exception($limit->message);
}
```

**Storage**: Plan limits are typically fetched from SaaS service or stored in settings.

---

## Read-Only Mode

The `read-only` middleware enforces read-only database access for:
- Scheduled maintenance
- Demo/staging environments
- Testing scenarios

**Configuration**: `config/read-only.php`

**Enforcement**:
```php
// Any write operation blocked by CheckForReadOnlyMode middleware
if (config('read-only.enabled')) {
    throw new ReadOnlyModeException();
}
```

---

## Localization & Languages

### Language Configuration

`config/language.php` defines:
- Available locales
- Default locale
- Translation file paths

Supported locales:
- English (en)
- Spanish (es)
- German (de)
- French (fr)
- Turkish (tr)
- Portuguese (pt)
- Russian (ru)
- And more...

### Translation Prefixes

Translation keys follow consistent patterns:

```php
trans('documents.invoice.statuses.draft')
trans('documents.bill.statuses.paid')
trans('general.companies')
trans('messages.success.created', ['type' => 'Invoice'])
```

---

## Middleware Configuration

Key middleware in `App\Http\Kernel`:

| Middleware | Purpose | Applied To |
|-----------|---------|-----------|
| `auth` | Authenticate user | web, admin |
| `auth.dynamic.once` | Bearer or Basic auth | api |
| `permission:*` | Check specific permission | Specific routes |
| `company.identify` | Set current company context | admin, api, common |
| `read.only` | Enforce read-only mode | All routes |
| `money` | Transform money values from form input | Routes with money input |
| `date.format` | Parse date format from config | Routes with date input |
| `dropzone` | Handle file uploads | Routes with file inputs |
| `menu.admin` | Inject admin menu into view | admin routes |
| `plan.limits` | Check plan feature limits | admin routes |

---

## Service Configuration

### Mail Service

Configured in `config/mail.php`:
- SMTP, Sendmail, Mailgun, Postmark, SendGrid drivers
- Default from address and name
- Retry strategy

Used for:
- User invitations
- Document delivery (PDF attach)
- Payment reminders
- Transaction notifications

### File Storage

Configured in `config/filesystems.php`:
- Local disk: `storage/app/`
- S3 disk: AWS S3 (for production)
- Media attachment storage via `plank/laravel-mediable`

### Cache Driver

Configured in `config/cache.php`:
- Array (testing)
- Redis (production)
- Database fallback

Used for:
- Model query caching (GeneaLabs\LaravelModelCaching)
- Rate limiting buckets
- Session storage

### Queue Driver

Configured in `config/queue.php`:
- Sync (default, processes immediately)
- Database (async via jobs table)
- Redis (async via Redis)

Used for:
- Email sending
- Module installation
- Large file processing

---

## Monitoring & Error Tracking

### Sentry Integration

```php
// config/sentry.php
'dsn' => env('SENTRY_LARAVEL_DSN'),
'environment' => env('APP_ENV'),
```

All unhandled exceptions logged to Sentry for monitoring.

### Bugsnag Integration

Alternative or complementary error tracking service configured in `config/bugsnag.php`.

---

## Firewall Configuration

`config/firewall.php` implements IP-based and domain-based access controls:

**Use Cases**:
- Restrict API access by IP
- Block or allow specific countries
- Rate limit by IP

---

## Validation Rules

Custom validation rules defined in `App\Providers\Validation`:

- `greater_than_field`: Compare two fields
- `currency`: Valid currency code
- `tax_rate`: Valid tax percentage (0-100)
- `document_number`: Unique per company and type

These are bound in the service provider and available via rule objects in requests.

---

## Extending Configuration

### Adding a New Setting

1. Create database migration adding to `settings` table
2. Reference in code via `setting('key')`
3. Create UI form in Settings area to edit
4. Document the setting in this guide

### Adding a New Document Type

1. Add to `config/type.php` under `document` key
2. Create controller in `App\Http\Controllers\Sales\` or `Purchases\`
3. Create routes in `routes/admin.php`
4. Create API controller in `App\Http\Controllers\Api\Document\`
5. Create views for create/edit/show forms
6. Create event listeners if needed

### Adding Permissions

1. Add to `config/type.php` under `permission` key
2. Create role in RBAC UI or seed via factory
3. Use in middleware: `'permission:your-permission-name'`
4. Document the permission purpose

---

## Best Practices

1. **Never commit .env**: Use `.env.example` as template
2. **Environment-Specific Config**: Use `APP_ENV` for environment-specific behavior
3. **Config Over Code**: Feature flags and toggles belong in config, not hardcoded
4. **Validation First**: Define validation rules once in form requests, reuse in API
5. **Consistent Naming**: Follow `{action}-{domain}-{resource}` for permissions, `{domain}.{entity}` for settings

---

*Reference: Source inspection of `/config`, `/app/Providers`, `/app/Models`*
