---
type: system-overview
title: Settings - Configuration Management
description: Company configuration, currencies, taxes, categories, email templates, and feature settings in Akaunting.
tags: [settings, configuration, company-settings, features]
---

# Settings Overview

The Settings system provides company-level configuration for accounting rules, localization, feature flags, and integration setup. Settings are scoped per company and stored in the `settings` table.

## Core Settings Structure

**Table**: `settings`

**Key fields**:
```
id, company_id, key, value, created_at, updated_at
```

Settings are stored as key-value pairs, where `key` typically follows a namespace convention:

```
company.name                      – Company legal name
company.timezone                  – Company timezone
company.default_currency          – Default currency code
localisation.date_format          – Date display format
localisation.decimal_separator    – Decimal symbol (. or ,)
tax.default_calculation           – Tax mode (inclusive/exclusive)
```

## Setting Categories

### Company Settings

Company identification and defaults:

- **company.name** – Legal company name
- **company.domain** – White-label domain (if enabled)
- **company.email** – Company contact email
- **company.phone** – Company phone
- **company.tax_number** – Tax/VAT number
- **company.address** – Company address
- **company.country** – Country code
- **company.currency** – Default currency (USD, EUR, GBP, etc.)
- **company.timezone** – Timezone for date/time operations

### Localization Settings

Date, number, and language formats:

- **localisation.date_format** – YYYY-MM-DD, MM/DD/YYYY, DD/MM/YYYY
- **localisation.decimal_separator** – . or , for decimals
- **localisation.thousands_separator** – , or . for thousands
- **localisation.language** – en, es, fr, de, etc.
- **localisation.percent_position** – before or after percentage symbol

### Tax Settings

Tax calculation rules:

- **tax.default_calculation** – `inclusive` or `exclusive`
- **tax.automatic_calculation** – Enable auto-tax in documents
- **tax.compound_mode** – Enable compound tax

### Feature Flags

Enable/disable features:

- **feature.invoicing** – Enable invoice functionality
- **feature.banking** – Enable banking/transactions
- **feature.reports** – Enable reporting
- **feature.api** – Enable API access

### Email & Notification Settings

- **mail.from_address** – Outgoing email address
- **mail.from_name** – Display name in emails
- **mail.driver** – SMTP, Mailgun, etc.
- **notification.send_invoice_notifications** – Auto-send invoice emails
- **notification.send_payment_notifications** – Auto-send payment confirmations

## Core Models

### Company Setting Storage

**File**: `App\Models\Setting\Setting` (or stored directly on Company model)

Access settings:

```php
$company->setting('company.name');           // Get value
$company->setting('company.name', 'Default'); // With default
setting('company.name');                      // Global helper
```

Set settings:

```php
$company->setSetting('company.name', 'Acme Corp');
```

### Category (Transaction Categories)

**File**: `App\Models\Setting\Category`
**Table**: `categories`

**Types**:
- Income categories: Service, Sales, Consultation, etc.
- Expense categories: Utilities, Salary, Supplies, etc.

Used to classify income/expense transactions for reporting.

### Currency

**File**: `App\Models\Setting\Currency`
**Table**: `currencies`

**Fields**:
```
id, code, name, rate (to base currency), decimal_places, enabled
```

Supported currencies (ISO 4217 codes): USD, EUR, GBP, JPY, etc.

### Tax

**File**: `App\Models\Setting\Tax`
**Table**: `taxes`

Tax rules and rates.

**Fields**:
```
id, company_id, name, type (percentage|fixed), rate, 
enabled, created_at, updated_at
```

**Types**:
- **Percentage**: Rate as percentage (10%, 5%)
- **Fixed**: Fixed amount per unit ($5, €2)

See [Taxes](taxes.md) for detailed tax configuration.

## Settings Controllers

**Main controller**: `App\Http\Controllers\Settings\*`

Controllers for different setting areas:

- `Settings\Settings` – General settings
- `Settings\Categories` – Income/expense categories
- `Settings\Currencies` – Multi-currency setup
- `Settings\Taxes` – Tax configuration
- `Settings\EmailTemplates` – Email customization

## API Operations

**REST Endpoints**:

```
GET    /api/settings                    – Get all settings
GET    /api/settings/{key}              – Get specific setting
POST   /api/settings                    – Update settings
GET    /api/settings/currencies         – List currencies
GET    /api/settings/taxes              – List taxes
GET    /api/settings/categories         – List categories
POST   /api/settings/categories         – Create category
```

## Common Setting Workflows

### Change Company Currency

```php
$company->setSetting('company.currency', 'EUR');

// Affects:
// - Default currency in new documents/accounts
// - Reporting currency
// - Display format
```

### Configure Tax Rules

```php
$vat = Tax::create([
    'company_id' => $company->id,
    'name' => 'VAT',
    'type' => 'percentage',
    'rate' => 20,
    'enabled' => true,
]);

// Apply to items/documents as needed
```

### Add Transaction Category

```php
$category = Category::create([
    'company_id' => $company->id,
    'name' => 'Office Supplies',
    'type' => 'expense',
]);

// Use in transaction creation
```

### Set Localization

```php
$company->setSetting('localisation.date_format', 'DD/MM/YYYY');
$company->setSetting('localisation.decimal_separator', ',');
$company->setSetting('localisation.language', 'es');

// Affects display and input formatting
```

## Authorization

**Permissions**:
- `read-settings-*` – View settings (varies by area)
- `update-settings-*` – Edit settings (varies by area)

Typically restricted to company admin/owner.

## Source Map

| Concept | File |
|---------|------|
| Settings model | `app/Models/Setting/Setting.php` |
| Category model | `app/Models/Setting/Category.php` |
| Currency model | `app/Models/Setting/Currency.php` |
| Tax model | `app/Models/Setting/Tax.php` |
| Settings controllers | `app/Http/Controllers/Settings/` (Categories.php, Currencies.php, Taxes.php, etc.) |
| Config | `config/type.php`, `config/money.php` |

## Related Pages

- [Currencies](currencies.md) – Multi-currency setup
- [Taxes](taxes.md) – Tax rules and configuration
- [Categories](categories.md) – Income/expense categories
- [Configuration](../../configuration.md) – Application-wide configuration
