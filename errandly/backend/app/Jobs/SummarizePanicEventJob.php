<?php

namespace App\Jobs;

use App\Models\PanicEvent;
use App\Services\Ai\PanicTriageSummarizer;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SummarizePanicEventJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public int $panicEventId) {}

    public function handle(PanicTriageSummarizer $summarizer): void
    {
        if (!config('ai.features.panic_triage')) {
            return;
        }

        $event = PanicEvent::find($this->panicEventId);
        if ($event) {
            $summarizer->summarize($event);
        }
    }
}
