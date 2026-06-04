<?php

namespace App\Support;

/**
 * PostgreSQL-safe geo distance helpers (HAVING on aliases is not supported).
 */
class GeoQuery
{
    public static function haversineKmExpression(
        string $latColumn = 'current_latitude',
        string $lngColumn = 'current_longitude',
    ): string {
        return "(6371 * acos(
            LEAST(1, GREATEST(-1,
                cos(radians(?)) * cos(radians({$latColumn})) *
                cos(radians({$lngColumn}) - radians(?)) +
                sin(radians(?)) * sin(radians({$latColumn}))
            ))
        ))";
    }

    /** @return array{0: float, 1: float, 2: float} */
    public static function haversineBindings(float $lat, float $lng): array
    {
        return [$lat, $lng, $lat];
    }

    public static function haversineKm(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $earthRadius = 6371;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

        return $earthRadius * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }

    /**
     * @param  \Illuminate\Database\Eloquent\Builder  $query
     */
    public static function applyDistanceScope(
        $query,
        float $lat,
        float $lng,
        float $radiusKm,
        string $tablePrefix,
        string $latColumn,
        string $lngColumn,
    ): void {
        $distance = self::haversineKmExpression($latColumn, $lngColumn);
        $bindings = self::haversineBindings($lat, $lng);

        $query
            ->selectRaw("{$tablePrefix}.*, {$distance} AS distance_km", $bindings)
            ->whereRaw("{$distance} <= ?", [...$bindings, $radiusKm])
            ->orderByRaw("{$distance} asc", $bindings);
    }
}
