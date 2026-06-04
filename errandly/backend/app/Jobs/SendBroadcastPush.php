<?php

namespace App\Jobs;

use App\Services\DeviceTokenService;
use App\Services\FcmService;
use App\Services\NotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SendBroadcastPush implements ShouldQueue
{
    use InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;

    public int $timeout = 300;

    /**
     * @param  list<int>  $userIds
     * @param  array<string, string>  $data
     */
    public function __construct(
        public array $userIds,
        public string $title,
        public string $body,
        public array $data = [],
    ) {}

    public function handle(
        FcmService $fcm,
        NotificationService $notifications,
        DeviceTokenService $deviceTokens,
    ): void {
        $tokens = $notifications->marketingPushTokensForUserIds($this->userIds);

        if ($tokens === []) {
            return;
        }

        $invalid = $fcm->sendBatch($tokens, $this->title, $this->body, $this->data);

        foreach ($invalid as $token) {
            $deviceTokens->removeToken($token);
        }
    }
}
