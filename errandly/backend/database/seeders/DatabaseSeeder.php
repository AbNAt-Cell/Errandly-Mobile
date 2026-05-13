<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;
use App\Models\User;
use App\Models\RunnerProfile;
use App\Models\Wallet;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            RolesAndPermissionsSeeder::class,
            SettingsSeeder::class,
            ServiceAreaSeeder::class,
            AdminUserSeeder::class,
        ]);

        if (app()->environment('local', 'staging')) {
            $this->call([
                TestUsersSeeder::class,
            ]);
        }
    }
}
