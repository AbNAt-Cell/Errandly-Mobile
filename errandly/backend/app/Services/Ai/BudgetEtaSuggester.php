<?php

namespace App\Services\Ai;

use App\Models\Errand;
use App\Support\GeoQuery;

class BudgetEtaSuggester
{
    /**
     * @return array{
     *     suggested_budget_kobo: int,
     *     suggested_eta_minutes: int,
     *     platform_fee_kobo: int,
     *     estimated_total_kobo: int,
     *     explanation: string,
     *     confidence: float
     * }
     */
    public function suggest(
        string $category,
        float $pickupLat,
        float $pickupLng,
        float $destLat,
        float $destLng,
        string $urgency = 'standard',
    ): array {
        $distanceKm = GeoQuery::haversineKm($pickupLat, $pickupLng, $destLat, $destLng);

        $budgets = Errand::query()
            ->where('category', $category)
            ->where('status', Errand::STATUS_COMPLETED)
            ->where('created_at', '>=', now()->subDays(90))
            ->pluck('budget')
            ->sort()
            ->values();

        $median = 0;
        if ($budgets->isNotEmpty()) {
            $mid = (int) floor($budgets->count() / 2);
            $median = (int) $budgets[$mid];
        }

        $base = $median > 0 ? $median : $this->defaultBudgetForCategory($category);

        $distanceAddon = (int) round($distanceKm * 15000);
        $urgencyMultiplier = $urgency === Errand::URGENCY_URGENT ? 1.25 : 1.0;

        $suggestedBudget = (int) max(
            config('errandly.min_errand_amount', 500),
            round(($base + $distanceAddon) * $urgencyMultiplier),
        );

        $etaMinutes = (int) max(15, round(20 + ($distanceKm * 8) * ($urgency === Errand::URGENCY_URGENT ? 0.85 : 1)));

        $platformFee = (int) ceil($suggestedBudget * config('errandly.commission_rate', 0.15));

        return [
            'suggested_budget_kobo' => $suggestedBudget,
            'suggested_eta_minutes' => $etaMinutes,
            'platform_fee_kobo' => $platformFee,
            'estimated_total_kobo' => $suggestedBudget + $platformFee,
            'distance_km' => round($distanceKm, 2),
            'explanation' => sprintf(
                'Based on %s errands (~₦%s) plus %.1f km travel%s.',
                $category,
                number_format($suggestedBudget / 100, 0),
                $distanceKm,
                $urgency === Errand::URGENCY_URGENT ? ' (urgent)' : '',
            ),
            'confidence' => $median > 0 ? 0.85 : 0.6,
        ];
    }

    private function defaultBudgetForCategory(string $category): int
    {
        return match ($category) {
            Errand::CATEGORY_GROCERY => 3500,
            Errand::CATEGORY_PRESCRIPTION => 4000,
            Errand::CATEGORY_DOCUMENT_SUBMISSION, Errand::CATEGORY_DOCUMENT_COLLECTION => 3000,
            Errand::CATEGORY_QUEUE_STANDING => 2500,
            default => 3000,
        };
    }
}
