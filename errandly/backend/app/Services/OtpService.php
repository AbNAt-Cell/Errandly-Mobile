<?php

namespace App\Services;

use App\Models\Errand;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

class OtpService
{
    const PICKUP_OTP_TTL = 3600;   // 1 hour
    const DELIVERY_OTP_TTL = 3600; // 1 hour
    const AUTH_OTP_TTL = 600;      // 10 minutes

    public function generatePickupOtp(Errand $errand): string
    {
        $otp = $this->generate6DigitOtp();
        $key = "pickup_otp:{$errand->id}";
        Cache::put($key, $otp, self::PICKUP_OTP_TTL);
        $errand->update(['pickup_otp' => bcrypt($otp)]);
        return $otp;
    }

    public function verifyPickupOtp(Errand $errand, string $otp): bool
    {
        $key = "pickup_otp:{$errand->id}";
        $stored = Cache::get($key);

        if (!$stored || $stored !== $otp) {
            return false;
        }

        Cache::forget($key);
        return true;
    }

    public function generateDeliveryOtp(Errand $errand): string
    {
        $otp = $this->generate6DigitOtp();
        $key = "delivery_otp:{$errand->id}";
        Cache::put($key, $otp, self::DELIVERY_OTP_TTL);
        $errand->update(['delivery_otp' => bcrypt($otp)]);
        return $otp;
    }

    public function verifyDeliveryOtp(Errand $errand, string $otp): bool
    {
        $key = "delivery_otp:{$errand->id}";
        $stored = Cache::get($key);

        if (!$stored || $stored !== $otp) {
            return false;
        }

        Cache::forget($key);
        return true;
    }

    public function generateAuthOtp(string $phone): string
    {
        $otp = $this->generate6DigitOtp();
        $key = "auth_otp:{$phone}";
        Cache::put($key, $otp, self::AUTH_OTP_TTL);
        return $otp;
    }

    public function verifyAuthOtp(string $phone, string $otp): bool
    {
        $key = "auth_otp:{$phone}";
        $stored = Cache::get($key);

        if (!$stored || $stored !== $otp) {
            return false;
        }

        Cache::forget($key);
        return true;
    }

    private function generate6DigitOtp(): string
    {
        return str_pad((string) random_int(100000, 999999), 6, '0', STR_PAD_LEFT);
    }
}
