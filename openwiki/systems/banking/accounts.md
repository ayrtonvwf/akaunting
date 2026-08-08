---
type: system-domain
title: Bank Accounts & Account Management
description: Bank account creation, balance tracking, currency handling, and account lifecycle in Akaunting.
tags: [banking, accounts, balance-tracking, currency]
---

# Bank Accounts

The Accounts system manages bank and payment accounts. Accounts hold transactions (income and expenses) and provide balance tracking. Each account is scoped to a company and has a base currency.

## Core Model: Account

**File**: `App\Models\Banking\Account`
**Table**: `accounts`

### Attributes

```
id, company_id, name, number, currency_code, 
opening_balance, opening_balance_date, enabled,
created_at, updated_at, deleted_at
```

### Key Fields

- **name**: Account name (e.g., "Checking", "Savings", "Credit Card")
- **number**: Bank account number or identifier (not unique globally, per company)
- **currency_code**: Account base currency (USD, EUR, etc.)
- **opening_balance**: Starting balance as of opening_balance_date
- **opening_balance_date**: Date from which opening_balance applies
- **enabled**: Whether account is active

### Relationships

```php
$account->transactions;        // HasMany: All transactions on account
$account->reconciliations;     // HasMany: Bank reconciliation records
$account->transfers_from;      // HasMany: Transfers from this account
$account->transfers_to;        // HasMany: Transfers to this account
```

## Account Creation

**Controller**: `App\Http\Controllers\Banking\Accounts`
**Job**: `App\Jobs\Banking\CreateAccount`

### Flow

1. User submits account form
2. Controller validates with `App\Http\Requests\Banking\Account`
3. Controller dispatches `CreateAccount` job
4. Job creates `Account` record
5. Job fires `AccountCreated` event

### Minimum Required Fields

```php
[
    'name' => 'Checking',
    'currency_code' => 'USD',
]
```

### Full Account Creation

```php
[
    'name' => 'Business Checking',
    'number' => '****1234',
    'currency_code' => 'USD',
    'opening_balance' => 5000.00,
    'opening_balance_date' => '2024-01-01',
    'enabled' => true,
]
```

## Balance Calculation

Account balance is **calculated dynamically** from opening balance and transactions:

```
account.balance = opening_balance + sum(transaction.amount)
```

Where:
- **opening_balance**: Initial balance as of opening_balance_date
- **transaction.amount**: Positive for income, negative for expenses/transfers
- Transactions filtered to account and current company

### Balance as of Date

Balance at a specific date:

```php
$account->balanceAsOf('2024-02-15');
```

Sums opening balance + transactions up to that date.

### Current Balance

```php
$account->balance;  // Current balance (calculated)
```

**Not stored**: Balance is derived, not persisted. This ensures accuracy after any transaction is added/removed.

## Account Types

While the model doesn't distinguish types internally, accounts represent different banking products:

| Type | Description |
|------|-------------|
| **Checking** | Primary operating account |
| **Savings** | Secondary savings account |
| **Credit Card** | Credit card (tracks payable balance) |
| **Money Market** | Higher-yield savings |
| **Loan** | Debt account (tracks owed amount) |

### Credit Card Account

For credit card accounts, transactions are typically **negative** (charges), and the balance represents the amount owed:

```
Transactions:
  -1000  (purchase)
  -500   (purchase)
Balance: -1500 (owed to credit card company)
```

## Multi-Currency Accounts

Accounts can hold multi-currency transactions:

```php
[
    'currency_code' => 'USD',  // Account base currency
]
```

Transactions on USD account can be recorded in USD. If transaction is in different currency (EUR), system stores original currency + exchange rate:

```php
$transaction->currency_code = 'EUR';
$transaction->currency_rate = 1.10;  // EUR to USD conversion
$transaction->amount_in_usd = $transaction->amount * $transaction->currency_rate;
```

## API Operations

**REST Endpoints**:

```
GET    /api/accounts                    – List accounts
GET    /api/accounts/{id}               – Get account details
POST   /api/accounts                    – Create account
PUT    /api/accounts/{id}               – Update account
DELETE /api/accounts/{id}               – Delete (soft delete)
GET    /api/accounts/{id}/balance       – Get current balance
GET    /api/accounts/{id}/balance-history – Balance over time
```

**Response**: Returns `Account` resource with balance, transactions, reconciliation status.

## Authorization

**Permissions**:
- `read-banking-accounts` – View accounts
- `create-banking-accounts` – Create new account
- `update-banking-accounts` – Edit account
- `delete-banking-accounts` – Delete account

## Account Reconciliation

Accounts are reconciled against bank statements:

**Model**: `App\Models\Banking\Reconciliation`

Reconciliation process:
1. Download bank statement
2. Mark transactions as reconciled
3. Match statement closing balance to account balance

See [Bank Reconciliation](reconciliation.md) for detailed workflow.

## Account Management

### Enable/Disable

```php
$account->enabled = false;
$account->save();
```

Disabled accounts:
- Don't appear in UI for new transactions
- Existing transactions remain
- Can be re-enabled

### Update Opening Balance

```php
$account->update([
    'opening_balance' => 10000.00,
    'opening_balance_date' => '2024-01-01',
]);
```

Changes balance calculation retroactively.

### Merge Accounts

Transfer all transactions from one account to another, then close original:

```php
// Move transactions
Transaction::where('account_id', $oldAccount->id)
    ->update(['account_id', $newAccount->id]);

// Soft delete old
$oldAccount->delete();
```

## Common Workflows

### Create Account and Record Opening Balance

```php
$account = $this->dispatch(new CreateAccount(
    auth()->user(),
    [
        'name' => 'Business Checking',
        'number' => '****1234',
        'currency_code' => 'USD',
        'opening_balance' => 5000.00,
        'opening_balance_date' => '2024-01-01',
    ],
    auth()->user()->currentCompany()
));

// Balance automatically: 5000.00
```

### Record Transaction

```php
$transaction = $this->dispatch(new CreateTransaction(
    auth()->user(),
    [
        'account_id' => $account->id,
        'type' => 'income',
        'amount' => 1000.00,
        'description' => 'Customer payment',
    ],
    auth()->user()->currentCompany()
));

// Balance now: 5000 + 1000 = 6000.00
```

### Transfer Between Accounts

```php
$transfer = $this->dispatch(new CreateTransfer(
    auth()->user(),
    [
        'from_account_id' => $checking->id,
        'to_account_id' => $savings->id,
        'amount' => 2000.00,
        'description' => 'Transfer to savings',
    ],
    auth()->user()->currentCompany()
));

// Checking balance: -2000
// Savings balance: +2000
```

### Check Balance at Specific Date

```php
$balance = $account->balanceAsOf('2024-02-15');
// Sum of opening_balance + transactions up to 2024-02-15
```

## Source Map

| Concept | File |
|---------|------|
| Account model | `app/Models/Banking/Account.php` |
| Account controller | `app/Http/Controllers/Banking/Accounts.php` |
| Create job | `app/Jobs/Banking/CreateAccount.php` |
| Request validation | `app/Http/Requests/Banking/Account.php` |
| API resource | `app/Http/Resources/Banking/Account.php` |
| Events | `app/Events/Banking/Account*.php` |

## Testing

**Feature tests**: `/tests/Feature/Banking/AccountsTest.php`

Key test cases:
- Create account with opening balance
- Calculate balance from transactions
- Balance as of date
- Multi-currency transactions
- Transfer between accounts
- Soft delete

---

## Related Pages

- [Banking Transactions](transactions.md) – Recording income/expenses
- [Transfers](transfers.md) – Inter-account transfers
- [Bank Reconciliation](reconciliation.md) – Matching bank statements
- [Banking Overview](overview.md) – Banking system structure
