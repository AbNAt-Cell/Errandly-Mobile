<?php

namespace App\Jobs;

use App\Models\Errand;
use App\Services\TrustScoreService;
use App\Services\NotificationService;
use App\Models\AppNotification;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class NotifyNearbyRunners implements ShouldQueue
{
    use Queueable, InteractsWithQueue, SerializesModels;

    public int $tries = 3;
    public int $timeout = 60;

    public function __construct(public Errand $errand) {}

    public function handle(TrustScoreService $trustScoreService, NotificationService $notificationService): void
    {
        $eligibleRunners = $trustScoreService->findNearbyEligibleRunners(
            $this->errand->pickup_latitude,
            $this->errand->pickup_longitude,
            10,
            30
        );

        if ($eligibleRunners->isEmpty()) {
            // Expand radius and try again
            $eligibleRunners = $trustScoreService->findNearbyEligibleRunners(
                $this->errand->pickup_latitude,
                $this->errand->pickup_longitude,
                20,
                50
            );
        }

        foreach ($eligibleRunners as $profile) {
            $notificationService->send(
                $profile->user,
                AppNotification::TYPE_ERRAND_OFFER,
                'New Errand Nearby!',
                "New errand: {$this->errand->title} — ₦{$this->errand->budget}. {$this->errand->category}.",
                [
                    'errand_id' => $this->errand->id,
                    'budget' => $this->errand->budget,
                    'category' => $this->errand->category,
                    'distance_km' => round($profile->distance_km, 1),
                ]
            );
        }
    }
}
