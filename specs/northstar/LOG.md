# Development log

**2026-08-06 — Local environment:** Configured [Laravel Herd](https://herd.laravel.com/) as the Windows PHP and Composer environment, set PHP 8.2 as the global and Akaunting-specific version, linked the checkout at [http://akaunting.test](http://akaunting.test), and verified Laravel and Composer platform requirements through Herd. Use `herd use <version>` to switch the global PHP version, `herd isolate <version>` to pin this project, and `herd php artisan ...` or `herd composer ...` to run project commands with its isolated PHP version.
