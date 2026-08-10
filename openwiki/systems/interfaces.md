---
type: system-overview
title: Interfaces & Contracts
description: Interface-based polymorphism for jobs, listeners, exports, and utilities to enable extensible behavior.
tags: [interfaces, contracts, design-patterns, polymorphism]
---

# Interfaces & Contracts

Akaunting uses interfaces (contracts) extensively to define behavioral contracts that classes must implement. This enables polymorphic behavior for jobs, listeners, exports, and other components, allowing third-party modules to extend core functionality by implementing the same interfaces.

## Job Interfaces (App\Interfaces\Job)

These interfaces indicate what operations a job performs and what capabilities it has.

### ShouldCreate

```php
interface ShouldCreate { }
```

Indicates job creates new data.

**Used by**: CreateDocument, CreateAccount, CreateTransaction, CreateCompany, CreateContact, etc.

**Checked by**: Job dispatcher to determine if operation requires creation permission.

### ShouldUpdate

```php
interface ShouldUpdate { }
```

Indicates job updates existing data.

**Used by**: UpdateDocument, UpdateAccount, UpdateTransaction, UpdateCompany, etc.

**Checked by**: Controllers and services to filter applicable jobs.

### ShouldDelete

```php
interface ShouldDelete { }
```

Indicates job deletes data.

**Used by**: DeleteDocument, DeleteAccount, DeleteTransaction, DeleteCompany, etc.

### HasOwner

```php
interface HasOwner { }
```

Indicates job has an owning user (created_by field).

**Used by**: Most jobs except system/batch operations.

**Effect**: Job `handle()` method automatically sets `created_by` to auth()->id().

### HasSource

```php
interface HasSource { }
```

Indicates job has a creation source (web form, API, module, import, etc.).

**Used by**: All user-facing jobs.

**Field**: `created_from` – distinguishes API vs. web vs. module vs. import operations.

**Values**: 'web', 'api', 'module-{name}', 'import', etc.

## Listener Interfaces (App\Interfaces\Listener)

### ShouldQueue

```php
// Laravel interface
implements ShouldQueue
```

Indicates listener should be queued (async) rather than executed synchronously.

**Usage**:
```php
class SendDocumentNotification implements ShouldQueue
{
    use Queueable;
    
    public function handle(DocumentSent $event)
    {
        // Executes asynchronously
    }
}
```

### WithoutOverlapping

```php
implements WithoutOverlapping
```

Prevents parallel execution of same listener on same event.

## Export Interfaces (App\Interfaces\Export)

### WithParentSheet

```php
interface WithParentSheet { }
```

Indicates export should organize data hierarchically (parent-child relationships).

**Example**: Invoice export with nested line items per invoice.

**Implementation**: Export class returns nested array structure; Excel writer formats as grouped rows.

## Utility Interfaces

### DocumentNumber

```php
interface DocumentNumber
{
    public function getNextNumber($type, $company_id);
    public function increaseNextNumber($type, $company_id);
}
```

Implemented by: `App\Utilities\DocumentNumber`

Responsible for generating unique document numbers per type per company.

### TransactionNumber

Similar interface for generating transaction numbers.

## Checking Interface Implementation

Jobs and listeners are often checked using `instanceof`:

```php
// In job dispatcher
if ($job instanceof ShouldCreate) {
    // This is a create operation
}

if ($job instanceof HasOwner) {
    // Set created_by automatically
}

// In listener
if ($listener instanceof ShouldQueue) {
    // Queue this listener
}
```

## Module Extension via Interfaces

Modules implement same interfaces as core to extend functionality:

```php
// Module job
namespace Modules\MyModule\Jobs;

use App\Abstracts\Job;
use App\Interfaces\Job\ShouldCreate;
use App\Interfaces\Job\HasOwner;

class CreateCustomDocument extends Job implements ShouldCreate, HasOwner
{
    public function handle()
    {
        // Custom creation logic
    }
}
```

Modules can also implement listeners:

```php
// Module listener
namespace Modules\MyModule\Listeners;

use App\Events\Document\DocumentCreated;

class LogDocumentCreation
{
    public function handle(DocumentCreated $event)
    {
        // Log to external system
    }
}
```

## Interface Hierarchy

```
Job Interfaces
├── ShouldCreate
├── ShouldUpdate
├── ShouldDelete
├── HasOwner
└── HasSource

Listener Interfaces
├── ShouldQueue
└── WithoutOverlapping (Laravel)

Export Interfaces
├── FromQuery
├── FromCollection
├── Exportable
└── WithParentSheet (custom)

Utility Interfaces
├── DocumentNumber
└── TransactionNumber
```

## Using Interfaces in Type Hints

Strong typing with interfaces enables IDE autocomplete and static analysis:

```php
public function dispatch(Job $job)
{
    if ($job instanceof ShouldCreate) {
        $this->authorizeCreate();
    }
    
    if ($job instanceof HasOwner) {
        $job->request['created_by'] = auth()->id();
    }
}

public function handleEvent(Event $event)
{
    // Type hint for IDE support
    if ($event instanceof DocumentCreated) {
        $doc = $event->document;  // IDE knows type
    }
}
```

## Custom Interfaces

Define custom interfaces for domain-specific behaviors:

```php
namespace App\Interfaces\Custom;

interface SendableToContact
{
    public function getSendableAddress();
}

// Implement in multiple classes
class Invoice implements SendableToContact
{
    public function getSendableAddress()
    {
        return $this->contact->email;
    }
}

class Transaction implements SendableToContact
{
    public function getSendableAddress()
    {
        return $this->account->email;
    }
}

// Use polymorphically
foreach ($sendables as $item) {
    if ($item instanceof SendableToContact) {
        Mail::send($item->getSendableAddress());
    }
}
```

## Best Practices

1. **Use Interfaces for Extensibility**: Define interfaces for behaviors that modules should override
2. **Check Before Acting**: Always check interface implementation before assuming capability
3. **Document Expectations**: Include docblock explaining what each interface means
4. **Single Responsibility**: Each interface represents one capability
5. **Compose Interfaces**: Use multiple interfaces for complex behaviors
6. **Type Hint with Interfaces**: Use interface type hints in function signatures

---

*Reference: /app/Interfaces, /app/Abstracts/Job.php*
