---
type: system-reference
title: Vue.js Components - Reusable UI Elements
description: Vue.js component library for forms, inputs, tables, modals, and data display with validation.
tags: [vue, components, ui, forms, data-display]
openwiki:
  source_paths: [resources/assets/js/components]
---

# Vue.js Components

Reusable Vue.js components for common UI patterns like forms, inputs, tables, and modals.

## Component Directory

```
resources/assets/js/components/
├─ Inputs/
│  ├─ MoneyInput.vue          # Currency input
│  ├─ DatePicker.vue          # Date selection
│  ├─ SelectInput.vue         # Dropdown with search
│  ├─ TextInput.vue           # Text input field
│  ├─ TextareaInput.vue       # Multi-line text
│  ├─ CheckboxInput.vue       # Checkbox
│  ├─ RadioInput.vue          # Radio buttons
│  └─ FileInput.vue           # File upload
│
├─ Cards/
│  ├─ SummaryCard.vue         # Stats card
│  ├─ InfoCard.vue            # Info card
│  └─ ProfileCard.vue         # User profile
│
├─ Tables/
│  ├─ DataTable.vue           # Sortable, paginated table
│  ├─ InlineEdit.vue          # Editable rows
│  └─ TreeTable.vue           # Nested data table
│
├─ CreditCard/
│  └─ CreditCard.vue          # Credit card display
│
├─ Modals/
│  ├─ ConfirmDialog.vue       # Confirmation dialog
│  ├─ Modal.vue               # Generic modal
│  └─ Toast.vue               # Toast notification
│
└─ Plugins/
   ├─ NotificationPlugin/     # Notification system
   └─ LoadingPlugin/          # Loading indicator
```

## Form Inputs

### TextInput

Basic text input with label and error display:

```vue
<TextInput
  v-model="form.name"
  name="name"
  label="Full Name"
  placeholder="Enter your name"
  required
  :error="errors.name"
  @input="handleChange"
/>
```

**Props**:
- `v-model` – Two-way binding
- `name` – Input name attribute
- `label` – Display label
- `placeholder` – Placeholder text
- `required` – Mark as required
- `error` – Error message to display
- `disabled` – Disable input
- `type` – Input type (text, email, password, etc.)

### MoneyInput

Currency-formatted input:

```vue
<MoneyInput
  v-model="invoice.amount"
  label="Amount"
  currency="USD"
  :error="errors.amount"
/>
```

**Features**:
- Automatic currency formatting
- Locale-aware decimal separator
- Thousand separator
- Copy with Ctrl+C

**Props**:
- `v-model` – Numeric value
- `label` – Display label
- `currency` – Currency code (USD, EUR, etc.)
- `error` – Error message

### DatePicker

Calendar date selection:

```vue
<DatePicker
  v-model="invoice.issued_at"
  label="Issue Date"
  format="Y-m-d"
  :min="minDate"
  :max="maxDate"
  @change="onDateChange"
/>
```

**Features**:
- Calendar popup
- Keyboard navigation
- Date range limits
- Custom format support

**Props**:
- `v-model` – Selected date (ISO format)
- `label` – Display label
- `format` – Display format (Y-m-d, M/d/Y, etc.)
- `min` – Minimum selectable date
- `max` – Maximum selectable date
- `disabled_dates` – Array of disabled dates

### SelectInput

Dropdown with search:

```vue
<SelectInput
  v-model="form.contact_id"
  label="Customer"
  :options="contacts"
  option-key="id"
  option-label="name"
  searchable
  clearable
  :error="errors.contact_id"
/>
```

**Features**:
- Autocomplete search
- Keyboard navigation
- Group options
- Custom rendering

**Props**:
- `v-model` – Selected value
- `label` – Display label
- `options` – Array of options
- `option-key` – Key field
- `option-label` – Label field
- `searchable` – Enable search
- `clearable` – Show clear button
- `multiple` – Multi-select
- `grouped` – Group options

### CheckboxInput

Checkbox with label:

```vue
<CheckboxInput
  v-model="form.is_default"
  label="Set as default account"
  name="is_default"
/>
```

### FileInput

File upload:

```vue
<FileInput
  v-model="form.attachment"
  label="Upload Invoice"
  accept="application/pdf"
  @change="onFileSelect"
/>
```

## Data Display

### DataTable

Sortable, paginated table:

```vue
<DataTable
  :items="invoices"
  :columns="tableColumns"
  :loading="loading"
  :paginated="true"
  :per-page="25"
  sortable
  @row-click="viewInvoice"
  @sort="onSort"
>
  <!-- Custom column rendering -->
  <template #amount="{ item }">
    <span class="font-bold">{{ formatMoney(item.amount) }}</span>
  </template>
  
  <template #actions="{ item }">
    <button @click="editInvoice(item.id)">Edit</button>
    <button @click="deleteInvoice(item.id)">Delete</button>
  </template>
</DataTable>
```

**Features**:
- Sortable columns
- Pagination
- Custom cell rendering
- Row selection
- Loading state
- Empty state handling

**Props**:
- `items` – Array of data rows
- `columns` – Column configuration
- `loading` – Loading indicator
- `paginated` – Show pagination
- `per-page` – Rows per page
- `sortable` – Enable sorting
- `selectable` – Row checkboxes

**Column Configuration**:

```javascript
const columns = [
  {
    key: 'document_number',
    label: 'Invoice #',
    sortable: true,
    width: '150px'
  },
  {
    key: 'issued_at',
    label: 'Date',
    format: 'date'
  },
  {
    key: 'amount',
    label: 'Amount',
    format: 'money',
    align: 'right'
  },
  {
    key: 'status',
    label: 'Status',
    render: (value) => `<span class="badge">${value}</span>`
  }
]
```

### SummaryCard

Stats card:

```vue
<SummaryCard
  title="Total Income"
  :value="totalIncome"
  icon="chart-line"
  color="blue"
  :loading="loading"
>
  <template #footer>
    <span class="text-green-600">+12.5% from last month</span>
  </template>
</SummaryCard>
```

**Props**:
- `title` – Card title
- `value` – Main value/stat
- `icon` – Icon name
- `color` – Color theme (blue, green, red, etc.)
- `loading` – Loading state

## Modals & Dialogs

### ConfirmDialog

Confirmation modal:

```vue
<ConfirmDialog
  v-if="showDeleteConfirm"
  title="Delete Invoice?"
  message="This action cannot be undone."
  action-text="Delete"
  @confirm="deleteInvoice"
  @cancel="showDeleteConfirm = false"
/>
```

**Features**:
- Confirmation prompt
- Danger/normal modes
- Action button states
- Keyboard shortcuts (Enter to confirm, Esc to cancel)

### Modal

Generic modal:

```vue
<Modal
  v-if="showModal"
  title="Create Invoice"
  size="lg"
  @close="showModal = false"
>
  <form @submit="saveInvoice">
    <!-- Form content -->
  </form>
  
  <template #footer>
    <button class="btn btn-primary" @click="saveInvoice">Save</button>
    <button class="btn btn-gray" @click="showModal = false">Cancel</button>
  </template>
</Modal>
```

## Common Patterns

### Form with Validation

```vue
<template>
  <form @submit.prevent="submitForm">
    <TextInput
      v-model="form.name"
      label="Name"
      :error="errors.name"
    />
    
    <MoneyInput
      v-model="form.amount"
      label="Amount"
      :error="errors.amount"
    />
    
    <DatePicker
      v-model="form.date"
      label="Date"
      :error="errors.date"
    />
    
    <button :disabled="submitting" type="submit">
      {{ submitting ? 'Saving...' : 'Save' }}
    </button>
  </form>
</template>

<script>
export default {
  data() {
    return {
      form: {
        name: '',
        amount: '',
        date: ''
      },
      errors: {},
      submitting: false
    }
  },
  methods: {
    async submitForm() {
      this.submitting = true
      this.errors = {}
      
      try {
        await this.$http.post('/api/documents', this.form)
        this.$notify.success('Document created')
      } catch (error) {
        this.errors = error.response.data.errors
      } finally {
        this.submitting = false
      }
    }
  }
}
</script>
```

### Data Table with Actions

```vue
<template>
  <div>
    <DataTable
      :items="invoices"
      :columns="columns"
      @row-click="viewInvoice"
    >
      <template #actions="{ item }">
        <button @click="editInvoice(item.id)" class="btn btn-sm">
          Edit
        </button>
        <button @click="deleteInvoice(item.id)" class="btn btn-sm btn-danger">
          Delete
        </button>
      </template>
    </DataTable>
    
    <ConfirmDialog
      v-if="showDeleteConfirm"
      title="Delete invoice?"
      @confirm="confirmDelete"
      @cancel="showDeleteConfirm = false"
    />
  </div>
</template>

<script>
export default {
  data() {
    return {
      invoices: [],
      columns: [
        { key: 'document_number', label: 'Invoice #' },
        { key: 'contact.name', label: 'Customer' },
        { key: 'amount', label: 'Amount', format: 'money' },
        { key: 'status', label: 'Status' },
        { key: 'actions', label: 'Actions' }
      ],
      showDeleteConfirm: false,
      selectedInvoiceId: null
    }
  },
  methods: {
    deleteInvoice(id) {
      this.selectedInvoiceId = id
      this.showDeleteConfirm = true
    },
    async confirmDelete() {
      await this.$http.delete(`/api/documents/${this.selectedInvoiceId}`)
      this.$notify.success('Invoice deleted')
      this.showDeleteConfirm = false
      this.loadInvoices()
    }
  }
}
</script>
```

## Styling & Theming

### Tailwind Integration

Components use Tailwind classes:

```vue
<template>
  <div class="space-y-4">
    <!-- Components automatically styled with Tailwind -->
    <TextInput v-model="name" label="Name" />
    <MoneyInput v-model="amount" label="Amount" />
  </div>
</template>
```

### Custom Styling

Override component styles with scoped CSS:

```vue
<style scoped>
:deep(.input-field) {
  @apply border-2 border-blue-500;
}

:deep(.card) {
  @apply shadow-lg rounded-lg;
}
</style>
```

## Related Pages

- [Frontend Overview](overview.md) – Vue.js and Tailwind setup
- [Styling Guide](tailwind-styles.md) – Custom styling
- [Livewire Components](../http/livewire.md) – Server-side reactive components

## Source Map

```
resources/assets/js/components/
├─ Inputs/
│  ├─ TextInput.vue
│  ├─ MoneyInput.vue
│  ├─ DatePicker.vue
│  └─ SelectInput.vue
├─ Cards/
│  ├─ SummaryCard.vue
│  └─ InfoCard.vue
├─ Tables/
│  └─ DataTable.vue
└─ Modals/
   ├─ Modal.vue
   └─ ConfirmDialog.vue
```

## Testing & Validation

```bash
# Test Vue components
npm run test

# Test component rendering
npm run test:watch

# Test snapshots
npm run test:update
```
