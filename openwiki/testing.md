---
type: system-overview
title: Testing Infrastructure
description: Test structure, patterns, framework setup, and validation strategies for Akaunting.
tags: [testing, phpunit, feature-tests, unit-tests]
---

# Testing Infrastructure

Akaunting uses PHPUnit for both feature and unit testing, with a Laravel-focused test structure. This guide explains the test setup, common patterns, and how to write new tests.

## Test Setup & Configuration

### PHPUnit Configuration

File: `phpunit.xml`

**Key Settings**:
```xml
<phpunit bootstrap="bootstrap/autoload.php" colors="true">
    <testsuites>
        <testsuite name="Unit">
            <directory suffix="Test.php">./tests/Unit</directory>
            <directory suffix="Test.php">./modules/**/Tests/Unit</directory>
        </testsuite>
        <testsuite name="Feature">
            <directory suffix="Test.php">./tests/Feature</directory>
            <directory suffix="Test.php">./modules/**/Tests/Feature</directory>
        </testsuite>
    </testsuites>
    <php>
        <server name="DB_CONNECTION" value="sqlite"/>
        <server name="DB_DATABASE" value=":memory:"/>
        <server name="QUEUE_CONNECTION" value="sync"/>
        <server name="MAIL_MAILER" value="array"/>
    </php>
</phpunit>
```

**Database**: SQLite in-memory for speed; migrations run fresh each test
**Queue**: Sync driver (processes jobs immediately)
**Mail**: Array driver (captures emails in memory)

### Running Tests

```bash
# All tests
php artisan test

# Feature tests only
php artisan test tests/Feature

# Unit tests only
php artisan test tests/Unit

# Specific test class
php artisan test tests/Feature/PaymentTestCase

# With output/verbose
php artisan test --verbose

# Parallel (used in CI)
php artisan test --parallel

# Watch mode (requires package)
php artisan test --watch
```

---

## Test Structure

### Directory Layout

```
tests/
├── Feature/
│   ├── FeatureTestCase.php              # Base class for feature tests
│   ├── PaymentTestCase.php              # Payment-specific test utilities
│   ├── Auth/UsersTest.php
│   ├── Banking/
│   │   ├── AccountsTest.php
│   │   ├── DocumentTransactionsTest.php
│   │   ├── ReconciliationsTest.php
│   │   ├── SplitTransactionTest.php
│   │   ├── TransactionTaxesTest.php
│   │   ├── TransactionsTest.php
│   │   └── TransfersTest.php
│   ├── Commands/
│   │   ├── BillReminderTest.php
│   │   ├── InvoiceReminderTest.php
│   │   └── RecurringCheckTest.php
│   ├── Common/
│   │   ├── CompaniesTest.php
│   │   ├── DashboardsTest.php
│   │   ├── ItemsTest.php
│   │   ├── ReportsTest.php
│   │   └── SourcesTest.php
│   ├── Document/CancelDocumentTest.php
│   ├── Email/TooManyEmailsSentTest.php
│   ├── Parallel/CompiledViewIsolationTest.php
│   ├── Performance/
│   │   ├── N1QueryOptimizationTest.php
│   │   └── VendorN1QueryTest.php
│   ├── Purchases/
│   │   ├── BillsTest.php
│   │   └── VendorsTest.php
│   ├── Sales/
│   │   ├── CustomersTest.php
│   │   └── InvoicesTest.php
│   ├── Settings/
│   │   ├── CategoriesTest.php
│   │   ├── CurrenciesTest.php
│   │   └── TaxesTest.php
│   └── Wizard/
│       ├── CompaniesTest.php
│       └── CurrenciesTest.php
└── Unit/
    ├── ExampleTest.php
    ├── UpdatesTest.php
    ├── Imports/Banking/TransfersImportTest.php
    ├── ParallelIsolationTest.php
    └── Utilities/
        ├── CalculationToQuantityTest.php
        └── DateImportParsingTest.php

modules/*/Tests/
├── Feature/                      # Module feature tests
└── Unit/                          # Module unit tests
```

36 `*Test.php` files across 12 `tests/Feature/` subdirectories (Auth, Banking, Commands, Common, Document, Email, Parallel, Performance, Purchases, Sales, Settings, Wizard), plus `tests/Feature/FeatureTestCase.php` and `tests/Feature/PaymentTestCase.php` as base test-case classes (not test files themselves).

### Base Test Classes

#### FeatureTestCase (tests/Feature/FeatureTestCase.php)

Base class for all feature tests.

**Setup**:
```php
protected function setUp(): void
{
    parent::setUp();
    
    $this->withoutExceptionHandling();  // Fail on exceptions
    
    $this->faker = Faker::create();
    $this->user = user_model_class()::first();  // Gets seeded user
    $this->company = $this->user->companies()->first();  // Gets seeded company
    
    config(['debugbar.enabled', false]);  // Disable for tests
}
```

**Key Methods**:
- `$this->loginAs($user, $company)`: Authenticate as user in company context
- `$this->assertFlashLevel($expected)`: Check flash message level

**Example**:
```php
public function test_user_can_create_invoice()
{
    $this->loginAs();
    
    $response = $this->post(route('invoices.store'), [
        'contact_id' => $this->faker->randomNumber(),
        'amount' => 1000.00,
        // ...
    ]);
    
    $this->assertDatabaseHas('documents', [
        'type' => 'invoice',
        'company_id' => company_id(),
    ]);
}
```

#### PaymentTestCase

Specialized base for payment and transaction testing.

---

## Common Test Patterns

### Factory-Based Setup

```php
use Database\Factories\Document as DocumentFactory;

public function test_invoice_can_be_duplicated()
{
    $invoice = Document::factory()
        ->for($this->company)
        ->invoice()
        ->create();
    
    $this->loginAs();
    
    $response = $this->post(route('invoices.duplicate', $invoice));
}
```

**Factories** defined in `database/factories/` for:
- Document (invoice/bill)
- Transaction (income/expense)
- Contact
- Account
- User
- Company

### Job Dispatch Testing

```php
use Illuminate\Support\Facades\Bus;

public function test_create_invoice_dispatches_document_items_job()
{
    Bus::fake();
    
    $response = $this->dispatch(new CreateDocument($request));
    
    Bus::assertDispatched(CreateDocumentItemsAndTotals::class);
}
```

**Job Testing**:
- Mock job execution with `Bus::fake()`
- Assert jobs dispatched: `Bus::assertDispatched(JobClass::class)`
- Assert job properties: `Bus::assertDispatched(JobClass::class, function ($job) { ... })`

### Event Testing

```php
use Illuminate\Support\Facades\Event;

public function test_document_created_event_fires()
{
    Event::fake();
    
    $invoice = Document::factory()->invoice()->create();
    
    Event::assertDispatched(DocumentCreated::class, function ($event) {
        return $event->document->id === $invoice->id;
    });
}
```

### Database Assertions

```php
public function test_invoice_created_in_correct_company()
{
    $this->loginAs();
    
    $this->post(route('invoices.store'), $invoiceData);
    
    $this->assertDatabaseHas('documents', [
        'type' => 'invoice',
        'company_id' => company_id(),
        'document_number' => 'INV-001',
    ]);
}
```

### HTTP Assertions

```php
public function test_unauthorized_user_cannot_access_invoice()
{
    $invoice = Document::factory()->for($this->company)->invoice()->create();
    $other_user = User::factory()->create();
    $other_company = Company::factory()->create();
    $other_user->companies()->attach($other_company);
    
    $response = $this->actingAs($other_user)
        ->get(route('invoices.show', $invoice));
    
    $response->assertForbidden();
}
```

---

## Test Categories

### Feature Tests (tests/Feature)

Test complete user workflows through HTTP requests.

**Characteristics**:
- Make HTTP requests via `$this->get()`, `$this->post()`, etc.
- Authenticate users with `$this->actingAs()`
- Assert database state changes
- Verify HTTP response codes and redirects

**Example Scenarios**:
- User creates invoice and receives PDF download
- Customer views invoice in portal
- Payment recorded, invoice marked paid
- Invoice sent via email

### Unit Tests (tests/Unit)

Test isolated components in isolation.

**Characteristics**:
- No HTTP requests
- No database transactions (in-memory)
- Focus on class logic, calculations
- Mock external dependencies

**Example Scenarios**:
- Document total calculation (items + taxes + discount)
- Currency conversion
- Date formatting
- Permission evaluation

### Module Tests (modules/*/Tests)

Each module has its own test suite following same patterns.

Example: `modules/OfflinePayments/Tests/Feature/PaymentTest.php`

---

## Writing Effective Tests

### Naming Convention

```php
class InvoiceTest extends FeatureTestCase
{
    // Describe the behavior being tested
    public function test_user_can_create_invoice_with_multiple_items()
    public function test_draft_invoice_cannot_be_paid()
    public function test_document_number_increments_on_creation()
    public function test_tax_calculation_includes_compound_taxes()
}
```

**Pattern**: `test_{scenario}_{expected_result}`

### Arrange-Act-Assert

```php
public function test_invoice_status_changes_to_sent_when_emailed()
{
    // Arrange: Create test data
    $invoice = Document::factory()->invoice()->create([
        'status' => 'draft',
        'contact_email' => 'test@example.com',
    ]);
    $this->loginAs();
    
    // Act: Perform action
    $response = $this->post(route('invoices.email', $invoice));
    
    // Assert: Verify results
    $response->assertRedirect();
    $this->assertFlashLevel('success');
    $this->assertDatabaseHas('documents', [
        'id' => $invoice->id,
        'status' => 'sent',
    ]);
}
```

### Testing Calculations

```php
public function test_document_total_includes_all_items_and_taxes()
{
    // Create invoice with known amounts
    $invoice = Document::factory()
        ->has(DocumentItem::factory()
            ->count(2)
            ->sequence(
                ['amount' => 100.00],
                ['amount' => 50.00],
            )
        )
        ->create();
    
    // Refresh with relationships
    $invoice->load('items', 'totals');
    
    // Verify total calculation
    $this->assertEquals(150.00, $invoice->amount);
}
```

### Testing Authorization

```php
public function test_user_cannot_delete_company_they_dont_own()
{
    $other_company = Company::factory()->create();
    $this->loginAs(); // In first company only
    
    $response = $this->delete(
        route('companies.destroy', $other_company)
    );
    
    $response->assertForbidden();
    $this->assertModelExists($other_company);
}
```

### Testing API Endpoints

```php
public function test_api_returns_invoices_in_company_context()
{
    $invoice = Document::factory()->for($this->company)->invoice()->create();
    
    $response = $this->getJson(route('api.documents.index'));
    
    $response->assertJsonCount(1, 'data');
    $response->assertJsonPath('data.0.id', $invoice->id);
}
```

---

## Fixtures & Seeding

### Test Data Seeding

Database seeders run before feature tests to populate baseline data.

**Primary Seeder**: `database/seeds/DatabaseSeeder.php`

**Seeded Data**:
- Default user with company
- Default currencies
- Default taxes
- Default categories
- Default email templates

**Usage in Tests**:
```php
// After setUp(), you have:
$this->user       // Seeded user
$this->company    // Seeded company
$this->faker      // Faker instance for random data
```

### Factories

Custom factories for all major models.

**Example Usage**:
```php
// Create single document
$invoice = Document::factory()->invoice()->create();

// Create with relationships
$invoice = Document::factory()
    ->has(DocumentItem::factory()->count(3))
    ->for($this->company)
    ->create();

// Create multiple
$invoices = Document::factory()->count(5)->invoice()->create();

// Create with specific attributes
$invoice = Document::factory()->invoice()->create([
    'status' => 'paid',
    'amount' => 5000.00,
]);
```

**Available Factories**:
- DocumentFactory (with states: invoice, bill, recurring)
- TransactionFactory (with states: income, expense, transfer)
- ContactFactory
- AccountFactory
- ItemFactory
- CompanyFactory
- UserFactory

---

## Mocking & Stubbing

### Mocking Mail

```php
use Illuminate\Support\Facades\Mail;

public function test_invoice_email_sent_with_pdf_attachment()
{
    Mail::fake();
    
    $invoice = Document::factory()->invoice()->create();
    $this->dispatch(new SendDocument($invoice));
    
    Mail::assertSent(InvoiceMail::class, function ($mail) use ($invoice) {
        return $mail->hasTo($invoice->contact->email) &&
               $mail->hasAttachment('invoice.pdf');
    });
}
```

### Mocking Queue

```php
use Illuminate\Support\Facades\Queue;

public function test_large_export_queued_for_processing()
{
    Queue::fake();
    
    $this->post(route('documents.export'), [
        'count' => 1000,
    ]);
    
    Queue::assertPushed(ExportDocuments::class);
}
```

---

## Assertion Reference

### Database Assertions

```php
$this->assertDatabaseHas('documents', ['status' => 'paid']);
$this->assertDatabaseMissing('documents', ['type' => 'draft']);
$this->assertDatabaseCount('documents', 5);
$this->assertModelExists($invoice);
$this->assertModelMissing($deletedInvoice);
```

### HTTP Assertions

```php
$response->assertStatus(200);
$response->assertOk();
$response->assertCreated();
$response->assertRedirect(route('invoices.show', $invoice));
$response->assertViewIs('sales.invoices.show');
$response->assertViewHas('invoice', $invoice);
$response->assertJsonPath('data.status', 'paid');
$response->assertJsonCount(10, 'data');
```

### Exception Assertions

```php
$this->expectException(ValidationException::class);
$this->expectExceptionMessage('Amount must be positive');

CreateDocument::dispatch($invalidRequest);
```

---

## Performance Testing

### Query Counting

```php
use Illuminate\Support\Facades\DB;

public function test_invoice_list_uses_optimal_queries()
{
    Document::factory()->count(10)->create();
    
    DB::enableQueryLog();
    
    $invoices = Document::invoice()->with([
        'contact', 'items', 'items.taxes', 'totals'
    ])->get();
    
    // Should be ~4 queries (documents, contacts, items, taxes)
    $this->assertLessThan(5, count(DB::getQueryLog()));
}
```

---

## Debugging Tests

### Dump & Stop

```php
public function test_something()
{
    $invoice = Document::factory()->create();
    
    dump($invoice);        // Print to console
    $this->dump();        // Print test context
}
```

### Test Database Inspection

```php
public function test_debug_invoice_state()
{
    $invoice = Document::factory()->create();
    
    // View in test output
    dd(DB::table('documents')->get());
}
```

---

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "UNIQUE constraint failed" | Clear test database between tests; ensure factories use unique attributes |
| "No query results" | Check company_id scoping; add `->allCompanies()` if needed |
| "Mail not sent in test" | Use `Mail::fake()` before making request; check mail driver in phpunit.xml |
| "Job not executed" | Use `Queue::fake()` or ensure queue driver is `sync` in phpunit.xml |
| "Transaction rolled back" | Feature tests auto-rollback; factory state may not persist |

---

## Best Practices

1. **One Assertion Per Test**: Each test verifies one behavior
2. **Clear Naming**: Test name should explain what is being tested
3. **Setup in Factory**: Use factories and scopes rather than creating raw data
4. **Avoid Test Data Leaks**: Ensure tests are isolated; use tearDown to clean
5. **Test Integration Points**: Feature tests verify HTTP→Job→Database flow
6. **Mock External Services**: Don't hit real APIs; use Http::fake()
7. **Use Database Transactions**: Tests use transactions; ensure they rollback
8. **Verify Both Success & Failure**: Test happy path and error cases

---

## Continuous Integration

Tests run automatically on:
- Pull requests (via GitHub Actions)
- Commits to main branch
- Scheduled nightly runs

**Configuration**: `.github/workflows/tests.yml`

**CI Commands**:
```bash
composer install
php artisan migrate
php artisan test --parallel
```

phpunit.xml has no `<coverage>` element configured, so no coverage report is generated by CI.

---

*Reference: /tests/, /phpunit.xml, /database/factories/*
