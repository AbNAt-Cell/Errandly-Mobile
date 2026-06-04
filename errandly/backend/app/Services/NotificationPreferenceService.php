<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\User;
use App\Models\UserNotificationPreference;

class NotificationPreferenceService
{
    public function getOrCreate(User $user): UserNotificationPreference
    {
        return UserNotificationPreference::firstOrCreate(
            ['user_id' => $user->id],
            [
                'push_enabled' => true,
                'errand_updates' => true,
                'payments' => true,
                'account' => true,
                'marketing' => false,
                'alerts' => true,
            ]
        );
    }

    public function wantsPush(User $user, string $notificationType): bool
    {
        $prefs = $this->getOrCreate($user);

        if (! $prefs->push_enabled) {
            return false;
        }

        $category = $this->categoryForType($notificationType);

        return match ($category) {
            'errand_updates' => $prefs->errand_updates,
            'payments' => $prefs->payments,
            'account' => $prefs->account,
            'marketing' => $prefs->marketing,
            'alerts' => $prefs->alerts,
            default => true,
        };
    }

    public function categoryForType(string $notificationType): string
    {
        return match ($notificationType) {
            AppNotification::TYPE_ERRAND_OFFER,
            AppNotification::TYPE_ERRAND_ASSIGNED,
            AppNotification::TYPE_RUNNER_ARRIVED,
            AppNotification::TYPE_TASK_STARTED,
            AppNotification::TYPE_TASK_COMPLETED => 'errand_updates',

            AppNotification::TYPE_PAYMENT_RELEASED => 'payments',

            AppNotification::TYPE_KYC_APPROVED,
            AppNotification::TYPE_KYC_REJECTED,
            AppNotification::TYPE_SUSPENSION => 'account',

            AppNotification::TYPE_ANNOUNCEMENT => 'marketing',

            AppNotification::TYPE_PANIC_ALERT,
            AppNotification::TYPE_DISPUTE_OPENED,
            AppNotification::TYPE_DISPUTE_RESOLVED => 'alerts',

            default => 'errand_updates',
        };
    }

    /**
     * @return array<string, bool>
     */
    public function toArray(UserNotificationPreference $prefs): array
    {
        return [
            'push_enabled' => $prefs->push_enabled,
            'errand_updates' => $prefs->errand_updates,
            'payments' => $prefs->payments,
            'account' => $prefs->account,
            'marketing' => $prefs->marketing,
            'alerts' => $prefs->alerts,
        ];
    }
}
