---
type: system-domain
title: Recurring Transactions
description: Auto-generated recurring income and expense transactions, scheduling, and lifecycle management.
tags: [banking, recurring, transactions, automation]
---

# Recurring Transactions

Recurring transactions are automatically generated income or expense entries on a schedule. They complement recurring documents for businesses with regular, predictable cash flows like salaries, subscriptions, and utilities.

## Core Model

Recurring transactions use the shared `Recurring` model:

**File**: `App\Models\Common\Recurring`

**Types**:
- **income-recurring**: Auto-generated income transactions
- **expense-recurring**: Auto-generated expense transactions

For details on the Recurring model and scheduling, see [Recurring Documents](../documents/recurring.md).

## Transaction Generation

When a recurring transaction generates, a new child `Transaction` record is created:

```
Recurring Record: type=income-recurring
  └─ Child 1: type=income, paid_at=2024-01-15
  └─ Child 2: type=income, paid_at=2024-02-15
  └─ Child 3: type=income, paid_at=2024-03-15
```

**Process**:
1. System checks daily for overdue recurring transactions
2. For each, generates new child transaction
3. Updates totals and categories
4. Fires `TransactionCreated` event

## Creating Recurring Income

**Example**: Monthly service fee income

```php
$recurring = new Recurring([
    'recurable_type' => 'App\Models\Banking\Transaction',
    'recurable_id' => $transaction->id,  // Template transaction
    'frequency' => 'monthly',
    'interval' => 1,
    'started_at' => '2024-01-15',
    'status' => 'active',
    'limit_by' => 'count',
    'limit_count' => 12,  // 12 months
]);

$recurring->save();
```

Or via job during transaction creation:

```php
$transaction = $this->dispatch(new CreateTransaction(
    auth()->user(),
    [
        'type' => 'income-recurring',
        'account_id' => 1,
        'amount' => 500.00,
        'category_id' => $service_fee_category->id,
        'description' => 'Monthly service fee',
        'recurring' => [
            'frequency' => 'monthly',
            'started_at' => now(),
            'limit_by' => 'count',
            'limit_count' => 12,
        ]
    ],
    $company
));
```

## Common Use Cases

### Salary Payments

Regular expense for employee salary:

```php
[
    'type' => 'expense-recurring',
    'account_id' => $checking->id,
    'amount' => -5000.00,
    'contact_id' => $employee->id,
    'description' => 'Salary - Jane Doe',
    'recurring' => [
        'frequency' => 'monthly',
        'started_at' => '2024-01-01',
        'limit_by' => null,  // Ongoing
    ]
]
```

### Subscription Payment

Regular subscription expense:

```php
[
    'type' => 'expense-recurring',
    'account_id' => $checking->id,
    'amount' => -99.00,
    'contact_id' => $vendor->id,
    'description' => 'SaaS subscription monthly',
    'recurring' => [
        'frequency' => 'monthly',
        'started_at' => now(),
        'limit_by' => 'date',
        'limit_date' => now()->addYears(3),  // 3-year subscription
    ]
]
```

### Service Revenue

Regular recurring income:

```php
[
    'type' => 'income-recurring',
    'account_id' => $checking->id,
    'amount' => 1500.00,
    'contact_id' => $customer->id,
    'category_id' => $retainer_category->id,
    'description' => 'Monthly retainer - Acme Corp',
    'recurring' => [
        'frequency' => 'monthly',
        'started_at' => '2024-01-15',
        'limit_by' => null,  // Ongoing
    ]
]
```

## Scheduling

Recurring transactions support all frequency options:

| Frequency | Interval Example |
|-----------|-----------------|
| daily | Every 1 day |
| weekly | Every 2 weeks |
| monthly | Every 1 month |
| quarterly | Every 1 quarter |
| semi-annually | Every 6 months |
| annually | Every 1 year |

**Stop conditions**:
- **After N generations**: `limit_by='count'`, `limit_count=12`
- **After date**: `limit_by='date'`, `limit_date='2024-12-31'`
- **Indefinite**: `limit_by=null`

## CLI Command

**Generate all recurring transactions**:

```bash
php artisan transaction:recurring-generate
```

Typically runs daily via Laravel scheduler:

```php
// app/Console/Kernel.php
$schedule->command('transaction:recurring-generate')->daily();
```

## Management

### View Recurring Transactions

```
Banking > Recurring Transactions
```

Lists all recurring transaction templates with status and generation count.

### Edit Schedule

Change frequency, amount, or stop condition:

```php
$recurring->update([
    'frequency' => 'quarterly',  // Changed from monthly
    'amount' => 600.00,          // Increased amount
]);
```

Changes apply to future generations only.

### End Recurring

Stop future generation:

```php
$recurring->update(['status' => 'ended']);
```

Existing child transactions remain.

### Manually Generate

Trigger immediate generation:

```
Action > Generate Now
```

## API Operations

**REST Endpoints**:

```
GET    /api/transactions?type=income-recurring        – List recurring income
GET    /api/transactions?type=expense-recurring       – List recurring expenses
GET    /api/transactions/{id}                         – Get recurring details
POST   /api/transactions                              – Create recurring
PUT    /api/transactions/{id}                         – Update recurring
DELETE /api/transactions/{id}                         – Delete recurring
```

## Testing

**Feature tests**: `/tests/Feature/Banking/TransactionsTest.php`

Key test cases:
- Create recurring income/expense
- Generate child transactions on schedule
- Stop generation when limit reached
- Manual generation
- Edit recurring template

---

## Related Pages

- [Banking Transactions](transactions.md) – Transaction recording
- [Recurring Documents](../documents/recurring.md) – Recurring invoices/bills
- [Bank Accounts](accounts.md) – Account balance tracking
