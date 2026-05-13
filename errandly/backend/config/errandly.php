<?php

return [
    'commission_rate' => env('PLATFORM_COMMISSION_RATE', 0.15),
    'min_errand_amount' => env('PLATFORM_MIN_ERRAND_AMOUNT', 500),
    'currency' => env('PLATFORM_CURRENCY', 'NGN'),
    'max_runner_radius_km' => 15,
    'errand_acceptance_timeout_minutes' => 30,
    'min_withdrawal_amount' => 1000,
    'withdrawal_processing_days' => 1,
    'otp_expiry_seconds' => 3600,
];
