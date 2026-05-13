<?php

namespace App\Services;

use App\Models\User;
use App\Models\AppNotification;
use Illuminate\Support\Facades\Log;

class NotificationService
{
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

        // Push notification via FCM if device token exists
        if ($user->device_token) {
            $this->sendPush($user, $title, $body, $data);
        }

        return $notification;
    }

    public function sendToMany(array $userIds, string $type, string $title, string $body, array $data = []): void
    {
        $users = User::whereIn('id', $userIds)->get();

        foreach ($users as $user) {
            $this->send($user, $type, $title, $body, $data);
        }
    }

    private function sendPush(User $user, string $title, string $body, array $data = []): void
    {
        try {
            // FCM Push notification via Firebase
            $serverKey = config('services.fcm.server_key');
            if (!$serverKey) {
                return;
            }

            $fields = [
                'to' => $user->device_token,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                    'sound' => 'default',
                ],
                'data' => $data,
                'priority' => 'high',
            ];

            $ch = curl_init('https://fcm.googleapis.com/fcm/send');
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Content-Type: application/json',
                "Authorization: key={$serverKey}",
            ]);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fields));
            curl_exec($ch);
            curl_close($ch);
        } catch (\Throwable $e) {
            Log::error('FCM push notification failed', ['error' => $e->getMessage(), 'user_id' => $user->id]);
        }
    }

    public function broadcastAnnouncement(string $title, string $body, array $filters = []): int
    {
        $query = User::query();

        if (!empty($filters['role'])) {
            $query->role($filters['role']);
        }

        if (!empty($filters['city'])) {
            $query->where('city', $filters['city']);
        }

        $users = $query->get();
        $count = 0;

        foreach ($users as $user) {
            $this->send($user, AppNotification::TYPE_ANNOUNCEMENT, $title, $body);
            $count++;
        }

        return $count;
    }
}
