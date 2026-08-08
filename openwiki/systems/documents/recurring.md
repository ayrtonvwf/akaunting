---
type: system-domain
title: Recurring Documents
description: Auto-generation schedules, lifecycle, and management of recurring invoices and bills in Akaunting.
tags: [recurring, documents, invoices, bills, automation]
---

# Recurring Documents

Recurring documents are automatically generated on a schedule. They allow businesses to create repeating invoices (subscriptions, retainers) and bills (recurring vendor charges) without manual intervention.

## Core Model: Recurring

**File**: `App\Models\Common\Recurring`
**Table**: `recurring`

The `Recurring` model stores scheduling configuration using a **polymorphic relationship** to both `Document` and `Transaction` records.

### Attributes

```
id, company_id, recurable_id, recurable_type,
frequency, interval, started_at, status, 
limit_by, limit_count, limit_date, auto_send,
created_from, created_by, created_at, updated_at, deleted_at
```

### Key Fields

- **recurable_id, recurable_type**: Morphic relationship to Document or Transaction
- **frequency**: `daily`, `weekly`, `bi-weekly`, `monthly`, `quarterly`, `semi-annually`, `annually`
- **interval**: Multiplier; e.g., frequency=`monthly` + interval=`2` = every 2 months
- **started_at**: First generation date
- **status**: `active`, `ended`, `completed`
- **limit_by**: How to stop generation: `count` (number of times), `date` (end date), or null (infinite)
- **limit_count**: Maximum number of generations (if limit_by='count')
- **limit_date**: Stop generation after this date (if limit_by='date')
- **auto_send**: Whether to automatically send documents after generation (invoices only)

## Document Types

Recurring documents are stored as `Document` with specific types:

| Type | Meaning |
|------|---------|
| **invoice-recurring** | Parent recurring template for sales invoices |
| **bill-recurring** | Parent recurring template for purchase bills |

### Generating Child Documents

When a recurring document generates, a new child `Document` is created with type `invoice` or `bill`.

**Relationship**:
```php
$recurringTemplate->documents();     // All child documents
$recurringTemplate->invoices();      // Child invoices only
$recurringTemplate->bills();         // Child bills only
```

**Reverse relationship**:
```php
$childInvoice->recurring;            // BelongsTo: Parent recurring
```

## Scheduling Logic

### Generation Frequency

The system determines when the next document should be generated based on:

1. **last_generated_at** (implicit): Derived from most recent child document
2. **frequency + interval**: e.g., monthly, every 2 weeks
3. **started_at**: First generation date
4. **limit_by + limit_count/limit_date**: Stop condition

### Generation Window

Documents are typically generated:

- **Automatically** via scheduled command: `php artisan document:recurring-generate`
- **On-demand** via admin action: Manual trigger to generate immediately

The system checks daily (via scheduled job) and generates any overdue recurring documents.

### Prevent Duplicate Generation

The system tracks generation using child document dates. If a recurring invoice is set to monthly:

- First generation: 2024-01-01
- Second generation: 2024-02-01
- Etc.

The system will not generate duplicates if called multiple times for same period.

## Stop Conditions

Recurring documents stop generation when:

1. **limit_by = 'count'**: Generated exactly `limit_count` times
2. **limit_by = 'date'**: Today's date >= `limit_date`
3. **status = 'ended'**: Manually ended
4. **status = 'completed'**: Automatically marked when limit reached

## Auto-Send Feature

For recurring invoices, the `auto_send` flag controls whether generated invoices are automatically sent:

```php
$recurringInvoice->auto_send = true;  // Auto-send each generated invoice
$recurringInvoice->save();
```

If enabled, the job that generates the invoice also dispatches `SendDocument`.

## Creating a Recurring Invoice

### Via Web Interface

1. Navigate to Sales > Invoices > New
2. Fill in invoice details (customer, items, amounts)
3. Check "Create as recurring"
4. Set frequency (monthly), interval (1), start date
5. Choose limit: count (12 times) or date (end date)
6. Optionally enable auto-send
7. Submit

### Via API

```json
POST /api/invoices

{
  "document_number": "RECURRING-001",
  "type": "invoice-recurring",
  "contact_id": 1,
  "issued_at": "2024-01-15",
  "due_at": "2024-02-15",
  "items": [...],
  "recurring": {
    "frequency": "monthly",
    "interval": 1,
    "started_at": "2024-01-15",
    "limit_by": "count",
    "limit_count": 12,
    "auto_send": true
  }
}
```

### Via Job

```php
$recurring = $this->dispatch(new CreateDocument(
    auth()->user(),
    [
        'type' => 'invoice-recurring',
        'document_number' => 'REC-001',
        'contact_id' => 1,
        'items' => [...],
        'recurring' => [
            'frequency' => 'monthly',
            'interval' => 1,
            'started_at' => now(),
            'limit_by' => 'count',
            'limit_count' => 12,
        ]
    ],
    $company
));
```

## Child Document Generation

When a recurring document generates a child:

1. **Clone parent**: Copy all fields (items, totals, contact info)
2. **Set type**: Change `invoice-recurring` → `invoice`
3. **New number**: Generate fresh document number (e.g., INV-002)
4. **Update dates**: issued_at and due_at incremented by frequency
5. **Fire event**: `DocumentCreated` event fired
6. **Auto-send** (optional): Send email if enabled
7. **Track parent**: `parent_id` set to recurring document ID

**Example**:
```
Recurring: type=invoice-recurring, issued_at=2024-01-15
  └─ Child 1: type=invoice, issued_at=2024-01-15, document_number=INV-001
  └─ Child 2: type=invoice, issued_at=2024-02-15, document_number=INV-002
  └─ Child 3: type=invoice, issued_at=2024-03-15, document_number=INV-003
```

## Management

### View Recurring Invoices

```
Sales > Recurring Invoices
```

Lists all recurring invoice templates with their status, frequency, and count of generated children.

### Edit Recurring Schedule

Edit frequency, interval, limit, or auto-send setting. Changes apply to future generations only (past children unchanged).

### Manual Generation

Trigger immediate generation of next child document:

```
Action > Generate Now
```

### End Recurring

Stop further generations:

```
Action > End
```

Changes status to `ended`; existing children remain.

### Delete Recurring

Soft delete stops generation. Child documents remain accessible.

## Transactions

Recurring transactions work similarly but for banking entries:

**Types**:
- **income-recurring**: Automatically generates income transactions
- **expense-recurring**: Automatically generates expense transactions

**Common use case**: Recurring salary payouts, regular vendor expenses

**Scheduling**: Same frequency options as documents

## Jobs & Events

### Generation Job

**File**: `app/Jobs/Document/CreateDocument` and related jobs

Dispatched daily by scheduler to generate overdue recurring documents.

### Events

- `DocumentCreating` – Before generation
- `DocumentCreated` – After generation, fires listeners for notifications, history

### Listeners

- `CreateDocumentHistory` – Record generation in history
- Document-specific listeners (emails, etc.)

## CLI Command

**Generate all overdue recurring documents**:

```bash
php artisan document:recurring-generate
```

Typically runs daily via Laravel scheduler.

## Source Map

| Concept | File |
|---------|------|
| Recurring model | `app/Models/Common/Recurring.php` |
| Recurring trait | `app/Traits/Recurring.php` |
| Document recurring relation | `app/Traits/Documents.php` |
| Create job | `app/Jobs/Document/CreateDocument.php` |
| Generation command | `app/Console/Commands/RecurringCheck.php` |
| Scheduler config | `app/Console/Kernel.php` |

## Common Workflows

### Create Monthly Subscription Invoice

```php
// Represent a customer's monthly retainer
$invoice = new Document([
    'type' => 'invoice-recurring',
    'contact_id' => $customer->id,
    'amount' => 1000.00,
    'issued_at' => now(),
    'due_at' => now()->addDays(30),
]);

$recurring = new Recurring([
    'frequency' => 'monthly',
    'interval' => 1,
    'started_at' => now(),
    'limit_by' => 'date',
    'limit_date' => now()->addYear(),
    'auto_send' => true,
]);

$invoice->recurring()->save($recurring);
```

### Stop Subscription

```php
$recurring->update(['status' => 'ended']);
// Next generation will not occur
```

### Change Frequency

```php
$recurring->update([
    'frequency' => 'quarterly',  // Changed from monthly
    'interval' => 1,
]);
// Affects next generation onward
```

## Testing

**Feature tests**: `/tests/Feature/Documents/Recurring.php`

Key test cases:
- Create recurring invoice with frequency and count limit
- Generate child documents on schedule
- Stop generation when limit reached
- Auto-send feature
- Manual generation
- Edit recurring template

---

## Related Pages

- [Invoices](invoices.md) – Parent invoice document type
- [Bills](bills.md) – Parent bill document type
- [Banking Transactions](../banking/recurring.md) – Recurring transactions
- [Events & Listeners](../events.md) – Document lifecycle events
