<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Errand;
use App\Models\Rating;
use App\Services\WalletService;
use App\Services\TrustScoreService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class RunnerController extends Controller
{
    public function __construct(
        private WalletService $walletService,
        private TrustScoreService $trustScoreService,
    ) {}

    public function dashboard(Request $request): JsonResponse
    {
        $runner = $request->user()->load(['runnerProfile', 'wallet']);
        $profile = $runner->runnerProfile;

        $today = now()->startOfDay();

        $todayEarnings = Errand::where('runner_id', $runner->id)
            ->where('status', Errand::STATUS_COMPLETED)
            ->where('completed_at', '>=', $today)
            ->sum('runner_earnings');

        $activeErrand = Errand::where('runner_id', $runner->id)
            ->whereIn('status', [
                Errand::STATUS_ACCEPTED,
                Errand::STATUS_RUNNER_EN_ROUTE,
                Errand::STATUS_ITEM_PICKED,
                Errand::STATUS_IN_PROGRESS,
                Errand::STATUS_AWAITING_CONFIRMATION,
            ])
            ->with(['customer:id,first_name,last_name,phone,profile_image'])
            ->first();

        return response()->json([
            'runner' => [
                'id' => $runner->id,
                'full_name' => $runner->full_name,
                'profile_image' => $runner->profile_image,
                'is_online' => $profile?->is_online,
                'is_available' => $profile?->is_available,
                'trust_score' => $profile?->trust_score,
                'average_rating' => $profile?->average_rating,
                'verification_status' => $profile?->verification_status,
            ],
            'today_earnings' => $todayEarnings,
            'wallet_balance' => $runner->wallet?->balance,
            'total_errands' => $profile?->total_errands,
            'completion_rate' => $profile?->completion_rate,
            'active_errand' => $activeErrand,
        ]);
    }

    public function updateAvailability(Request $request): JsonResponse
    {
        $request->validate([
            'is_online' => 'required|boolean',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
        ]);

        $runner = $request->user();
        $profile = $runner->runnerProfile;

        if (!$profile?->isVerified()) {
            return response()->json(['message' => 'Complete your verification to go online.'], 403);
        }

        $updateData = [
            'is_online' => $request->is_online,
            'is_available' => $request->is_online,
        ];

        if ($request->latitude && $request->longitude) {
            $updateData['current_latitude'] = $request->latitude;
            $updateData['current_longitude'] = $request->longitude;
            $updateData['location_updated_at'] = now();
        }

        $profile->update($updateData);
        $runner->update(['is_online' => $request->is_online, 'last_seen_at' => now()]);

        return response()->json([
            'message' => $request->is_online ? 'You are now online.' : 'You are now offline.',
            'is_online' => $request->is_online,
        ]);
    }

    public function updateLocation(Request $request): JsonResponse
    {
        $request->validate([
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        $runner = $request->user();
        $runner->runnerProfile()->update([
            'current_latitude' => $request->latitude,
            'current_longitude' => $request->longitude,
            'location_updated_at' => now(),
        ]);

        return response()->json(['message' => 'Location updated.']);
    }

    public function earnings(Request $request): JsonResponse
    {
        $runner = $request->user();
        $today = now()->startOfDay();
        $weekStart = now()->startOfWeek();
        $monthStart = now()->startOfMonth();

        $base = Errand::where('runner_id', $runner->id)->where('status', Errand::STATUS_COMPLETED);

        return response()->json([
            'today' => $base->clone()->where('completed_at', '>=', $today)->sum('runner_earnings'),
            'this_week' => $base->clone()->where('completed_at', '>=', $weekStart)->sum('runner_earnings'),
            'this_month' => $base->clone()->where('completed_at', '>=', $monthStart)->sum('runner_earnings'),
            'total' => $runner->runnerProfile?->total_earnings ?? 0,
            'wallet_balance' => $runner->wallet?->balance,
            'pending_withdrawal' => $runner->wallet?->pending_withdrawal,
            'recent_transactions' => $runner->wallet?->transactions()->limit(10)->get(),
        ]);
    }

    public function withdraw(Request $request): JsonResponse
    {
        $request->validate(['amount' => 'required|integer|min:1000']);

        try {
            $transaction = $this->walletService->requestWithdrawal($request->user(), $request->amount);
            return response()->json([
                'message' => 'Withdrawal request submitted. Processing within 24 hours.',
                'transaction' => $transaction,
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function withdrawals(Request $request): JsonResponse
    {
        $transactions = $request->user()->wallet
            ->transactions()
            ->where('type', \App\Models\WalletTransaction::TYPE_WITHDRAWAL)
            ->paginate(15);

        return response()->json($transactions);
    }

    public function updateBankAccount(Request $request): JsonResponse
    {
        $request->validate([
            'bank_name' => 'required|string',
            'bank_account_number' => 'required|string|size:10',
            'bank_account_name' => 'required|string',
            'bank_code' => 'required|string',
        ]);

        $request->user()->runnerProfile()->update($request->only([
            'bank_name', 'bank_account_number', 'bank_account_name', 'bank_code',
        ]));

        return response()->json(['message' => 'Bank account updated.']);
    }

    public function trustScore(Request $request): JsonResponse
    {
        $profile = $request->user()->runnerProfile;

        return response()->json([
            'trust_score' => $profile?->trust_score,
            'average_rating' => $profile?->average_rating,
            'completion_rate' => $profile?->completion_rate,
            'total_errands' => $profile?->total_errands,
            'cancelled_errands' => $profile?->cancelled_errands,
        ]);
    }

    public function stats(Request $request): JsonResponse
    {
        $runner = $request->user();

        return response()->json([
            'total_completed' => Errand::where('runner_id', $runner->id)->where('status', Errand::STATUS_COMPLETED)->count(),
            'total_cancelled' => Errand::where('runner_id', $runner->id)->where('status', Errand::STATUS_CANCELLED)->count(),
            'total_disputed' => Errand::where('runner_id', $runner->id)->where('status', Errand::STATUS_DISPUTED)->count(),
            'ratings_received' => Rating::where('rated_id', $runner->id)->where('role', Rating::ROLE_CUSTOMER_TO_RUNNER)->count(),
            'average_rating' => Rating::where('rated_id', $runner->id)->avg('overall_rating'),
        ]);
    }

    public function verificationStatus(Request $request): JsonResponse
    {
        $profile = $request->user()->runnerProfile;
        $kyc = $request->user()->kyc;

        return response()->json([
            'verification_status' => $profile?->verification_status,
            'kyc_status' => $request->user()->kyc_status,
            'steps' => [
                'personal_info' => !empty($request->user()->date_of_birth),
                'documents' => !empty($kyc?->id_document_url),
                'selfie' => !empty($kyc?->selfie_url),
                'bank_account' => !empty($profile?->bank_account_number),
                'approved' => $profile?->isVerified(),
            ],
        ]);
    }

    public function profile(Request $request): JsonResponse
    {
        $runner = $request->user()->load(['runnerProfile', 'kyc', 'wallet']);
        return response()->json($runner);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $request->validate([
            'available_days' => 'nullable|array',
            'available_hours_start' => 'nullable|date_format:H:i',
            'available_hours_end' => 'nullable|date_format:H:i',
            'service_radius_km' => 'nullable|integer|min:1|max:50',
            'transport_type' => 'nullable|in:foot,bicycle,motorcycle,car',
            'skills' => 'nullable|array',
        ]);

        $request->user()->runnerProfile()->update($request->only([
            'available_days', 'available_hours_start', 'available_hours_end',
            'service_radius_km', 'transport_type', 'skills',
        ]));

        return response()->json(['message' => 'Profile updated.']);
    }
}
