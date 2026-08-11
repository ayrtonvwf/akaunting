<?php

namespace Tests\Feature\Parallel;

use Illuminate\Support\Facades\View;
use Tests\Feature\FeatureTestCase;

// Reproduces the exact production CI failure by construction: parallel workers used to share
// storage/framework/views, and Illuminate\Filesystem\Filesystem::put() is not atomic, so a
// worker could `include` another worker's 0-byte, mid-write compiled view and render an empty
// body with a 200 status (as happened to AccountsTest::testItShouldSeeAccountListPage in CI).
// If tests/CreatesApplication.php stops calling isolateCompiledViews() (or points it back at the
// shared storage/framework/views directory), step 4 below should fail the same way.
class CompiledViewIsolationTest extends FeatureTestCase
{
    protected $plantedFiles = [];

    protected $plantedDir;

    public function testItShouldIgnoreStaleCompiledViewsFromOtherWorkers()
    {
        $viewName = 'banking.accounts.index';

        // Step 1: populate this worker's own isolated compiled-view directory.
        $this->loginAs()
            ->get(route('accounts.index'))
            ->assertStatus(200)
            ->assertSeeText(trans_choice('general.accounts', 2));

        // Step 2: resolve the deterministic, hash-based compiled filename for this view.
        $sourcePath = View::make($viewName)->getPath();
        $compiledPath = app('blade.compiler')->getCompiledPath($sourcePath);
        $basename = basename($compiledPath);

        // Step 3: simulate a concurrent worker caught mid file_put_contents() on this same
        // view, in both the old shared directory and a different worker's isolated directory.
        $sharedPath = storage_path('framework/views/' . $basename);
        file_put_contents($sharedPath, '');
        touch($sharedPath, time());
        $this->plantedFiles[] = $sharedPath;

        $this->plantedDir = storage_path('framework/testing/views/some-other-worker-token');
        if (!is_dir($this->plantedDir)) {
            mkdir($this->plantedDir, 0755, true);
        }

        $otherWorkerPath = $this->plantedDir . '/' . $basename;
        file_put_contents($otherWorkerPath, '');
        touch($otherWorkerPath, time());
        $this->plantedFiles[] = $otherWorkerPath;

        // Step 4: this worker must still read its own compiled view, unaffected by the decoys.
        $this->loginAs()
            ->get(route('accounts.index'))
            ->assertStatus(200)
            ->assertSeeText(trans_choice('general.accounts', 2));
    }

    protected function tearDown(): void
    {
        foreach ($this->plantedFiles as $file) {
            if (file_exists($file)) {
                @unlink($file);
            }
        }

        if ($this->plantedDir && is_dir($this->plantedDir) && count(scandir($this->plantedDir)) === 2) {
            @rmdir($this->plantedDir);
        }

        parent::tearDown();
    }
}
