---
type: system-reference
title: Livewire Components
description: Real-time, serverless UI components for interactive features without JavaScript frameworks.
tags: [http, livewire, frontend, reactive-components]
openwiki:
  source_paths: [app/Http/Livewire]
---

# Livewire Components

Livewire enables interactive, real-time UI components that eliminate the need for writing JavaScript. Components automatically handle state management, validation, and reactivity.

## What is Livewire?

Livewire is a Laravel library for building dynamic interfaces without building JavaScript. Components are classes that manage their own state and render Blade templates with automatic reactivity.

**Location**: `App\Http\Livewire\{Feature}\{ComponentName}`

**Base Class**: `Livewire\Component`

## Component Structure

### Basic Component

```php
namespace App\Http\Livewire;

use Livewire\Component;

class ContactForm extends Component
{
    // Public properties (reactive state)
    public $name = '';
    public $email = '';
    public $phone = '';
    
    // Validation rules
    protected $rules = [
        'name' => 'required|min:3',
        'email' => 'required|email',
        'phone' => 'nullable|regex:/^[\d\s\-\+\(\)]+$/',
    ];
    
    /**
     * Handle form submission
     */
    public function submit()
    {
        // Validate
        $this->validate();
        
        // Create contact
        Contact::create($this->all());
        
        // Reset form
        $this->reset();
        
        // Flash message
        session()->flash('message', 'Contact created successfully!');
    }
    
    /**
     * Render the component view
     */
    public function render()
    {
        return view('livewire.contact-form');
    }
}
```

### Component Blade Template

```blade
<div class="form-container">
    @if (session()->has('message'))
        <div class="alert alert-success">
            {{ session('message') }}
        </div>
    @endif
    
    <form wire:submit.prevent="submit">
        <div class="form-group">
            <label>Name</label>
            <input 
                type="text" 
                wire:model="name"
                class="form-control"
            >
            @error('name') 
                <span class="text-danger">{{ $message }}</span> 
            @enderror
        </div>
        
        <div class="form-group">
            <label>Email</label>
            <input 
                type="email" 
                wire:model="email"
                class="form-control"
            >
            @error('email') 
                <span class="text-danger">{{ $message }}</span> 
            @enderror
        </div>
        
        <button type="submit" class="btn btn-primary">
            Save
        </button>
    </form>
</div>
```

## Data Binding

### Wire:model (Two-Way Binding)

```blade
<!-- Automatically syncs value with component property -->
<input wire:model="name">
<!-- Updates component->name on input, re-renders on change -->
```

### Wire:model.lazy (Deferred Binding)

```blade
<!-- Only syncs when user leaves the field -->
<input wire:model.lazy="email">
```

### Wire:model.debounce (Throttled Binding)

```blade
<!-- Waits 500ms of inactivity before syncing -->
<input wire:model.debounce.500ms="search_query">
```

## Event Handling

### Click Events

```blade
<!-- Call component method on click -->
<button wire:click="deleteItem({{ $item->id }})">
    Delete
</button>

<!-- With loading state -->
<button wire:click="save" wire:loading.attr="disabled">
    Save
</button>
```

### Form Submission

```blade
<form wire:submit.prevent="saveChanges">
    <!-- Calls saveChanges() on submit -->
</form>
```

### Input Events

```blade
<!-- Real-time validation/search -->
<input wire:keydown.enter="search">
<input wire:change="updateFilter">
```

## Built-in Akaunting Components

### Menu Component

**Location**: `App\Http\Livewire\Menu`

Manages navigation menus in admin interface

```blade
<livewire:menu />
```

### Report Component

**Location**: `App\Http\Livewire\Report`

Builds and renders custom reports with filters

```blade
<livewire:report :report="$report" />
```

### Notification Component

**Location**: `App\Http\Livewire\Notification`

Real-time notification display system

```blade
<livewire:notification />
```

### Tab Component

**Location**: `App\Http\Livewire\Tab`

Tabbed interface for organization

```blade
<livewire:tab />
```

### Common Component

**Location**: `App\Http\Livewire\Common`

Shared UI utilities

```blade
<livewire:common.date-picker />
```

## Akaunting-Specific Patterns

### Multi-Tenancy in Livewire

```php
class ContactForm extends Component
{
    public function mount()
    {
        // Current company is automatically available
        $this->company = auth()->user()->currentCompany();
    }
    
    public function submit()
    {
        // Queries automatically scoped to company
        Contact::create([
            'company_id' => $this->company->id,
            'name' => $this->name,
        ]);
    }
}
```

### Permission Checking

```blade
@if (auth()->user()->can('edit', $contact))
    <button wire:click="edit({{ $contact->id }})">
        Edit
    </button>
@endif
```

### Real-Time Validation

```php
protected $rules = [
    'name' => 'required|min:3',
    'email' => 'required|email|unique:contacts',
];

public function updatedEmail()
{
    // Called automatically when email property changes
    $this->validateOnly('email');
}
```

## Lifecycle Hooks

```php
class ContactForm extends Component
{
    public function mount()
    {
        // Called when component is first rendered
    }
    
    public function hydrate()
    {
        // Called before every update
    }
    
    public function updating($name, $value)
    {
        // Called before any property changes
    }
    
    public function updated($name, $value)
    {
        // Called after any property changes
    }
    
    public function dehydrate()
    {
        // Called before sending response to browser
    }
}
```

## Common Use Cases

### Live Search

```php
class SearchContacts extends Component
{
    public $query = '';
    
    public function updatedQuery()
    {
        // Automatically called when query changes
    }
    
    public function getResultsProperty()
    {
        if (strlen($this->query) < 2) {
            return [];
        }
        
        return Contact::where('name', 'like', "%{$this->query}%")
            ->limit(10)
            ->get();
    }
    
    public function render()
    {
        return view('livewire.search-contacts', [
            'results' => $this->results,
        ]);
    }
}
```

### Modal Dialog

```php
class DeleteConfirm extends Component
{
    public $modelId;
    public $modelName;
    
    public function delete()
    {
        $model = $this->modelName::find($this->modelId);
        $model->delete();
        
        $this->emit('deleted');
    }
    
    public function render()
    {
        return view('livewire.delete-confirm');
    }
}
```

### List with Inline Editing

```php
class ContactsList extends Component
{
    public $contacts;
    public $editingId = null;
    
    public function mount()
    {
        $this->contacts = Contact::all();
    }
    
    public function edit($id)
    {
        $this->editingId = $id;
    }
    
    public function save($id, $data)
    {
        Contact::find($id)->update($data);
        $this->editingId = null;
    }
}
```

## Performance Considerations

- **Debounce rapid updates**: Use `wire:model.debounce` for searches
- **Lazy load**: Use `wire:model.lazy` for expensive updates
- **Computed properties**: Cache calculated data
- **Pagination**: Return only necessary records

## Related Pages

- [Controllers Overview](controllers.md) – Web request handling
- [Frontend Overview](../frontend/overview.md) – Vue.js and frontend structure

## Source Map

```
app/Http/Livewire/
├─ Common/
│  └─ *.php
├─ Menu/
│  └─ *.php
├─ Report/
│  └─ *.php
├─ Notification/
│  └─ *.php
└─ Tab/
   └─ *.php

resources/views/livewire/
├─ common/
├─ menu/
├─ report/
└─ ...
```

## Testing & Validation

```bash
# Run component-specific tests
php artisan test --filter=ContactFormTest
```

## Resources

- [Livewire Documentation](https://livewire.laravel.com/)
- [Akaunting Implementation](https://github.com/akaunting/akaunting/tree/master/app/Http/Livewire)
