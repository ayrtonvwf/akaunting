---
type: system-domain
title: Bills & Purchase Operations
description: Bill creation, purchase tracking, vendor payments, and purchase document lifecycle in Akaunting.
tags: [bills, documents, purchases, vendors, payment-tracking]
---

# Bills & Purchase Operations

The Bills system handles creation, management, and lifecycle of purchase bills. Bills are documents of type `bill` in the polymorphic `Document` model. The system tracks vendor invoices, purchase orders, payment obligations, and audit trails.

## Core Workflow

### 1. Bill Creation

**Controller**: `App\Http\Controllers\Purchases\Bills`
**Job**: `App\Jobs\Document\CreateDocument`

**Flow**:
1. User submits bill form via `POST /admin/purchases/bills`
2. Controller validates with `App\Http\Requests\Document\Document`
3. Controller dispatches `CreateDocument` job with validated data
4. Job creates `Document` record with `type='bill'`
5. Job creates line items and totals via `CreateDocumentItemsAndTotals`
6. Job attaches media (optional vendor invoice scans, receipts)
7. Job fires `DocumentCreated` event
8. Listeners create audit trails, send notifications

**Minimum required fields**:
```php
[
    'document_number' => 'BILL-001',
    'type' => 'bill',
    'contact_id' => 1,  // Vendor
    'issued_at' => '2024-01-15',
    'due_at' => '2024-02-15',
    'items' => [
        [
            'item_id' => 1,
            'quantity' => 10,
            'price' => 25.00,
        ]
    ]
]
```

### 2. Bill States

Bills progress through statuses:

| Status | Meaning |
|--------|---------|
| **draft** | Created locally but not yet committed; can be freely edited |
| **sent** | Received from vendor (status marker); can be edited |
| **viewed** | Marked as reviewed internally |
| **approved** | Approved for payment (if workflow enabled) |
| **partial** | Partial payment made to vendor |
| **paid** | Full payment made to vendor |
| **overdue** | Payment due date passed without full payment |
| **unpaid** | Never sent/marked; no payment recorded |
| **cancelled** | Voided; no longer valid |

**State transitions**:
```
draft → sent → viewed → [approved] → [partial] → paid
                              ↓
                           cancelled
                              ↑
           (can cancel from any state)
```

**Key difference from invoices**: Bills represent vendor obligations. "Sent" means bill was received from vendor (not that we sent it).

### 3. Bill Line Items

**Model**: `App\Models\Document\DocumentItem`

Line items represent purchased goods or services. Each item has:

```php
[
    'item_id' => 1,              // Link to product/service
    'name' => 'Office Supplies', // Override item name
    'description' => 'Box of 100', // Line description
    'quantity' => 2,             // Units purchased
    'unit' => 'box',             // Unit type
    'price' => 50.00,            // Unit price from vendor
    'tax_total' => 10.00,        // Taxes for this line
    'amount' => 100.00,          // quantity * price (before tax)
]
```

**Taxes**: Applied based on item's `tax_types` and supplier tax rules.

### 4. Payment Tracking

Payments to vendors are recorded as banking transactions linked to the bill:

**Model**: `App\Models\Banking\Transaction` (linked via `document_id`)

**When payment is recorded**:
1. Expense transaction created with `document_id` = bill ID
2. Transaction amount matched against bill total
3. Bill status automatically updates:
   - If paid amount < total → `partial`
   - If paid amount >= total → `paid`

**Reconciliation**: Bill payments can be reconciled with bank statements. See [Bank Reconciliation Workflow](../../workflows/bank-reconciliation.md).

**Payment methods**: Can be recorded as:
- Check payment (recorded in bank account with check number)
- Wire transfer (recorded with wire reference)
- Credit card charge (recorded in credit card account)
- Manual payment

## Key Features

### Multi-Currency Bills

Bills from international vendors may be in foreign currency:

```php
[
    'currency_code' => 'EUR',          // Bill currency
    'currency_rate' => 0.92,           // Conversion rate to company base
]
```

When payment is recorded, the amount is recorded in bill currency, then converted for reporting.

### Bill Templates

Bills use the same template system as invoices:
- **Professional** – Full details
- **Minimal** – Streamlined
- **Detailed** – Extended terms

### Recurring Bills

For vendors with recurring charges (subscriptions, maintenance), see [Recurring Documents](recurring.md).

**Relationship**:
```php
$bill->recurring;            // BelongsTo: Parent recurring bill
$recurringBill->children();  // HasMany: Generated bills
```

### Vendor Information

Vendor contact info is denormalized at bill creation:

```php
[
    'contact_id' => 1,
    'contact_name' => 'Acme Supplies',
    'contact_email' => 'orders@acme.com',
    'contact_tax_number' => '987654321',
    'contact_address' => '456 Industrial Ave',
    'contact_city' => 'Cleveland',
    'contact_state' => 'OH',
    'contact_country' => 'US',
]
```

Preserves historical accuracy even if vendor is deleted.

### Attachments & Media

Bills can have vendor invoices, receipts, and supporting documents attached:

**Relationship**: `Document.media()` – polymorphic

**Storage**: Files in `storage/app/public/bills/`

**Use case**: Attach vendor's original invoice PDF for audit trail.

## API Operations

**REST Endpoints**:

```
GET    /api/bills                    – List bills
GET    /api/bills/{id}               – Get bill details
POST   /api/bills                    – Create bill
PUT    /api/bills/{id}               – Update bill
DELETE /api/bills/{id}               – Delete (soft delete)
GET    /api/bills/{id}/pdf           – Download PDF
```

**Request body example**:
```json
{
  "document_number": "BILL-001",
  "type": "bill",
  "contact_id": 5,
  "issued_at": "2024-01-10",
  "due_at": "2024-02-10",
  "items": [
    {
      "item_id": 2,
      "quantity": 5,
      "price": 25.00,
      "taxes": [2]
    }
  ]
}
```

**Response**: Returns `Document` resource with full bill details.

## Authorization

**Permissions**:
- `read-sales-bills` – View bills (note: permission is still under "sales" umbrella)
- `create-sales-bills` – Create new bills
- `update-sales-bills` – Edit bills
- `delete-sales-bills` – Delete bills

**Middleware**: Applied to routes in `Purchases\Bills` controller.

## Common Workflows

### Receive Bill from Vendor

```php
// 1. Controller validates form
$this->authorize('create', Bill::class);

// 2. Dispatch create job
$bill = $this->dispatch(new CreateDocument(
    auth()->user(),
    request()->validated(),
    auth()->user()->currentCompany()
));

// Bill is now recorded and ready for approval/payment
```

### Approve Bill

```php
// Mark as approved (workflow step)
$bill->update(['status' => 'approved']);
$this->dispatch(new CreateDocumentHistory($bill));
```

### Pay Bill

```php
// Record payment
$payment = $this->dispatch(new CreateTransaction(
    auth()->user(),
    [
        'document_id' => $bill->id,
        'amount' => -$bill->amount,  // Negative for expense
        'account_id' => $checking_account_id,
        'paid_at' => now(),
        'payment_method' => 'check',
        'reference' => $check_number,
        'description' => "Payment for bill {$bill->document_number}",
    ],
    $company
));

// Bill status auto-updates to 'paid'
```

### Reconcile Payment with Bank Statement

```php
// During bank reconciliation
$reconciliation = new BankReconciliation([
    'account_id' => $account->id,
    'statement_date' => '2024-01-31',
    'closing_balance' => 5000.00,
]);

// Transactions are matched and marked as reconciled
$reconciliation->matchTransaction($payment_transaction);
```

## Difference from Invoices

| Aspect | Invoice | Bill |
|--------|---------|------|
| **Direction** | Sales (we invoice customers) | Purchases (vendors bill us) |
| **Amount** | We receive payment | We make payment |
| **Sender** | We generate and send | Vendor generates, we receive |
| **Contact Type** | Customer | Vendor |
| **Permission** | create-sales-invoices | create-sales-bills |
| **Impact** | Income recorded | Expense recorded |

## Source Map

| Concept | File |
|---------|------|
| Bill controller | `app/Http/Controllers/Purchases/Bills.php` |
| Create job | `app/Jobs/Document/CreateDocument.php` |
| Document model | `app/Models/Document/Document.php` |
| Request validation | `app/Http/Requests/Document/Document.php` |
| API resource | `app/Http/Resources/Document/Document.php` |
| Events | `app/Events/Document/*.php` |

## Testing

**Feature tests**: `/tests/Feature/Purchases/BillsTest.php`

Key test cases:
- Create bill with vendor items
- Update bill status
- Record payment and verify status change
- Delete bill (soft delete)
- Authorization checks

---

## Related Pages

- [Documents Overview](overview.md) – Document model structure
- [Document Calculations](totals.md) – Calculations and totals
- [Recurring Documents](recurring.md) – Recurring vendor bills
- [Banking Transactions](../banking/transactions.md) – Payment recording
- [Contacts](../common/contacts.md) – Vendor management
