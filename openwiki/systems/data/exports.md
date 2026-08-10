---
type: system-reference
title: Bulk Export System
description: Export documents and reports to Excel, CSV, and PDF formats with filtering and customization.
tags: [export, data, bulk-operations, excel, pdf, reporting]
openwiki:
  source_paths: [app/Exports, app/Jobs/Common/CreateMediableForExport.php]
---

# Bulk Export System

The bulk export system enables users to export documents, transactions, reports, and other data to Excel, CSV, and PDF formats. Exports support filtering, custom columns, and batch operations.

## Export Pipeline

```
User selects data
    ↓
Configure export options (format, columns, filters)
    ↓
Generate export file
    ↓
Transform data (formatting, calculations)
    ↓
Write to file (Excel/CSV/PDF)
    ↓
Return file for download
```

## Export Classes

### File Structure

**Location**: `App\Exports\{Domain}\{Entity}`

```
app/Exports/
├─ Banking/
│  ├─ Accounts.php
│  ├─ Transactions.php
│  └─ Reconciliations.php
├─ Common/
│  ├─ Contacts.php
│  ├─ Items.php
│  └─ Reports.php
├─ Sales/
│  └─ Documents.php
├─ Purchases/
│  └─ Documents.php
└─ Settings/
   ├─ Categories.php
   ├─ Currencies.php
   └─ Taxes.php
```

### Document Export Example

**Class**: `App\Exports\Sales\Documents`

```php
namespace App\Exports\Sales;

use Illuminate\Contracts\Queue\ShouldQueue;
use Maatwebsite\Excel\Concerns\Exportable;
use Maatwebsite\Excel\Concerns\FromQuery;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;

class Documents implements FromQuery, WithHeadings, WithMapping, ShouldQueue
{
    use Exportable;
    
    protected $query;
    
    public function __construct($query = null)
    {
        $this->query = $query ?? Document::invoice();
    }
    
    public function query()
    {
        return $this->query;
    }
    
    public function headings(): array
    {
        return [
            'Document Number',
            'Issue Date',
            'Customer',
            'Amount',
            'Status',
            'Paid',
        ];
    }
    
    public function map($document): array
    {
        return [
            $document->document_number,
            $document->issued_at->format('Y-m-d'),
            $document->contact->name,
            $document->amount,
            $document->status,
            $document->totalPaid(),
        ];
    }
}
```

## Export Methods

### Web UI Export

Users can export through web interface:

```
Admin → Documents → Select → Export → Choose Format → Download
```

### API Export

```php
GET /api/documents/export?format=excel&type=invoice
Response: Excel file download
```

### Command Line Export

```bash
php artisan export:documents --type=invoice --format=excel
php artisan export:transactions --account=1 --format=csv
php artisan export:contacts --format=pdf
```

## Supported Formats

### Excel (.xlsx)

Professional spreadsheet with formatting:

```
Document | Issue Date | Customer    | Amount   | Status | Paid
---------|-----------|-------------|----------|--------|-------
INV-001  | 2024-01-15| Acme Corp   | 1000.00  | Paid   | 1000.00
INV-002  | 2024-01-16| Example Inc | 2500.00  | Draft  | 0.00
```

**Features**:
- Multiple sheets
- Formatting (fonts, colors, borders)
- Formulas (SUM, AVERAGE)
- Frozen headers
- Column width auto-fit

### CSV (.csv)

Comma-separated values:

```
Document,Issue Date,Customer,Amount,Status,Paid
INV-001,2024-01-15,Acme Corp,1000.00,Paid,1000.00
INV-002,2024-01-16,Example Inc,2500.00,Draft,0.00
```

**Properties**:
- Simple text format
- Compatible with all spreadsheet programs
- Smaller file size
- No formatting preserved

### PDF

Printable format:

```
INVOICES EXPORT REPORT
Date: 2024-01-20

Document | Issue Date | Customer | Amount
---------|-----------|----------|--------
INV-001  | 2024-01-15| Acme     | 1000.00
...
```

**Features**:
- Professional layout
- Summaries and totals
- Page breaks
- Print-ready formatting

## Export Features

### Filtering

Export specific subset:

```php
// Export only paid invoices
Document::invoice()
    ->where('status', 'paid')
    ->export('documents.xlsx');

// Export by date range
Document::invoice()
    ->issuedBetween($start_date, $end_date)
    ->export('documents_Q1.xlsx');

// Export by customer
Document::invoice()
    ->where('contact_id', $customer_id)
    ->export('customer_invoices.xlsx');
```

### Column Selection

Choose which columns to include:

```php
$export = new DocumentExport();
$export->setColumns([
    'document_number',
    'issued_at',
    'contact.name',
    'amount',
    'status',
]);

return $export->download('documents.xlsx');
```

### Custom Formatting

Format data for export:

```php
public function map($document): array
{
    return [
        'Number' => $document->document_number,
        'Date' => $document->issued_at->format('M d, Y'),
        'Customer' => strtoupper($document->contact->name),
        'Total' => money($document->amount, $document->currency_code)->format(),
        'Paid' => $document->totalPaid() > 0 ? 'Yes' : 'No',
        'Remaining' => money($document->remainingAmount(), $document->currency_code)->format(),
    ];
}
```

### Calculations in Export

Include calculated fields:

```php
public function map($document): array
{
    return [
        $document->document_number,
        $document->issued_at,
        $document->contact->name,
        $document->amount,
        $document->totalPaid(),
        $document->amount - $document->totalPaid(),  // Remaining
        $document->isPaid() ? 'Yes' : 'No',          // Is Paid
    ];
}
```

### Multiple Sheets (Excel only)

```php
class CompleteExport implements WithMultipleSheets
{
    public function sheets(): array
    {
        return [
            'Invoices' => new InvoicesExport(),
            'Bills' => new BillsExport(),
            'Payments' => new PaymentsExport(),
        ];
    }
}
```

## Batch Export

### Export All Records

```php
// Export all invoices (with pagination)
$invoices = Document::invoice()->get();

return (new DocumentExport($invoices))
    ->download('all_invoices.xlsx');
```

### Export with Relationships (Eager Loading)

```php
$query = Document::invoice()
    ->with('contact', 'items')  // Eager load related data
    ->where('status', 'paid');

return (new DocumentExport($query))
    ->download('paid_invoices_with_items.xlsx');
```

## Job-Based Export

For large exports, use jobs:

**Class**: `App\Jobs\Common\CreateMediableForExport`

```php
// Queue large export as background job
$this->dispatch(new CreateMediableForExport([
    'model' => Document::class,
    'query' => ['status' => 'paid'],
    'format' => 'excel',
    'disk' => 'local',
]));

// User gets notification when ready
// File available for download from email link
```

## Export Configuration

### File Storage

Exported files can be stored or downloaded:

```php
// Stream directly to user
return $export->download('documents.xlsx');

// Store on disk for later
$export->store('exports/documents.xlsx', 'local');

// Store on cloud
$export->store('exports/documents.xlsx', 's3');
```

### Size Limits

Large exports may be queued:

```php
// If > 10,000 rows, queue as job
if ($query->count() > 10000) {
    $this->dispatch(new ExportLargeDataset($query));
} else {
    return $export->download('export.xlsx');
}
```

### Memory Management

Stream large datasets to avoid memory issues:

```php
class LargeExport implements FromQuery, WithChunkReading
{
    public function chunkSize(): int
    {
        return 1000;  // Process 1000 rows at a time
    }
}
```

## Multi-Tenancy in Exports

All exports automatically scoped to current company:

```php
// When user exports
$documents = Document::invoice()->get();

// Only returns current company's invoices
// No data leakage
```

## Real-World Workflows

### Scenario: Monthly Invoice Report

1. **User action**: Admin → Sales → Invoices → Export

2. **System dialog**:
   - Format: Excel ✓ CSV □ PDF □
   - Date range: Jan 1 - Jan 31, 2024
   - Status: All ▼

3. **Generate export**:
   - Filter: issued_at BETWEEN ... AND ... AND status IN (...)
   - Columns: document_number, issued_at, contact, amount, status, paid, remaining
   - Format data (dates, money)
   - Write Excel file with formatting

4. **Download**: `Invoices_January_2024.xlsx`

5. **File contains**:
   - Invoice list with totals
   - Summary: 150 invoices, $50,000 total, $10,000 paid
   - Frozen header row
   - Auto-fit columns

### Scenario: Reconciliation Export

```bash
# Export transactions for bank reconciliation
php artisan export:transactions \
  --account=1 \
  --start_date=2024-01-01 \
  --end_date=2024-01-31 \
  --format=csv

# CSV file: date, description, amount, reconciled
# Upload to bank reconciliation tool
```

### Scenario: Tax Report Export

```php
// Export all expenses by category for tax preparation
Transaction::expense()
    ->where('transaction_date', '>=', '2023-01-01')
    ->where('transaction_date', '<=', '2023-12-31')
    ->export('tax_report_2023.xlsx');

// File includes totals by category
```

## Related Pages

- [Bulk Import](imports.md) – Import from Excel/CSV
- [Data Processing](overview.md) – Data import/export overview
- [Documents System](../documents/overview.md) – Document model

## Source Map

```
app/
├─ Exports/
│  ├─ Banking/
│  ├─ Common/
│  ├─ Sales/
│  ├─ Purchases/
│  └─ Settings/
└─ Jobs/Common/CreateMediableForExport.php

routes/api.php
└─ GET /api/documents/export

Console/Commands/
└─ Export*.php
```

## Testing & Validation

```bash
# Test export pipeline
php artisan test tests/Feature/Export/

# Test document export
php artisan test tests/Feature/Export/ExportDocumentsTest.php

# Test export formatting
php artisan test tests/Feature/Export/ExportFormattingTest.php
```

## Common Patterns

### Export with totals

```php
public function registerEvents(): array
{
    return [
        AfterSheet::class => function(AfterSheet $event) {
            $sheet = $event->sheet;
            $row = $sheet->getHighestRow() + 2;
            
            // Total row
            $sheet->setCellValue('A' . $row, 'TOTAL');
            $sheet->setCellValue('D' . $row, '=SUM(D2:D' . ($row - 2) . ')');
        },
    ];
}
```

### Export with custom headers

```php
public function headings(): array
{
    return [
        'Invoice #',
        'Date',
        'Customer',
        'Amount',
        'Status',
        'Balance',
    ];
}
```

### Conditional formatting in export

```php
public function registerEvents(): array
{
    return [
        AfterSheet::class => function(AfterSheet $event) {
            // Color paid invoices green
            $event->sheet->style('A2:F100')->applyFromArray([
                'fill' => ['fillType' => Fill::FILL_SOLID, 'color' => ['rgb' => 'E2EFDA']],
            ]);
        },
    ];
}
```

### Streaming export (no file storage)

```php
return (new DocumentExport())
    ->download('invoices.xlsx', \Maatwebsite\Excel\Excel::XLSX);
```
