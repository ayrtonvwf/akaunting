---
type: system-overview
title: RESTful API Overview
description: API architecture, authentication, response formats, pagination, and error handling in Akaunting.
tags: [api, rest, json, endpoints]
---

# RESTful API Overview

Akaunting provides a complete RESTful API for programmatic access to all accounting operations. The API uses JSON for all request/response payloads and supports multiple authentication methods.

## API Architecture

### Base URL

```
https://your-akaunting-instance.com/api
```

### Routing

**File**: `routes/api.php`

**Middleware Stack**:
```php
'api' => [
    'header.www.authenticate',         // WWW-Authenticate header
    'auth.dynamic.once',               // Bearer or Basic auth auto-detect
    'auth.disabled',                   // Check if auth disabled
    'throttle:api',                    // Rate limiting
    'permission:read-api',             // API access permission
    'company.identify',                // Set company context
    'bindings',                        // Model binding
    'read.only',                       // Check read-only mode
    'language',                        // Locale negotiation
    'firewall.all',                    // IP firewall
]
```

All API routes protected by authentication and permissions.

### API Prefix

All routes prefixed with `/api/`:
```
GET /api/documents
POST /api/documents
PATCH /api/documents/{id}
DELETE /api/documents/{id}
```

---

## Response Structure

### Success Response (200, 201)

```json
{
  "data": {
    "id": 1,
    "type": "document",
    "attributes": {
      "document_number": "INV-001",
      "status": "draft",
      "amount": 1500.00,
      "issued_at": "2024-01-15T00:00:00Z",
      "contact": {
        "id": 10,
        "name": "Acme Corp"
      }
    },
    "relationships": {
      "contact": { ... },
      "items": { ... },
      "totals": { ... }
    }
  }
}
```

### Collection Response (200)

```json
{
  "data": [
    { ... },
    { ... },
    { ... }
  ],
  "meta": {
    "pagination": {
      "total": 50,
      "count": 10,
      "per_page": 10,
      "current_page": 1,
      "total_pages": 5,
      "links": {
        "first": "/api/documents?page=1",
        "next": "/api/documents?page=2",
        "prev": null,
        "last": "/api/documents?page=5"
      }
    }
  }
}
```

### Error Response (4xx, 5xx)

```json
{
  "errors": [
    {
      "status": 422,
      "code": "VALIDATION_FAILED",
      "title": "Unprocessable Entity",
      "detail": "The given data was invalid",
      "source": {
        "pointer": "/data/attributes/email"
      },
      "meta": {
        "field": "email",
        "message": "The email has already been taken."
      }
    }
  ]
}
```

---

## Authentication

### Supported Methods

#### 1. Bearer Token (Recommended)

```bash
curl -H "Authorization: Bearer {token}" https://api.example.com/api/documents
```

**Token Generation**:
```php
// In admin panel or via API
$token = auth()->user()->createToken('MyAppName');
$accessToken = $token->plainTextToken;  // Share with API consumer
```

**Implementation**: Laravel Sanctum

#### 2. Basic Authentication

```bash
curl -u user@example.com:password https://api.example.com/api/documents
```

Encodes credentials as base64 and sends in Authorization header.

**When to Use**: Simple integrations, less secure than Bearer tokens.

**Middleware**: `AuthenticateOnceWithBasicAuth` (basic_auth guard)

#### 3. OAuth 2.0 (Future)

OAuth support can be added via Passport package for advanced scenarios.

### Authentication Middleware

**File**: `app/Http/Middleware/AuthenticateOnceWithDynamicApi.php`

Automatically detects and validates:
1. Bearer token (Sanctum)
2. Basic auth credentials
3. Returns `401 Unauthorized` if invalid

**Usage**:
```php
// In routes/api.php
Route::group(['middleware' => 'auth.dynamic.once'], function () {
    Route::get('documents', ...);
});
```

### API Key/Token Management

**Create Token**:
```bash
POST /api/auth/tokens
{
  "name": "My Integration"
}

Response:
{
  "token": "abc123...",
  "plain_text_token": "abc123..."  // Only shown once
}
```

**Revoke Token**:
```bash
DELETE /api/auth/tokens/{id}
```

**List Tokens**:
```bash
GET /api/auth/tokens
```

Reference: [API Authentication](authentication.md)

---

## Pagination

Default page size: 25 items (configurable per app setting)

### Query Parameters

```bash
GET /api/documents?page=2&limit=50
```

**Parameters**:
- `page`: Page number (1-indexed)
- `limit`: Results per page (max 100)

### Response Meta

```json
{
  "meta": {
    "pagination": {
      "total": 523,
      "count": 50,
      "per_page": 50,
      "current_page": 2,
      "total_pages": 11,
      "from": 51,
      "to": 100,
      "links": {
        "first": "/api/documents?page=1&limit=50",
        "last": "/api/documents?page=11&limit=50",
        "prev": "/api/documents?page=1&limit=50",
        "next": "/api/documents?page=3&limit=50"
      }
    }
  }
}
```

---

## Filtering & Search

### Query String Filtering

```bash
GET /api/documents?status=paid&contact_id=10
```

Filters applied via query builder where clauses.

### Search String Syntax

Advanced search via Laravel Search String package:

```bash
GET /api/documents?search=status:paid contact_id:10 amount>1000

# Complex filters
GET /api/documents?search=status:(paid,partial) issued_at>=2024-01-01 issued_at<=2024-12-31
```

Supported operators: `=`, `!=`, `>`, `<`, `>=`, `<=`, `:` (in), `:!` (not in)

---

## Sorting

```bash
GET /api/documents?sort=issued_at,-amount

# Descending (prefix with -)
GET /api/documents?sort=-created_at

# Multiple fields
GET /api/documents?sort=contact_id,-issued_at
```

---

## Resource Transformation

### Resource Classes

Each API response uses a Resource class for transformation:

**Example**: `App\Http\Resources\Document\Document`

```php
class Document extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'type' => $this->type,
            'attributes' => [
                'document_number' => $this->document_number,
                'status' => $this->status,
                'amount' => $this->amount,
                'issued_at' => $this->issued_at?->toIso8601String(),
            ],
            'relationships' => [
                'contact' => $this->when($this->relationLoaded('contact'), new Contact($this->contact)),
                'items' => $this->when($this->relationLoaded('items'), Item::collection($this->items)),
            ],
        ];
    }
}
```

**Features**:
- Conditional attribute inclusion via `$this->when()`
- Relationship loading control
- Date formatting standardization
- Field filtering per request

### Eager Loading

API endpoints eager-load relationships to minimize queries:

```php
// Controller index method
$documents = Document::with('contact', 'items', 'items.taxes', 'totals')
    ->collect(['issued_at' => 'desc']);

return DocumentResource::collection($documents);
```

---

## HTTP Methods & Status Codes

### Standard CRUD

| Method | Route | Status | Purpose |
|--------|-------|--------|---------|
| GET | /api/documents | 200 | List documents |
| GET | /api/documents/{id} | 200 | Fetch document |
| POST | /api/documents | 201 | Create document |
| PATCH | /api/documents/{id} | 200 | Update document |
| DELETE | /api/documents/{id} | 204 | Delete document |

### Custom Actions

```
POST   /api/documents/{id}/send          – Send document (email)
GET    /api/documents/{id}/received      – Mark bill as received
POST   /api/documents/{id}/transactions  – Link transaction to document
```

### Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK (successful GET, PATCH, POST response) |
| 201 | Created (successful POST) |
| 204 | No Content (successful DELETE) |
| 400 | Bad Request (malformed syntax) |
| 401 | Unauthorized (invalid/missing auth) |
| 403 | Forbidden (auth valid but permission denied) |
| 404 | Not Found (resource doesn't exist) |
| 422 | Unprocessable Entity (validation failed) |
| 429 | Too Many Requests (rate limited) |
| 500 | Internal Server Error |

---

## Rate Limiting

**Configuration**: `config/api.php` and `config/throttle`

**Default**: 60 requests per minute per authenticated user

**Headers**:
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1640000000
```

**Exceeded**: Returns 429 status with Retry-After header.

---

## CORS & Headers

### CORS Configuration

**File**: `config/cors.php`

**Allowed Origins**: Configured in app settings or env variable

```php
'allowed_origins' => ['https://trusted-domain.com'],
```

**Allowed Methods**: GET, POST, PUT, PATCH, DELETE, OPTIONS

**Allowed Headers**: Authorization, Content-Type, Accept, etc.

### Custom Headers

**Response Headers**:
```
WWW-Authenticate: Bearer realm="api"     (on 401)
X-Total-Count: 523                        (collection count)
X-Response-Time: 142ms                    (API profiling)
```

---

## Error Handling

### Validation Errors

```json
{
  "errors": [
    {
      "status": 422,
      "code": "VALIDATION_ERROR",
      "title": "Unprocessable Entity",
      "detail": "Validation failed",
      "source": {
        "pointer": "/data/attributes/email"
      },
      "meta": {
        "field": "email",
        "messages": ["The email has already been taken."]
      }
    }
  ]
}
```

### Authorization Errors

```json
{
  "errors": [
    {
      "status": 403,
      "code": "INSUFFICIENT_PERMISSION",
      "title": "Forbidden",
      "detail": "You do not have permission to create invoices"
    }
  ]
}
```

### Not Found

```json
{
  "errors": [
    {
      "status": 404,
      "code": "RESOURCE_NOT_FOUND",
      "title": "Not Found",
      "detail": "Document ID 999 not found"
    }
  ]
}
```

---

## API Request Examples

### Create Invoice

```bash
POST /api/documents HTTP/1.1
Authorization: Bearer abc123...
Content-Type: application/json

{
  "type": "invoice",
  "contact_id": 10,
  "issued_at": "2024-01-15",
  "due_at": "2024-02-15",
  "items": [
    {
      "name": "Consulting",
      "description": "Monthly consulting",
      "quantity": 1,
      "price": 5000.00,
      "tax_id": 1
    }
  ],
  "notes": "Thank you for your business!"
}
```

**Response** (201):
```json
{
  "data": {
    "id": 42,
    "document_number": "INV-001",
    "status": "draft",
    "amount": 6000.00,
    "created_at": "2024-01-15T10:00:00Z"
  }
}
```

### Update Invoice

```bash
PATCH /api/documents/42 HTTP/1.1
Authorization: Bearer abc123...
Content-Type: application/json

{
  "status": "sent",
  "notes": "Updated notes"
}
```

### List Invoices with Filters

```bash
GET /api/documents?type=invoice&status=draft&limit=50&page=1&sort=-issued_at
Authorization: Bearer abc123...
```

### Delete Invoice

```bash
DELETE /api/documents/42
Authorization: Bearer abc123...
```

**Response** (204 No Content)

---

## API Documentation

Live API documentation available at:
```
https://your-akaunting-instance.com/api/docs
```

Or via:
```bash
GET /api/documentation
```

Returns OpenAPI/Swagger spec.

---

## SDK & Libraries

Official/community SDKs available for:
- JavaScript/Node.js
- Python
- PHP
- Ruby
- Go

Reference: [API Endpoints](endpoints.md) for complete endpoint list.

---

*Reference: /routes/api.php, /app/Http/Controllers/Api, /app/Http/Resources, /config/api.php*
