---
type: system-guide
title: API Authentication & Authorization
description: Bearer tokens, Basic auth, OAuth, scopes, and permission checking for API access.
tags: [api, authentication, authorization, tokens, oauth]
---

# API Authentication & Authorization

Akaunting API supports multiple authentication methods for different use cases: Bearer tokens (most common), Basic authentication, and extensible OAuth 2.0 support.

## Bearer Token Authentication

### Overview

Bearer tokens are the primary authentication method for API clients. They provide:
- Stateless authentication (no server-side sessions)
- Scalable for distributed systems
- Secure credential transmission
- Granular scopes for permission control

### Token Generation

#### Via Admin Panel

1. Navigate to Settings → API Tokens
2. Click "Generate New Token"
3. Enter token name (e.g., "Mobile App Integration")
4. Select scopes (read, write)
5. Click Generate
6. Copy token immediately (shown only once)

#### Via API

```bash
POST /api/auth/tokens
Authorization: Bearer {existing_token}
Content-Type: application/json

{
  "name": "Integration Name",
  "scopes": ["read", "write"]
}

Response:
{
  "data": {
    "id": 1,
    "name": "Integration Name",
    "plain_text_token": "abc123xyz789..."  # Only shown once!
  }
}
```

#### Programmatically (Internal)

```php
// In application code
$user = User::find(1);
$token = $user->createToken('MyIntegration', ['read', 'write']);
$plainToken = $token->plainTextToken;  // Share with consumer
```

### Using Bearer Token

#### In HTTP Request

```bash
curl -H "Authorization: Bearer abc123xyz789" \
     https://api.example.com/api/documents
```

#### In Code

```python
# Python
import requests

headers = {
    'Authorization': 'Bearer abc123xyz789',
    'Content-Type': 'application/json'
}

response = requests.get('https://api.example.com/api/documents', headers=headers)
```

```javascript
// JavaScript/Node.js
const axios = require('axios');

const client = axios.create({
  baseURL: 'https://api.example.com/api',
  headers: {
    'Authorization': 'Bearer abc123xyz789'
  }
});

client.get('/documents').then(response => {
  console.log(response.data);
});
```

```php
// PHP
$client = new \GuzzleHttp\Client([
    'base_uri' => 'https://api.example.com/api',
    'headers' => [
        'Authorization' => 'Bearer abc123xyz789'
    ]
]);

$response = $client->get('documents');
$data = json_decode($response->getBody());
```

### Token Storage

Tokens stored encrypted in `personal_access_tokens` table:

```
id | tokenable_type | tokenable_id | name | token | abilities | last_used_at | expires_at | created_at | updated_at
```

**Security**:
- Tokens hashed using SHA-256
- Only plain text shown at creation (never retrievable)
- Expiry can be set per token
- Last used timestamp tracked for audit

### Token Revocation

#### Via Admin Panel

1. Settings → API Tokens
2. Find token
3. Click Delete

#### Via API

```bash
DELETE /api/auth/tokens/{token_id}
Authorization: Bearer {existing_token}

Response: 204 No Content
```

#### Programmatically

```php
$user->tokens()->find($tokenId)->delete();
```

### Token Expiry

Set expiry at token creation:

```php
$token = $user->createToken('MyToken');
$token->accessToken()->update([
    'expires_at' => now()->addDays(30)
]);
```

**Behavior**: Expired tokens return 401 Unauthorized. Clients should rotate tokens before expiry.

---

## Basic Authentication

### Overview

Basic auth encodes username and password in the Authorization header. Simpler than tokens but less secure.

### Usage

```bash
curl -u username@example.com:password \
     https://api.example.com/api/documents
```

Or explicit Authorization header:

```bash
# Base64 encode: username:password
Authorization: Basic dXNlcm5hbWVAZXhhbXBsZS5jb206cGFzc3dvcmQ=
```

### Implementation

**Middleware**: `App\Http\Middleware\AuthenticateOnceWithBasicAuth`

Checks:
1. Extract credentials from header
2. Find user by email
3. Verify password
4. Return 401 if invalid

### When to Use

- Simple scripts and webhooks
- Testing (don't expose passwords in code)
- Legacy systems
- Trust relationship with API consumer

**Avoid** for production applications. Use Bearer tokens instead.

---

## Scopes & Permissions

### API Access Permission

To use API at all, user must have `read-api` permission.

**Checking**:
```php
// Middleware in routes/api.php
'permission:read-api'
```

### Token Scopes

Scopes control what API endpoints a token can access.

**Available Scopes**:
- `read`: Read-only operations (GET)
- `write`: Write operations (POST, PUT, PATCH, DELETE)
- `admin`: Administrative operations (user management, settings)

**Custom Scopes** (if implementing):
- `read-invoices`: Only read invoices
- `write-documents`: Only write documents
- `read-banking`: Only read banking data

### Scope Validation

**In Routes**:
```php
Route::group(['middleware' => 'scopes:read'], function () {
    Route::get('documents', ...);  // Only accessible with 'read' scope
});
```

**In Policy**:
```php
public function create(User $user, Document $document)
{
    return $user->tokenCan('write');
}
```

### Checking Scopes

```php
// In controller
if (! auth()->user()->tokenCan('read')) {
    abort(403);
}

// In middleware
public function handle($request, Closure $next)
{
    if ($request->user() && ! $request->user()->tokenCan('write')) {
        abort(403);
    }
    
    return $next($request);
}
```

---

## OAuth 2.0 (Extensible)

While not yet built-in, Akaunting can be extended with OAuth 2.0 via Laravel Passport.

### Use Cases

- Third-party apps requesting user authorization
- User delegates access to app for specific scopes
- User can revoke access at any time

### Implementation Pattern

If implementing OAuth:

1. Install Passport: `composer require laravel/passport`
2. Configure in Laravel's Passport service provider
3. Create OAuth routes in `routes/api.php` or separate OAuth route file
4. Users grant access to third-party apps
5. App receives authorization code
6. Code exchanged for access token
7. Token used for API calls

Reference: [Laravel Passport Documentation](https://laravel.com/docs/11/passport)

---

## Company Context

API requests must identify a company context.

### Company Identification

**Via Middleware**: `App\Http\Middleware\IdentifyCompany`

Extracts company_id from:
1. URL parameter: `/api/documents?company_id=1`
2. Header: `X-Company-ID: 1`
3. Session (if web-based auth)

Validates user has access to requested company:
```php
if (! auth()->user()->companies()->find($company_id)) {
    abort(403);  // User doesn't have access to this company
}
```

### Default Company

If no company specified, uses user's default/first company:
```php
$company_id = company_id() ?? auth()->user()->companies()->first()->id;
```

### Multi-Company API Usage

```bash
# Specify company
GET /api/documents?company_id=1

# Or via header
curl -H "X-Company-ID: 1" https://api.example.com/api/documents

# List documents across all user's companies
GET /api/documents?all_companies=true
```

---

## Rate Limiting

### Per-User Limits

**Default**: 60 requests per minute per authenticated user

**Configuration**:
```php
// config/api.php or env
API_RATE_LIMIT=60
API_RATE_PERIOD=60  // seconds
```

### Response Headers

```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1640000000  // Unix timestamp
```

### Handling Rate Limits

When limit exceeded:

```json
{
  "errors": [
    {
      "status": 429,
      "code": "TOO_MANY_REQUESTS",
      "title": "Too Many Requests",
      "detail": "You have exceeded the rate limit. Please retry after 60 seconds.",
      "meta": {
        "retry_after": 60
      }
    }
  ]
}
```

**Retry Strategy**:
```python
import time
import requests

while True:
    response = requests.get(url, headers=headers)
    
    if response.status_code == 429:
        retry_after = int(response.headers.get('Retry-After', 60))
        print(f"Rate limited. Retrying after {retry_after}s")
        time.sleep(retry_after)
        continue
    
    break
```

### Requesting Higher Limits

Contact support to increase rate limits for production integrations.

---

## Security Best Practices

### Token Storage

**DO**:
- Store tokens in secure server-side storage
- Use environment variables for tokens in scripts
- Rotate tokens periodically (e.g., monthly)
- Use different tokens for different environments (dev, staging, production)

**DON'T**:
- Commit tokens to version control
- Store tokens in client-side code (browser)
- Share tokens with other applications
- Use same token across multiple environments

### Over-The-Wire Security

**Always use HTTPS**: Never transmit tokens over HTTP.

```bash
# GOOD
curl -H "Authorization: Bearer token" https://api.example.com/...

# BAD
curl -H "Authorization: Bearer token" http://api.example.com/...
```

### Token Rotation

Implement token rotation for long-lived integrations:

```python
# Periodically refresh token
def rotate_token():
    # Create new token
    new_response = requests.post(
        'https://api.example.com/api/auth/tokens',
        headers={'Authorization': f'Bearer {old_token}'},
        json={'name': 'Rotated Token'}
    )
    
    new_token = new_response.json()['data']['plain_text_token']
    
    # Store new token
    save_token(new_token)
    
    # Delete old token
    delete_old_token()
```

### Webhook Signatures

When sending webhooks to external services, sign requests:

```php
$signature = hash_hmac('sha256', $payload, $webhook_secret);

// Send signature in header
$headers['X-Webhook-Signature'] = $signature;
```

Consumer verifies:
```python
import hmac

received_signature = request.headers.get('X-Webhook-Signature')
calculated_signature = hmac.new(
    webhook_secret.encode(),
    request.data,
    hashlib.sha256
).hexdigest()

assert calculated_signature == received_signature
```

---

## Audit & Monitoring

### Token Usage

Track which tokens accessed what:

```php
// Token last used at timestamp
$token->last_used_at;

// Monitor via logs
$user->tokens()->each(function ($token) {
    if ($token->last_used_at?->isOlderThan('30 days')) {
        notify_user_unused_token($token);
    }
});
```

### Access Logs

Log all API requests with:
- User ID
- Token ID
- Endpoint
- Method
- Response code
- Timestamp

Stored in `api_logs` table for audit trail.

---

## Troubleshooting

### 401 Unauthorized

Causes:
1. Token invalid or expired
2. Token not provided
3. User disabled
4. Company access revoked

**Solution**: Verify token is current and user has access.

### 403 Forbidden

Causes:
1. User lacks permission
2. Token scopes insufficient
3. Company access denied
4. Read-only mode enabled

**Solution**: Check user permissions and token scopes.

### Token Not Appearing

Token only shown at creation; cannot be retrieved. If lost:
1. Delete lost token
2. Create new token
3. Update client configuration

---

*Reference: /app/Http/Middleware/AuthenticateOnceWithDynamicApi, /app/Http/Middleware/AuthenticateOnceWithBasicAuth, /app/Traits/HasApiTokens*
