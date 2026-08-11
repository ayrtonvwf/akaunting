<?php

namespace Tests;

use Illuminate\Contracts\Console\Kernel;
use Tests\Concerns\IsolatesParallelTestState;

trait CreatesApplication
{
    use IsolatesParallelTestState;

    /**
     * Creates the application.
     *
     * @return \Illuminate\Foundation\Application
     */
    public function createApplication()
    {
        $this->isolateCompiledViews();

        $app = require __DIR__ . '/../bootstrap/app.php';

        $app->make(Kernel::class)->bootstrap();

        return $app;
    }
}
