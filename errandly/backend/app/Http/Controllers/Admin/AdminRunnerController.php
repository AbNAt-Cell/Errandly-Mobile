<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\RunnerProfile;
use App\Services\TrustScoreService;
use App\Services\NotificationService;
use App\Models\AppNotification;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class AdminRunnerController extends Controller
{
    public function __construct(
        private TrustScoreService $trustScoreService,
        private NotificationService $notificationService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $runners = User::role('runner')
            ->with(['runnerProfile', 'wallet', 'kyc'])
            ->when($request->status, fn($q) => $q->where('status', $request->status))
            ->when($request->verification, fn($q) => $q->whereHas('runnerProfile', fn($q2) => $q2->where('verification_status', $request->verification)))
            ->when($request->online, fn($q) => $q->whereHas('runnerProfile', fn($q2) => $q2->where('is_online', $request->online === 'true')))
            ->when($request->search, fn($q) => $q->where(function ($q2) use ($request) {
                $q2->where('first_name', 'like', "%{$request->search}%")
                   ->orWhere('last_name', 'like', "%{$request->search}%")
                   ->orWhere('phone', 'like', "%{$request->search}%");
            }))
            ->orderBy('created_at', 'desc')
            ->paginate(25);

        return response()->json($runners);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $runner = User::with([
            'runnerProfile',
            'kyc',
            'wallet.transactions' => fn($q) => $q->limit(10),
            'runnerErrands' => fn($q) => $q->orderBy('created_at', 'desc')->limit(5)->with('customer:id,first_name,last_name'),
        ])->findOrFail($id);

        if (!$runner->hasRole('runner')) {
            return response()->json(['message' => 'User is not a runner.'], 404);
        }

        return response()->json($runner);
    }

    public function approve(Request $request, int $id): JsonResponse
    {
        $runner = User::findOrFail($id);

        $runner->runnerProfile()->update([
            'verification_status' => RunnerProfile::VERIFICATION_APPROVED,
            'is_verified' => true,
            'verified_at' => now(),
        ]);

        $runner->update([
            'kyc_status' => \App\Models\User::KYC_APPROVED,
            'status' => \App\Models\User::STATUS_ACTIVE,
        ]);

        $this->notificationService->send(
            $runner,
            AppNotification::TYPE_KYC_APPROVED,
            'Runner Account Approved!',
            'Your runner account has been verified. You can now go online and start accepting errands.',
        );

        return response()->json(['message' => 'Runner approved and activated.']);
    }

    public function suspend(Request $request, int $id): JsonResponse
    {
        $request->validate(['reason' => 'required|string|max:500']);

        $runner = User::findOrFail($id);
        $runner->update([
            'status' => \App\Models\User::STATUS_SUSPENDED,
            'suspension_reason' => $request->reason,
            'suspended_at' => now(),
        ]);

        $runner->runnerProfile()->update(['is_online' => false, 'is_available' => false]);
        $runner->tokens()->delete();

        $this->notificationService->send(
            $runner,
            AppNotification::TYPE_SUSPENSION,
            'Account Suspended',
            "Your runner account has been suspended. Reason: {$request->reason}",
        );

        return response()->json(['message' => 'Runner suspended.']);
    }

    public function adjustTrustScore(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'adjustment' => 'required|numeric|min:-50|max:50',
            'reason' => 'required|string|max:500',
        ]);

        $runner = User::findOrFail($id);
        $profile = $runner->runnerProfile;

        if (!$profile) {
            return response()->json(['message' => 'Runner profile not found.'], 404);
        }

        $this->trustScoreService->applyManualAdjustment($profile, $request->adjustment, $request->reason);

        return response()->json([
            'message' => 'Trust score adjusted.',
            'new_score' => $profile->fresh()->trust_score,
        ]);
    }
}
