---
type: system-reference
title: Frontend Overview - Vue.js & Tailwind Architecture
description: Frontend technology stack, Vue.js component architecture, Tailwind CSS configuration, and asset compilation.
tags: [frontend, vue.js, tailwind-css, spa, javascript]
openwiki:
  source_paths: [resources/assets, resources/views, webpack.mix.js, tailwind.config.js]
---

# Frontend Overview

The Akaunting frontend is built with Vue.js 2, Tailwind CSS, and Laravel Blade templates. It provides a responsive, interactive user interface with real-time component updates.

## Technology Stack

| Technology | Purpose | Version |
|-----------|---------|---------|
| **Vue.js** | Client-side framework | 2.x |
| **Tailwind CSS** | Utility-first CSS framework | Latest |
| **Blade** | Server-side templating | Laravel 10 |
| **Livewire** | Real-time components | v3 |
| **Webpack** | Asset bundling and compilation | 5.x |
| **npm** | Package management | Latest |

## Project Structure

```
resources/
├─ assets/
│  ├─ css/
│  │  ├─ app.css               # Main stylesheet (Tailwind)
│  │  ├─ creditcard/           # Credit card specific styles
│  │  └─ tailwind.css          # Tailwind directives
│  ├─ js/
│  │  ├─ app.js               # Vue.js entry point
│  │  ├─ components/          # Vue components
│  │  ├─ directives/          # Custom Vue directives
│  │  ├─ mixins/              # Vue mixins
│  │  ├─ plugins/             # Vue plugins
│  │  ├─ exceptions/          # Error handling
│  │  └─ bootstrap.js         # Vue initialization
│  └─ lang/
│     └─ {locale}/            # Frontend translations
│
├─ views/
│  ├─ layouts/
│  │  ├─ app.blade.php        # Main layout
│  │  ├─ auth.blade.php       # Auth layout
│  │  └─ plain.blade.php      # Plain layout (no sidebar)
│  ├─ {domain}/               # Views by domain (sales, banking, etc)
│  └─ components/             # Reusable Blade components
│
└─ lang/
   └─ {locale}/               # Backend translations
```

## Vue Components

**Location**: `resources/assets/js/components/`

### Component Structure

```
components/
├─ Inputs/
│  ├─ MoneyInput.vue          # Currency-formatted input
│  ├─ DatePicker.vue          # Date selection
│  └─ SearchableSelect.vue    # Autocomplete dropdown
├─ Cards/
│  ├─ SummaryCard.vue         # Stats card
│  └─ InfoCard.vue            # Information card
├─ CreditCard/
│  └─ CreditCard.vue          # Credit card display
└─ Tables/
   ├─ DataTable.vue           # Sortable data table
   └─ InlineEdit.vue          # Inline row editing
```

### Common Components

| Component | File | Usage |
|-----------|------|-------|
| **MoneyInput** | `Inputs/MoneyInput.vue` | Currency input with formatting |
| **DatePicker** | `Inputs/DatePicker.vue` | Date selection with calendar |
| **SelectInput** | `Inputs/SelectInput.vue` | Dropdown with search |
| **DataTable** | `Tables/DataTable.vue` | Paginated, sortable table |
| **Card** | `Cards/SummaryCard.vue` | Stats/info card |
| **Modal** | `Modal.vue` | Dialog/confirmation modal |

### Component Props & Slots

```vue
<template>
  <DataTable
    :items="invoices"
    :columns="['number', 'customer', 'amount', 'status']"
    :loading="loading"
    @row-click="viewInvoice"
  >
    <template #header>
      <h1>Invoices</h1>
    </template>
    
    <template #amount="{ item }">
      {{ formatMoney(item.amount) }}
    </template>
  </DataTable>
</template>

<script>
export default {
  data() {
    return {
      invoices: [],
      loading: false
    }
  }
}
</script>
```

## CSS & Styling

### Tailwind Configuration

**File**: `tailwind.config.js`

```javascript
module.exports = {
  content: [
    './resources/views/**/*.blade.php',
    './resources/assets/js/**/*.vue',
    './resources/assets/js/**/*.js',
  ],
  theme: {
    extend: {
      colors: {
        primary: '#667eea',
        secondary: '#764ba2',
      },
      spacing: {
        // Custom spacing
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}
```

### Asset Files

**CSS**: `resources/assets/sass/app.css`

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Custom styles */
.btn-primary {
  @apply px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700;
}

.input-group {
  @apply flex items-center gap-2;
}
```

## Asset Compilation

### Webpack Configuration

**File**: `webpack.mix.js`

```javascript
const mix = require('laravel-mix');
require('laravel-mix-tailwind');

mix
    .setPublicPath('public/')
    .webpackConfig({
        output: {
            publicPath: 'public/js/',
            filename: '[name].js',
            chunkFilename: '[name].js',
        },
        stats: {
            children: true
        },
    })
    .options({
        terser: {
            extractComments: false,
        }
    })

    // ~22 .js() entries, one per feature area, each compiled to its own
    // public/js/<area>/<name>.min.js bundle — grouped as Auth, Banking,
    // Common, Install, Wizard, Modules, Portal, and Settings. For example:
    .js('resources/assets/js/views/auth/common.js', 'public/js/auth/common.min.js')
    .js('resources/assets/js/views/banking/accounts.js', 'public/js/banking/accounts.min.js')
    .js('resources/assets/js/views/common/documents.js', 'public/js/common/documents.min.js')
    // ...(see webpack.mix.js for the full, current list)

    .vue()

    .postCss('resources/assets/sass/app.css', 'public/css', [
        require('tailwindcss')
    ])
    .tailwind('./tailwind.config.js')

    if (mix.inProduction()) {
        mix.version()
    }
```

This is a condensed, verified reproduction of the real `webpack.mix.js` at the repository root — read that file directly for the complete, current entry list rather than treating this as exhaustive.

### Build Commands

```bash
# Development build with watch
npm run dev

# Production build (minified)
npm run prod

# Watch for changes
npm run watch

# Build and start dev server
npm run hot
```

### Output Files

```
public/
├─ js/
│  ├─ app.js
│  ├─ app.js.map
│  └─ manifest.json
├─ css/
│  ├─ app.css
│  └─ app.css.map
└─ mix-manifest.json        # Asset version hashes
```

## Blade Templates & Layouts

### Main Layout

**File**: `resources/views/components/layouts/admin.blade.php`

```blade
<!DOCTYPE html>
<html lang="{{ app()->getLocale() }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('title', 'Akaunting')</title>
    <link href="{{ mix('css/app.css') }}" rel="stylesheet">
</head>
<body>
    <div id="app" class="min-h-screen">
        <nav class="bg-white shadow">
            <!-- Navigation -->
        </nav>
        
        <main class="container mx-auto py-6">
            @yield('content')
        </main>
    </div>
    
    <script src="{{ mix('js/app.js') }}"></script>
</body>
</html>
```

### Form Component

**File**: `resources/views/components/form/index.blade.php`

```blade
<form method="{{ $method ?? 'POST' }}" action="{{ $action }}" class="space-y-4">
    @csrf
    
    {{ $slot }}
    
    <div class="flex gap-2">
        <button type="submit" class="btn btn-primary">Save</button>
        <a href="{{ $cancel ?? 'javascript:history.back()' }}" class="btn btn-gray">Cancel</a>
    </div>
</form>
```

### Usage

```blade
<x-form method="PATCH" action="{{ route('invoices.update', $invoice) }}">
    <x-input name="document_number" label="Invoice #" value="{{ $invoice->document_number }}" />
    <x-money-input name="amount" label="Amount" value="{{ $invoice->amount }}" />
    <x-select name="status" label="Status" :options="['draft' => 'Draft', 'sent' => 'Sent']" />
</x-form>
```

## Frontend Directory Structure

```
resources/
├─ assets/
│  ├─ js/
│  │  ├─ app.js                    # Entry point
│  │  ├─ bootstrap.js              # Vue initialization
│  │  ├─ components/               # Vue components
│  │  │  ├─ Inputs/                # Form inputs
│  │  │  ├─ Cards/                 # Card components
│  │  │  ├─ Tables/                # Table components
│  │  │  └─ ...
│  │  ├─ directives/               # v-tooltip, v-click-outside, etc
│  │  ├─ mixins/                   # Shared logic (formatMoney, etc)
│  │  ├─ plugins/                  # Vue plugins
│  │  ├─ exceptions/               # Error handlers
│  │  └─ stores/                   # Vuex stores
│  └─ css/
│     ├─ app.css                   # Tailwind entry
│     ├─ tailwind.css              # Tailwind config
│     └─ creditcard/               # Credit card styles
│
├─ views/
│  ├─ layouts/
│  │  ├─ app.blade.php             # Main layout
│  │  ├─ auth.blade.php            # Auth pages layout
│  │  └─ plain.blade.php           # Plain layout
│  ├─ sales/
│  │  ├─ invoices/
│  │  │  ├─ index.blade.php        # List invoices
│  │  │  ├─ create.blade.php       # Create form
│  │  │  ├─ edit.blade.php         # Edit form
│  │  │  └─ show.blade.php         # Detail view
│  │  └─ ...
│  ├─ components/
│  │  ├─ form.blade.php            # Form wrapper
│  │  ├─ input.blade.php           # Input field
│  │  └─ button.blade.php          # Button
│  └─ ...
│
└─ lang/
   └─ en/                          # English translations
      ├─ validation.php            # Validation messages
      ├─ auth.php                  # Auth strings
      └─ ...
```

## Performance Optimization

### Code Splitting

```javascript
// Lazy load routes for better initial load
const invoices = () => import('./pages/Invoices.vue')
const settings = () => import('./pages/Settings.vue')
```

### Asset Versioning

Webpack automatically versions files:

```html
<!-- mix-manifest.json hashes included in URLs -->
<script src="/js/app.js?id=abc123"></script>
<link href="/css/app.css?id=def456" rel="stylesheet">
```

### Caching Headers

Static assets cached in browser/CDN:

```
Cache-Control: max-age=31536000, immutable
```

## Related Pages

- [Vue Components](vue-components.md) – Component usage and examples
- [Styling Guide](tailwind-styles.md) – Tailwind CSS customization
- [Frontend Workflow](../http/livewire.md) – Real-time components

## Source Map

```
resources/
├─ assets/
│  ├─ js/
│  │  ├─ app.js
│  │  ├─ bootstrap.js
│  │  ├─ components/
│  │  ├─ directives/
│  │  ├─ mixins/
│  │  ├─ plugins/
│  │  └─ exceptions/
│  └─ css/
│     ├─ app.css
│     └─ tailwind.css
│
├─ views/
│  ├─ layouts/
│  ├─ {domain}/
│  └─ components/
│
└─ lang/
   └─ {locale}/
```

## Testing & Validation

```bash
# Run frontend linting
npm run lint

# Run frontend tests
npm test

# Build for production
npm run prod

# Check bundle size
npm run build:analyze
```

## Best Practices

- **Component isolation**: Each component handles one concern
- **Props validation**: Define and validate all props
- **Event naming**: Use kebab-case for emitted events
- **CSS scoping**: Use scoped styles in Vue components
- **Accessibility**: Include aria labels and semantic HTML
- **Performance**: Lazy load heavy components and routes

## Related Pages

- [Middleware & Routing](../http/middleware.md) – HTTP request routing
- [Controllers Overview](../http/controllers.md) – Request handlers
- [API Resources](../http/resources.md) – JSON response transformation
