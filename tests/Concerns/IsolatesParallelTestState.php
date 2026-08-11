<?php

namespace Tests\Concerns;

trait IsolatesParallelTestState
{
    protected function testToken(): string
    {
        return $_SERVER['TEST_TOKEN'] ?? 'serial';
    }

    public function compiledViewPath(string $token): string
    {
        return dirname(__DIR__, 2) . '/storage/framework/testing/views/' . $token;
    }

    // Runs before bootstrap/app.php is required, so this must not depend on the app being booted.
    public function isolateCompiledViews(): string
    {
        $token = $this->testToken();
        $path = $this->compiledViewPath($token);

        if (!is_dir($path)) {
            mkdir($path, 0755, true);
        }

        $_SERVER['VIEW_COMPILED_PATH'] = $path;
        putenv("VIEW_COMPILED_PATH=$path");

        return $path;
    }
}
