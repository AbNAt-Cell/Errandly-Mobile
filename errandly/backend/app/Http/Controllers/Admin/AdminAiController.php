<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AiFraudSignal;
use App\Models\AiVisionAnalysis;
use App\Models\Dispute;
use App\Models\Errand;
use App\Models\KycDocument;
use App\Services\Ai\DisputeSummarizer;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminAiController extends Controller
{
    public function errandInsights(Request $request, Errand $errand): JsonResponse
    {
        $proofIds = $errand->proofSubmissions()->pluck('id')->map(fn ($id) => (string) $id);

        $analyses = AiVisionAnalysis::query()
            ->where(function ($q) use ($proofIds, $errand) {
                $q->where('subject_type', 'proof_submission')
                    ->whereIn('subject_id', $proofIds);
            })
            ->get()
            ->keyBy('subject_id');

        return response()->json([
            'proof_analyses' => $analyses,
        ]);
    }

    public function kycAnalysis(int $kycId): JsonResponse
    {
        KycDocument::findOrFail($kycId);

        $analysis = AiVisionAnalysis::where('subject_type', 'kyc_document')
            ->where('subject_id', (string) $kycId)
            ->first();

        return response()->json(['analysis' => $analysis]);
    }

    public function summarizeDispute(Request $request, int $disputeId, DisputeSummarizer $summarizer): JsonResponse
    {
        $dispute = Dispute::findOrFail($disputeId);
        $analysis = $summarizer->summarize($dispute);

        return response()->json(['analysis' => $analysis]);
    }

    public function disputeAnalysis(int $disputeId): JsonResponse
    {
        $summary = AiVisionAnalysis::where('subject_type', 'dispute')
            ->where('subject_id', (string) $disputeId)
            ->first();
        $classification = AiVisionAnalysis::where('subject_type', 'dispute_classification')
            ->where('subject_id', (string) $disputeId)
            ->first();

        return response()->json([
            'summary' => $summary,
            'classification' => $classification,
        ]);
    }

    public function fraudSignals(Request $request): JsonResponse
    {
        $signals = AiFraudSignal::query()
            ->when($request->status, fn ($q) => $q->where('status', $request->status))
            ->when($request->severity, fn ($q) => $q->where('severity', $request->severity))
            ->orderByDesc('created_at')
            ->paginate(20);

        return response()->json($signals);
    }

    public function panicAnalysis(int $panicId): JsonResponse
    {
        $analysis = AiVisionAnalysis::where('subject_type', 'panic_event')
            ->where('subject_id', (string) $panicId)
            ->first();

        return response()->json(['analysis' => $analysis]);
    }
}
