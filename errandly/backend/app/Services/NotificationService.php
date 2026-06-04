<?php

namespace App\Services;

use App\Jobs\SendBroadcastPush;
use App\Jobs\SendPushNotification;
use App\Models\AppNotification;
use App\Models\User;
use App\Models\UserDeviceToken;

class NotificationService
{
    public function __construct(
        private FcmService $fcm,
        private NotificationPreferenceService $preferences,
        private DeviceTokenService $deviceTokens,
    ) {}

    public function send(
        User $user,
        string $type,
        string $title,
        string $body,
        array $data = [],
        ?string $actionUrl = null,
    ): AppNotification {
        $notification = AppNotification::create([
            'user_id' => $user->id,
            'type' => $type,
            'title' => $title,
            'body' => $body,
            'data' => $data,
            'action_url' => $actionUrl,
        ]);

        $this->dispatchPush($user, $type, $title, $body, $data);

        return $notification;
    }

    public function sendToMany(array $userIds, string $type, string $title, string $body, array $data = []): void
    {
        $users = User::whereIn('id', $userIds)->get();

        foreach ($users as $user) {
            $this->send($user, $type, $title, $body, $data);
        }
    }

    public function broadcastAnnouncement(string $title, string $body, array $filters = []): int
    {
        $query = User::query();

        if (! empty($filters['role'])) {
            $query->role($filters['role']);
        }

        if (! empty($filters['city'])) {
            $query->where('city', $filters['city']);
        }

        $users = $query->get();
        $userIds = [];

        foreach ($users as $user) {
            AppNotification::create([
                'user_id' => $user->id,
                'type' => AppNotification::TYPE_ANNOUNCEMENT,
                'title' => $title,
                'body' => $body,
            ]);
            $userIds[] = $user->id;
        }

        SendBroadcastPush::dispatch(
            $userIds,
            $title,
            $body,
            $this->fcm->normalizeData(['type' => AppNotification::TYPE_ANNOUNCEMENT]),
        );

        return count($userIds);
    }

    /**
     * @param  array<string, mixed>  $data
     */
    private function dispatchPush(User $user, string $type, string $title, string $body, array $data): void
    {
        if (! $this->fcm->isConfigured()) {
            return;
        }

        if (! $this->preferences->wantsPush($user, $type)) {
            return;
        }

        if ($this->deviceTokens->tokensForUser($user)->isEmpty()) {
            return;
        }

        $payload = $this->fcm->normalizeData(array_merge(['type' => $type], $data));

        SendPushNotification::dispatch($user->id, $title, $body, $payload);
    }

    /**
     * Collect FCM tokens for users who want marketing pushes (for batch job).
     *
     * @param  list<int>  $userIds
     * @return list<string>
     */
    public function marketingPushTokensForUserIds(array $userIds): array
    {
        $tokens = [];

        $users = User::whereIn('id', $userIds)->get();

        foreach ($users as $user) {
            if (! $this->preferences->wantsPush($user, AppNotification::TYPE_ANNOUNCEMENT)) {
                continue;
            }

            foreach ($this->deviceTokens->tokensForUser($user) as $token) {
                $tokens[] = $token;
            }
        }

        return array_values(array_unique($tokens));
    }
}
