---
type: system-reference
title: Banking Jobs - Transaction & Account Operations
description: Job classes for bank accounts, transactions, transfers, and reconciliation operations.
tags: [jobs, banking, transactions, accounts, reconciliation]
openwiki:
  source_paths: [app/Jobs/Banking]
  symbols: [CreateAccount, CreateTransaction, CreateTransfer, CreateReconciliation]
---

# Banking Jobs

Banking jobs handle all transaction and account management. They maintain account balances, handle transfers, reconciliation, and integrate with documents.

## Account Management

### CreateAccount

**File**: `App\Jobs\Banking\CreateAccount`

**Purpose**: Create new bank account

**Input**:
```php
$data = [
    'name' => 'Main Checking',
    'type' => 'bank',                   // bank, cash, credit
    'currency_code' => 'USD',
    'opening_balance' => '10000.00',    // Optional, default 0
    'opening_date' => '2024-01-01',     // Optional
    'bank_name' => 'First Bank',        // Optional
    'bank_phone' => '555-1234',         // Optional
    'bank_address' => '123 Bank St',    // Optional
    'enabled' => true,                  // Optional
]
```

**Process**:
1. Create Account model
2. Set opening balance
3. Record creation timestamp
4. Fire `AccountCreated` event
5. Return Account instance

**Usage**:
```php
$account = $this->dispatch(
    new CreateAccount($request->validated())
);
```

**Events Fired**:
- `App\Events\Banking\AccountCreated`

### UpdateAccount

**File**: `App\Jobs\Banking\UpdateAccount`

**Purpose**: Update account details

**Input**:
```php
$data = [
    'name' => 'Updated Name',
    'bank_name' => 'New Bank',
    // Cannot change: type, currency_code, opening_balance
]
```

**Process**:
1. Update editable fields
2. Fire `AccountUpdated` event
3. Return Account instance

### DeleteAccount

**File**: `App\Jobs\Banking\DeleteAccount`

**Purpose**: Delete bank account

**Input**:
```php
$account_instance  // The Account to delete
```

**Process**:
1. Check no transactions exist
2. Soft delete account
3. Fire `AccountDeleted` event

**Restrictions**:
- Cannot delete if transactions exist
- Cannot delete if reconciliation in progress

## Transaction Operations

### CreateTransaction

**File**: `App\Jobs\Banking\CreateTransaction`

**Purpose**: Record income, expense, or internal transfer

**Input**:
```php
$data = [
    'type' => 'income',                 // income, expense, transfer
    'account_id' => 1,
    'amount' => '500.00',
    'description' => 'Client payment',
    'reference' => 'CHK-001',           // Optional
    'transaction_date' => '2024-01-15',
    'category_id' => 5,                 // Required for income/expense
    'contact_id' => 10,                 // Optional
    'document_id' => null,              // Optional: link to invoice/bill
    'recurring_id' => null,             // Optional: for recurring transactions
]
```

**Process**:
1. Verify account exists
2. Create Transaction model
3. Update account balance
4. Attach to document if provided
5. Fire `TransactionCreated` event
6. Return Transaction instance

**Usage**:
```php
$transaction = $this->dispatch(
    new CreateTransaction($request->validated())
);
```

**Events Fired**:
- `App\Events\Banking\TransactionCreated`

**Transaction Types**:

| Type | Effect | Category | Contact |
|------|--------|----------|---------|
| **income** | Increases balance | Required | Optional |
| **expense** | Decreases balance | Required | Optional |
| **transfer** | Inter-account | N/A | N/A |

### UpdateTransaction

**File**: `App\Jobs\Banking\UpdateTransaction`

**Purpose**: Modify transaction

**Input**:
```php
$data = [
    'amount' => '600.00',
    'description' => 'Updated desc',
    'reference' => 'CHK-002',
    'transaction_date' => '2024-01-16',
    'category_id' => 6,
    // Cannot change: type, account_id
]
```

**Process**:
1. Reverse old transaction amount from account balance
2. Update transaction fields
3. Apply new amount to account balance
4. Fire `TransactionUpdated` event
5. Return Transaction instance

**Usage**:
```php
$transaction = $this->dispatch(
    new UpdateTransaction($existing_transaction, $request->validated())
);
```

### DeleteTransaction

**File**: `App\Jobs\Banking\DeleteTransaction`

**Purpose**: Remove transaction and adjust account balance

**Input**:
```php
$transaction_instance  // The Transaction to delete
```

**Process**:
1. Check not part of reconciliation
2. Reverse transaction amount from account
3. Soft delete transaction
4. Fire `TransactionDeleted` event
5. Return success

**Restrictions**:
- Cannot delete if reconciled
- Cannot delete if locked

## Transfer Operations

### CreateTransfer

**File**: `App\Jobs\Banking\CreateTransfer`

**Purpose**: Transfer money between accounts

**Input**:
```php
$data = [
    'from_account_id' => 1,
    'to_account_id' => 2,
    'amount' => '1000.00',
    'transfer_date' => '2024-01-15',
    'description' => 'Monthly transfer',
]
```

**Process**:
1. Create Transfer model
2. Create expense transaction on from_account
3. Create income transaction on to_account
4. Link transactions together
5. Update both account balances
6. Fire `TransferCreated` event
7. Return Transfer instance

**Usage**:
```php
$transfer = $this->dispatch(
    new CreateTransfer($request->validated())
);
```

**Internal Mechanism**:
```
Transfer creates two linked transactions:
  - Deduct from source account (via CreateTransaction)
  - Add to destination account (via CreateTransaction)
```

**Events Fired**:
- `App\Events\Banking\TransferCreated`

### UpdateTransfer

**File**: `App\Jobs\Banking\UpdateTransfer`

**Purpose**: Modify transfer amount or date

**Input**:
```php
$data = [
    'amount' => '1200.00',
    'transfer_date' => '2024-01-16',
    // Cannot change: from_account_id, to_account_id
]
```

**Process**:
1. Reverse original transactions
2. Create new transactions with new amount
3. Update account balances
4. Fire `TransferUpdated` event

### DeleteTransfer

**File**: `App\Jobs\Banking\DeleteTransfer`

**Purpose**: Delete transfer and reverse both transactions

**Input**:
```php
$transfer_instance  // The Transfer to delete
```

**Process**:
1. Delete both linked transactions
2. Reverse both account balances
3. Soft delete transfer
4. Fire `TransferDeleted` event

## Reconciliation Operations

### CreateReconciliation

**File**: `App\Jobs\Banking\CreateReconciliation`

**Purpose**: Reconcile account against bank statement

**Input**:
```php
$data = [
    'account_id' => 1,
    'closing_balance' => '5000.00',     // Balance per bank statement
    'closing_date' => '2024-01-31',
    'transactions' => [                 // Optional: transactions to mark reconciled
        1, 2, 3, 5, 7                   // Transaction IDs
    ],
]
```

**Process**:
1. Create Reconciliation record
2. Mark specified transactions as reconciled
3. Compare closing_balance to account balance
4. Fire `ReconciliationCreated` event
5. Return Reconciliation instance

**Usage**:
```php
$reconciliation = $this->dispatch(
    new CreateReconciliation($request->validated())
);
```

**Events Fired**:
- `App\Events\Banking\ReconciliationCreated`

### UpdateReconciliation

**File**: `App\Jobs\Banking\UpdateReconciliation`

**Purpose**: Adjust reconciliation

**Input**:
```php
$data = [
    'closing_balance' => '5100.00',
    'transactions' => [1, 2, 3],        // Replaced list
]
```

**Process**:
1. Update closing balance
2. Re-mark transactions
3. Fire `ReconciliationUpdated` event

### DeleteReconciliation

**File**: `App\Jobs\Banking\DeleteReconciliation`

**Purpose**: Revert reconciliation to mark transactions as unreconciled

**Input**:
```php
$reconciliation_instance  // The Reconciliation to delete
```

**Process**:
1. Unmark all reconciled transactions
2. Delete reconciliation record
3. Fire `ReconciliationDeleted` event

## Recurring Transactions

### CreateRecurringTransaction

**File**: `App\Jobs\Banking\CreateRecurringTransaction`

**Purpose**: Set up automatic recurring transactions

**Input**:
```php
$data = [
    'type' => 'income',
    'account_id' => 1,
    'amount' => '500.00',
    'category_id' => 1,
    'description' => 'Monthly subscription',
    'recurring_type' => 'month',        // month, quarter, year
    'recurring_every' => 1,             // Repeat every N periods
    'recurring_stop_date' => '2024-12-31',
]
```

**Process**:
1. Create recurring configuration
2. Generate first transaction
3. Schedule future transactions
4. Fire `RecurringTransactionCreated` event

## Document Integration

**Document Payments**:
When a document (invoice/bill) is paid via bank transaction:

```php
// Create payment transaction linked to document
$transaction = $this->dispatch(new CreateTransaction([
    'type' => 'income',
    'account_id' => 1,
    'amount' => $invoice->remaining_amount,
    'description' => "Payment for {$invoice->document_number}",
    'document_id' => $invoice->id,      // Links to invoice
]));

// Document status updated to 'paid' automatically
// Event listeners create history entry
```

## Related Pages

- [Jobs Overview](overview.md) – Job patterns
- [Banking System](../banking/overview.md) – Account and transaction models
- [Bank Reconciliation Workflow](../../workflows/bank-reconciliation.md) – Complete workflow

## Source Map

```
app/Jobs/Banking/
├─ CreateAccount.php
├─ UpdateAccount.php
├─ DeleteAccount.php
├─ CreateTransaction.php
├─ UpdateTransaction.php
├─ DeleteTransaction.php
├─ CreateTransfer.php
├─ UpdateTransfer.php
├─ DeleteTransfer.php
├─ CreateReconciliation.php
├─ UpdateReconciliation.php
├─ DeleteReconciliation.php
└─ CreateRecurringTransaction.php
```

## Testing & Validation

```bash
# Test banking jobs
php artisan test tests/Feature/Banking/

# Test transaction creation
php artisan test tests/Feature/Banking/TransactionsTest.php

# Test reconciliation
php artisan test tests/Feature/Banking/ReconciliationsTest.php
```

## Common Patterns

### Record payment against invoice

```php
// When payment received
$transaction = $this->dispatch(new CreateTransaction([
    'type' => 'income',
    'account_id' => $invoice->account_id,
    'amount' => $amount_paid,
    'document_id' => $invoice->id,
]));
// Document status auto-updates to 'paid' when fully paid
```

### Transfer between accounts

```php
$transfer = $this->dispatch(new CreateTransfer([
    'from_account_id' => 1,  // Checking
    'to_account_id' => 2,    // Savings
    'amount' => '5000.00',
    'transfer_date' => now()->toDateString(),
]));
// Creates two linked transactions automatically
```

### Balance verification

```php
// Account current balance is always = opening_balance + sum(transaction.amount)
$account->balance; // Automatically calculated and cached
```
