---
type: system-reference
title: Bulk Import System
description: CSV/Excel import pipeline with validation, mapping, and error handling for documents and transactions.
tags: [import, data, bulk-operations, excel, csv]
openwiki:
  source_paths: [app/Imports, app/Traits/Import.php]
---

# Bulk Import System

The bulk import system enables users to upload CSV and Excel files to import documents, transactions, contacts, and other data. It handles validation, mapping, and error reporting.

## Import Pipeline

```
User uploads file
    ↓
File validation (format, size, encoding)
    ↓
Row parsing (CSV/Excel reader)
    ↓
Data mapping (columns → fields)
    ↓
Row validation (rules per entity type)
    ↓
Import execution (create models)
    ↓
Report generation (success/failures)
```

## Import Classes

### File Structure

**Location**: `App\Imports\{Domain}\{Entity}`

```
app/Imports/
├─ Banking/
│  ├─ Accounts.php
│  └─ Transactions.php
├─ Common/
│  ├─ Contacts.php
│  └─ Items.php
├─ Sales/
│  └─ Documents.php
├─ Purchases/
│  └─ Documents.php
└─ Settings/
   ├─ Categories.php
   ├─ Currencies.php
   └─ Taxes.php
```

### Document Import Example

**Class**: `App\Imports\Sales\Documents`

```php
namespace App\Imports\Sales;

use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;

class Documents implements ToCollection, WithHeadingRow
{
    public function collection(Collection $rows)
    {
        foreach ($rows as $row) {
            // Validate row
            // Create document
        }
    }
}
```

## Import Methods

### Web UI Import

Users can import through web interface:

```
Admin → Documents → Import → Upload File → Map Columns → Review → Confirm
```

### API Import

```php
POST /api/documents/import
Content-Type: multipart/form-data

file: (binary file)
```

### Command Line Import

```bash
php artisan import:documents --file=import.xlsx
php artisan import:transactions --file=transactions.csv
php artisan import:contacts --file=contacts.csv
```

## Column Mapping

### Document Import Mapping

```
File Column          → Model Field
Document Number      → document_number
Issue Date           → issued_at
Due Date             → due_at
Customer/Vendor Name → contact_id (lookup)
Item Name            → item_id (lookup)
Quantity             → quantity
Unit Price           → price
Description          → description
Discount %           → discount_rate
Notes                → notes
```

### Transaction Import Mapping

```
File Column          → Model Field
Date                 → transaction_date
Account              → account_id
Category             → category_id
Amount               → amount
Type                 → type (income/expense)
Description          → description
Reference            → reference
Contact              → contact_id (optional)
```

### Contact Import Mapping

```
File Column          → Model Field
Name                 → name
Email                → email
Phone                → phone
Type                 → type (customer/vendor)
Tax Number           → tax_number
Address              → address
City                 → city
State                → state
Country              → country
Zip Code             → zip_code
```

## Validation Rules

### During Import

Each row is validated before creation:

```php
// Document row validation
[
    'document_number' => 'nullable|unique:documents,document_number',
    'issued_at' => 'required|date_format:Y-m-d',
    'contact_id' => 'required|exists:contacts,id',
    'items' => 'required|array|min:1',
]

// Transaction row validation
[
    'transaction_date' => 'required|date_format:Y-m-d',
    'account_id' => 'required|exists:accounts,id',
    'amount' => 'required|numeric|min:0.01',
    'type' => 'required|in:income,expense,transfer',
]
```

### Error Handling

Errors are collected and reported:

```json
{
  "success": false,
  "imported": 15,
  "failed": 3,
  "errors": [
    {
      "row": 2,
      "errors": {
        "issued_at": "The issued at field must be a valid date."
      }
    },
    {
      "row": 5,
      "errors": {
        "contact_id": "The selected contact id is invalid."
      }
    }
  ]
}
```

## Import Trait

**File**: `App\Traits\Import`

Provides import utilities to models.

### Methods

```php
// Get import fields
Model::importable();           // Array of importable fields

// Get import validation rules
Model::importRules();          // Validation rules

// Get column heading mapping
Model::importHeadings();       // Array of column names

// Perform import
Model::importFromArray($data); // Create from array
```

### Usage in Import Class

```php
foreach ($rows as $row) {
    // Validate against model rules
    $this->validate($row, Document::importRules());
    
    // Create document
    Document::importFromArray($row);
}
```

## Supported File Formats

### Excel (.xlsx, .xls)

Rows and sheets:

```
Sheet 1: Invoices
Row 1: Headers
Row 2+: Data

Sheet 2: Items
Row 1: Headers
Row 2+: Data
```

### CSV (.csv)

Comma or other delimited:

```
document_number,issued_at,customer_name,item_name,quantity,price
INV-001,2024-01-15,Acme Corp,Consulting Services,10,100.00
INV-002,2024-01-16,Example Inc,Product,5,50.00
```

### TSV (.tsv)

Tab-delimited:

```
document_number	issued_at	customer_name
INV-001	2024-01-15	Acme Corp
```

## Import Features

### Upsert (Update or Create)

If matching record found, update instead of create:

```php
Document::updateOrCreate(
    ['document_number' => $row['document_number']],
    $row
);
```

### Batch Import

Import multiple rows efficiently:

```php
Document::insert($rows);  // Faster than individual creates
```

### Transaction Handling

Entire import wrapped in database transaction:

```php
DB::transaction(function () {
    foreach ($rows as $row) {
        Document::create($row);
    }
});
```

If any row fails, entire import rolled back.

### Duplicate Detection

Check for duplicates before import:

```php
$existing = Document::where('document_number', $row['document_number'])
    ->first();

if ($existing && !$options['overwrite']) {
    // Skip or error
}
```

## Import Configuration

### File Size Limits

```php
// config/filesystems.php
'max_size' => 5,  // MB

// Validated before upload
```

### Allowed MIME Types

```php
'mimes' => 'xls,xlsx,csv,tsv',

// File uploaded to temporary storage
// Deleted after processing
```

## Multi-Tenancy in Imports

All imports automatically scoped to current company:

```php
// When user uploads import
Document::import($file);

// All created documents assigned to:
auth()->user()->currentCompany()->id
```

## Real-World Workflow

### Scenario: Import Monthly Invoices

1. **Export from billing system** → CSV file with columns: number, date, customer, amount

2. **Prepare file** → Ensure format matches import specification

3. **Upload via web UI**:
   - Admin → Documents → Import
   - Select file
   - Map columns
   - Review preview
   - Confirm import

4. **System processes**:
   - Validates each row
   - Looks up customers by name
   - Creates documents
   - Reports results

5. **Review results**:
   - 250 invoices imported successfully
   - 3 errors (customer not found, invalid date)
   - Download error report

### Scenario: Import Bank Transactions via Command

```bash
# Export from bank
# Format: date,amount,description

# Run import command
php artisan import:transactions \
  --file=bank_export_Jan2024.csv \
  --account=1 \
  --type=auto

# System creates Transaction records
# Links to documents if descriptions match
```

## Related Pages

- [Bulk Export](exports.md) – Export to Excel/CSV
- [Data Processing](overview.md) – Data import/export overview
- [Banking System](../banking/overview.md) – Transaction model

## Source Map

```
app/
├─ Imports/
│  ├─ Banking/
│  ├─ Common/
│  ├─ Sales/
│  ├─ Purchases/
│  └─ Settings/
└─ Traits/Import.php

routes/api.php
└─ POST /api/documents/import

Console/Commands/
└─ Import*.php
```

## Testing & Validation

```bash
# Test import pipeline
php artisan test tests/Feature/Import/

# Test document import
php artisan test tests/Feature/Import/ImportDocumentsTest.php

# Test import validation
php artisan test tests/Feature/Import/ImportValidationTest.php
```

## Common Patterns

### Import with error recovery

```php
$results = ['success' => 0, 'failed' => 0, 'errors' => []];

foreach ($rows as $index => $row) {
    try {
        Document::create($row);
        $results['success']++;
    } catch (Exception $e) {
        $results['failed']++;
        $results['errors'][] = [
            'row' => $index + 1,
            'error' => $e->getMessage()
        ];
    }
}

return $results;
```

### Lookup related entities

```php
// When importing, need to resolve contact_id from name
$contact = Contact::where('name', $row['customer_name'])
    ->where('company_id', auth()->user()->currentCompany()->id)
    ->first();

if (!$contact) {
    // Skip row or auto-create contact
}

$row['contact_id'] = $contact->id;
```

### Validate before import

```php
// Preview: validate all rows without importing
$errors = [];
foreach ($rows as $index => $row) {
    $validator = Validator::make($row, Document::importRules());
    if ($validator->fails()) {
        $errors[$index] = $validator->errors();
    }
}

// Return errors to user for review/correction
```
