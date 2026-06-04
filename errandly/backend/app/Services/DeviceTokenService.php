<?php

namespace App\Services;

use App\Models\User;
use App\Models\UserDeviceToken;
use Illuminate\Support\Collection;

class DeviceTokenService
{
    public function register(
        User $user,
        string $deviceId,
        string $token,
        string $deviceType = 'android',
        ?string $deviceName = null,
    ): UserDeviceToken {
        $record = UserDeviceToken::updateOrCreate(
            [
                'user_id' => $user->id,
                'device_id' => $deviceId,
            ],
            [
                'token' => $token,
                'device_type' => $deviceType,
                'device_name' => $deviceName,
                'last_used_at' => now(),
            ]
        );

        // Keep legacy column in sync (latest device).
        $user->update([
            'device_token' => $token,
            'device_type' => $deviceType,
        ]);

        return $record;
    }

    /**
     * @return Collection<int, string>
     */
    public function tokensForUser(User $user): Collection
    {
        return UserDeviceToken::where('user_id', $user->id)
            ->orderByDesc('last_used_at')
            ->pluck('token')
            ->unique()
            ->values();
    }

    public function removeToken(string $token): void
    {
        UserDeviceToken::where('token', $token)->delete();

        User::where('device_token', $token)->update([
            'device_token' => null,
            'device_type' => null,
        ]);
    }

    public function removeDevice(User $user, string $deviceId): void
    {
        $record = UserDeviceToken::where('user_id', $user->id)
            ->where('device_id', $deviceId)
            ->first();

        if (! $record) {
            return;
        }

        $record->delete();

        $latest = UserDeviceToken::where('user_id', $user->id)
            ->orderByDesc('last_used_at')
            ->first();

        $user->update([
            'device_token' => $latest?->token,
            'device_type' => $latest?->device_type,
        ]);
    }
}
