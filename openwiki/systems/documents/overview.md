---
type: system-overview
title: Documents System - Invoices & Bills
description: Document model, polymorphic types (invoices/bills), line items, taxes, totals, and document lifecycle.
tags: [documents, invoices, bills, accounting]
---

# Documents System Overview

The Documents system handles all document types: invoices, bills, and their recurring variants. All documents use a single polymorphic `Document` model with `type` field distinguishing between invoice, bill, invoice-recurring, and bill-recurring.

## Core Model: Document

**File**: `App\Models\Document\Document`

**Table**: `documents`

**Polymorphic Type Field**: `type` ∈ {`invoice`, `bill`, `invoice-recurring`, `bill-recurring`}

### Key Attributes

```
id, company_id, type, document_number, order_number, status,
issued_at, due_at, amount, currency_code, currency_rate,
discount_type, discount_rate, category_id, contact_id,
contact_name, contact_email, contact_tax_number, contact_phone,
contact_address, contact_country, contact_state, contact_zip_code,
contact_city, title, subheading, notes, footer, template, color,
parent_id, created_from, created_by, created_at, updated_at, deleted_at
```

### Important Attributes

- **document_number**: Unique per document type per company (e.g., INV-001, BILL-001)
- **status**: Draft, sent, viewed, approved, partial, paid, overdue, unpaid, cancelled
- **contact_***: Denormalized contact info for historical accuracy (if contact deleted, invoice preserves name/address)
- **template**: Document template style (professional, minimal, detailed)
- **color**: Custom branding color
- **currency_rate**: Conversion rate from document currency to company base currency

### Relationships

```php
$document->contact();           // BelongsTo: Customer or vendor
$document->items();             // HasMany: DocumentItem (line items)
$document->item_taxes();        // HasMany: DocumentItemTax (all taxes)
$document->totals();            // HasMany: DocumentTotal (subtotal, tax, discount, total rows)
$document->transactions();      // HasMany: Banking transactions (payments)
$document->histories();         // HasMany: DocumentHistory (audit trail)
$document->recurring();         // BelongsTo: Parent recurring document (for auto-generated)
$document->children();          // HasMany: Child documents generated from recurring
$document->media();             // Polymorphic: Attachments
```

### Scopes

```php
Document::invoice();            // Only invoices (type='invoice')
Document::bill();               // Only bills (type='bill')
Document::recurring();          // Only recurring (type ends with '-recurring')
Document::notRecurring();       // Only non-recurring
Document::status($status);      // Filter by status
```

---

## Related Models

### DocumentItem (App\Models\Document\DocumentItem)

Individual line item in a document.

**Attributes**:
```
id, document_id, item_id, name, description, quantity, unit, 
price, tax_total, amount, created_at, updated_at
```

**Calculation**: `amount = quantity * price` (before taxes)

**Relationships**:
```php
$item->document;                // BelongsTo document
$item->item;                    // BelongsTo catalog item (if from catalog)
$item->taxes;                   // HasMany: DocumentItemTax
```

### DocumentItemTax (App\Models\Document\DocumentItemTax)

Taxes applied to a document item.

**Attributes**:
```
id, item_id, tax_id, name, rate, amount, created_at, updated_at
```

**Calculation**: `amount = item.amount * rate / 100` (exclusive tax)

**Relationship**:
```php
$tax->tax;                      // BelongsTo: Tax definition (from settings)
```

### DocumentTotal (App\Models\Document\DocumentTotal)

Summary totals for a document (subtotal, discount, taxes, total).

**Attributes**:
```
id, document_id, code, name, amount, created_at, updated_at
```

**Common Codes**:
- `subtotal`: Sum of item amounts (before discount/tax)
- `discount`: Total discount amount
- `item_tax`: Total item taxes
- `total`: Final amount (subtotal - discount + taxes)

**Example**:
```
Subtotal:   $1000.00
Discount:   -$100.00  (10%)
Item Tax:   +$180.00  (18%)
─────────────────────
Total:      $1080.00
```

### DocumentHistory (App\Models\Document\DocumentHistory)

Audit trail of document state changes.

**Attributes**:
```
id, document_id, status, created_by, created_at
```

Entries created on:
- Document creation
- Status changes (draft→sent, sent→paid, etc.)
- Payment received
- Document cancelled/restored

---

## Document Lifecycle & Status

### Status Flowchart

**Invoice Statuses**:
```
Draft → Sent → [Viewed] → [Approved] → [Partial] → Paid
  ↓                                         ↑
  └─────────────────── Overdue ←────────────┘
         (Due date passed)
Unpaid, Cancelled (terminal states)
```

**Bill Statuses**:
```
Draft → Received → [Partial] → Paid
  ↓       ↓                      ↑
  └───────┴─── Overdue ←─────────┘
Unpaid, Cancelled (terminal states)
```

### Status Transitions

| From | To | Action | Middleware |
|------|----|----- |-----------|
| draft | sent | Send to customer | update-sales-invoices |
| draft | received | Mark received | update-purchases-bills |
| sent | viewed | Customer opens link | (automatic) |
| sent/partial | paid | Payment received | (automatic) |
| any | cancelled | User cancels | update-sales-invoices |
| cancelled | draft | Restore document | update-sales-invoices |

---

## Document Creation

### Controllers

**Invoice Creation**: `App\Http\Controllers\Sales\Invoices`
**Bill Creation**: `App\Http\Controllers\Purchases\Bills`

**Routes**:
```
GET    /admin/sales/invoices/create          – Form
POST   /admin/sales/invoices                 – Store
PATCH  /admin/sales/invoices/{id}            – Update
DELETE /admin/sales/invoices/{id}            – Delete
```

### Form Validation

**Request**: `App\Http\Requests\Document\Document`

**Rules**:
```php
'contact_id' => 'required|exists:contacts,id',
'issued_at' => 'required|date',
'due_at' => 'required|date|after:issued_at',
'items' => 'required|array|min:1',
'items.*.description' => 'required|string',
'items.*.quantity' => 'required|numeric|min:0.01',
'items.*.price' => 'required|numeric|min:0',
```

### Job: CreateDocument

**File**: `App\Jobs\Document\CreateDocument`

**Process**:
1. Validate authorization (plan limits)
2. Fire `DocumentCreating` event
3. Create document record in transaction
4. Attach file attachments to media
5. Dispatch `CreateDocumentItemsAndTotals` job
6. Fire `DocumentCreated` event

**Output**: Document instance with items and totals calculated

---

## Document Item & Tax Calculation

### Job: CreateDocumentItemsAndTotals

**File**: `App\Jobs\Document\CreateDocumentItemsAndTotals`

**Process**:
1. Create DocumentItem for each item in request
2. Calculate and create DocumentItemTax for each item's taxes
3. Create DocumentTotal rows (subtotal, discount, taxes, total)
4. Update Document.amount field with final total

**Tax Calculation**:
```php
// For each item
$item_amount = quantity * price

// For each tax on item
$tax_amount = item_amount * tax_rate / 100
$document_item_tax->amount = tax_amount

// Totals
$subtotal = sum(item_amount)
$total_discount = subtotal * discount_rate / 100
$total_tax = sum(tax_amount)
$final_total = subtotal - discount + total_tax
```

**Tax Methods** (from `config/money.php`):
- **Exclusive**: Tax added to price (standard)
- **Inclusive**: Tax included in price
- **Compound**: Tax on tax

---

## Document Operations

### Sending Documents

**Controller Method**: `Invoices@emailInvoice` or `Bills@emailInvoice`

**Job**: `App\Jobs\Document\SendDocument`

**Process**:
1. Validate document and contact email
2. Generate PDF
3. Send email with PDF attachment
4. Fire `DocumentSent` event
5. Listener updates status to 'sent'

### Downloading/Printing

**Routes**:
```
GET /admin/sales/invoices/{id}/pdf     – Download PDF
GET /admin/sales/invoices/{id}/print   – Print view
```

**PDF Generation**: Uses DomPDF via Laravel wrapper

**Templates**: Different invoice/bill templates available (professional, minimal)

### Duplication

**Route**: `GET /admin/sales/invoices/{id}/duplicate`

**Job**: `App\Jobs\Document\DuplicateDocument`

Creates new document with:
- Same items and taxes
- New document number
- Reset status to draft
- Cleared dates (new issued_at = today)

### Cancellation

**Route**: `GET /admin/sales/invoices/{id}/cancelled`

**Job**: `App\Jobs\Document\CancelDocument`

- Changes status to 'cancelled'
- Creates history entry
- Prevents further payments

### Restoration

**Route**: `GET /admin/sales/invoices/{id}/restore`

**Job**: `App\Jobs\Document\RestoreDocument`

Restores cancelled document to previous state.

---

## Recurring Documents

### RecurringDocument Relationship

Invoices/bills can be marked as recurring. Children are auto-generated at intervals.

**Parent Document**: Type = 'invoice-recurring' or 'bill-recurring'

**Child Documents**: Type = 'invoice' or 'bill' (created by recurring job)

**Schedule**: Monthly, quarterly, annually, or custom intervals

### Auto-Generation

**Schedule**: Checks daily for documents due for generation

**Job**: `App\Jobs\Document\CreateRecurringDocuments`

**Logic**:
1. Find active recurring documents past next generation date
2. For each, clone to create new child document
3. Update next generation date
4. Send automatically if configured

Reference: [Recurring Documents](recurring.md)

---

## Payment Tracking

Documents track associated payments via transactions.

**Relationship**: `$document->transactions()`

**Matching**: Transactions linked by:
1. Manual assignment during payment entry
2. Automatic matching by payment method/reference
3. Manual reconciliation UI

**Paid Amount**: Calculated from sum of linked transactions

**Status Automation**:
- If paid_amount >= amount: Status → 'paid'
- If paid_amount > 0 and < amount: Status → 'partial'
- If past due_at and unpaid: Status → 'overdue'

---

## API Endpoints

**Resource**: `App\Http\Resources\Document\Document`

```
GET    /api/documents              – List documents
GET    /api/documents/{id}         – Get document by ID or number
POST   /api/documents              – Create document
PATCH  /api/documents/{id}         – Update document
DELETE /api/documents/{id}         – Delete document
GET    /api/documents/{id}/received – Mark bill as received
POST   /api/documents/{id}/transactions – Link transaction
```

---

## Events

- `DocumentCreating` – Before creation
- `DocumentCreated` – After creation, fires listeners for history and numbering
- `DocumentUpdating` – Before update
- `DocumentUpdated` – After update
- `DocumentSending` – Before send email
- `DocumentSent` – After send, updates status to 'sent'
- `DocumentDeleting` – Before soft delete
- `DocumentCancelled` – Status changed to cancelled
- `DocumentRestored` – Restored from cancelled
- `DocumentViewed` – Customer opened PDF link
- `PaymentReceived` – Transaction linked to document

Listeners:
- Create audit history
- Increment document number sequence
- Send notifications
- Update document status
- Create related transactions

---

## Best Practices

1. **Save Original Contact Info**: Denormalize contact fields so deleted contacts don't break documents
2. **Document Numbers**: Use job to increment sequences; prevents duplicate numbers
3. **Tax Precision**: Store tax amounts, don't round until final total
4. **Currency Rates**: Always store rate for future reference (for reporting)
5. **Status Transitions**: Only allow valid transitions via scopes/middleware

---

## Testing Documents

```php
// Factory creation
$invoice = Document::factory()
    ->has(DocumentItem::factory()->count(3))
    ->invoice()
    ->create(['contact_id' => $contact->id]);

// Test creation flow
$this->post(route('invoices.store'), [
    'contact_id' => $contact->id,
    'items' => [[...], [...]],
]);
$this->assertDatabaseHas('documents', ['type' => 'invoice']);

// Test status transition
$invoice->markSent();
$this->assertEquals('sent', $invoice->fresh()->status);
```

---

*Reference: /app/Models/Document, /app/Http/Controllers/Sales, /app/Http/Controllers/Purchases, /app/Jobs/Document*
