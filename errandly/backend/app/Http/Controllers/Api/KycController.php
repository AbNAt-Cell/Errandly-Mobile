<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\KycDocument;
use App\Services\KycService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class KycController extends Controller
{
    public function __construct(private KycService $kycService) {}

    public function status(Request $request): JsonResponse
    {
        $kyc = $request->user()->kyc;
        return response()->json([
            'kyc_status' => $request->user()->kyc_status,
            'document' => $kyc,
        ]);
    }

    public function submit(Request $request): JsonResponse
    {
        $request->validate([
            'id_type' => 'required|in:national_id,drivers_license,passport,voters_card',
            'id_number' => 'required|string',
            'id_document_url' => 'required|string|url',
            'selfie_url' => 'required|string|url',
        ]);

        try {
            $kyc = $this->kycService->submitCustomerKyc($request->user(), $request->all());
            return response()->json([
                'message' => 'KYC submitted. We will review within 24 hours.',
                'kyc' => $kyc,
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function resubmit(Request $request): JsonResponse
    {
        return $this->submit($request);
    }

    public function documents(Request $request): JsonResponse
    {
        return response()->json($request->user()->kyc);
    }

    public function submitRunnerKyc(Request $request): JsonResponse
    {
        $request->validate([
            'id_type' => 'required|in:national_id,drivers_license,passport,voters_card',
            'id_number' => 'required|string',
            'id_document_url' => 'required|string|url',
            'selfie_url' => 'required|string|url',
            'nin_number' => 'nullable|string',
            'bvn_number' => 'nullable|string',
            'address_proof_url' => 'nullable|string|url',
        ]);

        try {
            $kyc = $this->kycService->submitRunnerKyc($request->user(), $request->all());
            return response()->json([
                'message' => 'KYC submitted successfully. We will review within 24-48 hours.',
                'kyc' => $kyc,
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }
}
