<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AiVisionAnalysis;
use App\Models\KycDocument;
use App\Services\KycService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class AdminKycController extends Controller
{
    public function __construct(private KycService $kycService) {}

    public function index(Request $request): JsonResponse
    {
        $kycs = KycDocument::with('user:id,first_name,last_name,email,phone,kyc_status')
            ->when($request->status, fn($q) => $q->where('status', $request->status))
            ->when($request->type, fn($q) => $q->where('type', $request->type))
            ->orderBy('submitted_at', 'asc')
            ->paginate(20);

        return response()->json($kycs);
    }

    public function pending(Request $request): JsonResponse
    {
        $kycs = KycDocument::with('user:id,first_name,last_name,email,phone')
            ->where('status', KycDocument::STATUS_SUBMITTED)
            ->orderBy('submitted_at', 'asc')
            ->paginate(20);

        return response()->json($kycs);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $kyc = KycDocument::with([
            'user',
            'user.runnerProfile',
            'reviewer:id,first_name,last_name',
        ])->findOrFail($id);

        $aiAnalysis = AiVisionAnalysis::where('subject_type', 'kyc_document')
            ->where('subject_id', (string) $kyc->id)
            ->first();

        return response()->json([
            'kyc' => $kyc,
            'ai_analysis' => $aiAnalysis,
        ]);
    }

    public function approve(Request $request, int $id): JsonResponse
    {
        $request->validate(['notes' => 'nullable|string']);

        $kyc = KycDocument::findOrFail($id);
        $this->kycService->approveKyc($kyc, $request->user(), $request->notes);

        return response()->json(['message' => 'KYC approved. User has been notified.']);
    }

    public function reject(Request $request, int $id): JsonResponse
    {
        $request->validate(['reason' => 'required|string|max:500']);

        $kyc = KycDocument::findOrFail($id);
        $this->kycService->rejectKyc($kyc, $request->user(), $request->reason);

        return response()->json(['message' => 'KYC rejected. User has been notified.']);
    }

    public function requestResubmission(Request $request, int $id): JsonResponse
    {
        $request->validate(['reason' => 'required|string|max:500']);

        $kyc = KycDocument::findOrFail($id);
        $this->kycService->requestResubmission($kyc, $request->user(), $request->reason);

        return response()->json(['message' => 'Resubmission requested. User has been notified.']);
    }
}
