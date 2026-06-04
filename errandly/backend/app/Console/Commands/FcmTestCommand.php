<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Services\DeviceTokenService;
use App\Services\Fcm\FcmSendResult;
use App\Services\FcmService;
use Illuminate\Console\Command;

class FcmTestCommand extends Command
{
    protected $signature = 'fcm:test
                            {user : User email or ID}
                            {--title=Errandly test : Notification title}
                            {--body=FCM is configured correctly. : Notification body}';

    protected $description = 'Send a test FCM push notification to a user';

    public function handle(FcmService $fcm, DeviceTokenService $deviceTokens): int
    {
        if (! $fcm->isConfigured()) {
            $this->error('FCM is not configured. Set FIREBASE_ENABLED=true, FIREBASE_PROJECT_ID, and place credentials at FIREBASE_CREDENTIALS.');

            return self::FAILURE;
        }

        $user = $this->resolveUser($this->argument('user'));

        if (! $user) {
            $this->error('User not found.');

            return self::FAILURE;
        }

        $tokens = $deviceTokens->tokensForUser($user)->all();

        if ($tokens === []) {
            $this->error("User {$user->email} has no registered devices. Log in from the mobile app first.");

            return self::FAILURE;
        }

        $invalid = $fcm->sendToTokens(
            $tokens,
            $this->option('title'),
            $this->option('body'),
            ['type' => 'test', 'source' => 'artisan'],
        );

        if ($invalid !== []) {
            foreach ($invalid as $token) {
                $deviceTokens->removeToken($token);
            }
            $this->warn('Some device tokens were invalid and removed.');
        }

        $this->info('Push sent to ' . count($tokens) . " device(s) for {$user->email}.");

        return self::SUCCESS;
    }

    private function resolveUser(string $identifier): ?User
    {
        if (is_numeric($identifier)) {
            return User::find((int) $identifier);
        }

        return User::where('email', $identifier)->first();
    }
}
