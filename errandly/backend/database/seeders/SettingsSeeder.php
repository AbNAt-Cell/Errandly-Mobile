<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class SettingsSeeder extends Seeder
{
    public function run(): void
    {
        $settings = [
            ['key' => 'platform_commission_rate', 'value' => '0.15', 'type' => 'float', 'group' => 'finance', 'description' => 'Platform commission rate (15%)'],
            ['key' => 'min_errand_amount', 'value' => '500', 'type' => 'integer', 'group' => 'finance', 'description' => 'Minimum budget for an errand (in kobo/pesewas)'],
            ['key' => 'max_runner_search_radius_km', 'value' => '15', 'type' => 'integer', 'group' => 'matching', 'description' => 'Maximum radius to search for runners'],
            ['key' => 'errand_acceptance_timeout_minutes', 'value' => '30', 'type' => 'integer', 'group' => 'matching', 'description' => 'Time before re-posting if unaccepted'],
            ['key' => 'withdrawal_processing_days', 'value' => '1', 'type' => 'integer', 'group' => 'finance', 'description' => 'Days to process withdrawals'],
            ['key' => 'min_withdrawal_amount', 'value' => '1000', 'type' => 'integer', 'group' => 'finance', 'description' => 'Minimum withdrawal amount'],
            ['key' => 'platform_name', 'value' => 'Errandly', 'type' => 'string', 'group' => 'general', 'description' => 'Platform name'],
            ['key' => 'support_email', 'value' => 'support@errandly.com', 'type' => 'string', 'group' => 'general', 'description' => 'Support email'],
            ['key' => 'support_phone', 'value' => '+2349000000000', 'type' => 'string', 'group' => 'general', 'description' => 'Support phone'],
            ['key' => 'currency', 'value' => 'NGN', 'type' => 'string', 'group' => 'finance', 'description' => 'Platform currency'],
            ['key' => 'kyc_required_for_errand', 'value' => 'true', 'type' => 'boolean', 'group' => 'kyc', 'description' => 'Require KYC before posting errands'],
        ];

        foreach ($settings as $setting) {
            DB::table('settings')->updateOrInsert(
                ['key' => $setting['key']],
                array_merge($setting, ['created_at' => now(), 'updated_at' => now()])
            );
        }
    }
}
