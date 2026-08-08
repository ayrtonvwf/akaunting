---
type: system-reference
title: Multi-Currency Configuration
description: Currency setup, exchange rates, multi-currency transactions, and currency conversion in Akaunting.
tags: [currencies, multi-currency, exchange-rates, localization]
---

# Multi-Currency Configuration

Akaunting supports multi-currency operations. Each company has a base currency, but transactions and documents can be in any supported currency.

## Currency Model

**File**: `App\Models\Setting\Currency`
**Table**: `currencies`

### Attributes

```
id, code, name, rate, decimal_places, enabled, created_at, updated_at
```

### Key Fields

- **code**: ISO 4217 code (USD, EUR, GBP, JPY, etc.)
- **name**: Full name (United States Dollar, Euro)
- **rate**: Exchange rate to base currency
- **decimal_places**: Precision (typically 2, but 0 for JPY)
- **enabled**: Whether currency is active

## Supported Currencies

Akaunting includes all ISO 4217 currencies. Example:

| Code | Name | Decimal Places |
|------|------|-----------------|
| USD | United States Dollar | 2 |
| EUR | Euro | 2 |
| GBP | British Pound | 2 |
| JPY | Japanese Yen | 0 |
| CHF | Swiss Franc | 2 |
| CAD | Canadian Dollar | 2 |
| AUD | Australian Dollar | 2 |

## Exchange Rates

Exchange rate stored in `rate` field represents conversion from currency to company base currency:

```
amount_in_base = amount_in_currency × rate

Example: EUR to USD
100 EUR × 1.10 = 110 USD
```

### Updating Exchange Rates

Exchange rates can be:

1. **Manual**: Manually entered and updated by user
2. **Automatic**: Synced from external API (if feature enabled)

**Manual update**:
```php
$currency = Currency::where('code', 'EUR')->first();
$currency->update(['rate' => 1.12]);
```

## Multi-Currency Accounts

Each account has a base currency:

```php
$account->currency_code = 'USD'
```

Transactions on USD account are recorded in USD. If transaction occurs in different currency (EUR):

```php
$transaction->currency_code = 'EUR'
$transaction->amount = 900  // In EUR
$transaction->currency_rate = 1.10
// Equivalent: 900 EUR × 1.10 = 990 USD
```

## Multi-Currency Documents

Invoices/bills can be in different currency than company base:

```php
$invoice->currency_code = 'EUR'
$invoice->currency_rate = 1.10
$invoice->amount = 1000  // In EUR, = 1100 USD equivalent
```

When document is converted or reported, `amount × currency_rate` converts to base currency.

## Multi-Currency Payment

When payment recorded in different currency than invoice:

```
Invoice: 1000 EUR @ 1.10 rate = 1100 USD equivalent
Payment: 1000 USD received
```

Payment automatically converts using current exchange rate.

## Localization Settings

Related currency/localization settings:

```
localisation.decimal_separator = '.' or ','
localisation.thousands_separator = ',' or '.'
```

Display format based on locale:
- US: 1,234.56
- Europe: 1.234,56

## API Operations

**REST Endpoints**:

```
GET    /api/settings/currencies        – List enabled currencies
GET    /api/settings/currencies/{code} – Get currency details
POST   /api/settings/currencies        – Create/enable currency
PUT    /api/settings/currencies/{code} – Update rate/decimal
```

## Common Workflows

### Change Company Base Currency

```php
// This changes reporting currency
$company->setSetting('company.currency', 'EUR');

// All future reports in EUR
// Existing transactions converted using historical rates
```

### Enable New Currency for International Customers

```php
$currency = Currency::create([
    'code' => 'GBP',
    'name' => 'British Pound',
    'rate' => 0.85,
    'decimal_places' => 2,
    'enabled' => true,
]);

// Can now invoice in GBP
```

### Update Exchange Rate

```php
Currency::where('code', 'EUR')->update(['rate' => 1.12]);

// Affects future documents and conversions
// Historical transactions unchanged
```

### Create Invoice in Foreign Currency

```php
[
    'currency_code' => 'EUR',
    'currency_rate' => 1.10,
    'amount' => 1000,  // 1000 EUR = 1100 USD
]
```

---

## Related Pages

- [Settings Overview](overview.md) – Configuration management
- [Invoices](../documents/invoices.md) – Multi-currency invoices
- [Banking Transactions](../banking/transactions.md) – Multi-currency transactions
