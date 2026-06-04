<?php

namespace App\Services\Ai;

use App\Models\Errand;
use App\Models\Rating;
use App\Models\RunnerProfile;
use App\Models\User;

class TrustScoreExplainer
{
    /**
     * @return array{score: float, factors: array<int, array{label: string, impact: string, detail: string}>, summary: string}
     */
    public function explain(User $user): array
    {
        $profile = $user->runnerProfile;
        if (!$profile) {
            throw new \InvalidArgumentException('Trust score is only available for runners.');
        }

        $runnerId = $user->id;
        $completed = Errand::where('runner_id', $runnerId)->where('status', Errand::STATUS_COMPLETED)->count();
        $cancelled = Errand::where('runner_id', $runnerId)
            ->where('status', Errand::STATUS_CANCELLED)
            ->where('cancellation_by', 'runner')->count();
        $disputed = Errand::where('runner_id', $runnerId)->where('status', Errand::STATUS_DISPUTED)->count();
        $avgRating = Rating::where('rated_id', $runnerId)
            ->where('role', Rating::ROLE_CUSTOMER_TO_RUNNER)
            ->avg('overall_rating') ?? 5.0;

        $factors = [
            [
                'label' => 'Completion history',
                'impact' => 'positive',
                'detail' => "{$completed} completed errands",
            ],
            [
                'label' => 'Customer ratings',
                'impact' => $avgRating >= 4 ? 'positive' : 'negative',
                'detail' => 'Average ' . round($avgRating, 1) . ' / 5',
            ],
            [
                'label' => 'Cancellations',
                'impact' => $cancelled > 0 ? 'negative' : 'neutral',
                'detail' => "{$cancelled} runner cancellations",
            ],
            [
                'label' => 'Disputes',
                'impact' => $disputed > 0 ? 'negative' : 'neutral',
                'detail' => "{$disputed} disputed errands",
            ],
        ];

        $summary = sprintf(
            'Your trust score is %.0f. It reflects completed jobs, ratings, and penalties for cancellations or disputes. Complete errands reliably and maintain high ratings to improve it.',
            $profile->trust_score,
        );

        return [
            'score' => (float) $profile->trust_score,
            'factors' => $factors,
            'summary' => $summary,
        ];
    }
}
