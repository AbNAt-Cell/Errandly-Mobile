<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\AuthorizesErrandAccess;
use App\Http\Controllers\Controller;
use App\Models\Errand;
use App\Services\ErrandService;
use App\Services\TrustScoreService;
use App\Support\GeoQuery;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class ErrandController extends Controller
{
    use AuthorizesErrandAccess;

    public function __construct(
        private ErrandService $errandService,
        private TrustScoreService $trustScoreService,
    ) {}

    public function customerIndex(Request $request): JsonResponse
    {
        $errands = Errand::where('customer_id', $request->user()->id)
            ->with(['runner', 'escrow', 'proofSubmissions'])
            ->when($request->status, fn($q) => $q->where('status', $request->status))
            ->orderBy('created_at', 'desc')
            ->paginate(15);

        return response()->json($errands);
    }

    public function available(Request $request): JsonResponse
    {
        $runner = $request->user();
        $profile = $runner->runnerProfile;

        if (!$profile?->is_online) {
            return response()->json(['message' => 'Go online to see available errands.'], 400);
        }

        $lat = $profile->current_latitude ?? $request->latitude;
        $lng = $profile->current_longitude ?? $request->longitude;

        if (!$lat || !$lng) {
            return response()->json(['message' => 'Location required.'], 400);
        }

        $radiusKm = $profile->service_radius_km ?? 10;

        $errandsQuery = Errand::query()
            ->where('status', Errand::STATUS_PENDING_ASSIGNMENT)
            ->whereNull('runner_id')
            ->with(['customer:id,first_name,last_name,profile_image']);

        GeoQuery::applyDistanceScope(
            $errandsQuery,
            (float) $lat,
            (float) $lng,
            (float) $radiusKm,
            'errands',
            'pickup_latitude',
            'pickup_longitude',
        );

        $errands = $errandsQuery
            ->orderBy('urgency', 'desc')
            ->paginate(20);

        return response()->json($errands);
    }

    public function runnerIndex(Request $request): JsonResponse
    {
        $errands = Errand::where('runner_id', $request->user()->id)
            ->with(['customer:id,first_name,last_name,phone,profile_image', 'proofSubmissions'])
            ->when($request->status, fn($q) => $q->where('status', $request->status))
            ->orderBy('created_at', 'desc')
            ->paginate(15);

        return response()->json($errands);
    }

    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:200',
            'description' => 'required|string|max:2000',
            'category' => 'required|in:' . implode(',', [
                Errand::CATEGORY_PACKAGE_PICKUP, Errand::CATEGORY_ITEM_DELIVERY,
                Errand::CATEGORY_GROCERY, Errand::CATEGORY_QUEUE_STANDING,
                Errand::CATEGORY_DOCUMENT_SUBMISSION, Errand::CATEGORY_DOCUMENT_COLLECTION,
                Errand::CATEGORY_SHOPPING, Errand::CATEGORY_PRESCRIPTION,
                Errand::CATEGORY_PERSONAL, Errand::CATEGORY_CUSTOM,
            ]),
            'urgency' => 'nullable|in:standard,urgent,scheduled',
            'pickup_address' => 'required|string',
            'pickup_latitude' => 'required|numeric|between:-90,90',
            'pickup_longitude' => 'required|numeric|between:-180,180',
            'destination_address' => 'required|string',
            'destination_latitude' => 'required|numeric|between:-90,90',
            'destination_longitude' => 'required|numeric|between:-180,180',
            'recipient_name' => 'nullable|string',
            'recipient_phone' => 'nullable|string',
            'item_details' => 'nullable|string',
            'special_instructions' => 'nullable|string',
            'budget' => 'required|integer|min:' . config('errandly.min_errand_amount', 500),
            'scheduled_at' => 'nullable|date|after:now',
            'attachments' => 'nullable|array',
            'attachments.*' => 'string|url',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        if (!$request->user()->isKycApproved()) {
            return response()->json(['message' => 'Please complete identity verification to post errands.'], 403);
        }

        try {
            $errand = $this->errandService->createErrand($request->user(), $validator->validated());
            return response()->json([
                'message' => 'Errand posted successfully. Looking for a runner...',
                'errand' => $errand->load(['escrow']),
            ], 201);
        } catch (QueryException $e) {
            Log::error('Errand creation failed', ['error' => $e->getMessage()]);
            return response()->json(['message' => 'Could not create errand. Please try again.'], 500);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function show(Request $request, Errand $errand): JsonResponse
    {
        $this->authorizeErrandView($request->user(), $errand);

        $errand->load([
            'customer:id,first_name,last_name,phone,profile_image',
            'runner:id,first_name,last_name,phone,profile_image',
            'runner.runnerProfile',
            'escrow',
            'proofSubmissions',
            'statusHistory',
            'dispute',
        ]);

        return response()->json($errand);
    }

    public function accept(Request $request, Errand $errand): JsonResponse
    {
        try {
            $errand = $this->errandService->acceptErrand($request->user(), $errand);
            return response()->json([
                'message' => 'Errand accepted. Navigate to pickup location.',
                'errand' => $errand,
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function reject(Request $request, Errand $errand): JsonResponse
    {
        return response()->json(['message' => 'Errand declined.']);
    }

    public function arrived(Request $request, Errand $errand): JsonResponse
    {
        try {
            $errand = $this->errandService->markArrived($request->user(), $errand);
            return response()->json(['message' => 'Arrival confirmed. OTP sent to customer.', 'errand' => $errand]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function verifyPickupOtp(Request $request, Errand $errand): JsonResponse
    {
        $request->validate(['otp' => 'required|string|size:6']);

        try {
            $errand = $this->errandService->verifyPickupOtp($request->user(), $errand, $request->otp);
            return response()->json(['message' => 'Pickup verified. You can start the errand.', 'errand' => $errand]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function start(Request $request, Errand $errand): JsonResponse
    {
        try {
            $errand = $this->errandService->startErrand($request->user(), $errand);
            return response()->json(['message' => 'Errand started.', 'errand' => $errand]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function submitProof(Request $request, Errand $errand): JsonResponse
    {
        return $this->submitProofInternal($request, $errand);
    }

    /** Alias for mobile clients that call POST .../complete */
    public function complete(Request $request, Errand $errand): JsonResponse
    {
        return $this->submitProofInternal($request, $errand);
    }

    private function submitProofInternal(Request $request, Errand $errand): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'type' => 'nullable|in:photo,receipt,signature,note',
            'file_url' => 'nullable|string|url',
            'notes' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $payload = $validator->validated();
        $payload['type'] = $payload['type'] ?? 'note';

        try {
            $errand = $this->errandService->submitProof($request->user(), $errand, $payload);
            return response()->json([
                'message' => 'Proof submitted. Waiting for customer confirmation.',
                'errand' => $errand,
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function confirmCompletion(Request $request, Errand $errand): JsonResponse
    {
        $request->validate(['otp' => 'required|string|size:6']);
        $this->authorizeErrandCustomer($request->user(), $errand);

        try {
            $errand = $this->errandService->confirmCompletion($request->user(), $errand, $request->otp);
            return response()->json([
                'message' => 'Errand completed! Payment released to runner.',
                'errand' => $errand,
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function cancel(Request $request, Errand $errand): JsonResponse
    {
        $request->validate(['reason' => 'required|string|max:500']);
        $this->authorizeErrandCustomer($request->user(), $errand);

        try {
            $errand = $this->errandService->cancelByCustomer($request->user(), $errand, $request->reason);
            return response()->json(['message' => 'Errand cancelled.', 'errand' => $errand]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function runnerCancel(Request $request, Errand $errand): JsonResponse
    {
        $request->validate(['reason' => 'required|string|max:500']);

        try {
            $errand = $this->errandService->cancelByRunner($request->user(), $errand, $request->reason);
            return response()->json(['message' => 'Errand cancelled.', 'errand' => $errand]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function panic(Request $request, Errand $errand): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'notes' => 'nullable|string',
        ]);

        $this->authorizeErrandParticipant($request->user(), $errand);

        try {
            $this->errandService->triggerPanic($request->user(), $errand, $validator->validated());
            return response()->json(['message' => 'Panic alert sent. Admin has been notified. Stay safe.']);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function getProof(Request $request, Errand $errand): JsonResponse
    {
        $this->authorizeErrandView($request->user(), $errand);

        $errand->load('proofSubmissions');

        return response()->json($errand->proofSubmissions);
    }

    public function generateDeliveryOtp(Request $request, Errand $errand): JsonResponse
    {
        $this->authorizeErrandCustomer($request->user(), $errand);

        if ($errand->status !== Errand::STATUS_AWAITING_CONFIRMATION) {
            return response()->json(['message' => 'OTP not available at this stage.'], 400);
        }

        return response()->json(['message' => 'Delivery OTP was sent when runner submitted proof. Check your notifications.']);
    }

    public function update(Request $request, Errand $errand): JsonResponse
    {
        $this->authorizeErrandCustomer($request->user(), $errand);

        if (!in_array($errand->status, [Errand::STATUS_DRAFT, Errand::STATUS_POSTED])) {
            return response()->json(['message' => 'Cannot edit errand after assignment.'], 400);
        }

        $errand->update($request->only([
            'title', 'description', 'special_instructions', 'scheduled_at',
        ]));

        return response()->json(['message' => 'Errand updated.', 'errand' => $errand]);
    }
}
