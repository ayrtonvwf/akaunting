---
type: system-overview
title: Console Commands & Scheduled Tasks
description: Artisan commands for recurring operations, module management, installation, and background processing.
tags: [console, commands, jobs, scheduling, artisan]
---

# Console Commands & Scheduled Tasks

Akaunting uses Laravel Artisan console commands for background operations, installation procedures, and administrative tasks. Key commands handle recurring document/transaction generation, payment reminders, module management, and database updates.

## Key Commands

### Recurring Check

**Command**: `php artisan recurring:check`

**File**: `App\Console\Commands\RecurringCheck`

**Purpose**: Auto-generate recurring documents and transactions based on schedule.

**Process**:
1. Query recurring documents past next generation date
2. For each, clone to create child document with new number
3. Query recurring transactions past next generation date
4. Clone transactions with new date
5. Mark documents/transactions as sent if configured
6. Fire events for notifications

**Frequency**: Run daily via scheduler

**Configuration**:
```php
// Kernel.php schedule
$schedule->command('recurring:check')->daily()->at('00:00');
```

### Invoice Reminders

**Command**: `php artisan invoice:remind`

**Purpose**: Send payment reminders for overdue invoices.

**Logic**:
1. Query invoices past due date with status 'unpaid' or 'partial'
2. Filter to not recently reminded (avoid spam)
3. Send email reminder to contact
4. Record reminder in invoice history

### Bill Reminders

**Command**: `php artisan bill:remind`

**Purpose**: Send reminders for bills due for payment.

**Logic**:
1. Query bills due in next N days (configurable)
2. Send email reminder to vendor
3. Optionally group multiple bills in one email

### Installation Command

**Command**: `php artisan install`

**File**: `App\Console\Commands\Install` (6600+ lines)

**Purpose**: Initial application installation and setup.

**Process**:
1. Check requirements (PHP version, extensions, writable directories)
2. Create .env file from .env.example
3. Database connection setup
4. Run migrations
5. Generate app key
6. Create admin user
7. Seed initial data (optional)
8. Enable/install modules
9. Publish assets
10. Create sample data (optional via --sample-data flag)

**Usage**:
```bash
php artisan install \
  --db-name="akaunting" \
  --db-username="root" \
  --db-password="secret" \
  --admin-email="admin@example.com" \
  --admin-password="password" \
  --sample-data
```

### Update Command

**Command**: `php artisan update`

**File**: `App\Console\Commands\Update` (8694 bytes)

**Purpose**: Upgrade Akaunting to new version.

**Process**:
1. Backup current database (optional)
2. Download new version files
3. Run migrations
4. Publish updated assets
5. Update module versions
6. Cache application config
7. Fire UpdateFinished event for listeners to run version-specific upgrades

**Usage**:
```bash
php artisan update --only-download
php artisan update
```

### Module Commands

#### Install Module

**Command**: `php artisan module:install {alias}`

**Purpose**: Download and install third-party module.

**Process**:
1. Download module from marketplace
2. Extract to modules directory
3. Register in database
4. Run module migrations
5. Publish module assets

#### Enable Module

**Command**: `php artisan module:enable {alias}`

**Purpose**: Activate installed module.

**Effect**: Module routes and services become available.

#### Disable Module

**Command**: `php artisan module:disable {alias}`

**Purpose**: Deactivate module without uninstalling.

**Effect**: Module routes not registered, but data preserved.

#### Uninstall Module

**Command**: `php artisan module:uninstall {alias}`

**Purpose**: Remove module and clean up.

**Process**:
1. Run module uninstall hooks
2. Delete module files
3. Remove from database
4. Delete module-specific data (optional)

### Database Commands

#### Seed Sample Data

**Command**: `php artisan sample-data:seed`

**Purpose**: Create demo company with sample documents and transactions.

**Data Created**:
- Demo company with settings
- 5 sample customers
- 5 sample vendors
- Sample products/services
- 10 sample invoices (various statuses)
- 10 sample bills
- 50 sample transactions
- 5 sample accounts

**Usage**: Useful for testing and demonstrations.

#### Migrate Command

**Command**: `php artisan migrate`

**Purpose**: Run pending database migrations.

**Scope**:
- Core migrations from `database/migrations/`
- Module migrations from `modules/*/database/migrations/`

---

## Scheduled Tasks

### Scheduler Configuration

**File**: `App\Console\Kernel`

Defines all scheduled commands:

```php
protected function schedule(Schedule $schedule)
{
    // Daily tasks
    $schedule->command('recurring:check')->daily()->at('00:00');
    $schedule->command('invoice:remind')->daily()->at('08:00');
    $schedule->command('bill:remind')->daily()->at('08:00');
    
    // Cleanup tasks
    $schedule->command('cache:clear')->daily();
    $schedule->command('view:clear')->daily();
    
    // Email queue processing
    $schedule->command('queue:work', ['--once' => true])->everyMinute();
}
```

### Running Scheduler

**One of two methods**:

1. **Cron method** (production):
```bash
* * * * * cd /path/to/akaunting && php artisan schedule:run >> /dev/null 2>&1
```

Add to system crontab to run every minute. Laravel's scheduler then decides which tasks to execute.

2. **Supervisor method**:
Use Supervisor to keep a queue worker running continuously:
```ini
[program:akaunting-worker]
process_name=%(program_name)s_%(process_num)02d
command=php artisan queue:work
numprocs=1
```

### Task Frequency Options

```php
$schedule->command('...')->everyMinute();
$schedule->command('...')->everyFiveMinutes();
$schedule->command('...')->everyTenMinutes();
$schedule->command('...')->everyFifteenMinutes();
$schedule->command('...')->everyThirtyMinutes();
$schedule->command('...')->hourly();
$schedule->command('...')->daily();
$schedule->command('...')->dailyAt('13:00');  // Specific time
$schedule->command('...')->twiceDaily(1, 13); // 1 AM and 1 PM
$schedule->command('...')->weekly();
$schedule->command('...')->monthlyOn(1, '12:00'); // First day of month
$schedule->command('...')->quarterly();
$schedule->command('...')->yearly();
```

---

## Job Queue Processing

### Queue Driver

Configured in `.env`:
```bash
QUEUE_CONNECTION=sync   # Synchronous (for development)
QUEUE_CONNECTION=database   # Database queue (persistent)
QUEUE_CONNECTION=redis   # Redis queue (recommended for production)
```

### Queue Worker

**Command**: `php artisan queue:work`

Listens for queued jobs and processes them.

**Options**:
```bash
# Process jobs once then exit
php artisan queue:work --once

# Process specific queue
php artisan queue:work --queue=emails

# Limit to specific number of jobs
php artisan queue:work --max-jobs=1000

# Stop after N seconds of inactivity
php artisan queue:work --timeout=3600

# Maximum attempts before failing
php artisan queue:work --tries=3
```

### Queue Monitoring

Check queued jobs:
```bash
php artisan queue:failed           # List failed jobs
php artisan queue:retry {id}       # Retry failed job
php artisan queue:clear           # Clear all queued jobs
```

---

## Custom Commands

Creating a custom command:

```bash
php artisan make:command MyCommand
```

**File**: `App/Console/Commands/MyCommand.php`

```php
class MyCommand extends Command
{
    protected $signature = 'my:command {argument} {--option}';
    protected $description = 'My command description';
    
    public function handle()
    {
        // Command logic
        $this->info('Success message');
        $this->error('Error message');
        $this->question('Question');
    }
}
```

Register in `Kernel.php`:
```php
protected $commands = [
    MyCommand::class,
];
```

---

## Testing Commands

```php
public function test_recurring_check_creates_new_documents()
{
    // Create recurring invoice
    $document = Document::factory()
        ->recurring()
        ->create(['next_generation_date' => now()]);
    
    // Run command
    $this->artisan('recurring:check');
    
    // Verify child created
    $this->assertDatabaseHas('documents', [
        'parent_id' => $document->id,
        'type' => 'invoice',
    ]);
}
```

---

## Best Practices

1. **Schedule Daily Tasks Strategically**: Avoid rush hours; stagger tasks
2. **Log Command Output**: Redirect cron output to logs for debugging
3. **Monitor Queue**: Check failed queue periodically
4. **Timeout Configuration**: Set appropriate timeouts for long-running tasks
5. **Error Notifications**: Configure alerts for failed commands
6. **Test Commands**: Verify commands work in test environment before production

---

*Reference: /app/Console/Commands, /app/Console/Kernel.php*
