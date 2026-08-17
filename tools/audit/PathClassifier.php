<?php

declare(strict_types=1);

namespace Akaunting\Audit;

/**
 * Assigns every file under app/ exactly one framework surface and one product domain.
 *
 * Surface is the leading path segment, with Http/ split one level deeper so that Http/Middleware
 * and Http/Controllers are distinct: middleware is upgrade-sensitive in a way controllers are not.
 *
 * Domain is the first segment after the surface that appears in DOMAINS, which is an explicit list
 * taken from the product areas in docs/product/ rather than inferred from the directory tree.
 * Guessing at this list is how a domain axis quietly becomes a directory listing.
 */
final class PathClassifier
{
    /**
     * Segment => canonical domain name. The tree carries both spellings of the areas it names
     * inconsistently (Setting/Settings, Report/Reports, Document/Documents), so both are listed
     * and both collapse to one row in the table.
     */
    public const DOMAINS = [
        'Auth' => 'Auth',
        'Banking' => 'Banking',
        'Common' => 'Common',
        'Document' => 'Documents',
        'Documents' => 'Documents',
        'Purchases' => 'Purchases',
        'Report' => 'Reports',
        'Reports' => 'Reports',
        'Sales' => 'Sales',
        'Setting' => 'Settings',
        'Settings' => 'Settings',
    ];

    public const CROSS_CUTTING = 'cross-cutting';

    public const ROOT_SURFACE = '(root)';

    /**
     * @param string $relativePath path relative to app/, forward slashes,
     *                             e.g. "Http/Controllers/Sales/Invoices.php"
     *
     * @return array{surface: string, domain: string}
     */
    public function classify(string $relativePath): array
    {
        $segments = explode('/', trim(str_replace('\\', '/', $relativePath), '/'));

        array_pop($segments); // drop the filename

        if ($segments === []) {
            return ['surface' => self::ROOT_SURFACE, 'domain' => self::CROSS_CUTTING];
        }

        $surfaceDepth = ($segments[0] === 'Http' && count($segments) > 1) ? 2 : 1;
        $surface = implode('/', array_slice($segments, 0, $surfaceDepth));

        foreach (array_slice($segments, $surfaceDepth) as $segment) {
            if (isset(self::DOMAINS[$segment])) {
                return ['surface' => $surface, 'domain' => self::DOMAINS[$segment]];
            }
        }

        return ['surface' => $surface, 'domain' => self::CROSS_CUTTING];
    }
}
