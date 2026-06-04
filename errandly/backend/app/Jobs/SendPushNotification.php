<?php

namespace App\Jobs;

use App\Models\User;
use App\Services\DeviceTokenService;
use App\Services\FcmService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SendPushNotification implements ShouldQueue
{
    use InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;

    public int $timeout = 60;

    /**
     * @param  array<string, string>  $data
     */
    public function __construct(
        public int $userId,
        public string $title,
        public string $body,
        public array $data = [],
    ) {}

    public function handle(FcmService $fcm, DeviceTokenService $deviceTokens): void
    {
        $user = User::find($this->userId);

        if (! $user) {
            return;
        }

        $tokens = $deviceTokens->tokensForUser($user)->all();

        if ($tokens === []) {
            return;
        }

        $invalid = $fcm->sendToTokens($tokens, $this->title, $this->body, $this->data);

        foreach ($invalid as $token) {
            $deviceTokens->removeToken($token);
        }
    }
}
