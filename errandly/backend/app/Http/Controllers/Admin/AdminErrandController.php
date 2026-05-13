<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Errand;
use App\Models\User;
use App\Services\ErrandService;
use App\Services\NotificationService;
use App\Models\AppNotification;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class AdminErrandController extends Controller
{
    public function __construct(
        private NotificationService $notificationService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $errands = Errand::with([
            'customer:id,first_name,last_name,email,phone',
            'runner:id,first_name,last_name,email,phone',
            'escrow',
        ])
        ->when($request->status, fn($q) => $q->where('status', $request->status))
        ->when($request->category, fn($q) => $q->where('category', $request->category))
        ->when($request->search, fn($q) => $q->where('title', 'like', "%{$request->search}%"))
        ->when($request->from, fn($q) => $q->where('created_at', '>=', $request->from))
        ->when($request->to, fn($q) => $q->where('created_at', '<=', $request->to))
        ->orderBy('created_at', 'desc')
        ->paginate(25);

        return response()->json($errands);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $errand = Errand::with([
            'customer',
            'runner',
            'runner.runnerProfile',
            'escrow',
            'messages.sender:id,first_name,last_name',
            'trackingLogs',
            'proofSubmissions',
            'statusHistory.changedBy:id,first_name,last_name',
            'dispute',
            'panicEvents.triggeredBy:id,first_name,last_name',
            'ratings',
        ])->findOrFail($id);

        return response()->json($errand);
    }

    public function reassign(Request $request, int $id): JsonResponse
    {
        $request->validate(['runner_id' => 'required|integer|exists:users,id']);

        $errand = Errand::findOrFail($id);
        $newRunner = User::findOrFail($request->runner_id);

        if (!$newRunner->hasRole('runner') || !$newRunner->runnerProfile?->isVerified()) {
            return response()->json(['message' => 'Selected user is not a verified runner.'], 400);
        }

        DB::transaction(function () use ($errand, $newRunner, $request) {
            $oldRunner = $errand->runner;

            $errand->update([
                'runner_id' => $newRunner->id,
                'status' => Errand::STATUS_ACCEPTED,
                'accepted_at' => now(),
            ]);

            // Update escrow runner
            $errand->escrow?->update(['runner_id' => $newRunner->id]);

            \App\Models\ErrandStatusHistory::create([
                'errand_id' => $errand->id,
                'from_status' => $errand->getOriginal('status'),
                'to_status' => Errand::STATUS_ACCEPTED,
                'changed_by' => $request->user()->id,
                'reason' => 'Admin reassignment',
                'created_at' => now(),
            ]);

            // Notify new runner
            $this->notificationService->send(
                $newRunner,
                AppNotification::TYPE_ERRAND_ASSIGNED,
                'Errand Assigned by Admin',
                "You have been assigned to: {$errand->title}",
                ['errand_id' => $errand->id]
            );

            // Notify customer
            $this->notificationService->send(
                $errand->customer,
                AppNotification::TYPE_ERRAND_ASSIGNED,
                'Runner Reassigned',
                "A new runner has been assigned to your errand.",
                ['errand_id' => $errand->id]
            );
        });

        return response()->json(['message' => 'Errand reassigned.', 'errand' => $errand->fresh()]);
    }

    public function cancel(Request $request, int $id): JsonResponse
    {
        $request->validate(['reason' => 'required|string|max:500']);

        $errand = Errand::findOrFail($id);

        DB::transaction(function () use ($errand, $request) {
            // Refund customer
            if ($errand->escrow && in_array($errand->escrow->status, [
                \App\Models\EscrowTransaction::STATUS_IN_ESCROW,
                \App\Models\EscrowTransaction::STATUS_FROZEN,
            ])) {
                $errand->customer->wallet->credit(
                    $errand->escrow->total_amount,
                    \App\Models\WalletTransaction::TYPE_REFUND,
                    "Admin cancelled errand #{$errand->id}. Full refund issued.",
                    $errand->id
                );
                $errand->escrow->update(['status' => \App\Models\EscrowTransaction::STATUS_REFUNDED, 'refunded_at' => now()]);
            }

            $errand->update([
                'status' => Errand::STATUS_CANCELLED,
                'cancelled_at' => now(),
                'cancellation_reason' => $request->reason,
                'cancellation_by' => 'admin',
                'payment_status' => Errand::PAYMENT_REFUNDED,
            ]);

            // Notify both parties
            $this->notificationService->send($errand->customer, AppNotification::TYPE_ANNOUNCEMENT, 'Errand Cancelled', "Your errand was cancelled by admin. Reason: {$request->reason}", ['errand_id' => $errand->id]);
            if ($errand->runner) {
                $this->notificationService->send($errand->runner, AppNotification::TYPE_ANNOUNCEMENT, 'Errand Cancelled', "Errand #{$errand->id} was cancelled by admin.", ['errand_id' => $errand->id]);
            }
        });

        return response()->json(['message' => 'Errand cancelled. Customer refunded.']);
    }

    public function timeline(Request $request, int $id): JsonResponse
    {
        $history = \App\Models\ErrandStatusHistory::where('errand_id', $id)
            ->with('changedBy:id,first_name,last_name')
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json($history);
    }

    public function tracking(Request $request, int $id): JsonResponse
    {
        $logs = \App\Models\TrackingLog::where('errand_id', $id)
            ->orderBy('logged_at', 'asc')
            ->get(['latitude', 'longitude', 'speed', 'logged_at']);

        return response()->json($logs);
    }
}
