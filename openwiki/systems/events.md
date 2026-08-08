---
type: system-overview
title: Event System & Listeners
description: Event-driven architecture, listener registration, audit trails, notifications, and business logic side effects.
tags: [events, listeners, pub-sub, side-effects, audit]
---

# Event System & Listeners

Akaunting uses Laravel events and listeners for event-driven architecture. Events are fired by jobs and models to trigger side effects: audit trail creation, notifications, status updates, and other workflows.

## Event Flow

### Basic Pattern

```
Job/Model Action
        ↓
Event Fired (e.g., DocumentCreated)
        ↓
ServiceProvider Listener Lookup
        ↓
All Registered Listeners Executed (in order)
        ↓
Side Effects (history, notifications, etc.)
```

### Example: Invoice Creation

```
CreateDocument job executes
        ↓
Fire DocumentCreating event (before DB write)
        ↓
Fire DocumentCreated event (after DB write)
        ↓
Listeners execute:
  - CreateDocumentCreatedHistory (create history entry)
  - IncreaseNextDocumentNumber (increment sequence)
  - SettingFieldCreated (save custom fields)
```

---

## Event Registration

### Service Provider

**File**: `App\Providers\Event`

All event→listener mappings defined in `$listen` array:

```php
protected $listen = [
    \App\Events\Document\DocumentCreated::class => [
        \App\Listeners\Document\CreateDocumentCreatedHistory::class,
        \App\Listeners\Document\IncreaseNextDocumentNumber::class,
        \App\Listeners\Document\SettingFieldCreated::class,
    ],
    
    \App\Events\Banking\TransactionCreated::class => [
        \App\Listeners\Banking\LinkDocumentTransaction::class,
    ],
    
    // ... many more event→listener mappings
];
```

### Event Discovery

Events discovered automatically from:
- `$listen` array in EventServiceProvider
- Event attributes on listener classes
- Subscriber classes implementing `Subscriber` interface

---

## Core Events by Domain

### Document Events

```
DocumentCreating        - Before create (can abort)
DocumentCreated         - After create
  ├→ CreateDocumentCreatedHistory
  ├→ IncreaseNextDocumentNumber
  └→ SettingFieldCreated

DocumentUpdating        - Before update
DocumentUpdated         - After update
  └→ SettingFieldUpdated

DocumentDeleting        - Before soft-delete
DocumentDeleted         - After soft-delete

DocumentSending         - Before email send
DocumentSent            - After email sent
  └→ MarkDocumentSent (update status)

DocumentMarkedSent      - Status changed to sent (alternative)
  └→ MarkDocumentSent

DocumentViewed          - Customer opened PDF
  ├→ MarkDocumentViewed
  └→ SendDocumentViewNotification

DocumentCancelled       - Status changed to cancelled
  └→ MarkDocumentCancelled

DocumentRestored        - Restored from cancelled
  └→ RestoreDocument

DocumentRecurring       - Recurring document generated
  └→ SendDocumentRecurringNotification

PaymentReceived         - Payment recorded for document
  ├→ CreateDocumentTransaction (create transaction)
  └→ SendDocumentPaymentNotification
```

### Banking Events

```
TransactionCreating     - Before create
TransactionCreated      - After create
  └→ LinkDocumentTransaction (match to invoice/bill)

TransactionUpdating     - Before update
TransactionUpdated      - After update

TransactionDeleting     - Before delete

TransactionSent         - Email transaction to contact

TransactionSplitting    - Before split
TransactionSplitted     - After split into categories

TransactionRecurring    - Auto-generated from recurring

AccountCreating         - Before account create
AccountCreated          - After account create

AccountUpdating
AccountUpdated
AccountDeleting

TransferCreating        - Before inter-account transfer
TransferCreated         - After transfer created
```

### Common Events

```
CompanyCreating         - Before company create
CompanyCreated          - After company create

CompanyMakingCurrent    - Before company switch
CompanyMadeCurrent      - After company switched
  └→ Initialize company context

ContactCreating
ContactCreated
ContactUpdating
ContactUpdated
ContactDeleting

ItemCreating
ItemCreated
ItemUpdating
ItemUpdated
ItemDeleting

DashboardCreated        - Dashboard created
  └→ CreateDefaultWidgets
```

### Auth Events

```
UserCreating            - Before user create
UserCreated             - After user create
  └→ NotifyUser (send welcome email)

UserUpdating
UserUpdated
UserDeleting

RoleCreating
RoleCreated
RoleUpdating
RoleUpdated
RoleDeleting
```

### Menu Events (for plugin integration)

```
AdminCreating/AdminCreated     - Admin menu building
SettingsCreating/SettingsCreated - Settings menu building
ProfileCreating/ProfileCreated - User profile menu building
PortalCreating/PortalCreated   - Portal menu building
```

### Report Events

```
DataLoading             - Before report data fetch
DataLoaded              - After data loaded
FilterApplying          - Custom filter logic
GroupApplying           - Custom grouping logic
TotalCalculating        - Before total calculation
TotalCalculated         - After calculation
```

---

## Listener Implementation

### Basic Listener

**File**: `App\Listeners\Document\CreateDocumentCreatedHistory`

```php
namespace App\Listeners\Document;

use App\Events\Document\DocumentCreated;
use App\Models\Document\DocumentHistory;

class CreateDocumentCreatedHistory
{
    public function handle(DocumentCreated $event)
    {
        // $event->document is the created document
        // $event->request is the original request
        
        DocumentHistory::create([
            'document_id' => $event->document->id,
            'status' => $event->document->status,
            'created_by' => auth()->id(),
        ]);
    }
}
```

### Conditional Logic

```php
public function handle(TransactionCreated $event)
{
    $transaction = $event->transaction;
    
    // Only link if has document_id
    if (! $transaction->document_id) {
        return;
    }
    
    $document = Document::find($transaction->document_id);
    
    // Update document paid amount
    $document->update([
        'paid_amount' => $transaction->amount,
    ]);
    
    // Fire another event
    event(new PaymentReceived($document, $transaction));
}
```

### Listener Order

Listeners execute in registration order. Important for dependencies:

```php
DocumentCreated::class => [
    CreateDocumentCreatedHistory::class,        // First: history entry
    IncreaseNextDocumentNumber::class,          // Second: increment sequence
    SettingFieldCreated::class,                 // Third: custom fields
],
```

---

## Event Attributes (Newer Pattern)

Events expose public attributes for listeners to access:

```php
class DocumentCreated
{
    public function __construct(
        public Document $document,
        public array $request = [],
    ) {}
}

// Listener accesses:
$event->document
$event->request
```

---

## "Creating" vs. "Created" Events

### Creating Event (Before Operation)

Fired **before** DB write. Listeners can:
- Modify request data
- Validate constraints
- Abort operation by throwing exception

```php
event(new DocumentCreating($this->request));

// Listener can modify:
public function handle(DocumentCreating $event)
{
    if ($event->request['amount'] < 0) {
        throw new \Exception("Amount must be positive");
    }
}
```

### Created Event (After Operation)

Fired **after** successful DB write. Listeners:
- Cannot abort (already saved)
- Create audit trail
- Send notifications
- Trigger side effects

```php
event(new DocumentCreated($this->model, $this->request));

// Listener creates history:
public function handle(DocumentCreated $event)
{
    DocumentHistory::create([
        'document_id' => $event->document->id,
        'status' => $event->document->status,
    ]);
}
```

---

## Listener Features

### Subscribers (Multiple Event Handling)

Listener can handle multiple events:

```php
namespace App\Listeners;

class SettingFieldListener
{
    public function handleCreated(DocumentCreated $event)
    {
        // Handle created
    }
    
    public function handleUpdated(DocumentUpdated $event)
    {
        // Handle updated
    }
    
    public function subscribe($events)
    {
        return [
            DocumentCreated::class => 'handleCreated',
            DocumentUpdated::class => 'handleUpdated',
        ];
    }
}

// Register as subscriber
protected $subscribe = [
    SettingFieldListener::class,
];
```

### Stopping Event Propagation

```php
public function handle($event)
{
    // Do something
    
    // Prevent other listeners from executing
    return false;
}
```

### Async Listeners (Queued)

```php
class SendDocumentNotification implements ShouldQueue
{
    use Queueable;
    
    public function handle(DocumentCreated $event)
    {
        // Executes in queue (async)
        Mail::send(...);
    }
}
```

---

## Common Listener Patterns

### Audit Trail

Create history entry for all state changes:

```php
public function handle(DocumentUpdated $event)
{
    DocumentHistory::create([
        'document_id' => $event->document->id,
        'previous_status' => $event->document->getOriginal('status'),
        'new_status' => $event->document->status,
        'changed_by' => auth()->id(),
    ]);
}
```

### Notification

Send notification on important events:

```php
public function handle(DocumentSent $event)
{
    Notification::send(
        $event->document->contact,
        new DocumentSentNotification($event->document)
    );
}
```

### State Machine

Update status based on event:

```php
public function handle(PaymentReceived $event)
{
    if ($event->document->amount <= $event->transaction->amount) {
        // Fully paid
        $event->document->update(['status' => 'paid']);
    } else {
        // Partially paid
        $event->document->update(['status' => 'partial']);
    }
}
```

### Calculation

Recompute derived values:

```php
public function handle(TransactionUpdated $event)
{
    // Recompute account balance
    $event->transaction->account->computeBalance();
}
```

---

## Testing Events

### Assert Event Fired

```php
use Illuminate\Support\Facades\Event;

public function test_document_created_fires_event()
{
    Event::fake();
    
    $document = Document::factory()->create();
    
    Event::assertDispatched(DocumentCreated::class);
}
```

### Assert Event Payload

```php
public function test_document_created_event_has_document()
{
    Event::fake();
    
    $document = Document::factory()->create();
    
    Event::assertDispatched(DocumentCreated::class, function ($event) {
        return $event->document->id === $document->id;
    });
}
```

### Assert Listener Executed

```php
public function test_document_history_created_on_document_creation()
{
    $document = Document::factory()->create();
    
    $this->assertDatabaseHas('document_histories', [
        'document_id' => $document->id,
    ]);
}
```

---

## Extension via Events

Modules can listen to core events:

```php
// In module's EventServiceProvider
protected $listen = [
    \App\Events\Document\DocumentCreated::class => [
        \Modules\MyModule\Listeners\OnDocumentCreated::class,
    ],
];
```

Module listener responds to core events:

```php
public function handle(DocumentCreated $event)
{
    // Integrate with external system
    ExternalAPI::notify($event->document);
}
```

---

## Best Practices

1. **Clear Event Names**: Use past tense for "created" events (DocumentCreated, not DocumentCreate)
2. **Listener Ordering**: Register listeners in dependency order
3. **Keep Listeners Focused**: One listener, one responsibility
4. **Async Notifications**: Queue email/notification listeners
5. **Test Events**: Verify important events fire
6. **Document Side Effects**: Comment what each listener does
7. **Avoid Loops**: Don't fire event that triggers listener that fires same event

---

## Event List Reference

For comprehensive list of all events, see:
- `app/Events/` – Event definitions
- `app/Providers/Event.php` – Event registration

---

*Reference: /app/Events, /app/Listeners, /app/Providers/Event.php*
