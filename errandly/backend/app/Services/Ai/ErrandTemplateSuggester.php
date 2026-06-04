<?php

namespace App\Services\Ai;

use App\Models\Errand;
use App\Models\User;

class ErrandTemplateSuggester
{
    /**
     * @return array{templates: array<int, array<string, mixed>>, match: array<string, mixed>|null}
     */
    public function suggest(User $customer, ?string $hint = null): array
    {
        $recent = Errand::where('customer_id', $customer->id)
            ->where('status', Errand::STATUS_COMPLETED)
            ->orderByDesc('completed_at')
            ->limit(5)
            ->get([
                'public_id', 'title', 'description', 'category', 'budget',
                'pickup_address', 'pickup_latitude', 'pickup_longitude',
                'destination_address', 'destination_latitude', 'destination_longitude',
                'item_details', 'special_instructions',
            ]);

        $templates = $recent->map(fn (Errand $e) => [
            'public_id' => $e->public_id,
            'title' => $e->title,
            'category' => $e->category,
            'budget' => $e->budget,
            'pickup_address' => $e->pickup_address,
            'destination_address' => $e->destination_address,
        ])->values()->all();

        $match = null;
        if ($hint !== null && $hint !== '') {
            $hintLower = mb_strtolower($hint);
            $match = $recent->first(function (Errand $e) use ($hintLower) {
                return str_contains(mb_strtolower($e->title), $hintLower)
                    || str_contains(mb_strtolower($e->category), $hintLower)
                    || str_contains(mb_strtolower($e->description ?? ''), $hintLower);
            });
        }

        return [
            'templates' => $templates,
            'match' => $match ? [
                'title' => $match->title,
                'description' => $match->description,
                'category' => $match->category,
                'pickup_address' => $match->pickup_address,
                'pickup_latitude' => $match->pickup_latitude,
                'pickup_longitude' => $match->pickup_longitude,
                'destination_address' => $match->destination_address,
                'destination_latitude' => $match->destination_latitude,
                'destination_longitude' => $match->destination_longitude,
                'budget' => $match->budget,
                'item_details' => $match->item_details,
                'special_instructions' => $match->special_instructions,
            ] : null,
        ];
    }
}
