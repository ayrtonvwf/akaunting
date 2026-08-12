---
type: system-reference
title: Reports & Analytics System
description: Custom report builder, pre-built reports, saved reports, widgets, and business analytics in Akaunting.
tags: [reports, analytics, dashboard, business-intelligence]
openwiki:
  source_paths: [app/Reports, app/Models/Common/Report.php]
---

# Reports & Analytics System

The reports system provides both pre-built reports and a custom report builder for business analytics. Reports can be viewed, exported, and embedded as dashboard widgets.

## Report Architecture

```
User → Report Builder/Selection
        ↓
    Report Engine
    ├─ Load report configuration
    ├─ Query data (filtered/aggregated)
    ├─ Calculate totals/summaries
    └─ Format for display/export
        ↓
    Output (Table/Chart/Export)
```

## Pre-Built Reports

Akaunting includes these standard reports:

### Financial Reports

| Report | Purpose | Data |
|--------|---------|------|
| **Income Summary** | Revenue by period/category | Documents (invoices) |
| **Expense Summary** | Expenses by period/category | Transactions |
| **Income-Expense** | Revenue vs expenses | Invoices + Transactions |
| **Profit & Loss** | Net profit/loss | Income - Expenses |
| **Tax Summary** | Tax collected/paid | Documents with tax |

### Category Reports

| Report | Purpose | Data |
|--------|---------|------|
| **Discount Summary** | Discounts applied | Document discounts |
| **Category Breakdown** | Analysis by category | Transactions by category |

### Cash Flow

| Report | Purpose | Data |
|--------|---------|------|
| **Cash Flow** | Inflows and outflows | All transactions |
| **Bank Reconciliation** | Account vs statement | Transactions and reconciliations |

## Report Classes

**Location**: `App\Reports\{ReportName}`

### Report Structure

```php
namespace App\Reports;

use App\Abstracts\Report;

class IncomeSummary extends Report
{
    public function setQuery()
    {
        $this->query = Document::invoice()->with('items');
    }
    
    public function setSummary()
    {
        $this->summary = [
            'total_invoices' => $this->query->count(),
            'total_income' => $this->query->sum('amount'),
            'average_invoice' => $this->query->avg('amount'),
        ];
    }
    
    public function setData()
    {
        // Group by date/category
        $this->data = $this->query
            ->groupBy(DB::raw('DATE(issued_at)'))
            ->selectRaw('DATE(issued_at) as date, SUM(amount) as total')
            ->get();
    }
}
```

### Core Methods

```php
public function setQuery()           // Define data source
public function setSummary()         // Calculate totals
public function setData()            // Format for display
public function setRows()            // Table rows
public function setColumns()         // Column definitions
public function setChart()           // Chart data/config
```

## Report Models

### Report (Saved Report)

**File**: `App\Models\Common\Report`

```php
$report = Report::find($id);

$report->name;                  // 'Q1 Sales Report'
$report->type;                  // Report class name
$report->query_string;          // Saved filters/params
$report->data;                  // Cached results
$report->updated_at;            // Last refreshed
```

### Dashboard

**File**: `App\Models\Common\Dashboard`

```php
$dashboard = Dashboard::find($id);

$dashboard->name;               // 'Executive Summary'
$dashboard->widgets;            // HasMany: DashboardWidget
$dashboard->enabled;            // true/false
```

### DashboardWidget

```php
$widget = DashboardWidget::find($id);

$widget->dashboard_id;          // Parent dashboard
$widget->report_id;             // Report to display
$widget->type;                  // Chart type (bar, pie, line)
$widget->position;              // Grid position (row/col)
$widget->width;                 // Grid width (1-12)
$widget->height;                // Grid height
```

## Custom Report Builder

### Using the Builder UI

Users can create custom reports through the web interface:

```
Admin → Reports → Create New
    ├─ Report Name: "Custom Sales Report"
    ├─ Type: Income Summary
    ├─ Filters
    │  ├─ Date Range: This month
    │  ├─ Status: Paid
    │  └─ Customer: Specific
    ├─ Display
    │  ├─ Group by: Month
    │  └─ Show: Total, Average
    └─ Visualization: Table / Bar Chart / Line Chart
```

### Filter Options

```php
// Date filters
'date_range' => 'this_month|this_quarter|this_year|custom',
'start_date' => '2024-01-01',
'end_date' => '2024-01-31',

// Entity filters
'status' => 'paid|draft|unpaid',
'contact_id' => 1,              // Specific customer
'category_id' => 1,             // Transaction category
'account_id' => 1,              // Bank account
```

### Aggregation Options

```php
'group_by' => 'day|week|month|quarter|year|category|contact',
'metrics' => ['sum', 'count', 'average', 'min', 'max'],
```

## Report Visualization

### Table Format

```
Date       | Category  | Amount   | Count
-----------|-----------|----------|-------
2024-01-31 | Services  | 5000.00  | 5
2024-01-31 | Products  | 2500.00  | 2
-----------|-----------|----------|-------
TOTAL      |           | 7500.00  | 7
```

### Chart Types

```
Bar Chart       → Compare categories
Line Chart      → Trends over time
Pie Chart       → Percentage breakdown
Table           → Detailed data
```

### Chart Configuration

```php
'chart' => [
    'type' => 'bar|line|pie|area',
    'title' => 'Monthly Income',
    'x_axis' => 'Date',
    'y_axis' => 'Amount',
    'stacked' => true|false,
    'legend' => true|false,
]
```

## Report Data Structure

### Response Format

```json
{
  "id": 1,
  "name": "Income Summary",
  "type": "income_summary",
  "summary": {
    "total_income": 50000.00,
    "total_invoices": 25,
    "average_invoice": 2000.00
  },
  "data": [
    {
      "date": "2024-01-31",
      "total": 5000.00,
      "count": 5
    },
    {
      "date": "2024-02-29",
      "total": 7500.00,
      "count": 8
    }
  ],
  "chart": {
    "type": "line",
    "datasets": [
      {
        "label": "Income",
        "data": [5000, 7500, 6000]
      }
    ]
  }
}
```

## Saved Reports

### Create Saved Report

```php
$report = Report::create([
    'company_id' => auth()->user()->currentCompany()->id,
    'name' => 'Monthly Income',
    'class' => 'App\Reports\IncomeSummary',
    'query_string' => json_encode([
        'start_date' => '2024-01-01',
        'end_date' => '2024-01-31',
        'status' => 'paid',
    ]),
    'enabled' => true,
]);
```

### View Saved Report

```php
GET /api/reports/{report_id}

Response: Report data with chart configuration
```

### List Reports

```php
GET /api/reports?type=income_summary

Response: All saved reports of that type
```

### Execute Report

```php
$report = Report::find($id);
$results = $report->execute();  // Returns formatted data
```

## Dashboard Widgets

### Add Report to Dashboard

```php
$widget = DashboardWidget::create([
    'dashboard_id' => $dashboard->id,
    'report_id' => $report->id,
    'type' => 'chart',           // chart, table, stat
    'title' => 'Monthly Income',
    'position' => 'top-left',
    'width' => 6,
    'height' => 4,
]);
```

### Widget Types

```
'chart'   → Visualize as chart (bar, line, pie)
'table'   → Display as data table
'stat'    → Show single number (KPI)
'text'    → Text content
```

## Real-World Examples

### Scenario: Generate Monthly Profit & Loss

1. **User action**: Admin → Reports → Create Report

2. **Configuration**:
   - Type: Profit & Loss
   - Period: January 2024
   - Filters: All categories

3. **System generates**:
   - Income: Sum of paid invoices
   - Expenses: Sum of expense transactions
   - Net: Income - Expenses
   - Breakdown by category

4. **Output**:
   - Table with totals
   - Line chart showing trend
   - PDF export for records

### Scenario: Dashboard with KPIs

```php
// Executive dashboard
$dashboard = Dashboard::create([
    'name' => 'Executive Summary',
    'enabled' => true,
]);

// Add widgets
Widget::create([
    'dashboard_id' => $dashboard->id,
    'report_id' => Report::find('income_summary')->id,
    'type' => 'stat',           // Show single number
    'width' => 3,
]);

// Widget displays: Total Income This Month: $50,000
```

### Scenario: Tax Summary Export

```php
// Export tax report for accountant
$report = Report::where('type', 'tax_summary')
    ->where('query_string', 'LIKE', '%2024%')
    ->first();

$data = $report->execute();

return (new ReportExport($data))
    ->download('Tax_Report_2024.xlsx');
```

## API Endpoints

```
GET    /api/reports              # List all reports
GET    /api/reports/{id}         # Get report data
POST   /api/reports              # Create saved report
PATCH  /api/reports/{id}         # Update report
DELETE /api/reports/{id}         # Delete report
GET    /api/dashboards           # List dashboards
GET    /api/dashboards/{id}      # Get dashboard with widgets
```

## Caching & Performance

Reports can cache results:

```php
$report = Report::find($id);

// Cached results
$data = $report->getCachedData();

// Force refresh
$data = $report->execute();

// Cache expires after 1 hour
// Cache invalidated when underlying data changes
```

## Multi-Tenancy

All reports scoped to company:

```php
// User views report
Report::where('company_id', auth()->user()->currentCompany()->id)->get();

// Data includes only company's documents/transactions
// No data leakage between companies
```

## Related Pages

- [Data Processing](data/overview.md) – Import/export and analytics
- [Dashboard Widget System](common/overview.md) – Dashboard infrastructure
- [Common Domain](common/overview.md) – Report models

## Source Map

```
app/
├─ Reports/
│  ├─ IncomeSummary.php
│  ├─ ExpenseSummary.php
│  ├─ IncomeExpenseSummary.php
│  ├─ ProfitLoss.php
│  ├─ TaxSummary.php
│  └─ DiscountSummary.php
└─ Models/Common/
   ├─ Report.php
   ├─ Dashboard.php
   └─ DashboardWidget.php

routes/api.php
└─ GET /api/reports
```

## Testing & Validation

```bash
# Test report generation
php artisan test tests/Feature/Common/ReportsTest.php

# Test report calculation
php artisan test tests/Feature/Common/ReportsTest.php

# Test dashboard widgets
php artisan test tests/Feature/Common/DashboardsTest.php
```

## Common Patterns

### Create custom report class

```php
namespace App\Reports;

use App\Abstracts\Report;

class CustomReport extends Report
{
    public function setQuery()
    {
        $this->query = Document::invoice();
    }
    
    public function setSummary()
    {
        $this->summary = [
            'count' => $this->query->count(),
            'total' => $this->query->sum('amount'),
        ];
    }
}
```

### Filter report by date range

```php
$report = Report::find($id);
$params = json_decode($report->query_string, true);

$params['start_date'] = '2024-01-01';
$params['end_date'] = '2024-01-31';

$report->update(['query_string' => json_encode($params)]);
```

### Export report to PDF

```php
$report = Report::find($id);
$data = $report->execute();

return PDF::loadView('reports.template', $data)
    ->download('report.pdf');
```
