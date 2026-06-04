<?php

namespace App\Jobs;

use App\Models\KycDocument;
use App\Services\Ai\Vision\KycDocumentAnalyzer;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class AnalyzeKycSubmissionJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public int $kycDocumentId) {}

    public function handle(KycDocumentAnalyzer $analyzer): void
    {
        if (!config('ai.features.kyc_assist')) {
            return;
        }

        $kyc = KycDocument::find($this->kycDocumentId);
        if ($kyc && $kyc->status === KycDocument::STATUS_SUBMITTED) {
            $analyzer->analyze($kyc);
        }
    }
}
