<?php

namespace App\Services\Ai\Vision;

use App\Models\AiVisionAnalysis;
use App\Models\ProofSubmission;
use App\Models\TrackingLog;
use App\Support\GeoQuery;

class GpsProofConsistencyChecker
{
    public function check(ProofSubmission $proof): ?AiVisionAnalysis
    {
        $errand = $proof->errand;
        if (!$errand) {
            return null;
        }

        $latestTrack = TrackingLog::where('errand_id', $errand->id)
            ->where('runner_id', $proof->runner_id)
            ->orderByDesc('logged_at')
            ->first();

        if (!$latestTrack || !$errand->destination_latitude || !$errand->destination_longitude) {
            return null;
        }

        $distanceKm = GeoQuery::haversineKm(
            (float) $latestTrack->latitude,
            (float) $latestTrack->longitude,
            (float) $errand->destination_latitude,
            (float) $errand->destination_longitude,
        );

        $thresholdKm = (float) config('ai.gps_proof_threshold_km', 2.0);
        $consistent = $distanceKm <= $thresholdKm;

        $result = [
            'gps_consistent' => $consistent,
            'distance_to_destination_km' => round($distanceKm, 2),
            'threshold_km' => $thresholdKm,
            'flags' => $consistent ? [] : [['code' => 'GPS_INCONSISTENT', 'severity' => 'medium', 'detail' => 'Runner location far from destination at proof time']],
        ];

        return AiVisionAnalysis::updateOrCreate(
            [
                'subject_type' => 'proof_gps_check',
                'subject_id' => (string) $proof->id,
            ],
            [
                'model' => 'rules',
                'result' => $result,
                'flags' => $result['flags'],
            ],
        );
    }
}
