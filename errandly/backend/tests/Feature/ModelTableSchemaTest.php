<?php

namespace Tests\Feature;

use App\Support\Schema\ModelTableVerifier;
use Tests\TestCase;

class ModelTableSchemaTest extends TestCase
{
    public function test_all_models_have_matching_migration_tables(): void
    {
        $failures = ModelTableVerifier::failures(checkDatabase: false);

        $this->assertSame(
            [],
            $failures,
            "Model table mismatches:\n" . implode("\n", $failures)
        );
    }
}
