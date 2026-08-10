---
type: system-overview
title: Banking System - Accounts & Transactions
description: Bank accounts, transactions (income/expense), transfers, reconciliation, and recurring transactions.
tags: [banking, transactions, accounts, reconciliation]
---

# Banking System Overview

The Banking system manages bank accounts, financial transactions (income and expenses), inter-account transfers, and bank reconciliation. It is distinct from Documents but often linked—invoices generate income transactions, bills generate expense transactions.

## Core Models

### Account (App\Models\Banking\Account)

Represents a bank or payment account.

**Attributes**:
```
id, company_id, name, number, currency_code, opening_balance, 
opening_balance_date, enabled, created_at, updated_at, deleted_at
```

**Key Fields**:
- **number**: Bank account number or identifier (not unique globally, per company)
- **currency_code**: Account base currency (can record multi-currency transactions)
- **opening_balance**: Initial balance as of opening_balance_date
- **enabled**: Active/inactive flag

**Relationships**:
```php
$account->transactions();          // HasMany: All transactions on account
$account->reconciliations();       // HasMany: Bank reconciliation records
$account->transfers_from();        // HasMany: Transfers from this account
$account->transfers_to();          // HasMany: Transfers to this account
```

**Balance Calculation**:
```php
$account->balance = opening_balance + sum(transaction.amount)
```

Where transactions are filtered to current company and transaction date ≤ reconciliation date.

### Transaction (App\Models\Banking\Transaction)

Individual bank entry: income, expense, transfer, or split.

**Attributes**:
```
id, company_id, type, number, account_id, paid_at, amount, 
currency_code, currency_rate, document_id, contact_id, description, 
category_id, payment_method, reference, parent_id, split_id, 
created_from, created_by, created_at, updated_at, deleted_at
```

**Type Field**: `income`, `expense`, `income-transfer`, `expense-transfer`, `income-split`, `expense-split`, `income-recurring`, `expense-recurring`

**Key Fields**:
- **number**: Transaction identifier within account
- **paid_at**: Transaction date
- **amount**: Positive for income, negative for expense
- **document_id**: Optional link to document (invoice payment, bill payment)
- **contact_id**: Optional contact (customer payment, vendor payment)
- **category_id**: Expense/income category
- **payment_method**: Cash, check, credit card, wire transfer, etc.
- **reference**: Cheque number, wire reference, or other identifier

**Relationships**:
```php
$transaction->account;             // BelongsTo: Account
$transaction->document;            // BelongsTo: Document (if linked)
$transaction->contact;             // BelongsTo: Contact
$transaction->taxes;               // HasMany: TransactionTax
$transaction->splits;              // HasMany: Split transactions (if parent)
$transaction->children;            // HasMany: Child transactions
```

### Transfer (App\Models\Banking\Transfer)

Inter-account transfer (movement between accounts within same company).

**Attributes**:
```
id, company_id, name, account_id (from), account_id_to (to), 
paid_at, amount, currency_code, currency_rate, 
created_from, created_by, created_at, updated_at, deleted_at
```

**Flow**:
1. User creates transfer from Account A to Account B
2. Two transactions created: expense in Account A, income in Account B
3. Both transactions linked via reference
4. Transfers are net-zero at company level

### TransactionTax (App\Models\Banking\TransactionTax)

Taxes on transactions (e.g., VAT on purchase).

**Attributes**:
```
id, transaction_id, tax_id, name, rate, amount, created_at, updated_at
```

Similar structure to DocumentItemTax.

### Reconciliation (App\Models\Banking\Reconciliation)

Bank statement matching to recorded transactions.

**Attributes**:
```
id, company_id, account_id, opened_at, closed_at, 
opening_balance, closing_balance, created_at, updated_at, deleted_at
```

**Purpose**: Verify recorded transactions match bank statement; identify errors or fraud.

**Process**:
1. Create reconciliation period (e.g., monthly)
2. Upload or import bank statement transactions
3. Mark recorded transactions as 'reconciled'
4. Calculate variance (statement balance vs. account balance)
5. Reconciliation complete when variance = 0

---

## Controllers

### Accounts Controller

**Routes**:
```
GET    /admin/banking/accounts             – List accounts
POST   /admin/banking/accounts             – Create account
PATCH  /admin/banking/accounts/{id}        – Update account
DELETE /admin/banking/accounts/{id}        – Delete account
GET    /admin/banking/accounts/{id}/enable – Enable account
GET    /admin/banking/accounts/{id}/disable – Disable account
```

**Jobs**:
- `CreateAccount`: Create account and set opening balance
- `UpdateAccount`: Update account details
- `DeleteAccount`: Soft-delete account

### Transactions Controller

**Routes**:
```
GET    /admin/banking/transactions             – List transactions
POST   /admin/banking/transactions             – Create transaction
PATCH  /admin/banking/transactions/{id}        – Update transaction
DELETE /admin/banking/transactions/{id}        – Delete transaction
POST   /admin/banking/transactions/{id}/split   – Split transaction
GET    /admin/banking/transactions/duplicate    – Duplicate transaction
GET    /admin/banking/transactions/export       – Export transactions
POST   /admin/banking/transactions/import       – Import transactions
```

**Special Methods**:
- **Split**: Divide transaction among multiple categories
- **Duplicate**: Create new transaction copying current one
- **Match**: Link transaction to document (payment matching)

### Transfers Controller

**Routes**:
```
GET    /admin/banking/transfers             – List transfers
POST   /admin/banking/transfers             – Create transfer
PATCH  /admin/banking/transfers/{id}        – Update transfer
DELETE /admin/banking/transfers/{id}        – Delete transfer
```

**Jobs**:
- `CreateTransfer`: Create two linked transactions (from and to)
- `UpdateTransfer`: Update transfer details and amounts
- `DeleteTransfer`: Delete both linked transactions

### Reconciliations Controller

**Routes**:
```
GET    /admin/banking/reconciliations          – List reconciliations
POST   /admin/banking/reconciliations          – Start new reconciliation
PATCH  /admin/banking/reconciliations/{id}     – Update reconciliation
DELETE /admin/banking/reconciliations/{id}     – Delete reconciliation (cancel)
GET    /admin/banking/reconciliations/{id}     – View reconciliation details
POST   /admin/banking/reconciliations/import   – Import bank statement
```

---

## Transaction Types & Flow

### Income Transaction

```
Type: 'income'
Amount: Positive (e.g., +1000.00)
Account: Debit (receiving account)
Common sources: Customer payment, refund, interest
```

**Dual Entry** (if linked to document):
```
Debit:  Bank Account     +1000.00
Credit: Accounts Receivable (Invoice) -1000.00
```

### Expense Transaction

```
Type: 'expense'
Amount: Negative (e.g., -500.00)
Account: Credit (spending account)
Common sources: Vendor payment, expense entry, fee
```

**Dual Entry** (if linked to document):
```
Debit:  Expense Account  +500.00
Credit: Bank Account     -500.00
```

### Transfer

Creates two transactions (income and expense) in different accounts:

```
Type: 'income-transfer' (receiving account)
Type: 'expense-transfer' (sending account)
Amount: Same in both, opposite direction
```

### Recurring Transactions

Auto-generated at intervals (daily, weekly, monthly, annually).

```
Type: 'income-recurring' or 'expense-recurring'
Schedule: Interval + end date
Next generation: Tracked in model
```

---

## Payment Matching

### Linking Transactions to Documents

When a customer pays an invoice, create income transaction and link to invoice:

```
POST /admin/banking/transactions
{
  "account_id": 1,
  "type": "income",
  "amount": 1000.00,
  "document_id": 42,      // Invoice ID
  "contact_id": 10,       // Customer ID
  "paid_at": "2024-01-15",
  "payment_method": "bank_transfer"
}
```

**Listener Flow**:
1. Transaction created
2. `TransactionCreated` event fired
3. Listener finds linked document
4. Updates document paid_amount
5. If fully paid, changes document status to 'paid'

### Matching via Job

**Job**: `App\Jobs\Banking\MatchBankingDocumentTransaction`

Automatically links transactions to documents based on:
- Amount matching
- Contact matching
- Date proximity
- Reference/memo matching

---

## Bank Reconciliation

### Starting a Reconciliation

```php
// Create reconciliation record
$reconciliation = Reconciliation::create([
    'company_id' => company_id(),
    'account_id' => $account->id,
    'opened_at' => now(),
    'opening_balance' => $account->balance,
]);
```

### Importing Statement

**Process**:
1. Upload CSV/OFX bank statement
2. Parse transactions
3. Create temporary statement transaction records
4. Display matching interface

### Matching Transactions

User marks which recorded transactions match statement:

```php
// Mark transaction as reconciled
$transaction->update([
    'reconciliation_id' => $reconciliation->id,
    'reconciled_at' => now(),
]);
```

### Closing Reconciliation

```php
$reconciliation->update([
    'closed_at' => now(),
    'closing_balance' => $statement_balance,
]);

// Calculate variance
$variance = $closing_balance - ($opening_balance + sum($reconciled_transactions));
// Variance should = 0 for successful reconciliation
```

---

## Multi-Currency Transactions

Akaunting supports transactions in currency different from account currency.

**Fields**:
```
account.currency_code = 'USD'
transaction.currency_code = 'EUR'
transaction.currency_rate = 0.92  // 1 USD = 0.92 EUR
```

**Amount Stored**: In transaction currency; converted to account currency for balance.

**Conversion Formula**:
```
account_currency_amount = transaction_amount / currency_rate
```

---

## Recurring Transactions

Auto-generate transactions at intervals.

**Setup**:
```php
$transaction->createRecurring([
    'frequency' => 'monthly',  // daily, weekly, monthly, yearly
    'ends_at' => '2024-12-31',
]);
```

**Generation Job**: `App\Jobs\Banking\CreateRecurringTransactions`

Runs daily, identifies due transactions, clones them with new date.

---

## Split Transactions

Divide a transaction among multiple categories or contacts.

**Example**: $500 expense split as:
- $300 Office Supplies (category 1)
- $200 Equipment (category 2)

**Job**: `App\Jobs\Banking\SplitTransaction`

Creates:
1. Parent transaction (original)
2. Child transactions (one per split)
3. Links via parent_id and split_id

---

## API Endpoints

```
GET    /api/accounts                  – List accounts
POST   /api/accounts                  – Create account
PATCH  /api/accounts/{id}             – Update account
DELETE /api/accounts/{id}             – Delete account

GET    /api/transactions              – List transactions
POST   /api/transactions              – Create transaction
PATCH  /api/transactions/{id}         – Update transaction
DELETE /api/transactions/{id}         – Delete transaction

GET    /api/transfers                 – List transfers
POST   /api/transfers                 – Create transfer
PATCH  /api/transfers/{id}            – Update transfer
DELETE /api/transfers/{id}            – Delete transfer

GET    /api/reconciliations           – List reconciliations
POST   /api/reconciliations           – Create reconciliation
PATCH  /api/reconciliations/{id}      – Update reconciliation
```

---

## Events

- `AccountCreated`, `AccountCreating`, `AccountUpdated`, `AccountUpdating`, `AccountDeleted`
- `TransactionCreated` → Listener: Link to document, update document status
- `TransactionUpdated`, `TransactionDeleting`
- `TransactionSent` – Email transaction to contact
- `TransactionSplitting`, `TransactionSplitted`
- `TransactionRecurring` – Auto-generated
- `TransferCreated` → Creates linked income/expense transactions
- `TransferDeleted` → Deletes linked transactions

---

## Best Practices

1. **Always Link Payments**: Reconcile transactions to documents for full audit trail
2. **Set Currency Rates**: Store rates for foreign transactions; don't convert on-the-fly
3. **Reconcile Regularly**: Monthly reconciliation catches errors early
4. **Validate Opening Balance**: Ensure account opening balance matches bank records
5. **Track Reference**: Always include payment method and reference for audit

---

## Testing Banking

```php
// Create account with opening balance
$account = Account::factory()->create([
    'opening_balance' => 10000,
    'currency_code' => 'USD',
]);

// Create income transaction
$transaction = Transaction::factory()
    ->for($account)
    ->income()
    ->create(['amount' => 500]);

// Verify balance updated
$this->assertEquals(10500, $account->fresh()->balance);

// Test transaction matching
$invoice = Document::factory()->invoice()->create(['amount' => 500]);
$transaction->update(['document_id' => $invoice->id]);

$this->assertTrue($invoice->fresh()->isPaid());
```

---

*Reference: /app/Models/Banking, /app/Http/Controllers/Banking, /app/Jobs/Banking*
