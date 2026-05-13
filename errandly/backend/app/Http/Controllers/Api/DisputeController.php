<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Dispute;
use App\Models\Errand;
use App\Services\NotificationService;
use App\Models\AppNotification;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class DisputeController extends Controller
{
    public function __construct(private NotificationService $notificationService) {}

    public function index(Request $request): JsonResponse
    {
        $disputes = Dispute::where('raised_by', $request->user()->id)
            ->with(['errand:id,title,status', 'assignedTo:id,first_name,last_name'])
            ->orderBy('created_at', 'desc')
            ->paginate(15);

        return response()->json($disputes);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'errand_id' => 'required|integer|exists:errands,id',
            'type' => 'required|in:item_not_delivered,item_damaged,wrong_task_execution,harassment,fraudulent_completion,missing_payment,other',
            'description' => 'required|string|max:2000',
            'evidence' => 'nullable|array',
            'evidence.*' => 'string|url',
        ]);

        $errand = Errand::findOrFail($request->errand_id);
        $user = $request->user();

        // Only customer or runner of this errand can raise a dispute
        if ($errand->customer_id !== $user->id && $errand->runner_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        // Check for existing open dispute
        if ($errand->dispute && in_array($errand->dispute->status, [Dispute::STATUS_OPEN, Dispute::STATUS_UNDER_REVIEW])) {
            return response()->json(['message' => 'A dispute is already open for this errand.'], 400);
        }

        $dispute = DB::transaction(function () use ($request, $errand, $user) {
            $dispute = Dispute::create([
                'errand_id' => $errand->id,
                'raised_by' => $user->id,
                'type' => $request->type,
                'status' => Dispute::STATUS_OPEN,
                'description' => $request->description,
                'evidence' => $request->evidence ?? [],
            ]);

            // Freeze escrow
            if ($errand->escrow) {
                $errand->escrow->update([
                    'status' => \App\Models\EscrowTransaction::STATUS_FROZEN,
                    'frozen_at' => now(),
                    'frozen_reason' => "Dispute opened: {$request->type}",
                ]);
            }

            // Update errand status
            $errand->update(['status' => Errand::STATUS_DISPUTED]);

            // Notify admin
            $admins = \App\Models\User::role('admin')->get();
            foreach ($admins as $admin) {
                $this->notificationService->send(
                    $admin,
                    AppNotification::TYPE_DISPUTE_OPENED,
                    'New Dispute Opened',
                    "Dispute on Errand #{$errand->id}: {$request->type}",
                    ['errand_id' => $errand->id, 'dispute_id' => $dispute->id]
                );
            }

            // Notify the other party
            $otherParty = $user->id === $errand->customer_id ? $errand->runner : $errand->customer;
            if ($otherParty) {
                $this->notificationService->send(
                    $otherParty,
                    AppNotification::TYPE_DISPUTE_OPENED,
                    'Dispute Raised',
                    "A dispute has been raised on Errand: {$errand->title}",
                    ['errand_id' => $errand->id, 'dispute_id' => $dispute->id]
                );
            }

            return $dispute;
        });

        return response()->json([
            'message' => 'Dispute opened. Admin will review within 24 hours. Escrow is frozen.',
            'dispute' => $dispute,
        ], 201);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $dispute = Dispute::with([
            'errand', 'raisedBy:id,first_name,last_name', 'assignedTo:id,first_name,last_name',
            'evidenceFiles',
        ])->findOrFail($id);

        $user = $request->user();
        $errand = $dispute->errand;

        if ($errand->customer_id !== $user->id && $errand->runner_id !== $user->id && !$user->hasRole('admin')) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        return response()->json($dispute);
    }

    public function addEvidence(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'type' => 'required|in:photo,video,document,text',
            'url' => 'required_unless:type,text|nullable|string|url',
            'description' => 'required_if:type,text|nullable|string',
        ]);

        $dispute = Dispute::findOrFail($id);
        $user = $request->user();
        $errand = $dispute->errand;

        if ($errand->customer_id !== $user->id && $errand->runner_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        \App\Models\DisputeEvidence::create([
            'dispute_id' => $dispute->id,
            'submitted_by' => $user->id,
            'type' => $request->type,
            'url' => $request->url,
            'description' => $request->description,
        ]);

        return response()->json(['message' => 'Evidence submitted.']);
    }
}
