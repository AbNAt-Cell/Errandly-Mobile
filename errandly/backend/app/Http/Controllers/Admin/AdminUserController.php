<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\NotificationService;
use App\Models\AppNotification;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class AdminUserController extends Controller
{
    public function __construct(private NotificationService $notificationService) {}

    public function index(Request $request): JsonResponse
    {
        $users = User::with(['wallet', 'kyc'])
            ->when($request->role, fn($q) => $q->role($request->role))
            ->when($request->status, fn($q) => $q->where('status', $request->status))
            ->when($request->kyc_status, fn($q) => $q->where('kyc_status', $request->kyc_status))
            ->when($request->search, fn($q) => $q->where(function ($q2) use ($request) {
                $q2->where('first_name', 'like', "%{$request->search}%")
                   ->orWhere('last_name', 'like', "%{$request->search}%")
                   ->orWhere('email', 'like', "%{$request->search}%")
                   ->orWhere('phone', 'like', "%{$request->search}%");
            }))
            ->orderBy('created_at', 'desc')
            ->paginate(25);

        return response()->json($users);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $user = User::with([
            'wallet.transactions' => fn($q) => $q->limit(10),
            'kyc',
            'runnerProfile',
            'customerErrands' => fn($q) => $q->orderBy('created_at', 'desc')->limit(5),
            'runnerErrands' => fn($q) => $q->orderBy('created_at', 'desc')->limit(5),
        ])->findOrFail($id);

        return response()->json($user);
    }

    public function suspend(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'reason' => 'required|string|max:500',
            'until' => 'nullable|date|after:now',
        ]);

        $user = User::findOrFail($id);

        if ($user->hasRole('super_admin')) {
            return response()->json(['message' => 'Cannot suspend super admin.'], 403);
        }

        $user->update([
            'status' => User::STATUS_SUSPENDED,
            'suspension_reason' => $request->reason,
            'suspended_at' => now(),
            'suspended_until' => $request->until,
        ]);

        // Invalidate all tokens
        $user->tokens()->delete();

        $this->notificationService->send(
            $user,
            AppNotification::TYPE_SUSPENSION,
            'Account Suspended',
            "Your account has been suspended. Reason: {$request->reason}",
        );

        return response()->json(['message' => 'User suspended.']);
    }

    public function restore(Request $request, int $id): JsonResponse
    {
        $user = User::findOrFail($id);
        $user->update([
            'status' => User::STATUS_ACTIVE,
            'suspension_reason' => null,
            'suspended_at' => null,
            'suspended_until' => null,
        ]);

        $this->notificationService->send(
            $user,
            AppNotification::TYPE_ANNOUNCEMENT,
            'Account Restored',
            'Your account has been restored. You can now use Errandly.',
        );

        return response()->json(['message' => 'User restored.']);
    }

    public function blacklist(Request $request, int $id): JsonResponse
    {
        $request->validate(['reason' => 'required|string|max:500']);

        $user = User::findOrFail($id);

        if ($user->hasRole('super_admin')) {
            return response()->json(['message' => 'Cannot blacklist super admin.'], 403);
        }

        $user->update([
            'status' => User::STATUS_BLACKLISTED,
            'suspension_reason' => $request->reason,
            'suspended_at' => now(),
        ]);

        $user->tokens()->delete();

        return response()->json(['message' => 'User blacklisted.']);
    }

    public function verify(Request $request, int $id): JsonResponse
    {
        $user = User::findOrFail($id);
        $user->update([
            'kyc_status' => User::KYC_APPROVED,
            'status' => User::STATUS_ACTIVE,
            'email_verified_at' => $user->email_verified_at ?? now(),
            'phone_verified_at' => $user->phone_verified_at ?? now(),
        ]);

        return response()->json(['message' => 'User manually verified.']);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $user = User::findOrFail($id);

        if ($user->hasRole('super_admin')) {
            return response()->json(['message' => 'Cannot delete super admin.'], 403);
        }

        $user->tokens()->delete();
        $user->delete();

        return response()->json(['message' => 'User deleted.']);
    }
}
