---
type: system-reference
title: API Response Formats
description: Standardized success and error response structures, pagination, and error handling in Akaunting API.
tags: [api, responses, error-handling, json-format]
---

# API Response Formats

All Akaunting API responses follow consistent JSON structures for success, validation errors, and server errors.

## HTTP Status Codes

| Code | Meaning | Usage |
|------|---------|-------|
| 200 | OK | Successful GET, PATCH, PUT |
| 201 | Created | Successful POST (resource created) |
| 204 | No Content | Successful DELETE or empty response |
| 400 | Bad Request | Malformed request syntax |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | Authenticated but lacks permission |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Data conflict (unique constraint, etc.) |
| 422 | Unprocessable Entity | Validation error |
| 429 | Too Many Requests | Rate limited |
| 500 | Server Error | Unexpected server error |

## Success Responses

### Single Resource (200/201)

```json
{
  "id": 1,
  "name": "Main Account",
  "type": "bank",
  "currency_code": "USD",
  "balance": "5000.00",
  "balance_formatted": "$5,000.00",
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-20T15:45:00Z"
}
```

### Collection with Pagination (200)

```json
{
  "data": [
    {
      "id": 1,
      "name": "Invoice #001",
      "type": "invoice",
      "amount": "1000.00",
      "status": "paid",
      "created_at": "2024-01-15T10:30:00Z"
    },
    {
      "id": 2,
      "name": "Invoice #002",
      "type": "invoice",
      "amount": "2500.00",
      "status": "draft",
      "created_at": "2024-01-16T11:00:00Z"
    }
  ],
  "links": {
    "first": "https://api.akaunting.com/api/documents?page=1",
    "last": "https://api.akaunting.com/api/documents?page=5",
    "prev": "https://api.akaunting.com/api/documents?page=1",
    "next": "https://api.akaunting.com/api/documents?page=3"
  },
  "meta": {
    "current_page": 2,
    "from": 16,
    "last_page": 5,
    "per_page": 15,
    "to": 30,
    "total": 73
  }
}
```

### Empty Collection (200)

```json
{
  "data": [],
  "links": {
    "first": "https://api.akaunting.com/api/documents?page=1",
    "last": "https://api.akaunting.com/api/documents?page=1",
    "prev": null,
    "next": null
  },
  "meta": {
    "current_page": 1,
    "from": null,
    "last_page": 1,
    "per_page": 15,
    "to": null,
    "total": 0
  }
}
```

### Delete Success (204)

```
HTTP/1.1 204 No Content
```

(Empty response body)

### Created Resource (201)

```json
{
  "id": 42,
  "name": "New Account",
  "type": "bank",
  "currency_code": "USD",
  "balance": "0.00",
  "created_at": "2024-01-21T08:15:00Z",
  "updated_at": "2024-01-21T08:15:00Z"
}
```

## Validation Error (422)

When request data fails validation:

```json
HTTP/1.1 422 Unprocessable Entity
Content-Type: application/json

{
  "message": "The given data was invalid.",
  "errors": {
    "name": [
      "The name field is required."
    ],
    "email": [
      "The email must be a valid email address.",
      "The email has already been taken."
    ],
    "items": [
      "At least one item is required."
    ],
    "items.0.quantity": [
      "The quantity must be at least 0.01."
    ]
  }
}
```

### Field Error Structure

- **Top-level fields**: Direct validation errors
- **Nested fields**: Array items with dot notation (e.g., `items.0.quantity`)
- **Multiple errors**: Each field can have multiple error messages

### Common Validation Errors

```json
{
  "errors": {
    "contact_id": ["The selected contact id is invalid."],
    "currency_code": ["The selected currency code is invalid."],
    "issued_at": ["The issued at field must be a valid date."],
    "amount": ["The amount must be a number."],
    "items": ["The items field is required."]
  }
}
```

## Authentication Errors

### Missing Authentication (401)

```json
HTTP/1.1 401 Unauthorized
Content-Type: application/json
WWW-Authenticate: Bearer realm="Application", error="invalid_token"

{
  "message": "Unauthenticated."
}
```

### Invalid Token (401)

```json
HTTP/1.1 401 Unauthorized
Content-Type: application/json
WWW-Authenticate: Bearer realm="Application", error="invalid_token"

{
  "message": "Invalid token."
}
```

## Authorization Error (403)

When authenticated but lacking permission:

```json
HTTP/1.1 403 Forbidden
Content-Type: application/json

{
  "message": "This action is unauthorized."
}
```

## Not Found Error (404)

```json
HTTP/1.1 404 Not Found
Content-Type: application/json

{
  "message": "Resource not found."
}
```

Or with more detail:

```json
{
  "message": "The requested resource does not exist.",
  "resource": "documents",
  "id": 9999
}
```

## Rate Limit Error (429)

When rate limit exceeded:

```json
HTTP/1.1 429 Too Many Requests
Content-Type: application/json
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1705945200

{
  "message": "Too many requests. Please try again later."
}
```

## Server Error (500)

Unexpected server error:

```json
HTTP/1.1 500 Internal Server Error
Content-Type: application/json

{
  "message": "An internal error occurred. Please contact support."
}
```

In development mode:

```json
{
  "message": "Error message details",
  "exception": "App\\Exceptions\\CustomException",
  "file": "app/Models/Document/Document.php",
  "line": 45,
  "trace": [...]
}
```

## Conflict Error (409)

Data conflict (unique constraint, business rule, etc.):

```json
HTTP/1.1 409 Conflict
Content-Type: application/json

{
  "message": "Resource conflict.",
  "reason": "Document number INV-001 already exists for this company.",
  "field": "document_number"
}
```

## Error Response Headers

All error responses include standard headers:

```
HTTP/1.1 400 Bad Request
Content-Type: application/json
X-Request-Id: abc123def456
X-Response-Time: 0.125
```

## Nested Resource Responses

When requesting related data:

```
GET /api/documents/1

{
  "id": 1,
  "document_number": "INV-001",
  "contact": {
    "id": 10,
    "name": "Acme Corp",
    "email": "contact@acme.com"
  },
  "items": [
    {
      "id": 1,
      "name": "Consulting Services",
      "quantity": 10,
      "price": "100.00",
      "amount": "1000.00"
    }
  ],
  "totals": [
    {
      "type": "subtotal",
      "label": "Subtotal",
      "amount": "1000.00"
    },
    {
      "type": "tax",
      "label": "Tax (10%)",
      "amount": "100.00"
    },
    {
      "type": "total",
      "label": "Total",
      "amount": "1100.00"
    }
  ]
}
```

## Pagination Headers

Responses include pagination metadata in both body and headers:

```
Link: <...?page=2>; rel="next", <...?page=1>; rel="prev", <...?page=5>; rel="last", <...?page=1>; rel="first"
X-Total-Count: 73
X-Per-Page: 15
X-Current-Page: 1
```

## API Response Wrapper

Some endpoints may wrap responses in a data envelope:

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "..."
  }
}
```

Or for errors:

```json
{
  "success": false,
  "message": "Error description",
  "errors": {}
}
```

## Content Negotiation

Specify response format via Accept header:

```
GET /api/documents
Accept: application/json
```

Response:

```
Content-Type: application/json
```

## Timestamps

All timestamps are in ISO 8601 format with timezone:

```
"created_at": "2024-01-15T10:30:00Z"    # UTC
"created_at": "2024-01-15T10:30:00+02:00"  # With timezone offset
```

## Money/Currency Formatting

Amounts are typically returned in two formats:

```json
{
  "balance": "5000.00",                    # Raw numeric string
  "balance_formatted": "$5,000.00"         # Formatted for display
}
```

## Related Pages

- [API Endpoints Reference](endpoints.md) – Complete endpoint list
- [API Overview](overview.md) – API architecture
- [API Authentication](authentication.md) – Auth methods
