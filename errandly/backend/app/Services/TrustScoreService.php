<?php

namespace App\Services;

use App\Models\RunnerProfile;
use App\Models\Errand;
use App\Models\Rating;
use App\Support\GeoQuery;

class TrustScoreService
{
    const BASE_SCORE = 100;
    const MAX_SCORE = 100;
    const MIN_SCORE = 0;

    const WEIGHTS = [
        'completion_rate' => 0.30,
        'average_rating' => 0.30,
        'cancellation_penalty' => 0.20,
        'dispute_penalty' => 0.15,
        'response_time' => 0.05,
    ];

    const PENALTIES = [
        'cancellation' => 5,
        'dispute_raised' => 10,
        'late_arrival' => 2,
        'safety_incident' => 20,
        'fake_proof' => 25,
        'abuse_report' => 15,
    ];

    const BONUSES = [
        'perfect_rating' => 2,
        'milestone_10' => 5,
        'milestone_50' => 10,
        'fast_response' => 1,
    ];

    public function recalculate(RunnerProfile $profile): float
    {
        $runnerId = $profile->user_id;

        // Get all completed/cancelled stats
        $totalErrands = Errand::where('runner_id', $runnerId)
            ->whereNotIn('status', [Errand::STATUS_DRAFT, Errand::STATUS_POSTED, Errand::STATUS_PENDING_ASSIGNMENT])
            ->count();

        $completedErrands = Errand::where('runner_id', $runnerId)
            ->where('status', Errand::STATUS_COMPLETED)->count();

        $cancelledErrands = Errand::where('runner_id', $runnerId)
            ->where('status', Errand::STATUS_CANCELLED)
            ->where('cancellation_by', 'runner')->count();

        $disputedErrands = Errand::where('runner_id', $runnerId)
            ->where('status', Errand::STATUS_DISPUTED)->count();

        $avgRating = Rating::where('rated_id', $runnerId)
            ->where('role', Rating::ROLE_CUSTOMER_TO_RUNNER)
            ->avg('overall_rating') ?? 5.0;

        // Completion rate score (0-30)
        $completionRate = $totalErrands > 0 ? ($completedErrands / $totalErrands) : 1;
        $completionScore = $completionRate * 30;

        // Rating score (0-30)
        $ratingScore = ($avgRating / 5) * 30;

        // Cancellation penalty
        $cancellationPenalty = min($cancelledErrands * self::PENALTIES['cancellation'], 20);

        // Dispute penalty
        $disputePenalty = min($disputedErrands * self::PENALTIES['dispute_raised'], 15);

        $score = $completionScore + $ratingScore - $cancellationPenalty - $disputePenalty;

        // Milestone bonuses
        if ($completedErrands >= 50) {
            $score += self::BONUSES['milestone_50'];
        } elseif ($completedErrands >= 10) {
            $score += self::BONUSES['milestone_10'];
        }

        $finalScore = max(self::MIN_SCORE, min(self::MAX_SCORE, round($score, 2)));

        $profile->update([
            'trust_score' => $finalScore,
            'completion_rate' => round($completionRate * 100, 2),
            'average_rating' => round($avgRating, 2),
            'total_errands' => $completedErrands,
            'cancelled_errands' => $cancelledErrands,
        ]);

        return $finalScore;
    }

    public function penalizeForCancellation(RunnerProfile $profile): void
    {
        $newScore = max(
            self::MIN_SCORE,
            $profile->trust_score - self::PENALTIES['cancellation']
        );
        $profile->update(['trust_score' => $newScore]);
    }

    public function penalizeForSafetyIncident(RunnerProfile $profile): void
    {
        $newScore = max(
            self::MIN_SCORE,
            $profile->trust_score - self::PENALTIES['safety_incident']
        );
        $profile->update(['trust_score' => $newScore]);
    }

    public function applyManualAdjustment(RunnerProfile $profile, float $adjustment, string $reason): void
    {
        $newScore = max(self::MIN_SCORE, min(self::MAX_SCORE, $profile->trust_score + $adjustment));
        $profile->update(['trust_score' => $newScore]);
    }

    public function findNearbyEligibleRunners(float $lat, float $lng, float $radiusKm = 10, int $limit = 20): \Illuminate\Support\Collection
    {
        $query = RunnerProfile::query()
            ->where('is_online', true)
            ->where('is_available', true)
            ->where('verification_status', RunnerProfile::VERIFICATION_APPROVED)
            ->whereHas('user', function ($q) {
                $q->where('status', \App\Models\User::STATUS_ACTIVE);
            })
            ->whereDoesntHave('user', function ($q) {
                $q->whereHas('runnerErrands', function ($q2) {
                    $q2->whereIn('status', [
                        Errand::STATUS_ACCEPTED,
                        Errand::STATUS_RUNNER_EN_ROUTE,
                        Errand::STATUS_ITEM_PICKED,
                        Errand::STATUS_IN_PROGRESS,
                    ]);
                });
            });

        GeoQuery::applyDistanceScope(
            $query,
            $lat,
            $lng,
            $radiusKm,
            'runner_profiles',
            'current_latitude',
            'current_longitude',
        );

        return $query
            ->orderBy('trust_score', 'desc')
            ->limit($limit)
            ->get();
    }
}
