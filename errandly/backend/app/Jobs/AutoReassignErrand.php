<?php

namespace App\Jobs;

use App\Models\Errand;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

/**
 * Re-opens an errand for assignment after runner cancellation.
 */
class AutoReassignErrand implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public Errand $errand) {}

    public function handle(): void
    {
        NotifyNearbyRunners::dispatch($this->errand)->afterCommit();
    }
}
