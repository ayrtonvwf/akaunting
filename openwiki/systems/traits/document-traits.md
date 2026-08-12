---
type: system-reference
title: Document Traits - Document-Specific Operations
description: Traits providing document model relationships, scopes, and document lifecycle behaviors.
tags: [traits, documents, invoices, bills, relationships]
openwiki:
  source_paths: [app/Traits/Documents.php, app/Traits/Recurring.php, app/Traits/Transactions.php]
---

# Document Traits

Document traits provide the core behaviors for invoice and bill management, including relationships, lifecycle operations, and payment tracking.

## Documents Trait

**File**: `App\Traits\Documents`

Provides relationships and scopes for document models.

### Relationships

```php
$document->contact();          // BelongsTo: Customer/Vendor
$document->items();            // HasMany: DocumentItem (line items)
$document->item_taxes();       // HasMany: DocumentItemTax (tax details)
$document->totals();           // HasMany: DocumentTotal (subtotal, tax, total)
$document->transactions();     // HasMany: Banking\Transaction (payments)
$document->histories();        // HasMany: DocumentHistory (audit trail)
$document->media();            // Polymorphic: Attachments (files)
$document->recurring();        // BelongsTo: Parent recurring document
$document->children();         // HasMany: Auto-generated child documents
$document->company();          // BelongsTo: Company (tenant)
```

### Query Scopes

#### Type Scopes

```php
Document::invoice();              // WHERE type = 'invoice'
Document::bill();                 // WHERE type = 'bill'
Document::recurring();            // WHERE type LIKE '%-recurring'
Document::notRecurring();         // WHERE type NOT LIKE '%-recurring'
```

#### Status Scopes

```php
Document::status('paid');         // WHERE status = 'paid'
Document::status(['paid', 'partial']); // WHERE status IN (...)

// Common status filters
Document::draft();                // status = 'draft'
Document::sent();                 // status = 'sent'
Document::paid();                 // status = 'paid'
Document::unpaid();               // status IN ('draft', 'sent', 'viewed', 'partial')
```

#### Date Scopes

```php
Document::issuedBetween($start, $end);  // WHERE issued_at BETWEEN
Document::dueBefore($date);             // WHERE due_at < $date
Document::dueAfter($date);              // WHERE due_at > $date
Document::overdue();                    // WHERE due_at < NOW() AND status NOT IN ('paid')
```

### Common Queries

```php
// All unpaid invoices
Document::invoice()->unpaid()->get();

// Paid invoices this month
Document::invoice()
    ->paid()
    ->issuedBetween(now()->startOfMonth(), now()->endOfMonth())
    ->get();

// Overdue bills
Document::bill()->overdue()->get();

// Documents for specific customer
Document::where('contact_id', $contact->id)->get();

// Documents by currency
Document::where('currency_code', 'USD')->get();
```

## Recurring Trait

**File**: `App\Traits\Recurring`

Manages recurring document generation and scheduling.

### Relationships

```php
$document->recurring();         // BelongsTo: Parent recurring template
$document->children();          // HasMany: Auto-generated copies
```

### Properties

```php
$document->recurring_type;      // month, quarter, year
$document->recurring_every;     // Repeat every N periods
$document->recurring_stop_date; // When to stop auto-generation
```

### Methods

```php
$document->isRecurring();           // true if type ends with '-recurring'
$document->nextRecurringDate();     // DateTime of next generation
$document->shouldGenerateNext();    // true if next date has passed
$document->generateNext();          // Create next document
$document->lastChild();              // Most recent auto-generated child
```

### Schedule Examples

```php
// Monthly invoices
$recurring = Document::create([
    'type' => 'invoice-recurring',
    'recurring_type' => 'month',
    'recurring_every' => 1,           // Every 1 month
    'recurring_stop_date' => '2024-12-31',
]);

// Quarterly billing
$recurring = Document::create([
    'type' => 'invoice-recurring',
    'recurring_type' => 'quarter',    // Every quarter
    'recurring_every' => 1,
    'recurring_stop_date' => '2025-03-31',
]);

// Annual contracts
$recurring = Document::create([
    'type' => 'bill-recurring',
    'recurring_type' => 'year',
    'recurring_every' => 1,
    'recurring_stop_date' => '2034-01-01',
]);
```

### Generation Logic

```php
// Automatic generation process (usually runs via scheduler or job)
$recurring = Document::find($id);

if ($recurring->shouldGenerateNext()) {
    // Create new document from template
    $new_document = $this->dispatch(new CreateDocument([
        'type' => $recurring->type,
        'contact_id' => $recurring->contact_id,
        'items' => $recurring->items,
        // ... other fields
        'parent_id' => $recurring->id,  // Links to template
    ]));
}
```

### Querying Recurring

```php
// All active recurring documents
Document::recurring()->get();

// Recurring documents needing generation
Document::recurring()
    ->where('recurring_stop_date', '>', now())
    ->where(DB::raw('DATE_ADD(updated_at, INTERVAL recurring_every MONTH)'), '<', now())
    ->get();

// Children of specific recurring
$recurring->children()->get();

// All auto-generated documents
$recurring = Document::findRecurring($id);
$auto_generated = $recurring->children;
```

## Transactions Trait

**File**: `App\Traits\Transactions`

Tracks payments and calculates remaining balance.

### Relationships

```php
$document->transactions();      // HasMany: Banking\Transaction (all payments)
```

### Methods

```php
$document->totalPaid();         // Sum of all transaction amounts
$document->remainingAmount();   // amount - totalPaid()
$document->isPaid();            // remainingAmount() == 0
$document->isPartiallyPaid();   // totalPaid() > 0 AND totalPaid() < amount
$document->isUnpaid();          // totalPaid() == 0
```

### Payment Status Logic

```php
$document->amount;              // Total document amount
$document->totalPaid();         // Sum of all payments
$document->remainingAmount();   // Still owed

// Status determined by payment state
if ($document->totalPaid() == 0) {
    $status = 'unpaid';
} elseif ($document->totalPaid() < $document->amount) {
    $status = 'partial';
} else {
    $status = 'paid';
}
```

### Querying Payment Status

```php
// All unpaid documents
Document::where(DB::raw('
    amount > COALESCE((
        SELECT SUM(amount) FROM transactions WHERE document_id = documents.id
    ), 0)
'))->get();

// Partially paid
Document::where(DB::raw('
    amount > COALESCE((
        SELECT SUM(amount) FROM transactions WHERE document_id = documents.id
    ), 0)
    AND COALESCE((
        SELECT SUM(amount) FROM transactions WHERE document_id = documents.id
    ), 0) > 0
'))->get();

// Fully paid
Document::where(DB::raw('
    amount <= COALESCE((
        SELECT SUM(amount) FROM transactions WHERE document_id = documents.id
    ), 0)
'))->get();
```

## Combining Traits

All three traits work together:

```php
$document = Document::find($id);

// Get document properties
$document->contact;             // From Documents trait
$document->totals;              // From Documents trait

// Check if recurring
if ($document->isRecurring()) {
    $next_date = $document->nextRecurringDate();  // From Recurring trait
    $document->generateNext();                    // From Recurring trait
}

// Check payment status
$remaining = $document->remainingAmount();       // From Transactions trait
$paid = $document->isPaid();                     // From Transactions trait

// Get all payments
$payments = $document->transactions;             // From Transactions trait
```

## Real-World Examples

### Track invoice payment progress

```php
$invoice = Document::find($id);

// Check status
echo "Total: " . $invoice->amount;
echo "Paid: " . $invoice->totalPaid();
echo "Remaining: " . $invoice->remainingAmount();

if ($invoice->isPaid()) {
    echo "Invoice is fully paid!";
} elseif ($invoice->isPartiallyPaid()) {
    echo "Payment received but not complete";
} else {
    echo "Waiting for payment";
}
```

### Process recurring generation

```php
// In scheduled job or command
$recurring_documents = Document::recurring()
    ->where('recurring_stop_date', '>', now())
    ->get();

foreach ($recurring_documents as $recurring) {
    if ($recurring->shouldGenerateNext()) {
        $recurring->generateNext();
    }
}
```

### Generate payment report

```php
// Unpaid invoices over 30 days
$overdue = Document::invoice()
    ->whereNull('status') // or status = 'unpaid'
    ->where(DB::raw('DATE_ADD(due_at, INTERVAL 30 DAY)'), '<', now())
    ->get();

foreach ($overdue as $document) {
    echo $document->document_number . ": " . $document->remainingAmount();
}
```

## Related Pages

- [Traits Overview](overview.md) – All traits in Akaunting
- [Documents System](../documents/overview.md) – Document data model
- [Banking System](../banking/overview.md) – Transaction relationships

## Source Map

```
app/Traits/
├─ Documents.php     # Document relationships and scopes
├─ Recurring.php     # Recurring schedule logic
└─ Transactions.php  # Payment tracking

app/Models/Document/
├─ Document.php      # Uses all three traits
└─ DocumentItem.php
```

