<?php

namespace App\Services\Fcm;

use DateTimeImmutable;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Lcobucci\JWT\Configuration;
use Lcobucci\JWT\Signer\Key\InMemory;
use Lcobucci\JWT\Signer\Rsa\Sha256;

class GoogleAccessTokenProvider
{
    private const CACHE_KEY = 'fcm.google_access_token';

    private const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

    public function __construct(
        private readonly string $credentialsPath,
    ) {}

    public function getAccessToken(): ?string
    {
        return Cache::remember(self::CACHE_KEY, 3300, function () {
            return $this->requestAccessToken();
        });
    }

    public function forgetCachedToken(): void
    {
        Cache::forget(self::CACHE_KEY);
    }

    private function requestAccessToken(): ?string
    {
        if (! is_readable($this->credentialsPath)) {
            Log::warning('FCM credentials file is not readable.', ['path' => $this->credentialsPath]);

            return null;
        }

        $credentials = json_decode(file_get_contents($this->credentialsPath), true);

        if (! is_array($credentials) || empty($credentials['client_email']) || empty($credentials['private_key'])) {
            Log::error('FCM credentials file is invalid.');

            return null;
        }

        $jwt = $this->buildJwt($credentials['client_email'], $credentials['private_key']);

        $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt,
        ]);

        if (! $response->successful()) {
            Log::error('FCM OAuth token request failed', [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);

            return null;
        }

        return $response->json('access_token');
    }

    private function buildJwt(string $clientEmail, string $privateKey): string
    {
        $config = Configuration::forAsymmetricSigner(
            new Sha256(),
            InMemory::plainText($privateKey),
            InMemory::plainText($privateKey),
        );

        $now = new DateTimeImmutable();

        return $config->builder()
            ->issuedBy($clientEmail)
            ->relatedTo($clientEmail)
            ->permittedFor('https://oauth2.googleapis.com/token')
            ->issuedAt($now)
            ->expiresAt($now->modify('+1 hour'))
            ->withClaim('scope', self::SCOPE)
            ->getToken($config->signer(), $config->signingKey())
            ->toString();
    }
}
