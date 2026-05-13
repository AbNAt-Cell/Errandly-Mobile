<?php

namespace App\Services;

use App\Models\User;
use App\Models\KycDocument;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class KycService
{
    public function __construct(
        private NotificationService $notificationService,
    ) {}

    public function submitCustomerKyc(User $user, array $data): KycDocument
    {
        return DB::transaction(function () use ($user, $data) {
            $kyc = KycDocument::updateOrCreate(
                ['user_id' => $user->id],
                [
                    'type' => 'customer',
                    'id_type' => $data['id_type'],
                    'id_number' => $data['id_number'],
                    'id_document_url' => $data['id_document_url'],
                    'selfie_url' => $data['selfie_url'],
                    'status' => KycDocument::STATUS_SUBMITTED,
                    'submitted_at' => now(),
                ]
            );

            $user->update(['kyc_status' => User::KYC_SUBMITTED]);

            return $kyc;
        });
    }

    public function submitRunnerKyc(User $user, array $data): KycDocument
    {
        return DB::transaction(function () use ($user, $data) {
            $kyc = KycDocument::updateOrCreate(
                ['user_id' => $user->id],
                array_merge($data, [
                    'type' => 'runner',
                    'status' => KycDocument::STATUS_SUBMITTED,
                    'submitted_at' => now(),
                ])
            );

            $user->update(['kyc_status' => User::KYC_SUBMITTED]);
            $user->runnerProfile()->update(['verification_status' => \App\Models\RunnerProfile::VERIFICATION_SUBMITTED]);

            return $kyc;
        });
    }

    public function approveKyc(KycDocument $kyc, User $reviewer, ?string $notes = null): void
    {
        DB::transaction(function () use ($kyc, $reviewer, $notes) {
            $kyc->update([
                'status' => KycDocument::STATUS_APPROVED,
                'reviewed_by' => $reviewer->id,
                'reviewed_at' => now(),
                'notes' => $notes,
            ]);

            $user = $kyc->user;
            $user->update(['kyc_status' => User::KYC_APPROVED, 'status' => User::STATUS_ACTIVE]);

            if ($user->hasRole('runner')) {
                $user->runnerProfile()->update([
                    'verification_status' => \App\Models\RunnerProfile::VERIFICATION_APPROVED,
                    'is_verified' => true,
                    'verified_at' => now(),
                ]);
            }

            $this->notificationService->send(
                $user,
                AppNotification::TYPE_KYC_APPROVED,
                'Identity Verified!',
                'Your identity has been verified. You can now use all platform features.',
            );
        });
    }

    public function rejectKyc(KycDocument $kyc, User $reviewer, string $reason): void
    {
        DB::transaction(function () use ($kyc, $reviewer, $reason) {
            $kyc->update([
                'status' => KycDocument::STATUS_REJECTED,
                'reviewed_by' => $reviewer->id,
                'reviewed_at' => now(),
                'rejection_reason' => $reason,
            ]);

            $user = $kyc->user;
            $user->update(['kyc_status' => User::KYC_REJECTED]);

            if ($user->hasRole('runner')) {
                $user->runnerProfile()->update([
                    'verification_status' => \App\Models\RunnerProfile::VERIFICATION_REJECTED,
                ]);
            }

            $this->notificationService->send(
                $user,
                AppNotification::TYPE_KYC_REJECTED,
                'Verification Failed',
                "Your identity verification was rejected. Reason: {$reason}. Please resubmit.",
            );
        });
    }

    public function requestResubmission(KycDocument $kyc, User $reviewer, string $reason): void
    {
        $kyc->update([
            'status' => KycDocument::STATUS_RESUBMISSION_REQUIRED,
            'reviewed_by' => $reviewer->id,
            'reviewed_at' => now(),
            'resubmission_reason' => $reason,
        ]);

        $this->notificationService->send(
            $kyc->user,
            AppNotification::TYPE_KYC_REJECTED,
            'Resubmission Required',
            "Please resubmit your verification documents. Reason: {$reason}",
        );
    }
}
