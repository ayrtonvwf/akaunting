---
type: system-overview
title: Jobs & Dispatching System
description: Asynchronous and synchronous job processing for business operations (create/update/delete), job lifecycle, and event coordination.
tags: [jobs, dispatch, async, operations, architecture]
---

# Jobs & Dispatching System

Jobs are dispatchable classes that handle all create, update, and delete operations in Akaunting. Instead of directly manipulating models in controllers, jobs are dispatched. This pattern provides:
- Reusability (same job can be called from web form or API)
- Testability (jobs tested in isolation)
- Event coordination (jobs fire events for listeners)
- Auditability (single place to log operations)
- Async capability (jobs can be queued)

## Core Architecture

### Base Job Class

**File**: `App\Abstracts\Job`

All jobs extend this abstract base.

**Key Attributes**:
```php
public $model;                  // The model being created/updated/deleted
public $request;                // FormRequest or array of data
public $error;                  // Error message if operation fails
public $actions = [];           // List of actions performed
```

**Key Methods**:
```php
public function handle()        // Main logic; return result
public function authorize()     // Check permissions before proceeding
public function fireEvent()     // Dispatch event after success
public function dispatch()      // Sync dispatch (use $this->dispatch() in jobs)
```

### Interfaces (Contracts)

Jobs implement interfaces to indicate capabilities:

```php
interface ShouldCreate { }      // Create operations
interface ShouldUpdate { }      // Update operations
interface ShouldDelete { }      // Delete operations
interface HasOwner { }          // Has created_by user
interface HasSource { }         // Has created_from source (web, api, module)
```

### Job Dispatch

**From Controller**:
```php
// Synchronous (immediately executes)
$invoice = $this->dispatch(new CreateDocument($request));

// Via trait (includes error handling)
$response = $this->ajaxDispatch(new CreateDocument($request));
```

**From Job**:
```php
// Within a job, dispatch another job
$this->dispatch(new CreateDocumentItemsAndTotals($document, $request));
```

**Configuration**:
- **Synchronous** (default): Executes immediately in same request
- **Asynchronous** (configured): Queued in job queue, processed later

---

## Job Categories

### Document Operations (App\Jobs\Document)

Handle invoice, bill, and recurring document lifecycle.

**Create**:
```php
CreateDocument::class
// Validates, creates document, items, totals
// Fires DocumentCreated event
```

**Update**:
```php
UpdateDocument::class
// Updates document fields, recalculates totals
// Fires DocumentUpdated event
```

**Delete**:
```php
DeleteDocument::class
// Soft-deletes document and related data
// Fires DocumentDeleting, DocumentDeleted events
```

**Duplicate**:
```php
DuplicateDocument::class
// Clones document with new number and dates
// Copies items and taxes
```

**Send**:
```php
SendDocument::class
// Generates PDF, sends email to contact
// Fires DocumentSent event
```

**Download**:
```php
DownloadDocument::class
// Generates PDF for download
// Records download in media
```

**Recurring**:
```php
// From DocumentCreating listener
DocumentRecurring::class
// Attached to parent recurring document
// Auto-generated children
```

**Totals Calculation**:
```php
CreateDocumentItemsAndTotals::class
// Created by CreateDocument and UpdateDocument
// Calculates items, taxes, and totals
// Updates document.amount
```

### Banking Operations (App\Jobs\Banking)

Handle accounts, transactions, transfers, reconciliations.

**Accounts**:
```php
CreateAccount::class          // Create bank account
UpdateAccount::class          // Update account details
DeleteAccount::class          // Delete/archive account
```

**Transactions**:
```php
CreateTransaction::class      // Record income/expense
UpdateTransaction::class      // Update transaction
DeleteTransaction::class      // Delete transaction
DuplicateTransaction::class   // Clone transaction
SplitTransaction::class       // Divide among categories
SendTransaction::class        // Email transaction
MatchBankingDocumentTransaction::class  // Link to document
```

**Transfers**:
```php
CreateTransfer::class         // Create inter-account transfer
UpdateTransfer::class         // Update transfer
DeleteTransfer::class         // Delete transfer
```

**Reconciliation**:
```php
CreateReconciliation::class   // Start reconciliation
UpdateReconciliation::class   // Update reconciliation state
DeleteReconciliation::class   // Cancel reconciliation
```

### Common Operations (App\Jobs\Common)

Handle shared entities: companies, contacts, items, dashboards, reports.

**Companies**:
```php
CreateCompany::class          // Create company (tenant)
UpdateCompany::class          // Update company
DeleteCompany::class          // Delete company
```

**Contacts**:
```php
CreateContact::class          // Create customer/vendor
UpdateContact::class          // Update contact
DeleteContact::class          // Delete contact
DuplicateContact::class       // Clone contact
```

**Items**:
```php
CreateItem::class             // Create product/service
UpdateItem::class             // Update item
DeleteItem::class             // Delete item
CreateItemTaxes::class        // Set item's taxes
```

**Dashboards & Widgets**:
```php
CreateDashboard::class        // Create custom dashboard
CreateWidget::class           // Add widget to dashboard
UpdateWidget::class           // Update widget
DeleteWidget::class           // Remove widget
```

**Reports**:
```php
CreateReport::class           // Save report definition
UpdateReport::class           // Update report filters
DeleteReport::class           // Delete report
```

### Auth Operations (App\Jobs\Auth)

Handle user management, roles, permissions.

**Users**:
```php
CreateUser::class             // Create user
UpdateUser::class             // Update user
DeleteUser::class             // Soft-delete user
NotifyUser::class             // Send notification
```

**Roles & Permissions**:
```php
CreateRole::class             // Create role
UpdateRole::class             // Update role
DeleteRole::class             // Delete role
CreatePermission::class       // Create permission
UpdatePermission::class       // Update permission
DeletePermission::class       // Delete permission
```

### Settings Operations (App\Jobs\Setting)

Handle configuration entities.

```php
CreateCurrency::class         // Define currency
UpdateCurrency::class         // Update currency
DeleteCurrency::class         // Delete currency
CreateTax::class              // Create tax rule
UpdateTax::class              // Update tax
DeleteTax::class              // Delete tax
CreateCategory::class         // Create category
UpdateCategory::class         // Update category
DeleteCategory::class         // Delete category
```

---

## Job Lifecycle

### 1. Instantiation

Controller creates job with request/data:

```php
$job = new CreateDocument($request);
```

Constructor stores request and validates it exists.

### 2. Dispatch

Controller dispatches job:

```php
$document = $this->dispatch($job);
// or
$document = $this->ajaxDispatch($job);  // With error handling
```

Dispatches either synchronously (immediately) or asynchronously (queued).

### 3. Authorization

Job's `authorize()` method checks:
- User has permission to perform action
- Plan limits not exceeded
- Data constraints met

Throws exception if unauthorized.

```php
public function authorize(): void
{
    // Example: Check plan limit
    $limit = $this->getAnyActionLimitOfPlan();
    if (! $limit->action_status && $this->request['type'] == 'invoice') {
        throw new \Exception($limit->message);
    }
}
```

### 4. Event: *Creating

Job fires "creating" event before operation:

```php
event(new DocumentCreating($this->request));
```

Listeners can modify request or abort.

### 5. Operation

Job's `handle()` method performs operation:

```php
public function handle(): Document
{
    \DB::transaction(function () {
        $this->model = Document::create($this->request->all());
        // ... additional logic
        $this->dispatch(new CreateDocumentItemsAndTotals(...));
    });
    
    return $this->model;
}
```

**Transaction**: Wrapped in DB transaction; all-or-nothing.

**Dispatch Child Jobs**: Can dispatch other jobs within transaction.

### 6. Event: *Created

Job fires "created" event after success:

```php
event(new DocumentCreated($this->model, $this->request));
```

Listeners create audit history, send notifications, etc.

### 7. Return

Job returns created/updated/deleted model:

```php
return $this->model;  // Document, Transaction, etc.
```

### 8. Response

Controller uses job result to build response:

```php
if ($response['success']) {
    return response()->json([
        'success' => true,
        'data' => new DocumentResource($document)
    ]);
} else {
    return response()->json([
        'success' => false,
        'message' => $response['message']
    ], 422);
}
```

---

## Synchronous vs. Asynchronous

### Synchronous (Default)

Jobs execute immediately in same request.

**Pros**:
- Immediate feedback
- Easier debugging
- No queue setup required

**Cons**:
- Slow for heavy operations
- Blocks user while processing
- Fails if process is long

**Configuration**:
```php
// QUEUE_CONNECTION=sync (default for development)
```

### Asynchronous

Jobs queued for background processing.

**Setup**:
```php
// .env
QUEUE_CONNECTION=database  // or redis, sqs, etc.
```

**Schedule**:
```php
// In scheduler or via queue worker
php artisan queue:work
```

**Job Queueing**:
```php
$job = new CreateDocument($request);
$job->delay(5);  // Delay 5 minutes
dispatch($job);
```

**Pros**:
- Fast response to user
- Can process in background
- Retry on failure

**Cons**:
- Requires queue worker running
- Harder to debug
- Delayed feedback

---

## Error Handling

### Authorization Failure

```php
// In authorize()
throw new \Exception("You don't have permission");
// Returns 403 Forbidden
```

### Validation Failure

```php
// FormRequest validation
protected function failedValidation($validator)
{
    throw new \Illuminate\Validation\ValidationException($validator);
    // Returns 422 Unprocessable Entity
}
```

### Business Logic Failure

```php
// In handle()
if (condition_not_met) {
    throw new \Exception("Cannot complete operation: ...");
    // Returns 400 Bad Request or 422
}
```

### ajaxDispatch Error Handling

```php
protected function ajaxDispatch($job): array
{
    try {
        $this->dispatch($job);
        return [
            'success' => true,
            'data' => $this->model,
        ];
    } catch (\Exception $e) {
        return [
            'success' => false,
            'message' => $e->getMessage(),
        ];
    }
}
```

---

## Testing Jobs

### Unit Testing Jobs

```php
use App\Jobs\Document\CreateDocument;

public function test_create_document_requires_contact()
{
    $request = new DocumentRequest([
        // Missing contact_id
    ]);
    
    $this->expectException(ValidationException::class);
    
    dispatch(new CreateDocument($request));
}

public function test_create_document_creates_items_and_totals()
{
    $request = new DocumentRequest([
        'contact_id' => $contact->id,
        'items' => [
            ['description' => 'Item 1', 'quantity' => 1, 'price' => 100],
        ],
    ]);
    
    $document = dispatch(new CreateDocument($request));
    
    $this->assertCount(1, $document->items);
    $this->assertEquals(100, $document->amount);
}
```

### Feature Testing Jobs

```php
public function test_api_create_document_dispatches_job()
{
    Bus::fake();
    
    $response = $this->postJson(route('api.documents.store'), [
        'contact_id' => $contact->id,
        // ...
    ]);
    
    Bus::assertDispatched(CreateDocument::class);
    $response->assertCreated();
}
```

---

## Best Practices

1. **Separate Concerns**: Each job handles one operation (create, update, or delete)
2. **Transactions**: Wrap operations in DB::transaction()
3. **Fire Events**: Always fire creating/created events for listeners
4. **Dispatch Child Jobs**: Complex operations can dispatch other jobs
5. **Test Jobs**: Unit test jobs with various inputs
6. **Document Side Effects**: List what events/listeners fire in job docblock
7. **Error Messages**: Provide clear, actionable error messages
8. **Idempotency**: If possible, make jobs safe to retry

---

*Reference: /app/Abstracts/Job, /app/Jobs, /app/Traits/Jobs*
