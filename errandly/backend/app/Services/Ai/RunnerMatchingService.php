<?php

namespace App\Services\Ai;

use App\Models\Errand;
use App\Models\RunnerProfile;
use App\Services\TrustScoreService;
use App\Support\GeoQuery;
use Illuminate\Support\Collection;

class RunnerMatchingService
{
    public function __construct(
        private TrustScoreService $trustScoreService,
    ) {}

    /**
     * Rank nearby runners for an errand with weighted scoring.
     *
     * @return Collection<int, RunnerProfile&{match_score: float, distance_km: float, match_reason: string}>
     */
    public function rankForErrand(Errand $errand, float $radiusKm = 10, int $limit = 20): Collection
    {
        $runners = $this->trustScoreService->findNearbyEligibleRunners(
            (float) $errand->pickup_latitude,
            (float) $errand->pickup_longitude,
            $radiusKm,
            $limit * 2,
        );

        return $runners->map(function (RunnerProfile $profile) use ($errand) {
            $distanceKm = (float) ($profile->distance_km ?? 0);
            $trustNorm = ((float) $profile->trust_score) / 100;
            $completionNorm = min(1, ((float) $profile->completion_rate) / 100);
            $distancePenalty = min(1, $distanceKm / 15);

            $score = (0.4 * $trustNorm) + (0.3 * $completionNorm) + (0.3 * (1 - $distancePenalty));

            $profile->match_score = round($score, 3);
            $profile->match_reason = sprintf(
                'Trust %.0f, %.1f km away, %s%% completion rate',
                $profile->trust_score,
                $distanceKm,
                $profile->completion_rate,
            );

            return $profile;
        })->sortByDesc('match_score')->take($limit)->values();
    }
}
