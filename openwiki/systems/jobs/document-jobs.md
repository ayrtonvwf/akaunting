---
type: system-reference
title: Document Jobs - Invoice & Bill Operations
description: Job classes for document creation, updates, lifecycle management, and document-specific operations.
tags: [jobs, documents, invoices, bills, lifecycle]
openwiki:
  source_paths: [app/Jobs/Document]
  symbols: [CreateDocument, UpdateDocument, DeleteDocument, SendDocument, DuplicateDocument]
---

# Document Jobs

Document jobs handle the complete lifecycle of invoices, bills, and recurring documents. All document changes go through these jobs to ensure consistency and proper event firing.

## Document Creation & Updates

### CreateDocument

**File**: `App\Jobs\Document\CreateDocument`

**Purpose**: Create a new document (invoice, bill, or recurring)

**Input**:
```php
$data = [
    'type' => 'invoice',                    // invoice, bill, invoice-recurring, bill-recurring
    'contact_id' => 1,
    'currency_code' => 'USD',
    'issued_at' => '2024-01-15',
    'due_at' => '2024-02-15',
    'document_number' => null,              // Auto-generated if null
    'discount_type' => 'percent',           // percent or fixed
    'discount_rate' => 10,
    'notes' => 'Payment terms...',
    'items' => [
        [
            'item_id' => 1,
            'quantity' => 2,
            'price' => '100.00',
            'tax_ids' => [1, 2],
        ],
    ],
    // For recurring documents:
    'recurring_type' => 'month',            // month, quarter, year
    'recurring_every' => 1,                 // Repeat every N periods
    'recurring_stop_date' => '2024-12-31',  // When to stop auto-generating
]
```

**Process**:
1. Create Document model with auto-generated number
2. Dispatch `CreateDocumentItemsAndTotals` to add items and calculate totals
3. Fire `DocumentCreated` event
4. Return Document instance

**Usage**:
```php
$document = $this->dispatch(
    new CreateDocument($request->validated())
);

return redirect()->route('invoices.show', $document->id)
    ->with('success', 'Invoice created');
```

**Events Fired**:
- `App\Events\Document\DocumentCreated` – Document created

**Validation**:
- Contact must exist
- Currency must be valid
- Items required, at least one

### UpdateDocument

**File**: `App\Jobs\Document\UpdateDocument`

**Purpose**: Update document and recalculate totals

**Input**:
```php
$data = [
    'contact_id' => 2,
    'currency_code' => 'EUR',
    'issued_at' => '2024-01-20',
    'due_at' => '2024-02-20',
    'discount_type' => 'fixed',
    'discount_rate' => 50,
    'notes' => 'Updated notes',
    'items' => [
        [
            'item_id' => 1,
            'quantity' => 3,
            'price' => '100.00',
        ],
    ],
    // Only allowed if status is 'draft':
    'status' => 'draft',
]
```

**Process**:
1. Verify document not already sent/paid (locked)
2. Update document fields
3. Clear old items/totals
4. Dispatch `CreateDocumentItemsAndTotals` for new items
5. Fire `DocumentUpdated` event
6. Return Document instance

**Usage**:
```php
$document = $this->dispatch(
    new UpdateDocument($existing_document, $request->validated())
);
```

**Restrictions**:
- Cannot modify if document status is not 'draft' or 'approved'
- Number and type cannot be changed

**Events Fired**:
- `App\Events\Document\DocumentUpdated`

## Document Lifecycle Operations

### SendDocument

**File**: `App\Jobs\Document\SendDocument`

**Purpose**: Mark document as sent and optionally email to contact

**Input**:
```php
$data = [
    'send_via' => 'email',              // email or print
    'email_subject' => 'Your Invoice',
    'email_body' => 'Please review...',
]
```

**Process**:
1. Update status to 'sent'
2. Record send timestamp
3. Send email if configured
4. Fire `DocumentSent` event
5. Return Document instance

**Usage**:
```php
$document = $this->dispatch(
    new SendDocument($document, ['send_via' => 'email'])
);
```

**Events Fired**:
- `App\Events\Document\DocumentSent`

### DeleteDocument

**File**: `App\Jobs\Document\DeleteDocument`

**Purpose**: Soft delete document

**Input**:
```php
$document_instance  // The Document to delete
```

**Process**:
1. Only allow if status is 'draft'
2. Soft delete document record
3. Fire `DocumentDeleted` event
4. Return success

**Usage**:
```php
$this->dispatch(new DeleteDocument($document));
```

**Restrictions**:
- Only draft documents can be deleted
- Sent/paid documents must be cancelled instead

**Events Fired**:
- `App\Events\Document\DocumentDeleted`

### CancelDocument

**File**: `App\Jobs\Document\CancelDocument`

**Purpose**: Cancel a sent/paid document without deleting

**Input**:
```php
$data = [
    'reason' => 'Customer requested',
    'keep_reference' => true,
]
```

**Process**:
1. Update status to 'cancelled'
2. Record cancellation reason
3. Reverse any associated transactions (optional)
4. Fire `DocumentCancelled` event
5. Return Document instance

**Usage**:
```php
$document = $this->dispatch(
    new CancelDocument($document, $request->validated())
);
```

**Events Fired**:
- `App\Events\Document\DocumentCancelled`

### DuplicateDocument

**File**: `App\Jobs\Document\DuplicateDocument`

**Purpose**: Create a copy of existing document with new number

**Input**:
```php
$source_document  // The document to copy
```

**Process**:
1. Copy document with new number
2. Reset status to 'draft'
3. Clear transaction links
4. Copy items and totals
5. Fire `DocumentDuplicated` event
6. Return new Document instance

**Usage**:
```php
$new_document = $this->dispatch(
    new DuplicateDocument($source_document)
);
```

## Document Item Operations

### CreateDocumentItem

**File**: `App\Jobs\Document\CreateDocumentItem`

**Purpose**: Add single line item to document

**Input**:
```php
[
    'item_id' => 1,
    'quantity' => 2,
    'price' => '100.00',
    'description' => 'Custom description',
]
```

**Process**:
1. Create DocumentItem record
2. Fire `DocumentItemCreated` event
3. Trigger total recalculation

### CreateDocumentItemsAndTotals

**File**: `App\Jobs\Document\CreateDocumentItemsAndTotals`

**Purpose**: Batch add items and recalculate all totals

**Input**:
```php
[
    'items' => [
        [
            'item_id' => 1,
            'quantity' => 2,
            'price' => '100.00',
            'tax_ids' => [1, 2],
        ],
        [
            'item_id' => 2,
            'quantity' => 1,
            'price' => '50.00',
        ],
    ],
    'discount_type' => 'percent',
    'discount_rate' => 10,
]
```

**Process**:
1. Create all DocumentItem records
2. Attach taxes to items
3. Calculate item totals
4. Apply document-level discount
5. Create DocumentTotal rows (subtotal, tax, discount, total)
6. Update document amount field
7. Fire `DocumentItemsCreated` event
8. Return Document with totals loaded

**Calculation Flow**:
```
For each item:
  item_total = quantity * price
  item_taxes = sum(taxes) on item_total

Document subtotal = sum(all item totals)
Document tax = sum(all item taxes)
Discount = subtotal * discount_rate (if percent) or discount_rate (if fixed)
Total = subtotal + tax - discount
```

## Document History & Tracking

### CreateDocumentHistory

**File**: `App\Jobs\Document\CreateDocumentHistory`

**Purpose**: Log document state changes (created by event listener)

**Input**:
```php
[
    'action' => 'created|viewed|sent|paid',
    'user_id' => auth()->id(),
]
```

**Process**:
1. Create DocumentHistory record
2. Record timestamp and user
3. Store action type

Usually called automatically by `CreateDocumentCreatedHistory` listener.

## Download & Export

### DownloadDocument

**File**: `App\Jobs\Document\DownloadDocument`

**Purpose**: Generate PDF or other format for download

**Input**:
```php
[
    'format' => 'pdf',  // pdf, html, print
]
```

**Process**:
1. Render document template
2. Apply styling (color, template)
3. Convert to requested format
4. Return file for download
5. Fire `DocumentDownloaded` event

## Related Pages

- [Jobs Overview](overview.md) – Job patterns and architecture
- [Documents System](../documents/overview.md) – Document data models
- [Document Workflows](../../workflows/invoice-workflow.md) – Complete workflows

## Source Map

```
app/Jobs/Document/
├─ CreateDocument.php
├─ UpdateDocument.php
├─ DeleteDocument.php
├─ CancelDocument.php
├─ SendDocument.php
├─ DuplicateDocument.php
├─ CreateDocumentItem.php
├─ CreateDocumentItemsAndTotals.php
├─ CreateDocumentHistory.php
├─ DownloadDocument.php
├─ RestoreDocument.php
└─ SendDocumentAsCustomMail.php
```

## Testing & Validation

```bash
# Test document jobs
php artisan test tests/Feature/Document/

# Test invoice workflows
php artisan test tests/Feature/Sales/InvoicesTest.php

# Test bill workflows
php artisan test tests/Feature/Purchases/BillsTest.php

# Test document cancellation
php artisan test tests/Feature/Document/CancelDocumentTest.php
```

## Common Patterns

### Create invoice with items in one call

```php
$invoice = $this->dispatch(new CreateDocument([
    'type' => 'invoice',
    'contact_id' => 1,
    'currency_code' => 'USD',
    'issued_at' => now()->toDateString(),
    'items' => [
        ['item_id' => 1, 'quantity' => 2, 'price' => '100.00'],
    ],
]));
```

### Update document and recalculate

```php
$updated = $this->dispatch(new UpdateDocument($document, [
    'items' => [
        ['item_id' => 2, 'quantity' => 1, 'price' => '200.00'],
    ],
]));
```

### Workflow: Create → Send → Record Payment

```php
// Create
$document = $this->dispatch(new CreateDocument($data));

// Send
$this->dispatch(new SendDocument($document));

// Payment handled by banking jobs (creates Transaction)
```
