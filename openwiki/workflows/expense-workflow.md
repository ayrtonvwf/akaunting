---
type: workflow
title: Expense Workflow
description: Recording expenses, matching bills, vendor payments, and expense tracking from purchase to reconciliation.
tags: [workflow, expenses, bills, vendors, accounting]
---

# Expense Workflow

The expense workflow covers the complete lifecycle of business expenses: from receiving vendor bills, recording them, approving payments, to reconciling with bank statements.

## Workflow Overview

```
Vendor Bill Received
    │
    ├─ Create Bill Record
    │  ├─ Capture vendor details
    │  ├─ Add line items
    │  ├─ Calculate taxes & totals
    │  └─ Attach bill copy (optional)
    │
    ├─ Review & Approve
    │  ├─ Verify amounts
    │  ├─ Check line items
    │  └─ Mark as approved (workflow)
    │
    ├─ Record Payment
    │  ├─ Select payment account
    │  ├─ Record payment date & method
    │  └─ Link to bill
    │
    └─ Reconcile with Bank
       ├─ Match payment to bank statement
       ├─ Verify clearing
       └─ Complete reconciliation
```

## Step 1: Record the Bill

**When**: Vendor bill arrives or service is delivered

**Action**: Create bill in Purchases > Bills

**What to enter**:
- Vendor (Customer)
- Invoice number / Bill ID
- Due date
- Line items (what was purchased)
- Amount and taxes

**System creates**:
- Bill record with `status='draft'`
- Line items with quantities and pricing
- Totals row calculating subtotal, taxes, total

**Source documents**:
- Vendor invoice
- Purchase order confirmation
- Receipt or packing slip

### Recording via API

```json
POST /api/bills

{
  "type": "bill",
  "document_number": "BILL-001",
  "contact_id": 5,
  "issued_at": "2024-01-15",
  "due_at": "2024-02-15",
  "items": [
    {
      "name": "Office Supplies",
      "quantity": 5,
      "price": 25.00,
      "taxes": [1]
    }
  ]
}
```

## Step 2: Review & Approve

**When**: After bill is recorded and reviewed

**Action**: Update bill status to "approved"

**Review checklist**:
- Amount matches vendor invoice
- Line items match receipt/PO
- Taxes calculated correctly
- Duplicate (already recorded?)

**System impact**:
- Bill status changes to `approved`
- Flagged as ready for payment
- Visible in approval workflow (if enabled)

### Workflow Steps (Optional)

If approval workflow enabled:

1. Bill created by Accountant (`draft`)
2. Awaiting Manager approval (`pending`)
3. Manager approves (`approved`)
4. Ready for payment

## Step 3: Record Payment

**When**: Payment is made to vendor

**Action**: Create banking transaction linked to bill

**Payment options**:
- Check (with number)
- Wire transfer (with reference)
- Credit card charge
- Manual payment

**System creates**:
- Expense transaction in selected account
- Linked to bill via `document_id`
- Bill status auto-updates to `paid` or `partial`

### Payment Recording

**In Banking > Transactions > New**:

```
Type:           Expense
Account:        Checking
Amount:         -125.00
Contact:        Acme Supplies (vendor)
Document:       BILL-001 (links to bill)
Payment Method: Check
Reference:      #12345
Date:           2024-02-01
```

### Partial Payments

If paying part of bill:

```
Bill Total:     $500.00
Payment 1:      -$250.00  (partial)
Payment 2:      -$250.00  (pays in full)
Status:         paid
```

Bill status auto-updates based on paid vs. total amount.

### Multiple Expenses from One Bill

Some bills span multiple expense categories:

```
Bill: Office Remodeling $1,000
├─ Materials:  $600 (Supplies)
├─ Labor:      $300 (Contractor)
└─ Tax:        $100 (Tax Services)
```

Can be recorded as:
1. Single bill with category-level detail, or
2. Split transaction across categories

## Step 4: Reconcile with Bank

**When**: Bank statement arrives (weekly/monthly)

**Action**: Match payment to bank statement

**Reconciliation steps**:

1. Download bank statement
2. Go to Banking > Reconciliations > New
3. Select account and statement date
4. Enter bank's closing balance
5. Match each statement line to recorded transaction

**Match the payment**:
- Expense transaction (check/wire)
- Matches bank statement withdrawal
- Same amount and date (or ±1 day)
- Marked as reconciled

**Result**:
- Payment verified to bank
- Bill fully documented
- Complete audit trail

## Complete Workflow Example

**Scenario**: Purchase office supplies from vendor

### Timeline

| Date | Action | Status | Notes |
|------|--------|--------|-------|
| 01/10 | Vendor ships supplies | – | Tracking #12345 |
| 01/12 | Bill received | draft | Invoice #INV-5678 |
| 01/12 | Create bill in system | draft | $125.00 total |
| 01/14 | Manager approves | approved | Ready to pay |
| 02/01 | Pay via check | paid | Check #12345 |
| 02/05 | Bank clears check | paid | Statement shows -$125 |
| 02/28 | Monthly reconciliation | reconciled | Matched to statement |

### Accounting Impact

**Journal entries** (simplified):

```
01/12: Record Bill
  Expense (Supplies)    $125.00
    Accounts Payable            $125.00

02/01: Record Payment
  Accounts Payable      $125.00
    Bank Account                $125.00
```

**Balance sheet**:
- 01/12: Payable increases $125
- 02/01: Payable decreases $125 (now paid)

### Reporting

**Profit & Loss**:
- Supplies Expense: $125.00

**Cash Flow**:
- Outflow 02/01: $125.00

**Aging Report**:
- Once paid, no longer in "Aging Payables"

## Variations

### Recurring Expenses

Regular vendor charges (subscriptions, utilities, rent):

1. Create bill manually each month, or
2. Set up recurring bill – auto-generates on schedule

Example: Monthly rent from landlord

```
Recurring Bill
├─ Monthly rent: $2,000
├─ Frequency: Monthly
├─ Start: 2024-01-01
└─ Limit: Indefinite (ongoing)

Auto-generated Bills
├─ 01/01: Rent Bill #1
├─ 02/01: Rent Bill #2
└─ 03/01: Rent Bill #3 (continues)
```

### Expense Reports

Employees submit expense reports; reimbursement recorded as bill:

```
Expense Report from John Smith
├─ Hotel:    $150
├─ Meals:    $45
├─ Mileage:  $30
└─ Total:    $225

Create Bill:
├─ Vendor: John Smith (Reimbursable)
├─ Items: Expenses
└─ Total: $225
```

### Early Payment Discount

Bill eligible for discount if paid early:

```
Bill:        $1,000
Terms:       2/10 net 30 (2% discount if paid within 10 days)
Early Pay:   $980
```

Record as bill with discount or document as separate transaction.

## Source Map

| Concept | File |
|---------|------|
| Bill controller | `app/Http/Controllers/Purchases/Bills.php` |
| Bill model | `app/Models/Document/Document.php` (type=bill) |
| Create bill job | `app/Jobs/Document/CreateDocument.php` |
| Transaction controller | `app/Http/Controllers/Banking/Transactions.php` |
| Create transaction job | `app/Jobs/Banking/CreateTransaction.php` |
| Reconciliation | `app/Models/Banking/Reconciliation.php` |

## Related Pages

- [Bills & Purchases](../systems/documents/bills.md) – Bill creation and management
- [Banking Transactions](../systems/banking/transactions.md) – Expense recording
- [Bank Reconciliation](../systems/banking/reconciliation.md) – Statement matching
- [Bank Reconciliation Workflow](bank-reconciliation.md) – Full reconciliation process
