<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ServiceAreaSeeder extends Seeder
{
    public function run(): void
    {
        $areas = [
            ['name' => 'Uyo City Centre', 'city' => 'Uyo', 'state' => 'Akwa Ibom', 'center_latitude' => 5.0543, 'center_longitude' => 7.9139, 'radius_km' => 5, 'is_active' => true],
            ['name' => 'Ewet Housing', 'city' => 'Uyo', 'state' => 'Akwa Ibom', 'center_latitude' => 5.0720, 'center_longitude' => 7.9280, 'radius_km' => 4, 'is_active' => true],
            ['name' => 'Use Offot', 'city' => 'Uyo', 'state' => 'Akwa Ibom', 'center_latitude' => 5.0400, 'center_longitude' => 7.9300, 'radius_km' => 4, 'is_active' => true],
            ['name' => 'Ikot Ekpene Road', 'city' => 'Uyo', 'state' => 'Akwa Ibom', 'center_latitude' => 5.0650, 'center_longitude' => 7.8900, 'radius_km' => 5, 'is_active' => true],
            ['name' => 'Ring Road', 'city' => 'Uyo', 'state' => 'Akwa Ibom', 'center_latitude' => 5.0500, 'center_longitude' => 7.9450, 'radius_km' => 4, 'is_active' => true],
        ];

        foreach ($areas as $area) {
            DB::table('service_areas')->updateOrInsert(
                ['name' => $area['name'], 'city' => $area['city']],
                array_merge($area, ['created_at' => now(), 'updated_at' => now()])
            );
        }
    }
}
