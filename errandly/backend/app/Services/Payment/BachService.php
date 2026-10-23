<?php

namespace App\Services\Payment;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

class BachService
{
    private string $baseUrl;
    private string $secretKey;
    private string $webhookSecret;
    private string $publicKey;

    public function __construct()
    {
        $this->baseUrl = rtrim(config('services.bach.base_url', 'https://sandbox-api.bachs.io'), '/');
        $this->secretKey = config('services.bach.secret_key', '');
        $this->webhookSecret = config('services.bach.webhook_secret', '');
        $this->publicKey = config('services.bach.public_key', '');
    }

    public function isConfigured(): bool
    {
        return !empty($this->secretKey) && !str_starts_with($this->secretKey, 'your_');
    }

    public function getPublicKey(): string
    {
        return $this->publicKey;
    }

    /*
    |--------------------------------------------------------------------------
    | Checkout Session Initialization
    |--------------------------------------------------------------------------
    */

    /**
     * Create a hosted or overlay checkout session with Bachs.
     * Note: Bachs expects amounts as decimal strings at currency precision ("5000.00"), never minor units.
     *
     * @param string $email
     * @param int|float $amountNaira
     * @param string $reference
     * @param array $metadata
     * @param string|null $customerName
     * @return array
     * @throws \Exception
     */
    public function initializeCheckoutSession(
        string $email,
        int|float $amountNaira,
        string $reference,
        array $metadata = [],
        ?string $customerName = null
    ): array {
        $defaultFrontend = config('app.frontend_url') ?: 'https://errandly-errand-web-cgokap-9d112b-169-58-145-66.sslip.io';
        $frontendUrl = rtrim($metadata['frontend_url'] ?? $defaultFrontend, '/');

        $isErrandPayment = ($metadata['type'] ?? '') === 'errand_payment';
        $errandPublicId = $metadata['errand_public_id'] ?? null;

        if ($isErrandPayment && $errandPublicId) {
            $successUrl = "{$frontendUrl}/customer/errands/{$errandPublicId}?payment=success&reference={$reference}";
            $cancelUrl = "{$frontendUrl}/customer/errands/{$errandPublicId}?payment=cancelled";
        } else {
            $successUrl = "{$frontendUrl}/customer/wallet?payment=success&reference={$reference}";
            $cancelUrl = "{$frontendUrl}/customer/wallet?payment=cancelled";
        }

        // Format amount as decimal string (e.g. "5000.00")
        $amountFormatted = number_format((float) $amountNaira, 2, '.', '');

        $customerPayload = ['email' => $email];
        if (!empty($customerName)) {
            $customerPayload['name'] = $customerName;
        }

        $payload = [
            'pricing' => [
                'currency' => 'NGN',
                'amount'   => $amountFormatted,
            ],
            'customer'    => $customerPayload,
            'success_url' => $successUrl,
            'cancel_url'  => $cancelUrl,
            'metadata'    => array_merge([
                'reference' => $reference,
            ], $metadata),
        ];

        $response = $this->post('/v1/checkout-sessions', $payload, [
            'Idempotency-Key' => 'checkout-' . $reference,
        ]);

        $checkoutUrl = $response['checkout_url'] ?? $response['data']['checkout_url'] ?? null;
        $checkoutId  = $response['checkout_id'] ?? $response['data']['checkout_id'] ?? null;

        if (!$checkoutUrl || !$checkoutId) {
            $errorMsg = $response['message'] ?? $response['error']['message'] ?? 'Unable to create checkout session';
            throw new \Exception('Bachs checkout initialization failed: ' . $errorMsg);
        }

        Log::info('Bachs checkout session created', [
            'reference'   => $reference,
            'checkout_id' => $checkoutId,
            'amount'      => $amountFormatted,
        ]);

        return [
            'authorization_url' => $checkoutUrl,
            'checkout_url'      => $checkoutUrl,
            'checkout_id'       => $checkoutId,
            'access_code'       => $checkoutId,
            'reference'         => $reference,
            'gateway'           => 'bach',
        ];
    }

    /*
    |--------------------------------------------------------------------------
    | Session & Payment Verification
    |--------------------------------------------------------------------------
    */

    /**
     * Retrieve and verify a checkout session or payment.
     *
     * @param string $checkoutId
     * @return array
     * @throws \Exception
     */
    public function verifyCheckoutSession(string $checkoutId): array
    {
        $response = $this->get("/v1/checkout-sessions/{$checkoutId}");

        $data = $response['data'] ?? $response;
        $status = strtolower($data['status'] ?? '');

        // Session status is 'completed' or 'paid'
        $isSuccess = in_array($status, ['completed', 'paid', 'succeeded']);

        // Check if there is an embedded payment record
        $payment = $data['payment'] ?? null;
        $amount = 0;
        if ($payment && isset($payment['amount'])) {
            $amount = (float) $payment['amount'];
        } elseif (isset($data['pricing']['amount'])) {
            $amount = (float) $data['pricing']['amount'];
        } elseif (isset($data['amount'])) {
            $amount = (float) $data['amount'];
        }

        $reference = $data['metadata']['reference'] ?? $checkoutId;

        return [
            'reference'        => $reference,
            'checkout_id'      => $checkoutId,
            'transaction_id'   => $payment['id'] ?? $checkoutId,
            'amount'           => (int) round($amount),
            'amount_decimal'   => number_format($amount, 2, '.', ''),
            'currency'         => $data['pricing']['currency'] ?? ($payment['currency'] ?? 'NGN'),
            'status'           => $isSuccess ? 'success' : $status,
            'paid_at'          => $data['completed_at'] ?? ($data['updated_at'] ?? now()->toIso8601String()),
            'gateway'          => 'bach',
            'gateway_response' => $data,
        ];
    }

    /*
    |--------------------------------------------------------------------------
    | Webhook Signature Validation
    |--------------------------------------------------------------------------
    */

    /**
     * Validate Bachs incoming webhook signature.
     * Follows Bachs specification:
     * - X-Bachs-Signature: HMAC-SHA256 hex digest of "{timestamp}.{raw_body}"
     * - X-Bachs-Signature-V2: t={timestamp},v1={signature}
     *
     * @param string $rawBody
     * @param string|null $signature
     * @param int|null $timestamp
     * @param string|null $signatureV2
     * @return bool
     */
    public function validateWebhookSignature(
        string $rawBody,
        ?string $signature = null,
        ?int $timestamp = null,
        ?string $signatureV2 = null
    ): bool {
        if (empty($this->webhookSecret)) {
            Log::warning('Bachs webhook secret not configured. Skipping validation in local sandbox.');
            return app()->environment('local', 'testing');
        }

        // 1. Try V2 header first if present
        if ($signatureV2) {
            $parts = [];
            foreach (explode(',', $signatureV2) as $pair) {
                $sub = explode('=', trim($pair), 2);
                if (count($sub) === 2) {
                    $parts[$sub[0]][] = $sub[1];
                }
            }

            $t = isset($parts['t'][0]) ? (int) $parts['t'][0] : null;
            $v1Signatures = $parts['v1'] ?? [];

            if ($t && !empty($v1Signatures)) {
                $expected = hash_hmac('sha256', "{$t}.{$rawBody}", $this->webhookSecret);
                foreach ($v1Signatures as $v1) {
                    if (hash_equals($expected, $v1)) {
                        return true;
                    }
                }
            }
        }

        // 2. Fall back to standard V1 header
        if ($signature && $timestamp) {
            $expected = hash_hmac('sha256', "{$timestamp}.{$rawBody}", $this->webhookSecret);
            return hash_equals($expected, $signature);
        }

        // 3. Fallback direct body signature
        if ($signature) {
            $expected = hash_hmac('sha256', $rawBody, $this->webhookSecret);
            if (hash_equals($expected, $signature)) {
                return true;
            }
        }

        return false;
    }

    /*
    |--------------------------------------------------------------------------
    | HTTP Helpers
    |--------------------------------------------------------------------------
    */

    private function post(string $endpoint, array $data = [], array $headers = []): array
    {
        $response = Http::withHeaders(array_merge([
            'Authorization' => "Bearer {$this->secretKey}",
            'Content-Type'  => 'application/json',
            'Accept'        => 'application/json',
        ], $headers))
        ->post("{$this->baseUrl}{$endpoint}", $data);

        return $this->handleResponse($response, $endpoint);
    }

    private function get(string $endpoint, array $params = []): array
    {
        $response = Http::withHeaders([
            'Authorization' => "Bearer {$this->secretKey}",
            'Accept'        => 'application/json',
        ])
        ->get("{$this->baseUrl}{$endpoint}", $params);

        return $this->handleResponse($response, $endpoint);
    }

    private function handleResponse($response, string $endpoint): array
    {
        if ($response->failed()) {
            $body = $response->json() ?? [];
            $message = $body['message'] ?? ($body['error']['message'] ?? $response->body());
            Log::error("Bachs API error at {$endpoint}", [
                'status'  => $response->status(),
                'message' => $message,
            ]);
            throw new \Exception("Bachs API Error [{$response->status()}]: {$message}");
        }

        return $response->json() ?? [];
    }
}
