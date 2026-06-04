<?php

namespace App\Services;

use App\Services\Fcm\FcmSendResult;
use App\Services\Fcm\GoogleAccessTokenProvider;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmService
{
    public function isConfigured(): bool
    {
        return config('services.firebase.enabled', false)
            && config('services.firebase.project_id')
            && $this->credentialsPath()
            && is_readable($this->credentialsPath());
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function sendToDevice(string $deviceToken, string $title, string $body, array $data = []): FcmSendResult
    {
        if (! $this->isConfigured()) {
            return FcmSendResult::Skipped;
        }

        $accessToken = $this->tokenProvider()->getAccessToken();

        if (! $accessToken) {
            return FcmSendResult::Failed;
        }

        $projectId = config('services.firebase.project_id');
        $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";

        $response = Http::withToken($accessToken)
            ->acceptJson()
            ->post($url, [
                'message' => [
                    'token' => $deviceToken,
                    'notification' => [
                        'title' => $title,
                        'body' => $body,
                    ],
                    'data' => $this->normalizeData($data),
                    'android' => [
                        'priority' => 'HIGH',
                    ],
                    'apns' => [
                        'headers' => [
                            'apns-priority' => '10',
                        ],
                        'payload' => [
                            'aps' => [
                                'sound' => 'default',
                            ],
                        ],
                    ],
                ],
            ]);

        if ($response->successful()) {
            return FcmSendResult::Sent;
        }

        if ($response->status() === 401) {
            $this->tokenProvider()->forgetCachedToken();
        }

        $errorCode = $response->json('error.details.0.errorCode')
            ?? $response->json('error.status');

        if ($this->isInvalidTokenError($response->status(), (string) $errorCode, $response->body())) {
            Log::info('FCM token invalid, should clear device token', [
                'status' => $response->status(),
                'error' => $response->json('error'),
            ]);

            return FcmSendResult::TokenInvalid;
        }

        Log::error('FCM send failed', [
            'status' => $response->status(),
            'body' => $response->body(),
        ]);

        return FcmSendResult::Failed;
    }

    /**
     * Send to multiple tokens (e.g. user's phone + tablet). Returns invalid tokens to remove.
     *
     * @param  list<string>  $deviceTokens
     * @param  array<string, mixed>  $data
     * @return list<string> Invalid tokens
     */
    public function sendToTokens(array $deviceTokens, string $title, string $body, array $data = []): array
    {
        $invalid = [];

        foreach (array_unique($deviceTokens) as $token) {
            $result = $this->sendToDevice($token, $title, $body, $data);

            if ($result === FcmSendResult::TokenInvalid) {
                $invalid[] = $token;
            }
        }

        return $invalid;
    }

    /**
     * Concurrent batch send for broadcasts (chunks of 25).
     *
     * @param  list<string>  $deviceTokens
     * @param  array<string, mixed>  $data
     * @return list<string> Invalid tokens
     */
    public function sendBatch(array $deviceTokens, string $title, string $body, array $data = []): array
    {
        if (! $this->isConfigured() || $deviceTokens === []) {
            return [];
        }

        $accessToken = $this->tokenProvider()->getAccessToken();

        if (! $accessToken) {
            return [];
        }

        $projectId = config('services.firebase.project_id');
        $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";
        $normalizedData = $this->normalizeData($data);
        $invalid = [];

        foreach (array_chunk(array_unique($deviceTokens), 25) as $chunk) {
            $responses = Http::pool(function ($pool) use ($chunk, $accessToken, $url, $title, $body, $normalizedData) {
                foreach ($chunk as $index => $token) {
                    $pool->as((string) $index)
                        ->withToken($accessToken)
                        ->acceptJson()
                        ->post($url, [
                            'message' => [
                                'token' => $token,
                                'notification' => [
                                    'title' => $title,
                                    'body' => $body,
                                ],
                                'data' => $normalizedData,
                                'android' => ['priority' => 'HIGH'],
                            ],
                        ]);
                }
            });

            foreach ($chunk as $index => $token) {
                $response = $responses[(string) $index] ?? null;

                if (! $response || $response->successful()) {
                    continue;
                }

                $errorCode = $response->json('error.details.0.errorCode')
                    ?? $response->json('error.status');

                if ($this->isInvalidTokenError($response->status(), (string) $errorCode, $response->body())) {
                    $invalid[] = $token;
                }
            }
        }

        return $invalid;
    }

    /**
     * FCM data payload values must be strings.
     *
     * @param  array<string, mixed>  $data
     * @return array<string, string>
     */
    public function normalizeData(array $data): array
    {
        $normalized = [];

        foreach ($data as $key => $value) {
            if (is_array($value) || is_object($value)) {
                $normalized[(string) $key] = json_encode($value);
            } elseif ($value === null) {
                $normalized[(string) $key] = '';
            } else {
                $normalized[(string) $key] = (string) $value;
            }
        }

        return $normalized;
    }

    private function isInvalidTokenError(int $status, string $errorCode, string $body): bool
    {
        if (in_array($errorCode, ['UNREGISTERED', 'INVALID_ARGUMENT'], true)) {
            return true;
        }

        if ($status === 404 && str_contains($body, 'UNREGISTERED')) {
            return true;
        }

        return str_contains($body, 'registration-token-not-registered')
            || str_contains($body, 'invalid-registration-token');
    }

    private function tokenProvider(): GoogleAccessTokenProvider
    {
        return new GoogleAccessTokenProvider($this->credentialsPath());
    }

    private function credentialsPath(): ?string
    {
        $path = config('services.firebase.credentials_file');

        if (! $path) {
            return null;
        }

        if (! str_starts_with($path, '/') && ! preg_match('/^[A-Za-z]:[\\\\\\/]/', $path)) {
            return base_path($path);
        }

        return $path;
    }
}
