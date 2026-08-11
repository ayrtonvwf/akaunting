<?php

namespace Tests\Unit;

use Tests\Concerns\IsolatesParallelTestState;
use Tests\TestCase;

// Guardrail: catches silent regressions in parallel-test isolation (see IsolatesParallelTestState),
// since the underlying race is otherwise a flaky, hard-to-reproduce CI failure. If a new file-backed
// driver or temp path is added to tests without going through IsolatesParallelTestState::testToken(),
// it should fail here rather than flake in CI.
class ParallelIsolationTest extends TestCase
{
    use IsolatesParallelTestState;

    public function testItShouldReturnDifferentCompiledViewPathsForDifferentTokens()
    {
        $path_one = $this->compiledViewPath('1');
        $path_two = $this->compiledViewPath('2');

        $this->assertNotEquals($path_one, $path_two);
    }

    public function testItShouldConfigureCompiledViewPathUnderTestingViewsDirectory()
    {
        $compiled = config('view.compiled');

        $this->assertStringContainsString('storage/framework/testing/views/', str_replace('\\', '/', $compiled));
    }

    public function testItShouldNotUseSharedUnsafeCompiledViewPath()
    {
        $compiled = config('view.compiled');
        $shared_unsafe_path = realpath(storage_path('framework/views'));

        $this->assertNotEquals($shared_unsafe_path, $compiled);
    }

    public function testItShouldDeriveCompiledViewPathFromGivenToken()
    {
        $path = $this->compiledViewPath('some-token');

        $this->assertStringEndsWith('/some-token', str_replace('\\', '/', $path));
    }

    public function testItShouldUseArrayCacheDriverInTesting()
    {
        $this->assertSame('array', config('cache.default'));
    }

    public function testItShouldUseArraySessionDriverInTesting()
    {
        $this->assertSame('array', config('session.driver'));
    }

    public function testItShouldUseInMemorySqliteDatabaseInTesting()
    {
        $this->assertSame(':memory:', config('database.connections.sqlite.database'));
    }

    public function testItShouldUseSyncQueueDriverInTesting()
    {
        $this->assertSame('sync', config('queue.default'));
    }

    public function testItShouldHaveDebugbarDisabledInTesting()
    {
        $this->assertFalse(config('debugbar.enabled'));
    }
}
