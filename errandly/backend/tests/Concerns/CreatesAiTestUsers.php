<?php

namespace Tests\Concerns;

use App\Models\User;
use App\Models\Wallet;
use Database\Seeders\RolesAndPermissionsSeeder;
use Illuminate\Support\Facades\Hash;

trait CreatesAiTestUsers
{
    protected function seedRoles(): void
    {
        $this->seed(RolesAndPermissionsSeeder::class);
    }

    protected function createCustomer(array $overrides = []): User
    {
        $user = User::create(array_merge([
            'first_name' => 'Test',
            'last_name' => 'Customer',
            'email' => 'ai-customer-' . uniqid() . '@test.com',
            'phone' => '+23481' . random_int(10000000, 99999999),
            'password' => Hash::make('password'),
            'status' => User::STATUS_ACTIVE,
            'kyc_status' => User::KYC_APPROVED,
            'referral_code' => 'AI' . strtoupper(substr(uniqid(), -6)),
            'city' => 'Uyo',
            'state' => 'Akwa Ibom',
            'email_verified_at' => now(),
            'phone_verified_at' => now(),
        ], $overrides));

        $user->assignRole('customer');

        Wallet::create([
            'user_id' => $user->id,
            'balance' => 100000,
            'currency' => 'NGN',
            'total_funded' => 100000,
        ]);

        return $user->fresh(['wallet']);
    }

    protected function createRunner(array $overrides = []): User
    {
        $user = User::create(array_merge([
            'first_name' => 'Test',
            'last_name' => 'Runner',
            'email' => 'ai-runner-' . uniqid() . '@test.com',
            'phone' => '+23482' . random_int(10000000, 99999999),
            'password' => Hash::make('password'),
            'status' => User::STATUS_ACTIVE,
            'kyc_status' => User::KYC_APPROVED,
            'referral_code' => 'RUN' . strtoupper(substr(uniqid(), -6)),
            'city' => 'Uyo',
            'state' => 'Akwa Ibom',
            'email_verified_at' => now(),
            'phone_verified_at' => now(),
        ], $overrides));

        $user->assignRole('runner');

        \App\Models\RunnerProfile::create([
            'user_id' => $user->id,
            'verification_status' => \App\Models\RunnerProfile::VERIFICATION_APPROVED,
            'is_verified' => true,
            'trust_score' => 80,
            'is_available' => true,
            'is_online' => true,
        ]);

        return $user->fresh();
    }
}
