<?php

namespace App\Console\Commands;

use App\Support\Schema\ModelTableVerifier;
use Illuminate\Console\Command;

class VerifyModelTablesCommand extends Command
{
    protected $signature = 'schema:verify-models
                            {--database : Also check that each table exists in the connected database}';

    protected $description = 'Verify Eloquent model table names match migration definitions (and optionally the database)';

    public function handle(): int
    {
        $checkDatabase = (bool) $this->option('database');
        $failures = ModelTableVerifier::failures($checkDatabase);

        if ($failures === []) {
            $this->info('All models have matching migration tables' . ($checkDatabase ? ' and database tables.' : '.'));

            return self::SUCCESS;
        }

        $this->error('Model / schema mismatches found:');
        foreach ($failures as $message) {
            $this->line("  - {$message}");
        }

        $this->newLine();
        $this->line('Fix by aligning migration Schema::create() names with each model\'s getTable() name.');
        $this->line('Run migrations after fixing: php artisan migrate');

        return self::FAILURE;
    }
}
