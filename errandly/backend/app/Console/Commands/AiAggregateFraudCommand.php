<?php

namespace App\Console\Commands;

use App\Services\Ai\FraudSignalAggregator;
use Illuminate\Console\Command;

class AiAggregateFraudCommand extends Command
{
    protected $signature = 'ai:aggregate-fraud';

    protected $description = 'Run heuristic fraud signal detection';

    public function handle(FraudSignalAggregator $aggregator): int
    {
        $count = $aggregator->aggregate();
        $this->info("Created {$count} new fraud signal(s).");

        return self::SUCCESS;
    }
}
