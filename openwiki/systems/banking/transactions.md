---
type: system-domain
title: Banking Transactions
description: Income and expense transaction recording, transaction types, split transactions, and transaction lifecycle in Akaunting.
tags: [banking, transactions, income, expenses, splits]
---

# Banking Transactions

The Transactions system records all income and expense entries into bank accounts. Transactions are the foundation of cash flow tracking and bank reconciliation.

## Core Model: Transaction

**File**: `App\Models\Banking\Transaction`
**Table**: `transactions`

### Attributes

```
id, company_id, type, number, account_id, paid_at, amount,
currency_code, currency_rate, document_id, contact_id, 
description, category_id, payment_method, reference,
parent_id, split_id, created_from, created_by,
created_at, updated_at, deleted_at
```

### Key Fields

- **type**: `income`, `expense`, `income-transfer`, `expense-transfer`, `income-split`, `expense-split`, `income-recurring`, `expense-recurring`
- **account_id**: Bank account transaction is on
- **paid_at**: Transaction date
- **amount**: Positive for income, negative for expenses
- **document_id**: Optional link to invoice/bill (payment)
- **contact_id**: Customer (income) or vendor (expense)
- **category_id**: Income/expense category
- **payment_method**: Cash, check, wire transfer, credit card, etc.
- **reference**: Cheque number, wire reference, transaction ID

### Relationships

```php
$transaction->account;        // BelongsTo: Account
$transaction->document;       // BelongsTo: Document (if payment)
$transaction->contact;        // BelongsTo: Contact
$transaction->taxes;          // HasMany: TransactionTax
$transaction->splits;         // HasMany: Split transactions (if parent)
$transaction->children;       // HasMany: Child transactions
```

## Transaction Types

### Income

Transaction type `income`: Money received

```php
[
    'type' => 'income',
    'amount' => 1000.00,
    'contact_id' => $customer->id,
    'description' => 'Invoice payment received',
]
```

### Expense

Transaction type `expense`: Money paid out

```php
[
    'type' => 'expense',
    'amount' => -500.00,
    'contact_id' => $vendor->id,
    'description' => 'Office supplies purchase',
]
```

### Transfers

Inter-account transfers create pairs of transactions:

- **income-transfer**: Money received into account
- **expense-transfer**: Money sent from account

See [Transfers](transfers.md) for details.

### Split Transactions

A single transaction can split into multiple sub-transactions:

- **income-split**: Parent income split into multiple splits
- **expense-split**: Parent expense split into multiple splits

See [Split Transactions](#split-transactions) below.

### Recurring Transactions

Auto-generated transactions:

- **income-recurring**: Auto-generated income
- **expense-recurring**: Auto-generated expense

See [Recurring Transactions](recurring.md).

## Transaction Creation

**Controller**: `App\Http\Controllers\Banking\Transactions`
**Job**: `App\Jobs\Banking\CreateTransaction`

### Flow

1. User submits transaction form
2. Controller validates with `App\Http\Requests\Banking\Transaction`
3. Controller dispatches `CreateTransaction` job
4. Job creates `Transaction` record
5. Job updates linked document status if payment
6. Job fires `TransactionCreated` event

### Minimum Required Fields

```php
[
    'type' => 'income',
    'account_id' => 1,
    'amount' => 1000.00,
    'paid_at' => '2024-01-15',
]
```

### Full Transaction Creation

```php
[
    'type' => 'income',
    'account_id' => 1,
    'amount' => 1000.00,
    'paid_at' => '2024-01-15',
    'document_id' => 1,         // Link to invoice
    'contact_id' => 5,          // Customer
    'category_id' => 1,         // Income category
    'payment_method' => 'wire',
    'reference' => 'WIRE-12345',
    'description' => 'Invoice INV-001 payment',
    'currency_code' => 'USD',
]
```

## Linking to Documents

Transactions can be linked to invoices/bills as payment records:

```php
$transaction->document_id = $invoice->id;
```

When transaction linked to document:
- Document status auto-updates (paid/partial)
- Payment amount tracked against invoice total
- Multiple transactions can link to one document (partial payments)

## Categories

Income and expense transactions are categorized:

**Model**: `App\Models\Setting\Category`

```php
[
    'category_id' => 1,  // E.g., "Sales", "Operating Expense", "Utilities"
]
```

Categories used for:
- Profit & loss reporting
- Expense tracking
- Income analysis

## Transaction Taxes

**Model**: `App\Models\Banking\TransactionTax`

Some transactions have associated taxes (VAT on purchase, sales tax collected):

```php
[
    'type' => 'expense',
    'amount' => -100.00,
    'taxes' => [
        ['tax_id' => 1, 'amount' => -10.00],  // VAT 10%
    ]
]
```

Tax rows stored separately for tax reporting.

## Split Transactions

A single transaction can split into multiple allocations:

**Parent transaction**: `type='income-split'` or `type='expense-split'`
**Child transactions**: Point to parent via `parent_id`

**Use case**: Expense split across multiple cost centers

```
Parent: $1000 expense
  ├─ Split 1: $600 to Utilities (category 5)
  ├─ Split 2: $300 to Maintenance (category 8)
  └─ Split 3: $100 to Supplies (category 12)
```

### Creating Split Transaction

```php
$parent = $this->dispatch(new CreateTransaction(
    auth()->user(),
    [
        'type' => 'expense-split',
        'account_id' => 1,
        'amount' => -1000.00,
        'description' => 'Large expense split',
    ],
    $company
));

// Create splits
foreach ($splits as $split) {
    $this->dispatch(new CreateTransaction(
        auth()->user(),
        array_merge($split, [
            'parent_id' => $parent->id,
            'type' => 'expense',
        ]),
        $company
    ));
}
```

## Payment Methods

Transaction can specify payment method for audit trail:

```php
'payment_method' => 'cash'              // Physical cash
'payment_method' => 'check'             // Check payment
'payment_method' => 'wire'              // Wire transfer
'payment_method' => 'credit_card'       // Credit card
'payment_method' => 'bank_transfer'     // ACH/bank transfer
'payment_method' => 'paypal'            // PayPal
'payment_method' => 'cryptocurrency'    // Crypto payment
```

With optional **reference** (check number, wire ID, etc.):

```php
[
    'payment_method' => 'check',
    'reference' => 'CHK-12345',
]
```

## API Operations

**REST Endpoints**:

```
GET    /api/transactions               – List transactions
GET    /api/transactions/{id}          – Get transaction details
POST   /api/transactions               – Create transaction
PUT    /api/transactions/{id}          – Update transaction
DELETE /api/transactions/{id}          – Delete (soft delete)
```

**Query parameters**:
```
?type=income               – Filter by type
?account_id=1              – Filter by account
?contact_id=5              – Filter by contact
?category_id=1             – Filter by category
?paid_at_from=2024-01-01   – Date range
?paid_at_to=2024-01-31
```

**Response**: Returns `Transaction` resource with full details including document link, splits, taxes.

## Authorization

**Permissions**:
- `read-banking-transactions` – View transactions
- `create-banking-transactions` – Create transaction
- `update-banking-transactions` – Edit transaction
- `delete-banking-transactions` – Delete transaction

## Multi-Currency Transactions

Transaction can be in different currency than account:

```php
$account->currency_code = 'USD'

$transaction->currency_code = 'EUR'
$transaction->currency_rate = 1.10
$transaction->amount = 900  // EUR
```

Amount is stored in transaction currency; when displayed/reported, converted via exchange rate.

## Common Workflows

### Record Invoice Payment

```php
$transaction = $this->dispatch(new CreateTransaction(
    auth()->user(),
    [
        'type' => 'income',
        'account_id' => $checking->id,
        'amount' => $invoice->amount,
        'paid_at' => now(),
        'document_id' => $invoice->id,
        'contact_id' => $invoice->contact_id,
        'description' => "Payment for {$invoice->document_number}",
    ],
    $company
));

// Invoice status auto-updates to 'paid'
```

### Record Bill Payment

```php
$transaction = $this->dispatch(new CreateTransaction(
    auth()->user(),
    [
        'type' => 'expense',
        'account_id' => $checking->id,
        'amount' => -$bill->amount,
        'paid_at' => now(),
        'document_id' => $bill->id,
        'contact_id' => $bill->contact_id,
        'payment_method' => 'check',
        'reference' => '12345',
    ],
    $company
));

// Bill status auto-updates to 'paid'
```

### Record Operating Expense

```php
$transaction = $this->dispatch(new CreateTransaction(
    auth()->user(),
    [
        'type' => 'expense',
        'account_id' => $checking->id,
        'amount' => -50.00,
        'paid_at' => now(),
        'category_id' => $utilities_category->id,
        'description' => 'Electricity bill',
    ],
    $company
));
```

## Source Map

| Concept | File |
|---------|------|
| Transaction model | `app/Models/Banking/Transaction.php` |
| Transaction tax model | `app/Models/Banking/TransactionTax.php` |
| Transaction controller | `app/Http/Controllers/Banking/Transactions.php` |
| Create job | `app/Jobs/Banking/CreateTransaction.php` |
| Request validation | `app/Http/Requests/Banking/Transaction.php` |
| API resource | `app/Http/Resources/Banking/Transaction.php` |
| Events | `app/Events/Banking/Transaction*.php` |

## Testing

**Feature tests**: `/tests/Feature/Banking/Transactions.php`

Key test cases:
- Create income transaction
- Create expense transaction
- Link transaction to invoice/bill
- Split transaction
- Auto-update document status
- Multi-currency transaction

---

## Related Pages

- [Bank Accounts](accounts.md) – Account balance tracking
- [Transfers](transfers.md) – Inter-account transfers
- [Bank Reconciliation](reconciliation.md) – Matching transactions to statements
- [Recurring Transactions](recurring.md) – Auto-generated transactions
- [Invoices](../documents/invoices.md) – Invoice payment tracking
- [Bills](../documents/bills.md) – Bill payment tracking
