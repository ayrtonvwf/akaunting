---
type: system-reference
title: Styling Guide - Tailwind CSS Customization
description: Tailwind CSS configuration, custom theme settings, color schemes, and styling conventions.
tags: [css, tailwind, styling, theme, customization]
openwiki:
  source_paths: [tailwind.config.js, resources/assets/css]
---

# Styling Guide - Tailwind CSS

Akaunting uses Tailwind CSS for utility-first styling with custom theme extensions. This guide covers configuration, customization, and best practices.

## Tailwind Configuration

**File**: `tailwind.config.js`

```javascript
module.exports = {
  // Files to scan for class usage
  content: [
    './resources/views/**/*.blade.php',
    './resources/assets/js/**/*.vue',
    './resources/assets/js/**/*.js',
  ],
  
  // Theme customization
  theme: {
    extend: {
      colors: {
        primary: '#667eea',
        secondary: '#764ba2',
        success: '#48bb78',
        warning: '#ed8936',
        danger: '#f56565',
      },
      spacing: {
        // Additional spacing values
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
        mono: ['Menlo', 'monospace'],
      },
    },
  },
  
  // Plugins
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}
```

## Color Palette

### Primary Colors

```css
/* Use for main actions and highlights */
.btn-primary { @apply bg-primary text-white; }
.text-primary { @apply text-primary; }
.border-primary { @apply border-primary; }
```

**Color Values**:
- **Primary**: `#667eea` (Blue-Purple)
- **Secondary**: `#764ba2` (Purple)
- **Success**: `#48bb78` (Green)
- **Warning**: `#ed8936` (Orange)
- **Danger**: `#f56565` (Red)

### Semantic Colors

```
bg-success    → Green (success messages, positive actions)
bg-warning    → Orange (warning messages, caution)
bg-danger     → Red (error messages, destructive actions)
bg-info       → Blue (information, neutral)
```

### Neutral Colors

```
text-gray-900 → Dark text
text-gray-600 → Secondary text
text-gray-400 → Disabled/muted text
bg-gray-50    → Light background
bg-gray-100   → Card background
bg-gray-200   → Border/separator
```

## Component Classes

### Buttons

```html
<!-- Primary button -->
<button class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition">
  Save
</button>

<!-- Secondary button -->
<button class="px-4 py-2 bg-gray-200 text-gray-900 rounded hover:bg-gray-300 transition">
  Cancel
</button>

<!-- Danger button -->
<button class="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition">
  Delete
</button>

<!-- Disabled button -->
<button disabled class="px-4 py-2 bg-gray-300 text-gray-500 cursor-not-allowed">
  Loading...
</button>
```

### Forms

```html
<!-- Text input -->
<input type="text" class="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:border-blue-500">

<!-- Text area -->
<textarea class="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:border-blue-500"></textarea>

<!-- Select -->
<select class="w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:border-blue-500">
  <option>Option 1</option>
</select>

<!-- Checkbox -->
<input type="checkbox" class="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500">

<!-- Error state -->
<input class="border-2 border-red-500 focus:border-red-600">
<span class="text-red-600 text-sm">This field is required</span>
```

### Cards

```html
<!-- Basic card -->
<div class="bg-white rounded-lg shadow p-6">
  <h3 class="text-lg font-semibold mb-4">Card Title</h3>
  <p class="text-gray-600">Card content</p>
</div>

<!-- Card with header -->
<div class="bg-white rounded-lg shadow">
  <div class="px-6 py-4 border-b border-gray-200">
    <h3 class="text-lg font-semibold">Header</h3>
  </div>
  <div class="px-6 py-4">
    Content
  </div>
</div>

<!-- Highlighted card -->
<div class="bg-blue-50 border-l-4 border-blue-600 px-4 py-3 rounded">
  <p class="text-blue-900">Important information</p>
</div>
```

### Alerts/Notifications

```html
<!-- Success alert -->
<div class="bg-green-50 border border-green-200 text-green-800 rounded p-4">
  <p class="font-semibold">Success!</p>
  <p>Your changes have been saved.</p>
</div>

<!-- Warning alert -->
<div class="bg-yellow-50 border border-yellow-200 text-yellow-800 rounded p-4">
  <p class="font-semibold">Warning</p>
  <p>Please review your data.</p>
</div>

<!-- Error alert -->
<div class="bg-red-50 border border-red-200 text-red-800 rounded p-4">
  <p class="font-semibold">Error</p>
  <p>Something went wrong.</p>
</div>
```

### Tables

```html
<table class="w-full border-collapse">
  <thead class="bg-gray-100 border-b-2 border-gray-200">
    <tr>
      <th class="px-4 py-2 text-left font-semibold text-gray-900">Column 1</th>
      <th class="px-4 py-2 text-left font-semibold text-gray-900">Column 2</th>
    </tr>
  </thead>
  <tbody>
    <tr class="border-b border-gray-200 hover:bg-gray-50">
      <td class="px-4 py-3">Data</td>
      <td class="px-4 py-3">Data</td>
    </tr>
  </tbody>
</table>
```

## Layout & Spacing

### Containers

```html
<!-- Full-width container -->
<div class="w-full">Content</div>

<!-- Max-width container -->
<div class="max-w-4xl mx-auto px-4">Content</div>

<!-- Fixed sidebar layout -->
<div class="flex">
  <aside class="w-64 bg-gray-900">Sidebar</aside>
  <main class="flex-1">Main content</main>
</div>
```

### Spacing Utilities

```
m-4    → margin: 1rem (all sides)
mt-4   → margin-top: 1rem
mx-4   → margin-left & right: 1rem
p-4    → padding: 1rem (all sides)
px-4   → padding-left & right: 1rem
gap-4  → gap between flex items: 1rem
space-y-4 → vertical gap between children: 1rem
```

### Responsive Layout

```html
<!-- Stacked on mobile, side-by-side on tablet+ -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  <div>Item 1</div>
  <div>Item 2</div>
  <div>Item 3</div>
</div>

<!-- Flex layout -->
<div class="flex flex-col md:flex-row gap-4">
  <div class="w-full md:w-1/3">Sidebar</div>
  <div class="w-full md:w-2/3">Main</div>
</div>
```

## Typography

### Headings

```html
<h1 class="text-4xl font-bold text-gray-900">Main Heading</h1>
<h2 class="text-3xl font-bold text-gray-900">Section Heading</h2>
<h3 class="text-2xl font-semibold text-gray-900">Subsection</h3>
<h4 class="text-xl font-semibold text-gray-900">Minor Heading</h4>
<p class="text-base text-gray-600">Body text</p>
<small class="text-sm text-gray-500">Small text</small>
```

### Text Styles

```
font-bold      → font-weight: 700
font-semibold  → font-weight: 600
font-normal    → font-weight: 400
font-light     → font-weight: 300

text-center    → text-align: center
text-left      → text-align: left
text-right     → text-align: right

italic         → font-style: italic
underline      → text-decoration: underline
line-through   → text-decoration: line-through
```

## Custom CSS

**File**: `resources/assets/sass/app.css`

### Adding Custom Utilities

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Custom component classes */
@layer components {
  .btn {
    @apply px-4 py-2 rounded font-semibold transition duration-200;
  }
  
  .btn-primary {
    @apply bg-blue-600 text-white hover:bg-blue-700;
  }
  
  .btn-secondary {
    @apply bg-gray-200 text-gray-900 hover:bg-gray-300;
  }
  
  .card {
    @apply bg-white rounded-lg shadow p-6;
  }
  
  .input-field {
    @apply w-full px-3 py-2 border border-gray-300 rounded focus:outline-none focus:border-blue-500;
  }
}

/* Custom utilities */
@layer utilities {
  .text-truncate {
    @apply truncate;
  }
  
  .line-clamp-2 {
    @apply line-clamp-2;
  }
  
  .glass {
    @apply bg-white/30 backdrop-blur-md;
  }
}
```

## Accessibility

### Color Contrast

Ensure sufficient contrast for readability:

```html
<!-- Good contrast -->
<p class="text-gray-900">Dark text on light background</p>

<!-- Avoid -->
<p class="text-gray-400">Light gray text (low contrast)</p>
```

### Focus States

Always include focus states for keyboard navigation:

```html
<input class="focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
<button class="focus:outline-none focus:ring-2 focus:ring-blue-500">
  Button
</button>
```

### Responsive Text

Adjust text size for readability on mobile:

```html
<h1 class="text-2xl md:text-3xl lg:text-4xl">
  Responsive Heading
</h1>
```

## Dark Mode

Tailwind supports dark mode:

```html
<!-- Enable in tailwind.config.js: darkMode: 'class' -->
<div class="bg-white dark:bg-gray-900">
  <p class="text-gray-900 dark:text-white">Content</p>
</div>
```

## Common Patterns

### Modal Overlay

```html
<div class="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
  <div class="bg-white rounded-lg shadow-lg p-6 max-w-md">
    <!-- Modal content -->
  </div>
</div>
```

### Badge/Label

```html
<span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800">
  Label
</span>
```

### Loading Spinner

```html
<div class="inline-block animate-spin">
  <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" opacity="0.25"></circle>
    <path fill="currentColor" d="..."></path>
  </svg>
</div>
```

### Skeleton Loader

```html
<div class="animate-pulse">
  <div class="h-4 bg-gray-300 rounded mb-2"></div>
  <div class="h-4 bg-gray-300 rounded"></div>
</div>
```

## Related Pages

- [Frontend Overview](overview.md) – Vue.js and asset setup
- [Vue Components](vue-components.md) – Component library
- [Livewire Components](../http/livewire.md) – Real-time components

## Source Map

```
resources/
├─ assets/css/
│  ├─ app.css              # Main stylesheet
│  ├─ tailwind.css         # Tailwind directives
│  └─ creditcard/          # Credit card styles
│
└─ views/
   ├─ layouts/
   └─ components/
```

## Resources

- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [Tailwind UI Components](https://tailwindui.com/)
- [Tailwind Color Palette](https://tailwindcss.com/docs/customizing-colors)

## Best Practices

1. **Use semantic classes**: Use `btn-primary` instead of repeating `bg-blue-600 text-white...`
2. **Responsive design**: Always design mobile-first with responsive breakpoints
3. **Accessibility**: Include focus states and sufficient color contrast
4. **Consistency**: Use the defined color palette and spacing scale
5. **Performance**: Only include used utilities (Tailwind purges unused classes)
6. **Documentation**: Comment complex styles in custom CSS sections
