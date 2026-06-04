<?php

namespace App\Jobs;

use App\Models\Dispute;
use App\Services\Ai\DisputeSummarizer;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SummarizeDisputeJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public int $disputeId) {}

    public function handle(DisputeSummarizer $summarizer): void
    {
        if (!config('ai.features.dispute_copilot', true)) {
            return;
        }

        $dispute = Dispute::find($this->disputeId);
        if ($dispute && in_array($dispute->status, [Dispute::STATUS_OPEN, Dispute::STATUS_UNDER_REVIEW], true)) {
            $summarizer->summarize($dispute);
        }
    }
}
