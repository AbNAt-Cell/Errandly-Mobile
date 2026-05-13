<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ServiceAreaSeeder extends Seeder
{
    public function run(): void
    {
        $areas = [
            ['name' => 'Lekki', 'city' => 'Lekki', 'state' => 'Lagos', 'center_latitude' => 6.4698, 'center_longitude' => 3.5852, 'radius_km' => 10, 'is_active' => true],
            ['name' => 'Yaba', 'city' => 'Yaba', 'state' => 'Lagos', 'center_latitude' => 6.5058, 'center_longitude' => 3.3767, 'radius_km' => 8, 'is_active' => true],
            ['name' => 'Ikeja', 'city' => 'Ikeja', 'state' => 'Lagos', 'center_latitude' => 6.5955, 'center_longitude' => 3.3401, 'radius_km' => 10, 'is_active' => true],
            ['name' => 'Surulere', 'city' => 'Surulere', 'state' => 'Lagos', 'center_latitude' => 6.5059, 'center_longitude' => 3.3534, 'radius_km' => 8, 'is_active' => true],
            ['name' => 'Victoria Island', 'city' => 'Victoria Island', 'state' => 'Lagos', 'center_latitude' => 6.4281, 'center_longitude' => 3.4219, 'radius_km' => 7, 'is_active' => true],
        ];

        foreach ($areas as $area) {
            DB::table('service_areas')->updateOrInsert(
                ['name' => $area['name'], 'city' => $area['city']],
                array_merge($area, ['created_at' => now(), 'updated_at' => now()])
            );
        }
    }
}
