<?php

declare(strict_types=1);

/**
 * Ch1 audit: records a Laravel ceiling and a reason for every direct Composer dependency.
 *
 * Reads composer.json and composer.lock, queries Packagist per direct package, and writes
 * audit-out/ceilings.json and audit-out/ceilings.md. Transitive packages are out of scope: one
 * enters the audit only when a resolver probe names it as the reason a direct package is stuck.
 *
 * There is no blank state and no default bucket. A package this script cannot place in exactly one
 * classification stops the run.
 */

require_once dirname(__DIR__, 2) . '/vendor/autoload.php';

use Composer\Semver\Semver;
use Composer\Semver\VersionParser;

const TARGET_MAJOR = 12;
const CANDIDATE_MAJORS = [13, 12, 11, 10, 9, 8, 7, 6, 5];
const USER_AGENT = 'akaunting-fork-ch1-audit (+https://github.com/ayrtonvwf/akaunting)';

function fail(string $message): void
{
    fwrite(STDERR, "ceilings: {$message}\n");

    exit(1);
}

function fetchPackagist(string $name): array
{
    $context = stream_context_create([
        'http' => [
            'header' => "User-Agent: " . USER_AGENT . "\r\nAccept: application/json\r\n",
            'timeout' => 30,
            'ignore_errors' => true,
        ],
    ]);

    $body = @file_get_contents("https://packagist.org/packages/{$name}.json", false, $context);

    if ($body === false) {
        fail("request failed for {$name}");
    }

    $status = 0;

    foreach ($http_response_header ?? [] as $header) {
        if (preg_match('#^HTTP/\S+\s+(\d{3})#', $header, $matches) === 1) {
            $status = (int) $matches[1];
        }
    }

    if ($status !== 200) {
        fail("Packagist returned HTTP {$status} for {$name}");
    }

    $decoded = json_decode($body, true);

    if (! is_array($decoded) || ! isset($decoded['package']['versions'])) {
        fail("unexpected Packagist payload for {$name}");
    }

    return $decoded['package'];
}

function latestStable(string $name, array $versions): array
{
    $best = null;
    $bestNormalized = null;

    foreach ($versions as $version => $details) {
        if (! isset($details['version_normalized'])) {
            continue;
        }

        if (VersionParser::parseStability((string) $version) !== 'stable') {
            continue;
        }

        $normalized = (string) $details['version_normalized'];

        if ($bestNormalized === null || version_compare($normalized, $bestNormalized, '>')) {
            $best = $details;
            $bestNormalized = $normalized;
        }
    }

    if ($best === null) {
        fail("no stable release found for {$name}");
    }

    return $best;
}

function laravelConstraints(array $require): array
{
    $constraints = [];

    foreach ($require as $dependency => $constraint) {
        if ($dependency === 'laravel/framework' || str_starts_with($dependency, 'illuminate/')) {
            $constraints[$dependency] = (string) $constraint;
        }
    }

    ksort($constraints);

    return $constraints;
}

function ceilingFor(array $constraints): ?int
{
    foreach (CANDIDATE_MAJORS as $major) {
        $satisfiesAll = true;

        foreach ($constraints as $constraint) {
            if (! Semver::satisfies("{$major}.99.99", $constraint)) {
                $satisfiesAll = false;

                break;
            }
        }

        if ($satisfiesAll) {
            return $major;
        }
    }

    return null;
}

function renderTable(array $records): string
{
    $lines = [
        '| package | section | installed | latest | released | ceiling | classification |',
        '|---|---|---|---|---|---:|---|',
    ];

    foreach ($records as $record) {
        $lines[] = sprintf(
            '| %s%s | %s | %s | %s | %s | %s | %s |',
            $record['name'],
            $record['first_party'] ? ' *(first-party)*' : '',
            $record['section'],
            $record['installed'],
            $record['latest'],
            substr($record['latest_released_at'], 0, 10),
            $record['ceiling'] === null ? '—' : (string) $record['ceiling'],
            $record['classification']
        );
    }

    return implode("\n", $lines) . "\n";
}

if (! class_exists(Semver::class)) {
    fail('composer/semver is not installed; run composer install first');
}

$root = dirname(__DIR__, 2);
$composer = json_decode(file_get_contents($root . '/composer.json'), true);
$lock = json_decode(file_get_contents($root . '/composer.lock'), true);

if (! is_array($composer) || ! is_array($lock)) {
    fail('could not read composer.json or composer.lock');
}

$installed = [];

foreach (array_merge($lock['packages'], $lock['packages-dev']) as $package) {
    $installed[$package['name']] = $package['version'];
}

$direct = [];

foreach (['require', 'require-dev'] as $section) {
    foreach (array_keys($composer[$section] ?? []) as $name) {
        if ($name === 'php' || str_starts_with($name, 'ext-')) {
            continue;
        }

        $direct[$name] = $section;
    }
}

ksort($direct);

$records = [];

foreach ($direct as $name => $section) {
    if (! isset($installed[$name])) {
        fail("{$name} is required but absent from composer.lock; the lockfile is out of date");
    }

    $package = fetchPackagist($name);
    $latest = latestStable($name, $package['versions']);
    $constraints = laravelConstraints($latest['require'] ?? []);

    if ($name === 'laravel/framework') {
        // The framework declares no constraint on itself, so its ceiling is its own major.
        $ceiling = (int) explode('.', ltrim((string) $latest['version'], 'v'))[0];
        $constraints = ['laravel/framework' => '(itself)'];
    } elseif ($constraints === []) {
        $ceiling = null;
    } else {
        $ceiling = ceilingFor($constraints);

        if ($ceiling === null) {
            fail("{$name} declares Laravel constraints no candidate major satisfies: " . json_encode($constraints));
        }
    }

    $abandoned = $package['abandoned'] ?? false;

    if ($abandoned !== false) {
        $classification = 'abandoned';
    } elseif ($constraints === []) {
        $classification = 'framework-agnostic';
    } elseif ($ceiling >= TARGET_MAJOR) {
        $classification = 'supports-12';
    } else {
        $classification = 'ceiling-below';
    }

    $records[] = [
        'name' => $name,
        'section' => $section,
        'first_party' => str_starts_with($name, 'akaunting/'),
        'installed' => $installed[$name],
        'latest' => (string) $latest['version'],
        'latest_released_at' => (string) ($latest['time'] ?? ''),
        'laravel_constraints' => $constraints,
        'ceiling' => $ceiling,
        'classification' => $classification,
        'abandoned_replacement' => is_string($abandoned) ? $abandoned : null,
    ];

    usleep(200000); // stay polite to Packagist
}

if (count($records) !== count($direct)) {
    fail('not every direct dependency produced a record');
}

$summary = [];

foreach ($records as $record) {
    $summary[$record['classification']] = ($summary[$record['classification']] ?? 0) + 1;
}

ksort($summary);

file_put_contents(
    $root . '/audit-out/ceilings.json',
    json_encode([
        'generated_at' => gmdate('c'),
        'source' => 'https://packagist.org/packages/{name}.json',
        'target_laravel_major' => TARGET_MAJOR,
        'summary' => $summary,
        'packages' => $records,
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n"
);

file_put_contents($root . '/audit-out/ceilings.md', renderTable($records));

printf("ceilings: %d direct dependencies\n", count($records));

foreach ($summary as $classification => $count) {
    printf("  %-20s %d\n", $classification, $count);
}
