<?php

namespace Tests\Unit\Audit;

use Akaunting\Audit\PathClassifier;
use PHPUnit\Framework\TestCase;

require_once __DIR__ . '/../../../tools/audit/PathClassifier.php';

class PathClassifierTest extends TestCase
{
    private PathClassifier $classifier;

    protected function setUp(): void
    {
        parent::setUp();

        $this->classifier = new PathClassifier();
    }

    public function testSurfaceIsTheLeadingSegment()
    {
        $this->assertSame(
            ['surface' => 'Providers', 'domain' => 'cross-cutting'],
            $this->classifier->classify('Providers/Macro.php')
        );
    }

    public function testHttpIsSplitOneLevelDeeperSoMiddlewareIsItsOwnSurface()
    {
        $this->assertSame(
            'Http/Middleware',
            $this->classifier->classify('Http/Middleware/Money.php')['surface']
        );

        $this->assertSame(
            'Http/Controllers',
            $this->classifier->classify('Http/Controllers/Sales/Invoices.php')['surface']
        );
    }

    public function testFilesDirectlyUnderHttpKeepHttpAsTheirSurface()
    {
        $this->assertSame(
            ['surface' => 'Http', 'domain' => 'cross-cutting'],
            $this->classifier->classify('Http/Kernel.php')
        );
    }

    public function testDomainComesFromTheFirstMatchingSegmentAfterTheSurface()
    {
        $this->assertSame(
            'Sales',
            $this->classifier->classify('Http/Controllers/Sales/Invoices.php')['domain']
        );

        $this->assertSame(
            'Banking',
            $this->classifier->classify('Models/Banking/Account.php')['domain']
        );
    }

    public function testDomainIsFoundBelowAnIntermediateSegment()
    {
        $this->assertSame(
            'Sales',
            $this->classifier->classify('Http/Controllers/Api/Sales/Invoices.php')['domain']
        );
    }

    public function testFirstMatchWinsWhenSegmentsNest()
    {
        $this->assertSame(
            'Banking',
            $this->classifier->classify('Jobs/Banking/Transactions/CreateTransaction.php')['domain']
        );
    }

    public function testInconsistentSpellingsAreCanonicalised()
    {
        $this->assertSame('Settings', $this->classifier->classify('Models/Setting/Category.php')['domain']);
        $this->assertSame('Settings', $this->classifier->classify('Jobs/Settings/CreateCategory.php')['domain']);
        $this->assertSame('Documents', $this->classifier->classify('Jobs/Document/CreateDocument.php')['domain']);
        $this->assertSame('Reports', $this->classifier->classify('Http/Controllers/Report/Standard.php')['domain']);
    }

    public function testUnrecognisedAreasAreCrossCutting()
    {
        $this->assertSame('cross-cutting', $this->classifier->classify('Console/Kernel.php')['domain']);
        $this->assertSame('cross-cutting', $this->classifier->classify('Http/Controllers/Portal/Invoices.php')['domain']);
    }

    public function testFilesAtTheRootOfAppGetTheRootSurface()
    {
        $this->assertSame(
            ['surface' => '(root)', 'domain' => 'cross-cutting'],
            $this->classifier->classify('Something.php')
        );
    }
}
