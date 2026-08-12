<?php

declare(strict_types=1);

/**
 * Ch1 audit: buckets the instrumented coverage run onto two axes and recounts the suite.
 *
 * Reads audit-out/clover.xml, writes audit-out/coverage.json and audit-out/coverage.md.
 * Every check here is a hard failure. Ch2, Ch3 and Ch4 are meant to trust this data without
 * re-deriving it, so a partial artefact that looks complete is worse than no artefact at all.
 */

require_once __DIR__ . '/PathClassifier.php';

use Akaunting\Audit\PathClassifier;

$root = dirname(__DIR__, 2);
$cloverPath = $root . '/audit-out/clover.xml';
$jsonPath = $root . '/audit-out/coverage.json';
$markdownPath = $root . '/audit-out/coverage.md';
$testsPath = $root . '/tests';

function fail(string $message): void
{
    fwrite(STDERR, "coverage-map: {$message}\n");

    exit(1);
}

function aggregate(array $files, string $key): array
{
    $buckets = [];

    foreach ($files as $file) {
        $bucket = $file[$key];

        if (! isset($buckets[$bucket])) {
            $buckets[$bucket] = ['files' => 0, 'untested_files' => 0, 'statements' => 0, 'covered' => 0];
        }

        $buckets[$bucket]['files']++;
        $buckets[$bucket]['statements'] += $file['statements'];
        $buckets[$bucket]['covered'] += $file['covered'];

        if ($file['covered'] === 0 && $file['statements'] > 0) {
            $buckets[$bucket]['untested_files']++;
        }
    }

    foreach ($buckets as $name => $bucket) {
        $buckets[$name]['percent'] = $bucket['statements'] === 0
            ? 0.0
            : round($bucket['covered'] / $bucket['statements'] * 100, 2);
    }

    ksort($buckets);

    return $buckets;
}

/**
 * Counting rules, stated so the numbers are reproducible: a test file is any *Test.php under
 * tests/; a test method is a `function testX` declaration or a #[Test]/@test marker; an assertion
 * call is any `->assertSomething(`. Different rules give different numbers, which is exactly why
 * the rule is written down here and repeated in AUDIT.md.
 */
function countSuite(string $testsPath): array
{
    if (! is_dir($testsPath)) {
        fail("missing tests directory at {$testsPath}");
    }

    $counts = ['files' => 0, 'methods' => 0, 'assertions' => 0];

    $iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($testsPath, FilesystemIterator::SKIP_DOTS));

    foreach ($iterator as $entry) {
        if (! $entry->isFile() || ! str_ends_with($entry->getFilename(), 'Test.php')) {
            continue;
        }

        $source = file_get_contents($entry->getPathname());

        $counts['files']++;
        $counts['methods'] += preg_match_all('/\bfunction\s+test[A-Z_]/', $source);
        $counts['methods'] += preg_match_all('/(#\[Test\]|@test\b)/', $source);
        $counts['assertions'] += preg_match_all('/->assert[A-Za-z]+\s*\(/', $source);
    }

    return $counts;
}

function renderTable(string $title, array $buckets): string
{
    $lines = [
        "### {$title}",
        '',
        '| bucket | files | untested files | statements | covered | % |',
        '|---|---:|---:|---:|---:|---:|',
    ];

    foreach ($buckets as $name => $bucket) {
        $lines[] = sprintf(
            '| %s | %d | %d | %d | %d | %.2f |',
            $name,
            $bucket['files'],
            $bucket['untested_files'],
            $bucket['statements'],
            $bucket['covered'],
            $bucket['percent']
        );
    }

    return implode("\n", $lines) . "\n";
}

if (! is_file($cloverPath)) {
    fail("missing {$cloverPath}; run the instrumented suite first");
}

$xml = @simplexml_load_file($cloverPath);

if ($xml === false) {
    fail("could not parse {$cloverPath}");
}

$fileNodes = $xml->xpath('//file');

if ($fileNodes === false || $fileNodes === []) {
    fail('clover report contains no <file> elements');
}

$classifier = new PathClassifier();

$files = [];
$sumStatements = 0;
$sumCovered = 0;

foreach ($fileNodes as $node) {
    $name = str_replace('\\', '/', (string) $node['name']);
    $marker = strpos($name, '/app/');

    if ($marker === false) {
        fail("file outside app/ scope in clover report: {$name}");
    }

    $relative = substr($name, $marker + 5);

    if (! isset($node->metrics) || ! isset($node->metrics['statements'])) {
        fail("file without metrics in clover report: {$relative}");
    }

    $labels = $classifier->classify($relative);

    if ($labels['surface'] === '' || $labels['domain'] === '') {
        fail("unclassified file: {$relative}");
    }

    $statements = (int) $node->metrics['statements'];
    $covered = (int) $node->metrics['coveredstatements'];

    $files[] = [
        'path' => 'app/' . $relative,
        'surface' => $labels['surface'],
        'domain' => $labels['domain'],
        'statements' => $statements,
        'covered' => $covered,
    ];

    $sumStatements += $statements;
    $sumCovered += $covered;
}

$projectMetrics = $xml->xpath('/coverage/project/metrics');

if ($projectMetrics === false || $projectMetrics === []) {
    fail('clover report has no project-level <metrics>');
}

$reportedStatements = (int) $projectMetrics[0]['statements'];
$reportedCovered = (int) $projectMetrics[0]['coveredstatements'];

if ($sumStatements !== $reportedStatements || $sumCovered !== $reportedCovered) {
    fail(sprintf(
        'bucketed totals do not reconcile: summed %d/%d, report says %d/%d',
        $sumCovered,
        $sumStatements,
        $reportedCovered,
        $reportedStatements
    ));
}

// Cross-check the report against the source tree. A report naming a file that is not on disk means
// the report is stale and everything downstream would be wrong. The reverse is legitimate: Clover
// omits files with no executable statements, so those are counted and reported rather than failed.
$onDisk = [];

$sourceIterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root . '/app', FilesystemIterator::SKIP_DOTS));

foreach ($sourceIterator as $entry) {
    if ($entry->isFile() && $entry->getExtension() === 'php') {
        $onDisk[] = 'app/' . str_replace('\\', '/', substr($entry->getPathname(), strlen($root . '/app/')));
    }
}

$reported = array_column($files, 'path');
$missingFromDisk = array_diff($reported, $onDisk);

if ($missingFromDisk !== []) {
    fail('clover report names files absent from app/: ' . implode(', ', array_slice($missingFromDisk, 0, 5)));
}

$withoutCoverageData = array_values(array_diff($onDisk, $reported));

sort($withoutCoverageData);

usort($files, fn (array $a, array $b): int => strcmp($a['path'], $b['path']));

$bySurface = aggregate($files, 'surface');
$byDomain = aggregate($files, 'domain');

$payload = [
    'generated_at' => gmdate('c'),
    'command' => 'docker compose -f compose.local.yml run --rm --no-deps app php -d pcov.enabled=1 -d pcov.directory=/var/www/html/app -d memory_limit=-1 vendor/bin/phpunit --coverage-clover audit-out/clover.xml',
    'totals' => [
        'files' => count($files),
        'statements' => $sumStatements,
        'covered' => $sumCovered,
        'percent' => $sumStatements === 0 ? 0.0 : round($sumCovered / $sumStatements * 100, 2),
        'php_files_on_disk' => count($onDisk),
    ],
    'files_without_coverage_data' => $withoutCoverageData,
    'suite' => countSuite($testsPath),
    'by_surface' => $bySurface,
    'by_domain' => $byDomain,
    'files' => $files,
];

file_put_contents(
    $jsonPath,
    json_encode($payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n"
);

file_put_contents(
    $markdownPath,
    renderTable('Coverage by framework surface', $bySurface)
    . "\n"
    . renderTable('Coverage by product domain', $byDomain)
);

printf(
    "coverage-map: %d files, %.2f%% of %d statements, %d test files / %d methods / %d assertions\n",
    count($files),
    $payload['totals']['percent'],
    $sumStatements,
    $payload['suite']['files'],
    $payload['suite']['methods'],
    $payload['suite']['assertions']
);
