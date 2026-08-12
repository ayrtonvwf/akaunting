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

There is no Livewire component in this codebase named `ContactForm`, and contact creation is not
implemented as a Livewire component — the real contact form is a set of non-Livewire Blade
components under `resources/views/components/contacts/form/`. Below is a real, verified Akaunting
Livewire component instead: `App\Http\Livewire\Common\Search` (`app/Http/Livewire/Common/Search.php`),
the global navbar search box.

```php
namespace App\Http\Livewire\Common;

use App\Events\Common\GlobalSearched;
use App\Models\Banking\Account;
use Livewire\Component;

class Search extends Component
{
    public $user = null;

    public $keyword = '';

    public $results = [];

    protected $listeners = ['resetKeyword'];

    public function render()
    {
        $this->user = user();

        $this->search();

        return view('livewire.common.search');
    }

    public function search()
    {
        $this->results = [];

        if (empty($this->keyword)) {
            return;
        }

        $this->searchOnAccounts();
        // ...and searchOnItems(), searchOnInvoices(), searchOnCustomers(),
        // searchOnBills(), searchOnVendors() — one method per searchable model.

        $this->dispatchGlobalSearched();
    }

    public function resetKeyword()
    {
        $this->keyword = '';
    }
}
```

Each `searchOn*()` method checks a permission (e.g. `$this->user->can('read-banking-accounts')`)
before querying, so results are automatically scoped to what the current user can see — see the
full file for all six `searchOn*()` methods.

### Component Blade Template

The real template, `resources/views/livewire/common/search.blade.php`, renders the input and a
results dropdown. Trimmed to its essential structure:

```blade
<form wire:click.stop class="navbar-search ...">
    <input type="text" name="search" wire:model.live.debounce.500ms="keyword" ...>

    @if ($results)
    <div class="dropdown-menu ...">
        @foreach($results as $result)
        <a href="{{ $result->href }}">
            <div class="name">{{ $result->name }}</div>
            <span class="type">{{ $result->type }}</span>
        </a>
        @endforeach
    </div>
    @endif
</form>
```

Note the `wire:model.live.debounce.500ms` binding syntax — this project uses Livewire 3.x
(`livewire/livewire: ^3.0` in `composer.json`).

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

No verified Livewire component in this codebase demonstrates explicit company-scoping in its
`mount()`/action methods (the real search component, above, scopes results implicitly through
each model's existing query scopes and the user's permissions, not by reading
`currentCompany()` directly). In general, per this codebase's multi-tenancy pattern documented in
`workflows/multi-tenancy.md`, a Livewire component's Eloquent queries are scoped the same way any
other request-cycle code is: through the `Tenants` trait's global scope on the model, not through
manual company-ID filtering inside the component.

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

These are Livewire 3.x framework hooks (from `livewire/livewire`, not Akaunting-specific code —
none of the built-in Akaunting components in this codebase currently implement all of them):

| Hook | Called |
|------|--------|
| `mount()` | When the component is first rendered |
| `hydrate()` | Before every update |
| `updating($name, $value)` | Before any property changes |
| `updated($name, $value)` | After any property changes |
| `dehydrate()` | Before sending the response to the browser |

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

No dedicated Livewire component test suite exists in this repository (there is no
`tests/Feature/Livewire` directory and no test file targets a Livewire component directly).

## Resources

- [Livewire Documentation](https://livewire.laravel.com/)
- [Akaunting Implementation](https://github.com/akaunting/akaunting/tree/master/app/Http/Livewire)
