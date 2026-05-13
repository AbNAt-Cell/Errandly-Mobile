<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\RunnerProfile;
use App\Models\Wallet;
use App\Models\KycDocument;
use Illuminate\Support\Facades\Hash;

class TestUsersSeeder extends Seeder
{
    public function run(): void
    {
        // Test Customer
        $customer = User::firstOrCreate(
            ['email' => 'customer@test.com'],
            [
                'first_name' => 'Ada',
                'last_name' => 'Okafor',
                'phone' => '+2348100000001',
                'password' => Hash::make('Test@1234'),
                'status' => User::STATUS_ACTIVE,
                'kyc_status' => User::KYC_APPROVED,
                'referral_code' => 'CUST001',
                'city' => 'Lekki',
                'state' => 'Lagos',
                'email_verified_at' => now(),
                'phone_verified_at' => now(),
            ]
        );

        $customer->assignRole('customer');

        if (!$customer->wallet) {
            Wallet::create([
                'user_id' => $customer->id,
                'balance' => 50000,
                'currency' => 'NGN',
                'total_funded' => 50000,
            ]);
        }

        // Test Runner
        $runner = User::firstOrCreate(
            ['email' => 'runner@test.com'],
            [
                'first_name' => 'Chidi',
                'last_name' => 'Madu',
                'phone' => '+2348100000002',
                'password' => Hash::make('Test@1234'),
                'status' => User::STATUS_ACTIVE,
                'kyc_status' => User::KYC_APPROVED,
                'referral_code' => 'RUN001',
                'city' => 'Lekki',
                'state' => 'Lagos',
                'email_verified_at' => now(),
                'phone_verified_at' => now(),
            ]
        );

        $runner->assignRole('runner');

        if (!$runner->runnerProfile) {
            RunnerProfile::create([
                'user_id' => $runner->id,
                'transport_type' => 'motorcycle',
                'service_radius_km' => 10,
                'service_city' => 'Lekki',
                'service_state' => 'Lagos',
                'verification_status' => RunnerProfile::VERIFICATION_APPROVED,
                'is_verified' => true,
                'verified_at' => now(),
                'trust_score' => 85.00,
                'completion_rate' => 95.00,
                'average_rating' => 4.7,
                'total_errands' => 47,
                'is_online' => false,
                'current_latitude' => 6.4698,
                'current_longitude' => 3.5852,
            ]);
        }

        if (!$runner->wallet) {
            Wallet::create([
                'user_id' => $runner->id,
                'balance' => 24500,
                'currency' => 'NGN',
                'total_earned' => 87000,
            ]);
        }

        KycDocument::firstOrCreate(
            ['user_id' => $runner->id],
            [
                'type' => 'runner',
                'status' => KycDocument::STATUS_APPROVED,
                'id_type' => KycDocument::ID_NATIONAL,
                'id_number' => '12345678901',
                'submitted_at' => now()->subDays(7),
                'reviewed_at' => now()->subDays(5),
            ]
        );

        $this->command->info('Test users seeded:');
        $this->command->info('  Customer: customer@test.com / Test@1234');
        $this->command->info('  Runner:   runner@test.com / Test@1234');
        $this->command->info('  Admin:    admin@errandly.com / Admin@1234');
    }
}
