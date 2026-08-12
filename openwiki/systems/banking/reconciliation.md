---
type: system-domain
title: Bank Reconciliation
description: Bank statement matching, reconciliation process, transaction verification, and reconciliation lifecycle in Akaunting.
tags: [banking, reconciliation, bank-statements, audit]
---

# Bank Reconciliation

The Reconciliation system matches recorded transactions to bank statements, verifying account accuracy and identifying discrepancies. Reconciliation is essential for financial audit trails and cash flow validation.

## Core Model: Reconciliation

**File**: `App\Models\Banking\Reconciliation`
**Table**: `reconciliations`

### Attributes

```
id, company_id, account_id, statement_date, 
opening_balance, closing_balance, 
created_at, updated_at, deleted_at
```

### Key Fields

- **account_id**: Bank account being reconciled
- **statement_date**: Bank statement date (end of period)
- **opening_balance**: Account balance at start of period
- **closing_balance**: Bank-reported balance at end of period

### Relationships

```php
$reconciliation->account;           // BelongsTo: Account being reconciled
$reconciliation->transactions;      // BelongsToMany: Matched transactions
```

## Reconciliation Process

### 1. Download Bank Statement

Obtain statement from bank showing:
- Opening balance
- All transactions (deposits and withdrawals)
- Closing balance
- Statement date

### 2. Create Reconciliation Record

**Controller**: `App\Http\Controllers\Banking\Reconciliations`
**Job**: `App\Jobs\Banking\CreateReconciliation`

```php
$reconciliation = $this->dispatch(new CreateReconciliation(
    auth()->user(),
    [
        'account_id' => $account->id,
        'statement_date' => '2024-01-31',
        'opening_balance' => $account->balance,
        'closing_balance' => 5234.50,  // From bank statement
    ],
    $company
));
```

### 3. Match Transactions

Match each statement line to recorded transaction in Akaunting:

```php
// For each transaction on statement
$transaction = Transaction::where([
    ['account_id', '=', $reconciliation->account_id],
    ['amount', '=', $stmt_amount],
    ['paid_at', '=', $stmt_date],
])->first();

// Mark as matched/reconciled
$reconciliation->matchTransaction($transaction);
```

**Matching criteria**:
- Amount (exact match)
- Date (within tolerance, typically 1-2 days)
- Description (optional, for verification)

### 4. Verify Balance

System verifies that reconciliation balances:

```
calculated_balance = opening_balance + sum(matched_transactions)

if calculated_balance == closing_balance:
    reconciliation is valid
else:
    discrepancy found
```

**Discrepancy handling**:
- **Unmatched transactions**: Recorded in Akaunting but not on statement
- **Outstanding items**: On statement but not recorded in Akaunting
- **Amount mismatch**: Transaction recorded with different amount

### 5. Mark Reconciliation Complete

Once balanced, mark reconciliation as complete:

```php
$reconciliation->update(['completed_at' => now()]);
```

Transactions marked as `reconciled=true`.

## Workflow: Step-by-Step

### Initial Setup

1. Account balance as of reconciliation date: **$5,000.00**
2. Recorded transactions:
   - Deposit 1: +$1,000
   - Expense 1: -$250
   - Expense 2: -$100
   - Transfer: -$500
3. **Calculated balance**: $5,000 + $1,000 - $250 - $100 - $500 = **$5,150**

### Bank Statement

1. Opening balance: $5,000
2. Deposits: $1,000
3. Withdrawals: $250 + $100 + $500 = $850
4. **Statement closing balance**: $5,000 + $1,000 - $850 = **$5,150**

✓ **Balanced!**

### With Discrepancies

Scenario: Outstanding check not yet cleared

1. Akaunting recorded: Check for $300 on 01/30
2. Bank statement: No $300 check (date 01/31)
3. Calculated vs Statement: Off by $300
4. **Resolution**: Check cleared next period; re-reconcile

## Matching Transactions

### Manual Matching

User manually selects transactions from list to match to statement items:

```
Statement Item        Akaunting Transaction
$1,000 Deposit    ↔   $1,000 Income Transaction (01/29)
$250 Debit        ↔   $250 Expense Transaction (01/30)
```

### Auto-Matching

System attempts to match transactions automatically:

```php
foreach ($statementItems as $stmt) {
    $match = $account->transactions()
        ->whereBetween('amount', [$stmt['amount'] - 0.01, $stmt['amount'] + 0.01])
        ->whereBetween('paid_at', [$stmt['date']->subDays(2), $stmt['date']->addDays(2)])
        ->first();
    
    if ($match) {
        $reconciliation->matchTransaction($match);
    }
}
```

**Confidence levels**:
- **Exact**: Amount and date match exactly
- **Probable**: Amount matches, date within tolerance
- **Suggested**: Similar amount, needs review

## Reconciliation States

| State | Meaning |
|-------|---------|
| **Draft** | Created but not completed |
| **In Progress** | User actively matching transactions |
| **Complete** | All transactions matched, balance verified |
| **Abandoned** | Cancelled, replaced with new reconciliation |

## Reconciliation Report

Once complete, generate reconciliation report:

```
RECONCILIATION REPORT - Checking Account
Statement Date: January 31, 2024

Akaunting Balance (01/31):           $5,150.00
Bank Statement Balance:               $5,150.00
                                      ───────
Difference:                           $0.00 ✓

Matched Transactions:
  (+) Deposit                         $1,000.00
  (-) Check #12345                    ($250.00)
  (-) Debit Card                      ($100.00)
  (-) Transfer Out                    ($500.00)
                                      ───────
Net Change:                           $150.00
Opening Balance:                      $5,000.00
Calculated Closing:                   $5,150.00
```

## Reconciliation Issues

### Outstanding Checks

Check written but not yet cleared by bank.

**Solution**: Match when it clears next period, or manually adjust.

### Deposits in Transit

Deposit recorded but not yet deposited.

**Solution**: Verify deposit was made; if not, reverse transaction.

### Bank Errors

Bank charges an incorrect fee or amount.

**Solution**: Contact bank to correct; record memo in reconciliation notes.

### Timing Differences

Transaction dates differ between Akaunting and bank (e.g., check clear date vs. write date).

**Solution**: Normal; expect 1-2 day lag for checks.

## Reconciliation History

Historical reconciliations are retained for audit trail:

```php
$account->reconciliations()
    ->where('completed_at', '!=', null)
    ->get();
```

Previous reconciliations show:
- Historical account balances
- What transactions were matched in each period
- Any discrepancies
- Who performed reconciliation

## API Operations

**REST Endpoints**:

```
GET    /api/reconciliations               – List reconciliations
GET    /api/reconciliations/{id}          – Get details
POST   /api/reconciliations               – Create reconciliation
PUT    /api/reconciliations/{id}          – Update reconciliation
POST   /api/reconciliations/{id}/complete – Mark complete
GET    /api/reconciliations/{id}/report   – Get reconciliation report
```

## Authorization

**Permissions**:
- `read-banking-reconciliations` – View reconciliations
- `create-banking-reconciliations` – Create reconciliation
- `update-banking-reconciliations` – Edit reconciliation
- `delete-banking-reconciliations` – Delete reconciliation

## Common Workflows

### Monthly Bank Reconciliation

```
1. Download bank statement for January
2. Go to Banking > Reconciliations > New
3. Select account (Checking)
4. Enter statement date (01/31)
5. Enter closing balance ($5,150)
6. Match transactions from statement
7. Verify all matched, balance correct
8. Complete reconciliation
```

### Investigate Discrepancy

```
1. Reconciliation shows $500 difference
2. Review unmatched transactions
3. Find: $500 check recorded but not on statement
4. Status: Outstanding check, will clear next month
5. Leave open; will match next period
```

### Correct Recorded Error

```
1. Reconciliation shows $100 mismatch
2. Review: Expense recorded as $100 but bank shows $110
3. Find record: Bank fee charged $10 additional
4. Update transaction to $110
5. Re-match and verify balance
```

## Source Map

| Concept | File |
|---------|------|
| Reconciliation model | `app/Models/Banking/Reconciliation.php` |
| Reconciliation controller | `app/Http/Controllers/Banking/Reconciliations.php` |
| Create job | `app/Jobs/Banking/CreateReconciliation.php` |
| Request validation | `app/Http/Requests/Banking/Reconciliation.php` |
| API resource | `app/Http/Resources/Banking/Reconciliation.php` |

## Testing

**Feature tests**: `/tests/Feature/Banking/ReconciliationsTest.php`

Key test cases:
- Create reconciliation
- Match transactions
- Verify balance
- Detect discrepancies
- Multiple reconciliations (history)

---

## Related Pages

- [Bank Accounts](accounts.md) – Account balance tracking
- [Banking Transactions](transactions.md) – Transaction recording
- [Bank Reconciliation Workflow](../../workflows/bank-reconciliation.md) – End-to-end workflow
