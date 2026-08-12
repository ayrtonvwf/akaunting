---
type: workflow
title: Invoice Workflow - Complete Lifecycle
description: Step-by-step invoice creation, sending, payment receipt, and reconciliation workflow with all system components.
tags: [invoices, workflow, documents, payments]
---

# Invoice Workflow - Complete Lifecycle

This workflow documents the complete lifecycle of an invoice from creation through payment reconciliation, showing all system components involved.

## 1. Invoice Creation

### User Action: Create Invoice Form

**Route**: `GET {company_id}/sales/invoices/create`

**Controller**: `App\Http\Controllers\Sales\Invoices@create`

**Flow**:
1. Load create form with:
   - Contact autocomplete (AJAX)
   - Item catalog dropdown
   - Tax selector
   - Company context pre-filled
2. Render Blade view with Vue components for:
   - Item line picker
   - Tax calculator
   - Currency display
   - Date pickers

### User Submits Form

**Route**: `POST {company_id}/sales/invoices`

**Controller**: `App\Http\Controllers\Sales\Invoices@store`

**Request Validation**:
- `App\Http\Requests\Document\Document`
- Validates contact_id exists
- Validates dates (issued_at < due_at)
- Validates items (min 1 item, quantity > 0, price > 0)
- Validates amount calculation

### Job Dispatched

**Job**: `App\Jobs\Document\CreateDocument`

**Authorization Checks**:
1. User has `create-sales-invoices` permission
2. Plan allows creating invoices (if SaaS)

**Creating Event Fired**:
```php
event(new DocumentCreating($request));

// Listeners can:
// - Validate business rules
// - Modify request data
// - Abort by throwing exception
```

### Database Transaction

**Within DB::transaction()**:

1. **Create Document**:
   ```php
   Document::create([
       'type' => 'invoice',
       'company_id' => company_id(),
       'contact_id' => $contact_id,
       'document_number' => DocumentNumber::getNextNumber('invoice'),
       'status' => 'draft',
       'issued_at' => now(),
       'due_at' => $due_date,
       'amount' => 0,  // Will be updated after items/taxes calculated
   ]);
   ```

2. **Attach Files** (if any):
   ```php
   foreach ($request->file('attachment') as $file) {
       $media = $this->getMedia($file, 'invoices');
       $document->attachMedia($media, 'attachment');
   }
   ```

3. **Dispatch CreateDocumentItemsAndTotals Job**:
   ```php
   $this->dispatch(new CreateDocumentItemsAndTotals($document, $request));
   ```

   This job:
   - Creates DocumentItem for each item
   - Creates DocumentItemTax for each item's taxes
   - Creates DocumentTotal rows (subtotal, tax, discount, total)
   - Updates document.amount with final total

4. **Update Document** with final request data:
   ```php
   $document->update($request->all());
   ```

5. **Create Recurring** (if recurring):
   ```php
   $document->createRecurring($request->all());
   // Creates Recurring model, sets next_generation_date
   ```

### Created Event Fired

**Event**: `DocumentCreated`

**Listeners**:
1. `CreateDocumentCreatedHistory`: Creates first history entry
   ```php
   DocumentHistory::create([
       'document_id' => $document->id,
       'status' => 'draft',
       'created_by' => auth()->id(),
   ]);
   ```

2. `IncreaseNextDocumentNumber`: Increments sequence
   ```php
   Setting::where('key', 'invoice_number')
       ->increment('value');
   ```

3. `SettingFieldCreated`: Saves any custom fields

### Response to User

```json
{
  "success": true,
  "data": {
    "id": 42,
    "document_number": "INV-001",
    "status": "draft",
    "amount": 1500.00,
    "created_at": "2024-01-15T10:00:00Z"
  },
  "redirect": "{company_id}/sales/invoices/42"
}
```

**UI Updates**:
- Flash message: "Invoice created successfully"
- Redirect to invoice show page

---

## 2. Invoice Management (Draft)

### View Invoice

**Route**: `GET {company_id}/sales/invoices/{id}`

**Controller**: `App\Http\Controllers\Sales\Invoices@show`

**Load Relationships**:
```php
$invoice->load([
    'contact',
    'items.taxes.tax',
    'totals',
    'transactions',
    'histories',
    'media',
    'recurring'
]);
```

**Display**:
- Invoice header (number, date, contact, amount)
- Line items with taxes
- Totals breakdown
- History tab (status changes)
- Attachments
- Transactions (payments)

### Edit Invoice

**Route**: `PATCH {company_id}/sales/invoices/{id}`

**Restrictions**: Only if `status == 'draft'`

**Job**: `App\Jobs\Document\UpdateDocument`

**Event**: `DocumentUpdating` → `DocumentUpdated`

**Listener**: `SettingFieldUpdated` - Updates custom fields

---

## 3. Sending Invoice to Customer

### User Action: Send Invoice

**Route**: `GET {company_id}/sales/invoices/{id}/email`

**Controller**: `App\Http\Controllers\Sales\Invoices@emailInvoice`

**Preconditions**:
- Contact has email address
- Permission: `update-sales-invoices`

### Job Dispatch

**Job**: `App\Jobs\Document\SendDocument`

**Steps**:
1. Fire `DocumentSending` event
2. Generate PDF from template
3. Create email with PDF attachment
4. Send via configured mail service
5. Fire `DocumentSent` event

### Events & Side Effects

**DocumentSent Event** fires listeners:
1. **MarkDocumentSent**:
   ```php
   $document->update(['status' => 'sent', 'sent_at' => now()]);
   ```

2. **UpdateDocumentHistory**:
   ```php
   DocumentHistory::create([
       'document_id' => $document->id,
       'status' => 'sent',
       'created_by' => auth()->id(),
   ]);
   ```

### Email Template

**Template**: Configurable in Settings → Email Templates

**Rendered with**:
- Contact name
- Invoice details
- Line items
- Totals
- Payment instructions
- Signed URL for portal viewing

**PDF Attachment**:
- Generated using DomPDF
- Template styling applied
- Branded with company logo (if set)

---

## 4. Customer Views Invoice (Portal)

### Signed URL

Email contains link:
```
https://app.example.com/signed/invoices/{id}?signature=...
```

**Middleware**: `ValidateSignature` verifies:
- Signature matches URL
- Not expired
- Invoice belongs to company

### Portal View

**Route**: `GET /signed/invoices/{id}`

**Controller**: `App\Http\Controllers\Portal\Invoices@signed`

**Display** (read-only):
- Invoice header
- Line items
- Totals
- Payment button

### Payment Recording

Customer clicks "Pay Now" → redirected to payment processor or bank payment form

After payment:
- Payment received notification sent
- Status updated to "paid" (if fully paid)
- Transaction created in accounting system

**Event**: `PaymentReceived`

---

## 5. Payment Receipt & Recording

### Scenario A: Manual Payment Recording

**User Action**: Create income transaction in Banking section

**Route**: `POST {company_id}/banking/transactions`

**Form**:
- Account: Select account payment received into
- Amount: Payment amount
- Document: Link to invoice (autocomplete)
- Contact: Auto-filled from invoice
- Payment Method: Bank Transfer, Check, Cash, etc.

### Job Dispatch

**Job**: `App\Jobs\Banking\CreateTransaction`

**Event**: `TransactionCreated`

**Listeners**:
1. **LinkDocumentTransaction**:
   ```php
   if ($transaction->document_id) {
       $document = Document::find($transaction->document_id);
       
       // Update paid amount
       $paid = $document->transactions()
           ->sum('amount');
       
       // Update status
       if ($paid >= $document->amount) {
           $document->update(['status' => 'paid']);
       } elseif ($paid > 0) {
           $document->update(['status' => 'partial']);
       }
   }
   ```

2. **Fire PaymentReceived Event**

**PaymentReceived Listeners**:
1. Create transaction
2. Send payment received notification

### Scenario B: API Payment Submission

Customer's payment processor (Stripe, PayPal) posts webhook:

```php
POST /api/webhook/payment
{
  "invoice_id": 42,
  "amount": 1500.00,
  "payment_id": "stripe_....",
  "status": "completed"
}
```

**Handler**:
1. Verify webhook signature
2. Create transaction (API)
3. Link to invoice
4. Fire PaymentReceived event

---

## 6. Status Transitions & History

### Status Flow

```
Created (draft)
    ↓
[Edit/Update] (still draft)
    ↓
Send Email
    ↓
Sent (status: sent)
    ↓
Customer Opens PDF
    ↓
Viewed (status: viewed)
    ↓
Payment Received
    ↓
Paid (status: paid) [if fully paid]
```

Or:
```
Sent
    ↓
Partial Payment
    ↓
Partial (status: partial)
    ↓
More Payments
    ↓
Paid (status: paid)
```

Or:
```
Any Status
    ↓
Past Due Date + Unpaid
    ↓
Overdue (status: overdue) [automatic via scope]
    ↓
Payment Received
    ↓
Paid (status: paid)
```

### History Tracking

Every status change creates entry in `document_histories`:

```php
DocumentHistory::create([
    'document_id' => 42,
    'status' => 'sent',
    'created_by' => auth()->id(),
    'created_at' => now(),
]);
```

**Queryable**:
```php
$invoice->histories;  // All history entries
$invoice->last_history;  // Most recent
```

---

## 7. Reconciliation

### Bank Reconciliation

When bank statement is reconciled, linked transactions are marked:

```php
$transaction->update([
    'reconciliation_id' => $reconciliation->id,
    'reconciled_at' => now(),
]);
```

**Effect**: 
- Transaction confirmed as received
- Bank account balance verified
- Invoice marked as fully reconciled

### Reporting

Invoice appears in:
- **Revenue Report**: Grouped by month, customer, category
- **Aged Receivables**: By status and days overdue
- **Cash Flow Report**: By payment date
- **Custom Reports**: Via Report Builder

---

## 8. Duplicate & Recurring

### Duplicate Invoice

**Route**: `GET {company_id}/sales/invoices/{id}/duplicate`

**Job**: `App\Jobs\Document\DuplicateDocument`

Creates new invoice with:
- Same items and taxes
- New document_number
- New issued_at = today
- Status reset to 'draft'
- Contact preserved

### Recurring Invoice

If original invoice marked as recurring:

**Parent**: Type = 'invoice-recurring'

**Auto-Generation** (daily via `recurring:check`):
1. Query recurring invoices past next_generation_date
2. Clone each to create child invoice
3. Increment next_generation_date
4. Fire DocumentRecurring event
5. Send if configured

**Child**: Type = 'invoice', parent_id = parent recurring id

---

## Cross-System Integration

### Events Across Systems

```
DocumentCreated → Create account entries (financial reporting)
DocumentSent → Send customer notification
PaymentReceived → Create banking transaction, update document status
DocumentPaid → Mark account receivable as settled
DocumentCancelled → Reverse any accounting entries
```

### Multi-Currency

If invoice in currency different from company:
```php
$invoice->currency_code = 'EUR';  // Invoice currency
$invoice->currency_rate = 0.92;   // 1 USD = 0.92 EUR
// Converted to USD for reporting via: amount / rate
```

---

## Testing the Workflow

```php
public function test_complete_invoice_workflow()
{
    // 1. Create
    $response = $this->post(route('invoices.store'), [
        'contact_id' => $contact->id,
        'items' => [['description' => 'Item', 'quantity' => 1, 'price' => 100]],
    ]);
    
    $invoice = Document::whereType('invoice')->latest()->first();
    $this->assertEquals('draft', $invoice->status);
    $this->assertEquals(100, $invoice->amount);
    
    // 2. Send
    $this->post(route('invoices.email', $invoice));
    $this->assertEquals('sent', $invoice->fresh()->status);
    
    // 3. Record Payment
    $this->post(route('transactions.store'), [
        'document_id' => $invoice->id,
        'amount' => 100,
        'account_id' => $account->id,
    ]);
    
    // 4. Verify Status
    $this->assertEquals('paid', $invoice->fresh()->status);
}
```

---

*Reference: /app/Http/Controllers/Sales, /app/Jobs/Document, /app/Models/Document, /routes/admin.php*
