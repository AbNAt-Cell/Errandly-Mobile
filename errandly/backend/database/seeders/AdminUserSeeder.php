<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::firstOrCreate(
            ['email' => 'admin@errandly.com'],
            [
                'first_name' => 'Super',
                'last_name' => 'Admin',
                'phone' => '+2349000000001',
                'password' => Hash::make('Admin@1234'),
                'status' => User::STATUS_ACTIVE,
                'kyc_status' => User::KYC_APPROVED,
                'referral_code' => 'ADMIN001',
                'email_verified_at' => now(),
                'phone_verified_at' => now(),
            ]
        );

        $admin->syncRoles(['super_admin']);

        if (!$admin->wallet) {
            Wallet::create([
                'user_id' => $admin->id,
                'balance' => 0,
                'currency' => 'NGN',
            ]);
        }

        $verOfficer = User::firstOrCreate(
            ['email' => 'kyc@errandly.com'],
            [
                'first_name' => 'KYC',
                'last_name' => 'Officer',
                'phone' => '+2349000000002',
                'password' => Hash::make('Kyc@Officer1234'),
                'status' => User::STATUS_ACTIVE,
                'kyc_status' => User::KYC_APPROVED,
                'referral_code' => 'KYCO001',
                'email_verified_at' => now(),
                'phone_verified_at' => now(),
            ]
        );

        $verOfficer->syncRoles(['verification_officer']);

        if (!$verOfficer->wallet) {
            Wallet::create(['user_id' => $verOfficer->id, 'balance' => 0, 'currency' => 'NGN']);
        }
    }
}
