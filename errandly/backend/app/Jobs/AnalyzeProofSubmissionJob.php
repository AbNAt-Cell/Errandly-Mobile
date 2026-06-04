<?php

namespace App\Jobs;

use App\Models\ProofSubmission;
use App\Services\Ai\Vision\GpsProofConsistencyChecker;
use App\Services\Ai\Vision\ProofAnalyzer;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class AnalyzeProofSubmissionJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public int $proofSubmissionId) {}

    public function handle(ProofAnalyzer $analyzer, GpsProofConsistencyChecker $gpsChecker): void
    {
        if (!config('ai.features.proof_scan')) {
            return;
        }

        $proof = ProofSubmission::find($this->proofSubmissionId);
        if ($proof) {
            $analyzer->analyze($proof);
            if (config('ai.features.gps_proof_check', true)) {
                $gpsChecker->check($proof);
            }
        }
    }
}
