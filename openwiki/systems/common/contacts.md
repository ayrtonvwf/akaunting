---
type: system-domain
title: Contacts Management
description: Customer and vendor management, polymorphic contact types, contact persons, and contact-based operations in Akaunting.
tags: [contacts, customers, vendors, polymorphic, relationships]
---

# Contacts Management

The Contacts system manages customers and vendors as a single polymorphic entity. Contacts are the parties involved in business transactions—customers receive invoices, vendors send bills. Each contact can have multiple contact persons for direct communication.

## Core Model: Contact

**File**: `App\Models\Common\Contact`
**Table**: `contacts`

### Attributes

```
id, company_id, type (customer|vendor), name, email, phone, website,
tax_number, currency_code, enabled, created_at, updated_at, deleted_at
```

### Key Fields

- **type**: `customer` (invoicing) or `vendor` (purchasing)
- **name**: Company or individual name
- **email**: Primary contact email
- **phone**: Primary phone number
- **website**: Company website
- **tax_number**: Tax ID or VAT number
- **currency_code**: Default currency for transactions
- **enabled**: Whether contact is active

### Address Fields

Address stored as model attributes (denormalized):

```php
'address'    => '123 Main St',
'country'    => 'US',
'state'      => 'CA',
'city'       => 'San Francisco',
'zip_code'   => '94102',
```

### Relationships

```php
$contact->contact_persons;    // HasMany: Individual persons at contact
$contact->documents;          // HasMany: Invoices/bills for this contact
$contact->transactions;       // HasMany: Banking transactions
$contact->user;               // BelongsTo: Linked user account (optional)
```

### Scopes

```php
Contact::customer();    // Only customers
Contact::vendor();      // Only vendors
Contact::enabled();     // Only active contacts
```

## Contact Types

### Customer

Receives invoices. Data fields typically include:

- Company name
- Billing contact email
- Billing address
- Tax registration number

**Relationships**:
- Invoices (sales documents)
- Income transactions (payments from customer)

### Vendor

Sends bills. Data fields typically include:

- Vendor company name
- Contact email
- Vendor address
- Tax ID or VAT number

**Relationships**:
- Bills (purchase documents)
- Expense transactions (payments to vendor)

## Contact Persons

**Model**: `App\Models\Common\ContactPerson`
**Table**: `contact_people`

Individual people at a contact organization. Used for directed communication.

### Attributes

```
id, contact_id, name, email, phone, created_at, updated_at
```

### Usage

When sending invoices/bills:
- Primary contact email from `Contact.email`
- Additional contact persons CC'd or BCC'd from `ContactPerson` records

**Example**:
```
Invoice sent to: billing@acme.com (Contact.email)
CC: ap@acme.com, finance@acme.com (ContactPerson entries)
```

### Managing Contact Persons

```php
$contact->contact_persons()->create([
    'name' => 'John Smith',
    'email' => 'john@acme.com',
    'phone' => '+12025551234',
]);

$contact->contact_persons;  // All persons at this contact
```

## Contact Creation

**Controller**: `App\Http\Controllers\Common\Contacts`
**Job**: `App\Jobs\Common\CreateContact`

### Flow

1. User submits contact form (customer or vendor type)
2. Controller validates with `App\Http\Requests\Common\Contact`
3. Controller dispatches `CreateContact` job
4. Job creates `Contact` record
5. Optionally creates `ContactPerson` entries
6. Job fires `ContactCreated` event

### Minimum Required Fields

```php
[
    'type' => 'customer',  // or 'vendor'
    'name' => 'Acme Corp',
    'email' => 'billing@acme.com',
]
```

### Full Contact Creation

```php
[
    'type' => 'customer',
    'name' => 'Acme Corporation',
    'email' => 'billing@acme.com',
    'phone' => '+1-555-0100',
    'website' => 'https://acme.com',
    'tax_number' => '123456789',
    'currency_code' => 'USD',
    'address' => '123 Main St',
    'city' => 'Springfield',
    'state' => 'IL',
    'zip_code' => '62701',
    'country' => 'US',
    'contact_persons' => [
        ['name' => 'John Doe', 'email' => 'john@acme.com'],
        ['name' => 'Jane Smith', 'email' => 'jane@acme.com'],
    ]
]
```

## API Operations

**REST Endpoints**:

```
GET    /api/contacts                    – List contacts
GET    /api/contacts/{id}               – Get contact details
POST   /api/contacts                    – Create contact
PUT    /api/contacts/{id}               – Update contact
DELETE /api/contacts/{id}               – Delete (soft delete)
```

**Query parameters**:
```
?type=customer       – Filter by type
?enabled=true        – Filter by status
?search=acme         – Search by name/email
```

**Response**: Returns `Contact` resource with full details including contact persons.

## Contact Information Denormalization

When an invoice/bill is created, contact information is **denormalized** (copied) into the document:

**Why**: If contact is deleted or updated later, the document preserves historical accuracy.

**In Document**:
```php
'contact_id' => 1,
'contact_name' => 'Acme Corp',
'contact_email' => 'billing@acme.com',
'contact_tax_number' => '123456789',
'contact_address' => '123 Main St',
'contact_city' => 'Springfield',
...
```

If later the contact is updated or deleted, the invoice still displays original customer information.

## Authorization

**Permissions**:
- `read-common-contacts` – View contacts
- `create-common-contacts` – Create new contact
- `update-common-contacts` – Edit contact
- `delete-common-contacts` – Delete contact

## Multi-Currency Contacts

Contacts can have a default currency:

```php
$contact->currency_code = 'EUR';
```

When creating transactions with this contact, the default currency is suggested.

## Contact Lifecycle

### Active Contact

```php
$contact->enabled = true;
$contact->save();
```

Active contacts appear in dropdowns for invoice/bill creation.

### Disable Contact

```php
$contact->enabled = false;
$contact->save();
```

Disabled contacts don't appear in UI but remain in database and documents.

### Delete Contact

```php
$contact->delete();  // Soft delete, sets deleted_at
```

Soft-deleted contacts:
- Hidden from lists
- Cannot be selected for new documents
- Existing documents with this contact remain accessible

## Contact-Based Workflows

### Find All Invoices for Customer

```php
$customer = Contact::find($id);
$invoices = $customer->documents()
    ->where('type', 'invoice')
    ->get();
```

### Find All Payments from Customer

```php
$payments = $customer->transactions()
    ->where('type', 'income')
    ->get();
```

### Send Invoice to Contact Persons

```php
$contact = Contact::find($id);

$recipients = [$contact->email];

foreach ($contact->contact_persons as $person) {
    if ($person->email) {
        $recipients[] = $person->email;
    }
}

// Send to all recipients
Mail::to($recipients)->send(new InvoiceMail($invoice));
```

## Source Map

| Concept | File |
|---------|------|
| Contact model | `app/Models/Common/Contact.php` |
| Contact person model | `app/Models/Common/ContactPerson.php` |
| Contact controller | `app/Http/Controllers/Common/Contacts.php` |
| Create job | `app/Jobs/Common/CreateContact.php` |
| Request validation | `app/Http/Requests/Common/Contact.php` |
| API resource | `app/Http/Resources/Common/Contact.php` |
| Events | `app/Events/Common/Contact*.php` |

## Common Workflows

### Create Customer

```php
$customer = $this->dispatch(new CreateContact(
    auth()->user(),
    [
        'type' => 'customer',
        'name' => 'Acme Corp',
        'email' => 'billing@acme.com',
        'currency_code' => 'USD',
    ],
    auth()->user()->currentCompany()
));
```

### Add Contact Person

```php
$contact->contact_persons()->create([
    'name' => 'John Smith',
    'email' => 'john@acme.com',
]);
```

### Import Contacts from CSV

```php
// Bulk import via CSV/Excel using Import trait
$import = new ContactsImport();
Excel::import($import, 'contacts.xlsx');
```

## Testing

**Feature tests**: `/tests/Feature/Common/Contacts.php`

Key test cases:
- Create customer/vendor
- Add contact persons
- Update contact
- Delete contact (soft delete)
- Query by type
- Authorization checks

---

## Related Pages

- [Companies & Multi-Tenancy](companies.md) – Company context for contacts
- [Invoices](../documents/invoices.md) – Customer invoicing
- [Bills](../documents/bills.md) – Vendor purchases
- [Banking Transactions](../banking/transactions.md) – Transaction recording with contacts
