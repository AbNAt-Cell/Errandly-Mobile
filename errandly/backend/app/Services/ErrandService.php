<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\Errand;
use App\Models\User;
use App\Models\ErrandStatusHistory;
use App\Models\EscrowTransaction;
use App\Models\RunnerProfile;
use App\Events\ErrandStatusUpdated;
use App\Events\RunnerAssigned;
use App\Events\PanicTriggered;
use App\Jobs\AnalyzeProofSubmissionJob;
use App\Jobs\SummarizePanicEventJob;
use App\Jobs\NotifyNearbyRunners;
use App\Jobs\AutoReassignErrand;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class ErrandService
{
    public function __construct(
        private WalletService $walletService,
        private NotificationService $notificationService,
        private TrustScoreService $trustScoreService,
        private OtpService $otpService,
    ) {}

    public function createErrand(User $customer, array $data): Errand
    {
        return DB::transaction(function () use ($customer, $data) {
            $platformFee = $this->calculatePlatformFee($data['budget']);
            $totalAmount = $data['budget'] + $platformFee;

            // Ensure customer has enough balance
            if (!$customer->wallet->hasSufficientFunds($totalAmount)) {
                throw new \Exception('Insufficient wallet balance. Please fund your wallet.');
            }

            $errand = Errand::create([
                'customer_id' => $customer->id,
                'title' => $data['title'],
                'description' => $data['description'],
                'category' => $data['category'],
                'urgency' => $data['urgency'] ?? Errand::URGENCY_STANDARD,
                'pickup_address' => $data['pickup_address'],
                'pickup_latitude' => $data['pickup_latitude'],
                'pickup_longitude' => $data['pickup_longitude'],
                'pickup_city' => $data['pickup_city'] ?? null,
                'destination_address' => $data['destination_address'],
                'destination_latitude' => $data['destination_latitude'],
                'destination_longitude' => $data['destination_longitude'],
                'destination_city' => $data['destination_city'] ?? null,
                'recipient_name' => $data['recipient_name'] ?? null,
                'recipient_phone' => $data['recipient_phone'] ?? null,
                'item_details' => $data['item_details'] ?? null,
                'special_instructions' => $data['special_instructions'] ?? null,
                'budget' => $data['budget'],
                'platform_fee' => $platformFee,
                'runner_earnings' => $data['budget'],
                'scheduled_at' => $data['scheduled_at'] ?? null,
                'attachments' => $data['attachments'] ?? [],
                'status' => Errand::STATUS_POSTED,
                'payment_status' => Errand::PAYMENT_PENDING,
            ]);

            // Hold payment in escrow
            $escrow = EscrowTransaction::create([
                'errand_id' => $errand->id,
                'customer_id' => $customer->id,
                'total_amount' => $totalAmount,
                'runner_amount' => $data['budget'],
                'platform_fee' => $platformFee,
                'status' => EscrowTransaction::STATUS_IN_ESCROW,
                'payment_method' => 'wallet',
                'funded_at' => now(),
            ]);

            // Debit customer wallet
            $this->walletService->holdForEscrow($customer, $totalAmount, $errand->id);

            // Update errand escrow reference
            $errand->update([
                'escrow_id' => $escrow->id,
                'payment_status' => Errand::PAYMENT_IN_ESCROW,
                'status' => Errand::STATUS_PENDING_ASSIGNMENT,
            ]);

            $this->logStatusChange($errand, null, Errand::STATUS_PENDING_ASSIGNMENT, $customer->id);

            // Dispatch job to notify nearby runners
            NotifyNearbyRunners::dispatch($errand)->afterCommit();

            return $errand;
        });
    }

    public function acceptErrand(User $runner, Errand $errand): Errand
    {
        return DB::transaction(function () use ($runner, $errand) {
            // Race condition guard: lock the row
            $errand = Errand::lockForUpdate()->findOrFail($errand->id);

            if ($errand->status !== Errand::STATUS_PENDING_ASSIGNMENT) {
                throw new \Exception('This errand is no longer available.');
            }

            if ($errand->runner_id) {
                throw new \Exception('This errand has already been accepted by another runner.');
            }

            $errand->update([
                'runner_id' => $runner->id,
                'status' => Errand::STATUS_ACCEPTED,
                'accepted_at' => now(),
            ]);

            // Update escrow with runner
            $errand->escrow->update(['runner_id' => $runner->id]);

            $this->logStatusChange($errand, Errand::STATUS_PENDING_ASSIGNMENT, Errand::STATUS_ACCEPTED, $runner->id);

            // Notify customer
            $this->notificationService->send(
                $errand->customer,
                AppNotification::TYPE_ERRAND_ASSIGNED,
                'Runner Assigned!',
                "{$runner->full_name} has accepted your errand and is on the way.",
                $this->errandNotificationData($errand)
            );

            event(new RunnerAssigned($errand));

            return $errand->fresh(['runner', 'customer']);
        });
    }

    public function markArrived(User $runner, Errand $errand): Errand
    {
        $this->validateRunnerOwnership($runner, $errand);
        $this->validateStatus($errand, Errand::STATUS_ACCEPTED, 'mark as arrived');

        $errand->update(['status' => Errand::STATUS_RUNNER_EN_ROUTE]);
        $this->logStatusChange($errand, Errand::STATUS_ACCEPTED, Errand::STATUS_RUNNER_EN_ROUTE, $runner->id);

        // Generate pickup OTP
        $otp = $this->otpService->generatePickupOtp($errand);

        $this->notificationService->send(
            $errand->customer,
            AppNotification::TYPE_RUNNER_ARRIVED,
            'Runner Has Arrived',
            "Your runner has arrived. Your pickup OTP is: {$otp}",
            $this->errandNotificationData($errand, ['otp' => $otp])
        );

        event(new ErrandStatusUpdated($errand));
        return $errand;
    }

    public function verifyPickupOtp(User $runner, Errand $errand, string $otp): Errand
    {
        $this->validateRunnerOwnership($runner, $errand);

        if (!$this->otpService->verifyPickupOtp($errand, $otp)) {
            throw new \Exception('Invalid or expired pickup OTP.');
        }

        $errand->update([
            'status' => Errand::STATUS_ITEM_PICKED,
            'pickup_otp_verified_at' => now(),
        ]);

        $this->logStatusChange($errand, Errand::STATUS_RUNNER_EN_ROUTE, Errand::STATUS_ITEM_PICKED, $runner->id);
        event(new ErrandStatusUpdated($errand));

        return $errand;
    }

    public function startErrand(User $runner, Errand $errand): Errand
    {
        $this->validateRunnerOwnership($runner, $errand);
        $this->validateStatus($errand, Errand::STATUS_ITEM_PICKED, 'start');

        $errand->update([
            'status' => Errand::STATUS_IN_PROGRESS,
            'started_at' => now(),
        ]);

        $this->logStatusChange($errand, Errand::STATUS_ITEM_PICKED, Errand::STATUS_IN_PROGRESS, $runner->id);

        $this->notificationService->send(
            $errand->customer,
            AppNotification::TYPE_TASK_STARTED,
            'Errand In Progress',
            "Your runner is now carrying out your errand. Track their progress live.",
            $this->errandNotificationData($errand)
        );

        event(new ErrandStatusUpdated($errand));
        return $errand;
    }

    public function submitProof(User $runner, Errand $errand, array $data): Errand
    {
        $this->validateRunnerOwnership($runner, $errand);

        $proof = \App\Models\ProofSubmission::create([
            'errand_id' => $errand->id,
            'runner_id' => $runner->id,
            'type' => $data['type'],
            'file_url' => $data['file_url'] ?? null,
            'notes' => $data['notes'] ?? null,
            'submitted_at' => now(),
        ]);

        AnalyzeProofSubmissionJob::dispatch($proof->id)->afterCommit();

        $errand->update(['status' => Errand::STATUS_AWAITING_CONFIRMATION]);
        $this->logStatusChange($errand, Errand::STATUS_IN_PROGRESS, Errand::STATUS_AWAITING_CONFIRMATION, $runner->id);

        // Generate delivery OTP
        $otp = $this->otpService->generateDeliveryOtp($errand);

        $this->notificationService->send(
            $errand->customer,
            AppNotification::TYPE_TASK_COMPLETED,
            'Errand Completed by Runner',
            "Your runner has marked the errand complete. Your delivery OTP: {$otp}. Please verify and confirm.",
            $this->errandNotificationData($errand, ['otp' => $otp])
        );

        event(new ErrandStatusUpdated($errand));
        return $errand;
    }

    public function confirmCompletion(User $customer, Errand $errand, string $otp): Errand
    {
        return DB::transaction(function () use ($customer, $errand, $otp) {
            if ($errand->customer_id !== $customer->id) {
                throw new \Exception('Unauthorized.');
            }

            $this->validateStatus($errand, Errand::STATUS_AWAITING_CONFIRMATION, 'confirm');

            if (!$this->otpService->verifyDeliveryOtp($errand, $otp)) {
                throw new \Exception('Invalid or expired delivery OTP.');
            }

            $errand->update([
                'status' => Errand::STATUS_COMPLETED,
                'completed_at' => now(),
                'delivery_otp_verified_at' => now(),
            ]);

            // Release escrow funds to runner
            $this->walletService->releaseEscrow($errand);

            $this->logStatusChange($errand, Errand::STATUS_AWAITING_CONFIRMATION, Errand::STATUS_COMPLETED, $customer->id);

            // Update runner stats
            $this->updateRunnerStats($errand->runner);

            $this->notificationService->send(
                $errand->runner,
                AppNotification::TYPE_PAYMENT_RELEASED,
                'Payment Released!',
                "Your earnings for the errand have been released to your wallet.",
                $this->errandNotificationData($errand, ['amount' => $errand->runner_earnings])
            );

            event(new ErrandStatusUpdated($errand));
            return $errand->fresh();
        });
    }

    public function cancelByCustomer(User $customer, Errand $errand, string $reason): Errand
    {
        return DB::transaction(function () use ($customer, $errand, $reason) {
            if ($errand->customer_id !== $customer->id) {
                throw new \Exception('Unauthorized.');
            }

            if (!$errand->canBeCancelledByCustomer()) {
                throw new \Exception('This errand cannot be cancelled at its current stage.');
            }

            $previousStatus = $errand->status;
            $refundAmount = $this->calculateCustomerCancellationRefund($errand);

            $errand->update([
                'status' => Errand::STATUS_CANCELLED,
                'cancelled_at' => now(),
                'cancellation_reason' => $reason,
                'cancellation_by' => 'customer',
            ]);

            // Process refund
            $this->walletService->processRefund($customer, $errand, $refundAmount);

            $this->logStatusChange($errand, $previousStatus, Errand::STATUS_CANCELLED, $customer->id, $reason);

            // Notify runner if assigned
            if ($errand->runner_id) {
                $this->notificationService->send(
                    $errand->runner,
                    AppNotification::TYPE_ERRAND_ASSIGNED,
                    'Errand Cancelled',
                    "The customer has cancelled the errand: {$errand->title}",
                    $this->errandNotificationData($errand)
                );

                // Trust score impact if runner had already accepted
                if (in_array($previousStatus, [Errand::STATUS_ACCEPTED, Errand::STATUS_RUNNER_EN_ROUTE])) {
                    // No penalty for runner in customer cancellation
                }
            }

            event(new ErrandStatusUpdated($errand));
            return $errand;
        });
    }

    public function cancelByRunner(User $runner, Errand $errand, string $reason): Errand
    {
        return DB::transaction(function () use ($runner, $errand, $reason) {
            $this->validateRunnerOwnership($runner, $errand);

            if (!$errand->canBeCancelledByRunner()) {
                throw new \Exception('Cannot cancel at this stage.');
            }

            $previousStatus = $errand->status;

            $errand->update([
                'status' => Errand::STATUS_PENDING_ASSIGNMENT,
                'runner_id' => null,
                'cancelled_at' => null,
                'cancellation_reason' => $reason,
                'cancellation_by' => 'runner',
            ]);

            // Penalty: reduce trust score
            $this->trustScoreService->penalizeForCancellation($runner->runnerProfile);

            $this->logStatusChange($errand, $previousStatus, Errand::STATUS_PENDING_ASSIGNMENT, $runner->id, $reason);

            AutoReassignErrand::dispatch($errand)->afterCommit();

            // Notify customer
            $this->notificationService->send(
                $errand->customer,
                AppNotification::TYPE_ERRAND_ASSIGNED,
                'Runner Cancelled',
                "Your runner had to cancel. We are finding you a new runner.",
                $this->errandNotificationData($errand)
            );

            event(new ErrandStatusUpdated($errand));
            return $errand;
        });
    }

    public function triggerPanic(User $user, Errand $errand, array $data): void
    {
        DB::transaction(function () use ($user, $errand, $data) {
            $panic = \App\Models\PanicEvent::create([
                'errand_id' => $errand->id,
                'triggered_by' => $user->id,
                'latitude' => $data['latitude'] ?? null,
                'longitude' => $data['longitude'] ?? null,
                'notes' => $data['notes'] ?? null,
                'status' => \App\Models\PanicEvent::STATUS_ACTIVE,
            ]);

            SummarizePanicEventJob::dispatch($panic->id)->afterCommit();

            $errand->update([
                'panic_triggered_at' => now(),
                'panic_triggered_by' => $user->id,
                'status' => Errand::STATUS_DISPUTED,
            ]);

            // Freeze escrow
            if ($errand->escrow) {
                $errand->escrow->update([
                    'status' => EscrowTransaction::STATUS_FROZEN,
                    'frozen_at' => now(),
                    'frozen_reason' => 'Panic event triggered',
                ]);
            }

            event(new PanicTriggered($errand, $user));
        });
    }

    private function errandNotificationData(Errand $errand, array $extra = []): array
    {
        return array_merge([
            'errand_id' => $errand->id,
            'public_id' => $errand->public_id,
        ], $extra);
    }

    private function calculatePlatformFee(int $budget): int
    {
        $rate = config('errandly.commission_rate', 0.15);
        return (int) ceil($budget * $rate);
    }

    private function calculateCustomerCancellationRefund(Errand $errand): int
    {
        $totalPaid = $errand->budget + $errand->platform_fee;

        return match ($errand->status) {
            Errand::STATUS_POSTED,
            Errand::STATUS_PENDING_ASSIGNMENT => $totalPaid,
            Errand::STATUS_ACCEPTED => $totalPaid - $errand->platform_fee,
            Errand::STATUS_RUNNER_EN_ROUTE => (int) ($totalPaid * 0.5),
            default => 0,
        };
    }

    private function logStatusChange(Errand $errand, ?string $from, string $to, int $changedBy, ?string $reason = null): void
    {
        ErrandStatusHistory::create([
            'errand_id' => $errand->id,
            'from_status' => $from,
            'to_status' => $to,
            'changed_by' => $changedBy,
            'reason' => $reason,
            'created_at' => now(),
        ]);
    }

    private function validateRunnerOwnership(User $runner, Errand $errand): void
    {
        if ($errand->runner_id !== $runner->id) {
            throw new \Exception('You are not assigned to this errand.');
        }
    }

    private function validateStatus(Errand $errand, string $expectedStatus, string $action): void
    {
        if ($errand->status !== $expectedStatus) {
            throw new \Exception("Cannot {$action}: errand is in '{$errand->status}' status.");
        }
    }

    private function updateRunnerStats(User $runner): void
    {
        $profile = $runner->runnerProfile;
        $profile->increment('total_errands');

        // Recalculate completion rate
        $completed = Errand::where('runner_id', $runner->id)
            ->where('status', Errand::STATUS_COMPLETED)->count();
        $total = Errand::where('runner_id', $runner->id)
            ->whereNotIn('status', [Errand::STATUS_DRAFT, Errand::STATUS_POSTED])
            ->count();

        $profile->update([
            'completion_rate' => $total > 0 ? round(($completed / $total) * 100, 2) : 100,
        ]);

        $this->trustScoreService->recalculate($profile);
    }
}
