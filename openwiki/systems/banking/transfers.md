---
type: system-domain
title: Inter-Account Transfers
description: Transfers between bank accounts, transfer recording, and balance updates in Akaunting.
tags: [banking, transfers, accounts, transactions]
---

# Inter-Account Transfers

The Transfers system manages movements of funds between accounts (internal transfers). Each transfer creates two linked transactions: an outflow from source account and an inflow to destination account.

## Core Model: Transfer

**File**: `App\Models\Banking\Transfer`
**Table**: `transfers`

### Attributes

```
id, company_id, from_account_id, to_account_id, 
amount, description, transferred_at,
created_at, updated_at, deleted_at
```

### Key Fields

- **from_account_id**: Source account
- **to_account_id**: Destination account
- **amount**: Transfer amount (positive)
- **transferred_at**: Transfer date
- **description**: Transfer reason/reference

### Relationships

```php
$transfer->from_account;    // BelongsTo: Source account
$transfer->to_account;      // BelongsTo: Destination account
$transfer->transactions;    // HasMany: Related transactions (2 per transfer)
```

## Transfer Recording

When a transfer is created, the system creates **two linked transactions**:

1. **Expense transaction from source account**: Debit (negative amount)
2. **Income transaction to destination account**: Credit (positive amount)

**Example**: Transfer $1,000 from Checking to Savings

```
Transfer Record:
├─ from_account_id: 1 (Checking)
├─ to_account_id: 2 (Savings)
└─ amount: 1000

Transactions Created:
├─ Type: expense-transfer
│  Account: Checking
│  Amount: -1000
│  Reference: TRANSFER-123
└─ Type: income-transfer
   Account: Savings
   Amount: +1000
   Reference: TRANSFER-123
```

### Balance Impact

After transfer:
- **Checking balance**: -$1,000
- **Savings balance**: +$1,000
- **Net change**: $0 (funds moved, not created/destroyed)

## Transfer Creation

**Controller**: `App\Http\Controllers\Banking\Transfers`
**Job**: `App\Jobs\Banking\CreateTransfer`

### Flow

1. User submits transfer form
2. Controller validates accounts exist and are different
3. Controller dispatches `CreateTransfer` job
4. Job creates `Transfer` record
5. Job creates two linked transactions
6. Job fires `TransferCreated` event

### Minimum Required Fields

```php
[
    'from_account_id' => 1,
    'to_account_id' => 2,
    'amount' => 1000.00,
]
```

### Full Transfer Creation

```php
[
    'from_account_id' => 1,
    'to_account_id' => 2,
    'amount' => 1000.00,
    'transferred_at' => '2024-01-15',
    'description' => 'Monthly sweep to savings',
]
```

## Multi-Currency Transfers

When transferring between accounts in different currencies, exchange rate is applied:

```php
$from_account->currency_code = 'USD'
$to_account->currency_code = 'EUR'

$transfer->amount = 900  // EUR received
// Exchange rate: 1 USD = 0.92 EUR
// From account debited: $978.26
```

Transactions store both currencies:
- Outflow transaction: 978.26 USD
- Inflow transaction: 900 EUR

## API Operations

**REST Endpoints**:

```
GET    /api/transfers                   – List transfers
GET    /api/transfers/{id}              – Get transfer details
POST   /api/transfers                   – Create transfer
PUT    /api/transfers/{id}              – Update transfer
DELETE /api/transfers/{id}              – Delete (soft delete)
```

**Request body**:
```json
{
  "from_account_id": 1,
  "to_account_id": 2,
  "amount": 1000.00,
  "transferred_at": "2024-01-15",
  "description": "Monthly sweep"
}
```

**Response**: Returns `Transfer` resource with source/destination accounts and transactions.

## Authorization

**Permissions**:
- `read-banking-transfers` – View transfers
- `create-banking-transfers` – Create transfer
- `update-banking-transfers` – Edit transfer
- `delete-banking-transfers` – Delete transfer

## Common Workflows

### Periodic Sweep

Transfer surplus funds from operating account to savings:

```php
$transfer = $this->dispatch(new CreateTransfer(
    auth()->user(),
    [
        'from_account_id' => $checking->id,
        'to_account_id' => $savings->id,
        'amount' => 5000.00,
        'description' => 'Monthly sweep to savings',
        'transferred_at' => now(),
    ],
    $company
));

// Checking: -5000
// Savings: +5000
```

### Consolidate Accounts

Merge multiple checking accounts into primary:

```php
// Transfer 1
$this->dispatch(new CreateTransfer(
    auth()->user(),
    [
        'from_account_id' => $secondary_checking->id,
        'to_account_id' => $primary_checking->id,
        'amount' => 3000.00,
    ],
    $company
));

// Repeat for other accounts
```

### Rebalance by Currency

Move funds between accounts by currency:

```php
// From USD account to EUR account with conversion
$transfer = $this->dispatch(new CreateTransfer(
    auth()->user(),
    [
        'from_account_id' => $usd_account->id,
        'to_account_id' => $eur_account->id,
        'amount' => 900,  // EUR amount
        'transferred_at' => now(),
    ],
    $company
));
```

## Reconciliation Impact

Transfers should match when reconciling accounts:

**Example**: Monthly reconciliation

```
Checking Statement:
  Previous: $10,000
  Transfer out: -$1,000
  Closing: $9,000

Savings Statement:
  Previous: $5,000
  Transfer in: +$1,000
  Closing: $6,000
```

When reconciling, both outflow and inflow transactions should be matched to their respective statements.

## Source Map

| Concept | File |
|---------|------|
| Transfer model | `app/Models/Banking/Transfer.php` |
| Transfer controller | `app/Http/Controllers/Banking/Transfers.php` |
| Create job | `app/Jobs/Banking/CreateTransfer.php` |
| Request validation | `app/Http/Requests/Banking/Transfer.php` |
| API resource | `app/Http/Resources/Banking/Transfer.php` |
| Events | `app/Events/Banking/Transfer*.php` |

## Testing

**Feature tests**: `/tests/Feature/Banking/TransfersTest.php`

Key test cases:
- Create transfer between accounts
- Verify both transactions created and linked
- Multi-currency transfer
- Delete transfer (reverses transactions)

---

## Related Pages

- [Bank Accounts](accounts.md) – Account management
- [Banking Transactions](transactions.md) – Transaction recording
- [Bank Reconciliation](reconciliation.md) – Matching transfers to statements
