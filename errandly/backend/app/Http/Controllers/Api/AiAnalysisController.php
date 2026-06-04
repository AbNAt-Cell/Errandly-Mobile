<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AiVisionAnalysis;
use App\Models\Dispute;
use App\Models\KycDocument;
use App\Models\ProofSubmission;
use App\Services\Ai\DisputeSummarizer;
use App\Services\Ai\PolicySearchService;
use App\Services\Ai\Vision\KycDocumentAnalyzer;
use App\Services\Ai\Vision\ProofAnalyzer;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AiAnalysisController extends Controller
{
    public function searchPolicy(Request $request, PolicySearchService $search): JsonResponse
    {
        $request->validate(['query' => 'required|string|max:500', 'limit' => 'nullable|integer|max:10']);

        $chunks = $search->search(
            $request->string('query')->toString(),
            (int) ($request->input('limit', 5)),
            $request->user()->getRoleNames()->all(),
        );

        return response()->json(['chunks' => $chunks]);
    }

    public function proofAnalysis(Request $request, int $proofId, ProofAnalyzer $analyzer): JsonResponse
    {
        $proof = ProofSubmission::findOrFail($proofId);
        $errand = $proof->errand;
        if ($errand->customer_id !== $request->user()->id && $errand->runner_id !== $request->user()->id && !$request->user()->hasAnyRole(['admin', 'super_admin'])) {
            abort(404);
        }

        $analysis = AiVisionAnalysis::where('subject_type', 'proof_submission')
            ->where('subject_id', (string) $proofId)
            ->first();

        if (!$analysis && config('ai.features.proof_scan')) {
            $analysis = $analyzer->analyze($proof);
        }

        return response()->json(['analysis' => $analysis]);
    }

    public function kycAnalysis(Request $request, int $kycId, KycDocumentAnalyzer $analyzer): JsonResponse
    {
        if (!$request->user()->hasAnyRole(['admin', 'super_admin', 'verification_officer'])) {
            abort(403);
        }

        $kyc = KycDocument::findOrFail($kycId);
        $analysis = AiVisionAnalysis::where('subject_type', 'kyc_document')
            ->where('subject_id', (string) $kycId)
            ->first();

        if (!$analysis && config('ai.features.kyc_assist')) {
            $analysis = $analyzer->analyze($kyc);
        }

        return response()->json(['analysis' => $analysis]);
    }

    public function summarizeDispute(Request $request, int $disputeId, DisputeSummarizer $summarizer): JsonResponse
    {
        if (!$request->user()->hasAnyRole(['admin', 'super_admin', 'verification_officer'])) {
            abort(403);
        }

        $dispute = Dispute::findOrFail($disputeId);
        $analysis = $summarizer->summarize($dispute);

        return response()->json(['analysis' => $analysis]);
    }
}
