# Drift audit: the Akaunting developer manual against the current code

The `akaunting/docs` repository carries a nine-file developer manual. The application repository
itself ships a README and a security policy and nothing else.

> **Correction, added after the first pass.** This audit originally described the repository manual
> as the only architectural documentation in existence. That was wrong. A **live successor exists**
> in the vendor's help centre at `akaunting.com/hc/docs/developers`, carrying fifteen topics
> including three that postdate the repository version entirely (Bulk Actions, Search String,
> Payment Methods). The repository manual was migrated, not abandoned in place.
>
> Everything below about the repository files remains accurate, and remains worth having, because
> those files are what a web search surfaces and what an agent would otherwise ingest. But the live
> version should be the source consulted, and it is checked at the end of this document.
>
> The conclusion the audit fed into does not change: the live version is still **extension-surface**
> documentation. See "The live successor" below.

**It is older than it first appears.** The repository's last push was December 2022, but the
developer-manual files themselves were last touched between 2018 and 2021. That is five to six years
of drift, spanning at least one major Akaunting version and several Laravel majors. Every file is
dated below.

Audited on 2026-08-06 against `akaunting/akaunting@master` (PHP `^8.1`, Laravel `^10.0`).

## Summary

| Verdict | Files |
|---|---|
| Broadly still accurate | `menu.md`, `hooking-models.md` |
| Right idea, wrong details | `modules.md`, `permissions.md`, `settings.md`, `overriding-output.md` |
| Obsolete | `restful-api.md`, `reverse-proxy.md`, `adding-docs.md` |

Roughly a third is usable as-is, a third describes a real mechanism with at least one detail that no
longer resolves, and a third describes a stack that is gone. The obsolete third includes
`restful-api.md`, which at 1066 lines is larger than the other eight combined.

**The consequence for tooling: this manual cannot be handed to an agent as context.** Two thirds of
it would be confidently wrong, and the wrong parts are indistinguishable in tone from the right
parts. What it is good for is a checklist of which mechanisms exist, to be verified individually
against the code.

---

## File by file

### `menu.md` (last touched 2021-02-08) - broadly accurate

The mechanism is intact. `App\Events\Menu\AdminCreated` and `App\Events\Menu\PortalCreated` both
still exist, and the listener pattern the document describes is still how menu extension works.

| Claim | Current state |
|---|---|
| Listen to `AdminCreated` / `PortalCreated` | Correct, both classes present |
| Package is `akaunting/menu`, linking to `github.com/akaunting/menu/wiki` | Renamed to `akaunting/laravel-menu` (`^3.0`). The documented link is dead. |

Worth knowing that `app/Events/Menu/` has grown well past the two events documented: it now holds
fourteen, including `SettingsCreated`, `SettingsCreating`, `SettingsFinished`, `ProfileCreated`,
`NotificationsCreated` and an `ItemAuthorizing`. The document describes a smaller surface than exists.

### `hooking-models.md` (2020-04-17) - broadly accurate

Both referenced classes are present: `App\Models\Common\Item` and `App\Abstracts\Observer`. The
`Model::observe()` pattern is standard Eloquent and still valid.

The one thing the document predates: `akaunting/laravel-mutable-observer` (`^2.0`) is now a
first-party dependency, and `app/Providers/Observer.php` is one of the twelve service providers. There
is an observer layer here that the document does not mention.

### `modules.md` (2020-07-30) - right idea, wrong details

The module concept is unchanged and the document is still the best available explanation of it. The
specifics have all moved.

| Claim | Current state |
|---|---|
| Package `akaunting/module`, link `github.com/akaunting/module` | Renamed to `akaunting/laravel-module` (`^4.0`). Link dead. |
| Example `module.json` fields | Real modules add `extra-modules` and a `routes` object carrying `redirect_after_install` |
| Example icon `"fas fa-pen"` | Real modules use bare names such as `"credit_card"`. The icon system changed. |
| `providers` shows only `Providers\Main` | The shipped Offline Payments module registers two: `Providers\Event` and `Providers\Main` |
| Folder structure lists `Console/`, `Database/`, `Models/` | The real module has `Http/`, `Jobs/`, `Listeners/`, `Providers/`, `Resources/`, `Routes/`, `Tests/`. The documented tree is a superset. |
| "Offline Payments module built into the Akaunting core" | It is now a separate Composer package, `akaunting/module-offline-payments`, path-mapped into `modules/OfflinePayments` |
| `php artisan module:make my-blog` | Not found in the application's own commands. `module:install` and `module:download` are confirmed present and invoked from `app/Jobs/Install/`. |

Note that there is no `modules/` directory in the repository at all. Modules arrive through Composer
and are mapped into place, which the document does not describe.

### `permissions.md` (2020-03-18) - right idea, wrong version

Laratrust is still the ACL layer (`santigarcor/laratrust`), and `config/laratrust.php` is present.

The document links to Laratrust **5.0** documentation. The dependency is **`^7.0`**. Two major
versions of API drift sit between the linked reference and the installed package, so individual
method signatures in the examples need checking rather than trusting.

### `settings.md` (2020-07-17) - half broken

**Simple settings still work as documented.** The `settings` array in `module.json` is still a real
field.

**Custom settings are broken.** The document says to listen to `App\Events\Module\SettingShowing`.
That class does not exist anywhere in the codebase. `app/Events/Module/` contains `Copied`,
`Disabled`, `Disabling`, `Enabled`, `Installed`, `Installing`, `PaymentMethodShowing`, `Uninstalled`
and `Uninstalling`. The likely successor is `App\Events\Menu\SettingsCreated`, which exists and fits
the same purpose, but that is inference and needs confirming against a module that actually does it.

### `overriding-output.md` (2020-04-17) - mechanism valid, example dead

The view-composer approach is still standard Laravel and there is an `app/Providers/ViewComposer.php`
among the twelve service providers, so the pattern is clearly still in use.

The example does not resolve. It overrides `incomes.customers.create` and refers to
`resources/views/incomes/customers/create.blade.php`. **There is no `incomes/` view directory.** The
tree is now organised as `sales/` and `purchases/`, and the file is
`resources/views/sales/customers/create.blade.php`.

### `restful-api.md` (2021-05-11) - obsolete

The largest document in the manual and the least salvageable. It describes an API stack that has been
replaced wholesale.

| Claim | Current state |
|---|---|
| API is built on **Dingo API** | `dingo/api` is **absent** from `composer.json` |
| Register module routes via `app('Dingo\Api\Routing\Router')` | Dead |
| Authentication is **HTTP Basic** | `laravel/sanctum` (`^3.2`) is a dependency and `config/auth.php` defines a `passport` guard |
| Transformers live in `app/Transformers` | **Directory does not exist.** Replaced by `app/Http/Resources/` (`Auth`, `Banking`, `Common`, `Document`, `Setting`) |
| `read-api` permission gates API access | Correct. Still applied in `app/Http/Kernel.php`. |
| Endpoints live in `routes/api.php` | Correct, but the file is now plain Laravel routing with `Route::apiResource` |

Two facts survive out of six. Anything in the remaining thousand lines that depends on Dingo,
Basic auth, or transformers should be assumed wrong.

### `reverse-proxy.md` (2018-02-13) - obsolete

The oldest file in the manual, and the documented command will fail.

It says Akaunting ships `fideloper/TrustedProxy` and instructs
`php artisan vendor:publish --provider="Fideloper\Proxy\TrustedProxyServiceProvider"`.
`fideloper` is **absent** from `composer.json`; that package was absorbed into Laravel core at
version 9. `config/trustedproxy.php` and `app/Http/Middleware/TrustProxies.php` both exist, so the
capability is there, but it is Laravel's own and is configured differently.

### `adding-docs.md` (2020-04-18) - obsolete

Instructions for contributing to the documentation repository. That repository has not been touched
since December 2022, and the developer manual within it not since 2021. The process it describes is
no longer operating.

---

## The live successor

The vendor's help centre hosts a maintained version of this manual at
`akaunting.com/hc/docs/developers`. It is fresher than the repository copy, but only in places, and
it is aimed at the same audience.

**What it fixed:** the module page correctly names `akaunting/laravel-module`, which the repository
version gets wrong.

**What it did not fix:** it still lists the `module.json` fields as `alias`, `icon`, `version`,
`active`, `providers`, `aliases`, `files`, `requires`, `reports`, `widgets` and `settings`, omitting
the `extra-modules` and `routes` keys that the shipped Offline Payments module actually carries. And
it still points readers at the `akaunting/module` GitHub wiki, which is the dead pre-rename link.

**What it added:** three topics with no repository counterpart, on bulk actions, search strings and
payment methods.

**What it still does not cover, which is the important part.** The topic titled "Understanding the
hierarchy" sounds architectural and is not: it describes users managing companies that contain
invoices and customers. That is the domain hierarchy, at product level. Across the whole section
there is nothing on service providers, the console kernel, framework bootstrapping, module
autoloading mechanics, or the macro layer.

So the documentation landscape is: **published material explains how to build against Akaunting, and
nothing anywhere explains how Akaunting works.** The live docs are the better source for the first
question and no source at all for the second.

The practical consequence is that the live version needs the same verification discipline as the
dead one. It is fresher, not correct.

## What to carry forward

Three things worth writing into `AGENTS.md` directly, because they are cheap to state and expensive
to rediscover:

1. **Modules arrive via Composer and are path-mapped**, not created in-tree. `akaunting/laravel-module`
   is the mechanism. There is no `modules/` directory.
2. **`incomes/` no longer exists.** Views are split `sales/` and `purchases/`. Any reference to the
   old path in documentation or search results is pre-3.x.
3. **The API is plain Laravel with `app/Http/Resources/`,** not Dingo with transformers. Anything
   describing Dingo, HTTP Basic auth, or `app/Transformers` predates the rewrite.

And one thing to hold as an open question rather than a fact: whether `App\Events\Menu\SettingsCreated`
is genuinely the replacement for the vanished `SettingShowing`. It fits, but that has not been
confirmed against a module that uses it.
