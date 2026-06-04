<?php

namespace App\Jobs;

use App\Models\Dispute;
use App\Services\Ai\DisputeClassifier;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class ClassifyDisputeJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public int $disputeId) {}

    public function handle(DisputeClassifier $classifier): void
    {
        if (!config('ai.features.dispute_classifier')) {
            return;
        }

        $dispute = Dispute::find($this->disputeId);
        if ($dispute) {
            $classifier->classify($dispute);
        }
    }
}
