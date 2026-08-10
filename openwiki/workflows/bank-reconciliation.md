---
type: workflow
title: Bank Reconciliation Workflow
description: Complete bank reconciliation process from statement import through matching transactions and balance verification.
tags: [workflow, banking, reconciliation, audit]
---

# Bank Reconciliation Workflow

The Bank Reconciliation workflow is the process of verifying that recorded transactions match the bank statement, detecting discrepancies, and formally closing the accounting period.

## Reconciliation Overview

```
Bank Statement Arrives
    │
    ├─ Create Reconciliation
    │  ├─ Select account
    │  ├─ Enter statement period
    │  └─ Enter bank's closing balance
    │
    ├─ Match Transactions
    │  ├─ List recorded transactions
    │  ├─ List statement items
    │  └─ Match each line
    │
    ├─ Verify Balance
    │  ├─ Calculate: opening + transactions
    │  ├─ Compare to: bank closing
    │  └─ Resolve discrepancies
    │
    └─ Complete Reconciliation
       ├─ Mark transactions reconciled
       ├─ Document for audit
       └─ Generate report
```

## Complete Workflow Example

**Scenario**: Monthly reconciliation for business checking account, January 2024

### Setup: Account Starting Point

**Account**: Business Checking
- Opening balance (01/01): $10,000
- Currency: USD
- Last reconciliation: 12/31/2023

### Step 1: Obtain Bank Statement

**From bank**: Monthly statement for 1/1-1/31

**Statement shows**:
- Opening balance: $10,000
- Deposits:
  - 1/5: $5,000 (customer payment)
  - 1/12: $3,000 (customer payment)
  - 1/20: $500 (interest)
- Withdrawals:
  - 1/3: ($1,000) (vendor payment)
  - 1/10: ($800) (payroll)
  - 1/15: ($500) (utilities)
  - 1/25: ($1,200) (supplies)
  - 1/27: ($25) (bank fee)
- **Closing balance: $15,975**

### Step 2: Create Reconciliation Record

**In Banking > Reconciliations > New**:

```
Account:           Business Checking
Statement Date:    1/31/2024
Opening Balance:   $10,000
Closing Balance:   $15,975 (from statement)
```

**System**:
- Creates reconciliation record
- Status: In Progress
- Displays reconciliation form

### Step 3: Match Transactions

**Akaunting transactions recorded in January**:

```
1/5:   +$5,000   Customer payment (matched to deposit)
1/6:   +$3,000   Customer payment (matched to deposit)
1/10:  -$800     Payroll (matched to withdrawal)
1/12:  -$1,000   Vendor payment (matched to withdrawal)
1/15:  -$500     Utilities (matched to withdrawal)
1/22:  -$1,200   Office supplies (matched to withdrawal)

Not yet matched:
- Bank interest: $500 (not recorded in Akaunting!)
- Bank fee: $25 (not recorded in Akaunting!)
```

**Matching process**:

1. For each statement item, find corresponding transaction
2. Click checkbox to mark matched
3. System tracks matched total

**Matched so far**:
```
Matched deposits:  $5,000 + $3,000 = $8,000
Matched expenses:  $800 + $1,000 + $500 + $1,200 = $3,500
Matched total:     $8,000 - $3,500 = $4,500
```

### Step 4: Handle Unmatched Items

#### Interest Income (Bank Credit)

**Problem**: Bank paid $500 interest; not recorded in Akaunting

**Solution**: Record transaction for interest

**In Transactions > New**:
```
Type:           Income
Account:        Business Checking
Amount:         +$500
Category:       Interest Income
Description:    January interest earned
Paid At:        1/31/2024
```

**System**: Creates transaction, now appears in reconciliation

**Match**: Click interest item in reconciliation

#### Bank Fee (Bank Charge)

**Problem**: Bank charged $25 fee; not recorded in Akaunting

**Solution**: Record transaction for fee

**In Transactions > New**:
```
Type:           Expense
Account:        Business Checking
Amount:         -$25
Category:       Bank Fees
Description:    Monthly maintenance fee
Paid At:        1/31/2024
```

**Match**: Click fee item in reconciliation

### Step 5: Verify Balance

**Reconciliation form shows**:

```
Opening Balance (from statement):          $10,000
Matched Transactions:
  + Deposits:                 $8,500       (includes interest)
  - Expenses:                 ($3,525)     (includes fee)
────────────────────────────────────────
Calculated Balance:                        $14,975

Bank Statement Closing Balance:            $15,975
                                          ─────────
Difference:                                $1,000

Outstanding Items:
- Outstanding Check #145 (recorded but not cleared):  ($1,000)
────────────────────────────────────────────────────
Reconciled Balance:                        $14,975 ✓
```

#### Outstanding Check

**Issue**: Check written on 1/28 for $1,000, not yet cleared bank

**Status**: 
- Recorded in Akaunting ✓
- Not on bank statement (will clear next month)
- Do NOT mark as reconciled yet

**Handling**:
- Leave unmatched in current reconciliation
- Will match when check clears in February

### Step 6: Complete Reconciliation

Once balanced:

**Click**: "Mark Reconciliation Complete"

**System**:
1. Marks all matched transactions as reconciled
2. Sets reconciliation status: Complete
3. Records completion timestamp
4. Generates reconciliation report

**Outstanding items**: 
- Left as unreconciled
- Will reconcile in next period

### Step 7: Generate Report

**Reconciliation Report**:

```
RECONCILIATION REPORT
Account: Business Checking
Period: January 1 - January 31, 2024

AKAUNTING BALANCE (1/31):            $14,975
BANK STATEMENT BALANCE:              $15,975
                                     ─────────
DIFFERENCE:                          $1,000

RECONCILING ITEMS:
Outstanding Check #145:    ($1,000)  [Will clear next month]
                          ─────────
Reconciled Balance:         $14,975 ✓

MATCHED TRANSACTIONS:
✓ Customer Payment 1       $5,000    (1/5)
✓ Customer Payment 2       $3,000    (1/6)
✓ Interest Income           $500     (1/31)
✓ Payroll              ($800)        (1/10)
✓ Vendor Payment      ($1,000)       (1/12)
✓ Utilities            ($500)        (1/15)
✓ Supplies           ($1,200)        (1/22)
✓ Bank Fee              ($25)        (1/31)

TOTAL MATCHED:              $4,975
```

## Dealing with Discrepancies

### Scenario: Balance Doesn't Match

#### Case 1: Amount Mismatch

```
Calculated Balance:        $14,975
Bank Statement Balance:    $15,500
Difference:                $525
```

**Troubleshooting**:
1. Review all transactions for amount errors
2. Check for duplicate transactions
3. Verify exchange rates (if multi-currency)
4. Contact bank to verify statement accuracy

### Case 2: Missing Transactions

Bank shows transaction not recorded in Akaunting:

```
Bank shows $1,200 debit on 1/15
Akaunting shows no matching transaction
```

**Resolution**:
1. Create transaction for missing item
2. Explanation: Bank withdrew funds before we recorded
3. Common: Automatic payments, direct debits

### Case 3: Different Amounts

Transaction recorded but amount differs:

```
Akaunting: $500 withdrawal
Bank:      $510 withdrawal

Extra $10 = Fee not initially included
```

**Resolution**:
1. Update Akaunting transaction to $510, or
2. Record $10 fee separately

## Multi-Month Reconciliation

### Outstanding Items from Previous Month

Outstanding items from January (check) will clear in February:

**February reconciliation**:

```
January Outstanding Check #145:  ($1,000)
February Statement shows clearing on 2/2

Match February check clearing to January outstanding
Status: Now reconciled (closes Jan issue)
```

### Continuous Reconciliation

For ongoing accuracy:

1. **Weekly**: Review transactions recorded vs. pending
2. **Monthly**: Full statement reconciliation
3. **Quarterly**: Review aging unreconciled items
4. **Annually**: Full audit reconciliation

## Reconciliation Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Outstanding check | Check written but not cleared | Wait for clearing, reconcile next month |
| Deposits in transit | Deposit recorded but not deposited | Verify deposit was made |
| Bank error | Incorrect charge/fee | Contact bank to correct |
| Timing difference | Date lag between recording and clearing | Normal, typically 1-2 days |
| Duplicate entry | Transaction recorded twice | Remove duplicate |
| Fee not recorded | Bank charged fee | Record fee transaction |

## Source Map

| Concept | File |
|---------|------|
| Reconciliation model | `app/Models/Banking/Reconciliation.php` |
| Reconciliation controller | `app/Http/Controllers/Banking/Reconciliations.php` |
| Create reconciliation job | `app/Jobs/Banking/CreateReconciliation.php` |
| Transaction model | `app/Models/Banking/Transaction.php` |
| Account model | `app/Models/Banking/Account.php` |

## Related Pages

- [Bank Accounts](../systems/banking/accounts.md) – Account management
- [Bank Reconciliation](../systems/banking/reconciliation.md) – Reconciliation system
- [Banking Transactions](../systems/banking/transactions.md) – Transaction recording
