<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Dispute;
use App\Models\Errand;
use App\Services\WalletService;
use App\Services\NotificationService;
use App\Models\AppNotification;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class AdminDisputeController extends Controller
{
    public function __construct(
        private WalletService $walletService,
        private NotificationService $notificationService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $disputes = Dispute::with([
            'errand:id,title,status,budget',
            'raisedBy:id,first_name,last_name,email',
            'assignedTo:id,first_name,last_name',
        ])
        ->when($request->status, fn($q) => $q->where('status', $request->status))
        ->when($request->type, fn($q) => $q->where('type', $request->type))
        ->orderBy('created_at', 'desc')
        ->paginate(20);

        return response()->json($disputes);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $dispute = Dispute::with([
            'errand.customer:id,first_name,last_name,phone,email',
            'errand.runner:id,first_name,last_name,phone,email',
            'errand.messages',
            'errand.trackingLogs',
            'errand.statusHistory.changedBy:id,first_name,last_name',
            'errand.proofSubmissions',
            'raisedBy:id,first_name,last_name',
            'assignedTo:id,first_name,last_name',
            'evidenceFiles.submittedBy:id,first_name,last_name',
        ])->findOrFail($id);

        return response()->json($dispute);
    }

    public function assign(Request $request, int $id): JsonResponse
    {
        $request->validate(['admin_id' => 'required|integer|exists:users,id']);

        $dispute = Dispute::findOrFail($id);
        $dispute->update([
            'assigned_to' => $request->admin_id,
            'status' => Dispute::STATUS_UNDER_REVIEW,
        ]);

        return response()->json(['message' => 'Dispute assigned.', 'dispute' => $dispute]);
    }

    public function resolve(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'resolution_type' => 'required|in:refund,release,partial_refund,no_action',
            'resolution' => 'required|string|max:2000',
            'refund_amount' => 'required_if:resolution_type,partial_refund|nullable|integer|min:0',
            'apply_penalty' => 'nullable|boolean',
            'penalty_party' => 'nullable|in:customer,runner',
        ]);

        $dispute = Dispute::with('errand.customer', 'errand.runner', 'errand.escrow')->findOrFail($id);

        DB::transaction(function () use ($request, $dispute) {
            $errand = $dispute->errand;

            switch ($request->resolution_type) {
                case 'refund':
                    // Full refund to customer
                    $this->walletService->processRefund($errand->customer, $errand, $errand->escrow?->total_amount ?? 0);
                    $errand->update(['status' => Errand::STATUS_REFUNDED]);
                    break;

                case 'release':
                    // Release to runner
                    $this->walletService->releaseEscrow($errand);
                    $errand->update(['status' => Errand::STATUS_COMPLETED]);
                    break;

                case 'partial_refund':
                    $refundAmount = $request->refund_amount ?? 0;
                    $runnerAmount = ($errand->escrow?->total_amount ?? 0) - $refundAmount;
                    // Partial refund + partial release
                    $this->walletService->processRefund($errand->customer, $errand, $refundAmount);
                    if ($runnerAmount > 0) {
                        $errand->runner->wallet->credit(
                            $runnerAmount,
                            \App\Models\WalletTransaction::TYPE_EARNINGS,
                            "Partial payment from resolved dispute #{$dispute->id}",
                            $errand->id
                        );
                    }
                    $errand->update(['status' => Errand::STATUS_COMPLETED]);
                    break;

                case 'no_action':
                    $errand->update(['status' => Errand::STATUS_CANCELLED]);
                    break;
            }

            $dispute->update([
                'status' => Dispute::STATUS_RESOLVED,
                'resolution' => $request->resolution,
                'resolution_type' => $request->resolution_type,
                'resolved_at' => now(),
                'refund_amount' => $request->refund_amount,
                'penalty_applied' => $request->apply_penalty ?? false,
                'assigned_to' => $request->user()->id,
            ]);

            // Notify both parties
            $this->notificationService->send(
                $errand->customer,
                AppNotification::TYPE_DISPUTE_RESOLVED,
                'Dispute Resolved',
                "Your dispute for Errand #{$errand->id} has been resolved: {$request->resolution_type}",
                ['errand_id' => $errand->id, 'dispute_id' => $dispute->id]
            );

            if ($errand->runner) {
                $this->notificationService->send(
                    $errand->runner,
                    AppNotification::TYPE_DISPUTE_RESOLVED,
                    'Dispute Resolved',
                    "The dispute for Errand #{$errand->id} has been resolved.",
                    ['errand_id' => $errand->id]
                );
            }
        });

        return response()->json(['message' => 'Dispute resolved.', 'dispute' => $dispute->fresh()]);
    }

    public function close(Request $request, int $id): JsonResponse
    {
        $request->validate(['notes' => 'required|string']);

        $dispute = Dispute::findOrFail($id);
        $dispute->update([
            'status' => Dispute::STATUS_CLOSED,
            'closed_at' => now(),
            'closing_notes' => $request->notes,
        ]);

        return response()->json(['message' => 'Dispute closed.']);
    }
}
