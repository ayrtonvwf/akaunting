# Extension vocabulary

This is a product-facing reference for the vocabulary used to describe Akaunting extensions. It is not an API contract or an implementation tutorial. Published concepts are linked to the developer Help Centre; statements checked in this checkout are marked **Verified against source** and name the local evidence.

## Extension concepts

- **Module** — an installable unit that adds or changes product behavior. The [modules guidance](https://akaunting.com/hc/docs/developers/modules/) provides the published extension context. **Verified against source** — this checkout depends on `akaunting/laravel-module`, maps installed module packages into `modules/`, and autoloads the `Modules\` namespace (`composer.json`).
- **`module.json`** — a module manifest that describes the module and declares extension metadata such as providers and settings. **Verified against source** — the installed Offline Payments and PayPal Standard manifests also contain `extra-modules` and `routes` (`modules/OfflinePayments/module.json`; `modules/PaypalStandard/module.json`).
- **Provider** — a module bootstrap entry that registers or starts the module's application services. **Verified against source** — both installed payment module manifests declare `Providers\Event` and `Providers\Main` entries (`modules/OfflinePayments/module.json`; `modules/PaypalStandard/module.json`).
- **Menu extension** — an addition to a menu-building surface, commonly made by responding to a menu event; see the published [menu guidance](https://akaunting.com/hc/docs/developers/menu/). **Verified against source** — the settings menu dispatches `SettingsCreated`, whose event object carries the menu being built (`app/Http/Livewire/Menu/Settings.php`; `app/Events/Menu/SettingsCreated.php`). This confirms the current event surface, not its relationship to any retired event.
- **Module settings** — configuration fields a module exposes to the product's settings experience; see the published [settings guidance](https://akaunting.com/hc/docs/developers/settings/). **Verified against source** — `settings` is a manifest field, and the installed PayPal Standard manifest declares its configuration controls there (`modules/PaypalStandard/module.json`).
- **Model hooks and observers** — extension points that react to model lifecycle events so behavior can accompany changes to business records; see the published [hooking models guidance](https://akaunting.com/hc/docs/developers/hooking-models/). **Verified against source** — the checkout includes `App\Abstracts\Observer`, registers observers through `app/Providers/Observer.php`, and depends on `akaunting/laravel-mutable-observer` (`app/Abstracts/Observer.php`; `app/Providers/Observer.php`; `composer.json`).
- **Bulk actions** — actions designed to operate on a selected set of records rather than a single record. The [bulk actions guidance](https://akaunting.com/hc/docs/developers/bulk-actions/) is the published reference.
- **Search strings** — structured search input used to express filters over searchable records. The [search string guidance](https://akaunting.com/hc/docs/developers/search-string/) is the published reference. **Verified against source** — this checkout depends on `lorisleiva/laravel-search-string` (`composer.json`).
- **Output overriding** — substituting or composing presentation output supplied by the application. The [overriding output guidance](https://akaunting.com/hc/docs/developers/overriding-output/) describes the published approach. **Verified against source** — a view-composer provider exists, while the current customer-create view is under `resources/views/sales/`, not the older `resources/views/incomes/` example path (`app/Providers/ViewComposer.php`; `resources/views/sales/customers/create.blade.php`; [drift audit](../../specs/northstar/DOCS-DRIFT-AUDIT.md)).
- **Payment method** — an extension that presents a way to collect or record payment; see the published [making a payment method guidance](https://akaunting.com/hc/docs/developers/making-a-payment-method/). **Verified against source** — Offline Payments and PayPal Standard are separate Composer packages installed into module paths (`composer.json`; `modules/OfflinePayments/module.json`; `modules/PaypalStandard/module.json`).
- **API** — the programmatic application surface through which clients work with Akaunting data. The published [RESTful API guidance](https://akaunting.com/hc/docs/developers/restful-api/) must be checked against the current application before use. **Verified against source** — current API routes use Laravel routing and response resources live under `app/Http/Resources` (`routes/api.php`; `app/Http/Resources/`; [drift audit](../../specs/northstar/DOCS-DRIFT-AUDIT.md)).
- **Version compatibility** — the requirement that an extension's supported Akaunting, framework, package, and PHP versions align with the target installation; see the published [version compatibility guidance](https://akaunting.com/hc/docs/developers/version-compatibility/). **Verified against source** — this checkout constrains PHP to `^8.1`, Laravel to `^10.0`, `akaunting/laravel-module` to `^4.0`, and the two installed payment module packages to `^3.0` (`composer.json`).

## Published guidance checked against this checkout

The corrections below come from the [developer-documentation drift audit](../../specs/northstar/DOCS-DRIFT-AUDIT.md) and are restated here because they change how the published extension surface should be read.

- The module package is akaunting/laravel-module, not the former akaunting/module name. **Verified against source** — `composer.json` declares `akaunting/laravel-module` and contains no dependency on the former package name; see the [drift audit](../../specs/northstar/DOCS-DRIFT-AUDIT.md).
- Modules are Composer-installed and path-mapped; modules/ is not a source-tracked core directory. **Verified against source** — `composer.json` maps `akaunting/module-offline-payments` and `akaunting/module-paypal-standard` to `modules/OfflinePayments` and `modules/PaypalStandard`; the two `module.json` files appeared only after the locked Composer dependencies were installed; see the [drift audit](../../specs/northstar/DOCS-DRIFT-AUDIT.md).
- The shipped module manifest surface includes extra-modules and routes in addition to the published field list. **Verified against source** — both keys are present in `modules/OfflinePayments/module.json` and `modules/PaypalStandard/module.json`; see the [drift audit](../../specs/northstar/DOCS-DRIFT-AUDIT.md).
- SettingsCreated exists; do not state that the vanished SettingShowing event exists. **Verified against source** — `app/Events/Menu/SettingsCreated.php` exists and is dispatched by `app/Http/Livewire/Menu/Settings.php`; no `SettingShowing` reference exists under `app/` or the installed `modules/`; see the [drift audit](../../specs/northstar/DOCS-DRIFT-AUDIT.md).
- The API is plain Laravel with app/Http/Resources; do not describe the retired Dingo/transformer stack as current. **Verified against source** — `routes/api.php` uses Laravel routing, `app/Http/Resources/` exists, and `composer.json` has no `dingo/api` dependency; see the [drift audit](../../specs/northstar/DOCS-DRIFT-AUDIT.md).

### Open question: settings menu event lineage

**Verified against source** — `SettingsCreated` is a current settings-menu event (`app/Events/Menu/SettingsCreated.php`; `app/Http/Livewire/Menu/Settings.php`). The local evidence does not prove that it is a behavioral replacement for the vanished `SettingShowing` event. Treat that relationship as unresolved until a module or migration history demonstrates it; see the [drift audit](../../specs/northstar/DOCS-DRIFT-AUDIT.md).

## Related product concepts

Extensions can add capabilities without redefining the canonical product vocabulary in [shared concepts](concepts.md). Module settings and installable capabilities relate to [administration](administration.md), while payment methods relate to the settlement and transaction vocabulary in [sales](sales.md) and [banking](banking.md).

## Published sources

- [Developer Help Centre index](https://akaunting.com/hc/docs/developers/), checked as part of the Help Centre snapshot on 2026-08-06.
- [Modules](https://akaunting.com/hc/docs/developers/modules/)
- [Menu](https://akaunting.com/hc/docs/developers/menu/)
- [Settings](https://akaunting.com/hc/docs/developers/settings/)
- [Bulk Actions](https://akaunting.com/hc/docs/developers/bulk-actions/)
- [Hooking Models](https://akaunting.com/hc/docs/developers/hooking-models/)
- [Search String](https://akaunting.com/hc/docs/developers/search-string/)
- [Overriding Output](https://akaunting.com/hc/docs/developers/overriding-output/)
- [Making a Payment Method](https://akaunting.com/hc/docs/developers/making-a-payment-method/)
- [Version Compatibility](https://akaunting.com/hc/docs/developers/version-compatibility/)
- [RESTful API](https://akaunting.com/hc/docs/developers/restful-api/), retained as published guidance but corrected above where it conflicts with the checkout.
