<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Errand;
use App\Services\ErrandService;
use App\Services\TrustScoreService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;

class ErrandController extends Controller
{
    public function __construct(
        private ErrandService $errandService,
        private TrustScoreService $trustScoreService,
    ) {}

    // Customer: list their errands
    public function customerIndex(Request $request): JsonResponse
    {
        $errands = Errand::where('customer_id', $request->user()->id)
            ->with(['runner', 'escrow', 'proofSubmissions'])
            ->when($request->status, fn($q) => $q->where('status', $request->status))
            ->orderBy('created_at', 'desc')
            ->paginate(15);

        return response()->json($errands);
    }

    // Runner: list available errands nearby
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

        $errands = Errand::select([
            'errands.*',
            \DB::raw("
                (6371 * acos(
                    cos(radians({$lat})) *
                    cos(radians(pickup_latitude)) *
                    cos(radians(pickup_longitude) - radians({$lng})) +
                    sin(radians({$lat})) *
                    sin(radians(pickup_latitude))
                )) AS distance_km
            "),
        ])
        ->where('status', Errand::STATUS_PENDING_ASSIGNMENT)
        ->whereNull('runner_id')
        ->with(['customer:id,first_name,last_name,profile_image'])
        ->having('distance_km', '<=', $profile->service_radius_km ?? 10)
        ->orderBy('distance_km', 'asc')
        ->orderBy('urgency', 'desc')
        ->paginate(20);

        return response()->json($errands);
    }

    // Runner: list their assigned errands
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
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $errand = Errand::with([
            'customer:id,first_name,last_name,phone,profile_image',
            'runner:id,first_name,last_name,phone,profile_image',
            'runner.runnerProfile',
            'escrow',
            'proofSubmissions',
            'statusHistory',
            'dispute',
        ])->findOrFail($id);

        // Authorization: only customer, runner, or admin can view
        if ($user->hasRole('customer') && $errand->customer_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }
        if ($user->hasRole('runner') && $errand->runner_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        return response()->json($errand);
    }

    public function accept(Request $request, int $id): JsonResponse
    {
        $errand = Errand::findOrFail($id);

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

    public function reject(Request $request, int $id): JsonResponse
    {
        // Runner rejects/ignores an errand offer — no penalty
        return response()->json(['message' => 'Errand declined.']);
    }

    public function arrived(Request $request, int $id): JsonResponse
    {
        $errand = Errand::findOrFail($id);

        try {
            $errand = $this->errandService->markArrived($request->user(), $errand);
            return response()->json(['message' => 'Arrival confirmed. OTP sent to customer.', 'errand' => $errand]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function verifyPickupOtp(Request $request, int $id): JsonResponse
    {
        $request->validate(['otp' => 'required|string|size:6']);
        $errand = Errand::findOrFail($id);

        try {
            $errand = $this->errandService->verifyPickupOtp($request->user(), $errand, $request->otp);
            return response()->json(['message' => 'Pickup verified. You can start the errand.', 'errand' => $errand]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function start(Request $request, int $id): JsonResponse
    {
        $errand = Errand::findOrFail($id);

        try {
            $errand = $this->errandService->startErrand($request->user(), $errand);
            return response()->json(['message' => 'Errand started.', 'errand' => $errand]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function submitProof(Request $request, int $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'type' => 'required|in:photo,receipt,signature,note',
            'file_url' => 'nullable|string|url',
            'notes' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $errand = Errand::findOrFail($id);

        try {
            $errand = $this->errandService->submitProof($request->user(), $errand, $validator->validated());
            return response()->json([
                'message' => 'Proof submitted. Waiting for customer confirmation.',
                'errand' => $errand,
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function confirmCompletion(Request $request, int $id): JsonResponse
    {
        $request->validate(['otp' => 'required|string|size:6']);
        $errand = Errand::findOrFail($id);

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

    public function cancel(Request $request, int $id): JsonResponse
    {
        $request->validate(['reason' => 'required|string|max:500']);
        $errand = Errand::findOrFail($id);

        try {
            $errand = $this->errandService->cancelByCustomer($request->user(), $errand, $request->reason);
            return response()->json(['message' => 'Errand cancelled.', 'errand' => $errand]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function runnerCancel(Request $request, int $id): JsonResponse
    {
        $request->validate(['reason' => 'required|string|max:500']);
        $errand = Errand::findOrFail($id);

        try {
            $errand = $this->errandService->cancelByRunner($request->user(), $errand, $request->reason);
            return response()->json(['message' => 'Errand cancelled.', 'errand' => $errand]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function panic(Request $request, int $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'notes' => 'nullable|string',
        ]);

        $errand = Errand::findOrFail($id);

        try {
            $this->errandService->triggerPanic($request->user(), $errand, $validator->validated());
            return response()->json(['message' => 'Panic alert sent. Admin has been notified. Stay safe.']);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function getProof(Request $request, int $id): JsonResponse
    {
        $errand = Errand::with('proofSubmissions')->findOrFail($id);
        return response()->json($errand->proofSubmissions);
    }

    public function generateDeliveryOtp(Request $request, int $id): JsonResponse
    {
        $errand = Errand::findOrFail($id);

        if ($errand->customer_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        if ($errand->status !== Errand::STATUS_AWAITING_CONFIRMATION) {
            return response()->json(['message' => 'OTP not available at this stage.'], 400);
        }

        // OTP already generated when runner submitted proof
        return response()->json(['message' => 'Delivery OTP was sent when runner submitted proof. Check your notifications.']);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $errand = Errand::findOrFail($id);

        if ($errand->customer_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        if (!in_array($errand->status, [Errand::STATUS_DRAFT, Errand::STATUS_POSTED])) {
            return response()->json(['message' => 'Cannot edit errand after assignment.'], 400);
        }

        $errand->update($request->only([
            'title', 'description', 'special_instructions', 'scheduled_at',
        ]));

        return response()->json(['message' => 'Errand updated.', 'errand' => $errand]);
    }
}
