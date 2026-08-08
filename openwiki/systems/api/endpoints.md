---
type: system-reference
title: API Endpoints Reference
description: Complete reference of all RESTful API routes, methods, parameters, and examples for Akaunting operations.
tags: [api, endpoints, rest-routes, http-methods]
---

# API Endpoints Reference

This page provides a comprehensive reference of all available API endpoints organized by resource domain.

## Endpoint Format

All endpoints follow REST conventions:

```
GET    /api/{resource}              # List all
GET    /api/{resource}/{id}         # Get single
POST   /api/{resource}              # Create
PATCH  /api/{resource}/{id}         # Update
DELETE /api/{resource}/{id}         # Delete
GET    /api/{resource}/{id}/{action} # Custom action
```

## Authentication Endpoints

### Ping
```
GET /api/ping
Response: { "pong": true }
```

## User Management

### List Users
```
GET /api/users
Parameters:
  - page: int (default: 1)
  - per_page: int (default: 15)
```

### Get User
```
GET /api/users/{user_id}
```

### Create User
```
POST /api/users
Body:
  - email: required, email
  - password: required, min:6
  - name: required
```

### Update User
```
PATCH /api/users/{user_id}
Body: (all fields optional)
  - email
  - name
  - password
```

### Delete User
```
DELETE /api/users/{user_id}
```

### Enable User
```
GET /api/users/{user_id}/enable
```

### Disable User
```
GET /api/users/{user_id}/disable
```

## Company Management

### List Companies
```
GET /api/companies
```

### Get Company
```
GET /api/companies/{company_id}
```

### Create Company
```
POST /api/companies
Body:
  - name: required, string
  - country: required, string (2-letter code)
  - currency_code: required, string (3-letter code)
  - tax_number: optional, string
```

### Update Company
```
PATCH /api/companies/{company_id}
Body: (fields optional)
  - name
  - country
  - currency_code
  - timezone
  - locale
```

### Delete Company
```
DELETE /api/companies/{company_id}
```

### Check Company Access
```
GET /api/companies/{company_id}/owner
Response: { "owner": true/false }
```

### Enable Company
```
GET /api/companies/{company_id}/enable
```

### Disable Company
```
GET /api/companies/{company_id}/disable
```

## Documents (Invoices & Bills)

### List Documents
```
GET /api/documents
Query Parameters:
  - type: invoice|bill|invoice-recurring|bill-recurring
  - status: draft|sent|viewed|approved|partial|paid
  - page: int
  - per_page: int
```

### Get Document
```
GET /api/documents/{document_id}
Response: Detailed document with items, totals, transactions
```

### Create Document
```
POST /api/documents
Body:
  - type: required, enum
  - contact_id: required, integer
  - currency_code: required, string
  - issued_at: required, date (Y-m-d)
  - due_at: optional, date (Y-m-d)
  - discount_type: optional, percent|fixed
  - discount_rate: optional, numeric
  - notes: optional, string
  - items: required, array
    - item_id: required
    - quantity: required, numeric
    - price: required, numeric
```

### Update Document
```
PATCH /api/documents/{document_id}
Body: (most fields optional)
  - type
  - contact_id
  - currency_code
  - issued_at
  - due_at
  - notes
  - items: (replaces all items)
```

### Delete Document
```
DELETE /api/documents/{document_id}
Only allowed if status is 'draft'
```

### Mark Document as Received
```
GET /api/documents/{document_id}/received
For bills: marks as received
```

## Document Line Items

### List Document Items
```
GET /api/documents/{document_id}/items
```

### Document Transactions (Payments)
```
GET /api/documents/{document_id}/transactions
Returns all payments related to document
```

## Banking Endpoints

### List Bank Accounts
```
GET /api/accounts
```

### Get Bank Account
```
GET /api/accounts/{account_id}
```

### Create Bank Account
```
POST /api/accounts
Body:
  - name: required, string
  - type: required, bank|cash|credit
  - currency_code: required, string
  - opening_balance: optional, numeric
  - bank_name: optional, string
  - bank_phone: optional, string
  - bank_address: optional, string
```

### Update Bank Account
```
PATCH /api/accounts/{account_id}
Body: (fields optional)
  - name
  - type
  - currency_code
  - bank_name
  - bank_phone
  - bank_address
```

### Delete Bank Account
```
DELETE /api/accounts/{account_id}
```

### Enable Account
```
GET /api/accounts/{account_id}/enable
```

### Disable Account
```
GET /api/accounts/{account_id}/disable
```

## Transactions

### List Transactions
```
GET /api/transactions
Query Parameters:
  - type: income|expense|transfer
  - account_id: filter by account
  - category_id: filter by category
  - page: int
  - per_page: int
```

### Get Transaction
```
GET /api/transactions/{transaction_id}
```

### Create Transaction
```
POST /api/transactions
Body:
  - type: required, income|expense|transfer
  - account_id: required, integer
  - category_id: required, integer (optional for transfer)
  - contact_id: optional, integer
  - amount: required, numeric
  - description: optional, string
  - reference: optional, string
  - transaction_date: required, date (Y-m-d)
```

### Update Transaction
```
PATCH /api/transactions/{transaction_id}
Body: (fields optional)
  - type
  - account_id
  - category_id
  - amount
  - description
  - reference
  - transaction_date
```

### Delete Transaction
```
DELETE /api/transactions/{transaction_id}
```

## Transfers

### List Transfers
```
GET /api/transfers
```

### Get Transfer
```
GET /api/transfers/{transfer_id}
```

### Create Transfer
```
POST /api/transfers
Body:
  - from_account_id: required, integer
  - to_account_id: required, integer
  - amount: required, numeric
  - transfer_date: required, date
  - description: optional, string
```

### Update Transfer
```
PATCH /api/transfers/{transfer_id}
```

### Delete Transfer
```
DELETE /api/transfers/{transfer_id}
```

## Bank Reconciliation

### List Reconciliations
```
GET /api/reconciliations
```

### Get Reconciliation
```
GET /api/reconciliations/{reconciliation_id}
```

### Create Reconciliation
```
POST /api/reconciliations
Body:
  - account_id: required, integer
  - closing_balance: required, numeric
  - closing_date: required, date
  - transactions: optional, array of transaction_ids
```

### Update Reconciliation
```
PATCH /api/reconciliations/{reconciliation_id}
```

### Delete Reconciliation
```
DELETE /api/reconciliations/{reconciliation_id}
```

## Contacts

### List Contacts
```
GET /api/contacts
Query Parameters:
  - type: customer|vendor
  - page: int
  - per_page: int
```

### Get Contact
```
GET /api/contacts/{contact_id}
```

### Create Contact
```
POST /api/contacts
Body:
  - type: required, customer|vendor
  - name: required, string
  - email: optional, email
  - phone: optional, string
  - tax_number: optional, string
  - address: optional, string
  - city: optional, string
  - state: optional, string
  - country: optional, string (2-letter code)
  - zip_code: optional, string
```

### Update Contact
```
PATCH /api/contacts/{contact_id}
Body: (fields optional)
```

### Delete Contact
```
DELETE /api/contacts/{contact_id}
```

### Enable Contact
```
GET /api/contacts/{contact_id}/enable
```

### Disable Contact
```
GET /api/contacts/{contact_id}/disable
```

## Items (Products/Services)

### List Items
```
GET /api/items
```

### Get Item
```
GET /api/items/{item_id}
```

### Create Item
```
POST /api/items
Body:
  - name: required, string
  - category_id: optional, integer
  - description: optional, string
  - quantity: optional, numeric
  - unit: optional, string
  - price: required, numeric
  - tax_ids: optional, array of tax_ids
```

### Update Item
```
PATCH /api/items/{item_id}
```

### Delete Item
```
DELETE /api/items/{item_id}
```

### Enable Item
```
GET /api/items/{item_id}/enable
```

### Disable Item
```
GET /api/items/{item_id}/disable
```

## Settings

### Categories

```
GET    /api/categories              # List
GET    /api/categories/{id}         # Get
POST   /api/categories              # Create
PATCH  /api/categories/{id}         # Update
DELETE /api/categories/{id}         # Delete
GET    /api/categories/{id}/enable  # Enable
GET    /api/categories/{id}/disable # Disable
```

### Currencies

```
GET    /api/currencies              # List
GET    /api/currencies/{id}         # Get
POST   /api/currencies              # Create
PATCH  /api/currencies/{id}         # Update
DELETE /api/currencies/{id}         # Delete
GET    /api/currencies/{id}/enable  # Enable
GET    /api/currencies/{id}/disable # Disable
```

### Taxes

```
GET    /api/taxes                   # List
GET    /api/taxes/{id}              # Get
POST   /api/taxes                   # Create
PATCH  /api/taxes/{id}              # Update
DELETE /api/taxes/{id}              # Delete
GET    /api/taxes/{id}/enable       # Enable
GET    /api/taxes/{id}/disable      # Disable
```

### Application Settings

```
GET    /api/settings                # Get all settings
PATCH  /api/settings                # Update settings
```

## Reports

### List Reports
```
GET /api/reports
```

### Get Report
```
GET /api/reports/{report_id}
```

### Create Report
```
POST /api/reports
Body:
  - name: required, string
  - type: required, string
  - class: optional, string
```

### Update Report
```
PATCH /api/reports/{report_id}
```

### Delete Report
```
DELETE /api/reports/{report_id}
```

## Dashboards

### List Dashboards
```
GET /api/dashboards
```

### Get Dashboard
```
GET /api/dashboards/{dashboard_id}
```

### Create Dashboard
```
POST /api/dashboards
Body:
  - name: required, string
```

### Update Dashboard
```
PATCH /api/dashboards/{dashboard_id}
```

### Delete Dashboard
```
DELETE /api/dashboards/{dashboard_id}
```

### Enable Dashboard
```
GET /api/dashboards/{dashboard_id}/enable
```

### Disable Dashboard
```
GET /api/dashboards/{dashboard_id}/disable
```

## Query Parameters

### Pagination

```
?page=2&per_page=50
```

### Filtering

```
?filter[status]=paid&filter[type]=invoice
```

### Sorting

```
?sort=name                    # Ascending
?sort=-created_at             # Descending
```

### Including Related Data

```
?include=contact,items        # Eager load relations
```

### Field Selection

```
?fields=id,name,email         # Select specific fields
```

## Related Pages

- [API Overview](overview.md) – API architecture and setup
- [API Authentication](authentication.md) – Authentication methods
- [Response Formats](responses.md) – Response structure and error handling

## Source Map

```
routes/
└─ api.php

app/Http/Controllers/Api/
├─ Auth/
├─ Banking/
├─ Common/
├─ Document/
└─ Settings/

app/Http/Resources/
└─ {Domain}/*.php
```
