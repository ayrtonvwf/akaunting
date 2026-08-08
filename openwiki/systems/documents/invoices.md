---
type: system-domain
title: Invoices & Sales Operations
description: Invoice creation, sending, payment tracking, and sales document lifecycle in Akaunting.
tags: [invoices, documents, sales, payment-tracking]
---

# Invoices & Sales Operations

The Invoices system handles creation, management, and lifecycle of sales invoices. Invoices are documents of type `invoice` in the polymorphic `Document` model. The system tracks issuance, sending, payment status, and audit trails.

## Core Workflow

### 1. Invoice Creation

**Controller**: `App\Http\Controllers\Sales\Invoices`
**Job**: `App\Jobs\Document\CreateDocument`

**Flow**:
1. User submits invoice form via `POST /admin/sales/invoices`
2. Controller validates with `App\Http\Requests\Document\Document`
3. Controller dispatches `CreateDocument` job with validated data
4. Job creates `Document` record with `type='invoice'`
5. Job creates line items and totals via `CreateDocumentItemsAndTotals`
6. Job attaches media (optional attachments)
7. Job fires `DocumentCreated` event
8. Listeners create audit trails, send notifications

**Minimum required fields**:
```php
[
    'document_number' => 'INV-001',
    'type' => 'invoice',
    'contact_id' => 1,
    'issued_at' => '2024-01-15',
    'due_at' => '2024-02-15',
    'items' => [
        [
            'item_id' => 1,
            'quantity' => 1,
            'price' => 100.00,
        ]
    ]
]
```

### 2. Invoice States

Invoices progress through statuses:

| Status | Meaning |
|--------|---------|
| **draft** | Created but not sent; can be freely edited |
| **sent** | Sent to customer; still editable via update |
| **viewed** | Customer opened email/view link |
| **approved** | Customer accepted (if workflow enabled) |
| **partial** | Payment received for part of total |
| **paid** | Full payment received |
| **overdue** | Due date passed without full payment |
| **unpaid** | Never marked as sent; no payment received |
| **cancelled** | Voided; no longer valid |

**State transitions**:
```
draft → sent → viewed → [approved] → [partial] → paid
                              ↓
                           cancelled
                              ↑
           (can cancel from any state)
```

**Updating status via jobs**:
- `SendDocument` – Mark sent, send email
- `MarkSentInvoice` – Manual sent marking
- `MarkCancelledInvoice` – Cancel invoice
- Payment recording via `CreateTransaction` automatically updates to paid/partial

### 3. Invoice Line Items

**Model**: `App\Models\Document\DocumentItem`

Line items are created via `CreateDocumentItem` job during invoice creation. Each item has:

```php
[
    'item_id' => 1,              // Link to product/service
    'name' => 'Service',         // Override item name
    'description' => 'Details',  // Line description
    'quantity' => 2,             // Units
    'unit' => 'hour',            // Unit type
    'price' => 150.00,           // Unit price
    'tax_total' => 30.00,        // Taxes for this line
    'amount' => 300.00,          // quantity * price (before tax)
]
```

**Tax calculation**:
- Item taxes determined by item's `tax_types` relationship
- Each tax is applied to quantity × price
- Tax totals summed in `item_taxes` collection

### 4. Invoice Totals

**Model**: `App\Models\Document\DocumentTotal`

Totals are aggregated rows representing subtotals, taxes, discounts, and grand total.

**Typical totals array**:
```php
[
    ['code' => 'subtotal', 'title' => 'Subtotal', 'amount' => 300.00],
    ['code' => 'tax', 'title' => 'Tax', 'amount' => 30.00],
    ['code' => 'discount', 'title' => 'Discount', 'amount' => -10.00],
    ['code' => 'total', 'title' => 'Total', 'amount' => 320.00],
]
```

See [Document Calculations](totals.md) for detailed calculation logic.

### 5. Sending Invoices

**Job**: `App\Jobs\Document\SendDocument`

Sending involves:

1. Email invoice to all contact persons with email
2. Mark document status as `sent`
3. Record send attempt in `DocumentHistory`
4. Fire `DocumentSent` event

**Route**: `POST /admin/sales/invoices/{id}/email`

**Email template**: Uses document template (professional, minimal, detailed) + custom color branding.

### 6. Payment Tracking

Payments are recorded as banking transactions linked to the invoice:

**Model**: `App\Models\Banking\Transaction` (linked via `document_id`)

**When payment is created**:
1. Transaction created with `document_id` = invoice ID
2. Transaction amount matched against invoice amount
3. Invoice status automatically updates:
   - If paid amount < total → `partial`
   - If paid amount >= total → `paid`

**Multi-payment invoices**: Multiple transactions can link to one invoice; totals reconcile across all.

**Reconciliation**: See [Bank Reconciliation Workflow](../../workflows/bank-reconciliation.md) for matching bank statement transactions.

## Key Features

### Invoice Templates

Invoices can use different visual templates:
- **Professional** – Full invoice layout with all details
- **Minimal** – Simplified layout
- **Detailed** – Extended details and terms

Template selected at creation, saved in `Document.template` field. CSS customization via `Document.color` for branding.

### Multi-Currency Invoices

Invoices support currency different from company base currency:

```php
[
    'currency_code' => 'EUR',          // Invoice currency
    'currency_rate' => 1.10,           // Conversion rate to base
]
```

Amount displayed in invoice currency; converted to base for reporting.

### Recurring Invoices

For auto-generated invoices, see [Recurring Documents](recurring.md).

**Relationship**: Child invoices created from recurring parent:
```php
$invoice->recurring;              // BelongsTo: Parent recurring invoice
$recurringInvoice->children();    // HasMany: Generated invoices
```

### Contact Information

Contact info is **denormalized** when invoice created:

```php
[
    'contact_id' => 1,
    'contact_name' => 'Acme Corp',
    'contact_email' => 'billing@acme.com',
    'contact_tax_number' => '123456789',
    'contact_address' => '123 Main St',
    'contact_city' => 'Springfield',
    'contact_state' => 'IL',
    'contact_zip_code' => '62701',
    'contact_country' => 'US',
]
```

If contact is deleted, invoice preserves historical accuracy via denormalized fields.

### Attachments & Media

Invoices can have file attachments (PDF, images, documents):

**Relationship**: `Document.media()` – polymorphic to `Media` model

**Storage**: Files stored in `storage/app/public/invoices/`

**API**: Upload during invoice creation via multipart `attachment` field.

## API Operations

**REST Endpoints**:

```
GET    /api/invoices                    – List invoices
GET    /api/invoices/{id}               – Get invoice details
POST   /api/invoices                    – Create invoice
PUT    /api/invoices/{id}               – Update invoice
DELETE /api/invoices/{id}               – Delete (soft delete)
GET    /api/invoices/{id}/pdf           – Download PDF
POST   /api/invoices/{id}/email         – Send email
```

**Request body example**:
```json
{
  "document_number": "INV-001",
  "type": "invoice",
  "contact_id": 1,
  "issued_at": "2024-01-15",
  "due_at": "2024-02-15",
  "items": [
    {
      "item_id": 1,
      "quantity": 1,
      "price": 100.00,
      "taxes": [1, 2]
    }
  ]
}
```

**Response**: Returns `Document` resource with full details including items, totals, transactions.

## Authorization

**Permissions**:
- `read-sales-invoices` – View invoices
- `create-sales-invoices` – Create new invoices
- `update-sales-invoices` – Edit existing invoices
- `delete-sales-invoices` – Delete invoices

**Middleware**: Applied to all routes in `Sales\Invoices` controller.

## Common Workflows

### Create and Send Invoice

```php
// 1. Controller receives form
$this->authorize('create', Invoice::class);

// 2. Dispatch job
$invoice = $this->dispatch(new CreateDocument(
    auth()->user(),
    request()->validated(),
    auth()->user()->currentCompany()
));

// 3. Optionally send immediately
$this->dispatch(new SendDocument($invoice));
```

### Record Payment

```php
// In banking/transactions controller
$payment = $this->dispatch(new CreateTransaction(
    auth()->user(),
    [
        'document_id' => $invoice->id,
        'amount' => $invoice->amount,
        'account_id' => 1,
        'paid_at' => now(),
        'description' => 'Invoice INV-001 payment',
    ],
    $company
));

// Invoice status auto-updates to 'paid'
```

### Duplicate Invoice

```php
$duplicate = $this->dispatch(new DuplicateDocument($invoice));
// Returns new invoice with same line items/totals, fresh document number
```

## Source Map

| Concept | File |
|---------|------|
| Invoice controller | `app/Http/Controllers/Sales/Invoices.php` |
| Create job | `app/Jobs/Document/CreateDocument.php` |
| Send job | `app/Jobs/Document/SendDocument.php` |
| Document model | `app/Models/Document/Document.php` |
| Line item model | `app/Models/Document/DocumentItem.php` |
| Request validation | `app/Http/Requests/Document/Document.php` |
| API resource | `app/Http/Resources/Document/Document.php` |
| Events | `app/Events/Document/*.php` |
| Listeners | `app/Listeners/Document/*.php` |

## Testing

**Feature tests**: `/tests/Feature/Documents/Invoices.php`

Key test cases:
- Create invoice with items and taxes
- Send invoice via email
- Update invoice status
- Record payment and verify status change
- Delete invoice (soft delete)
- Authorization/permission checks

---

## Related Pages

- [Documents Overview](overview.md) – Document model structure
- [Document Calculations](totals.md) – Line item and total calculations
- [Recurring Documents](recurring.md) – Auto-generation schedules
- [Banking Transactions](../banking/transactions.md) – Payment recording
- [Invoice Workflow](../../workflows/invoice-workflow.md) – End-to-end workflow
