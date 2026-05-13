<?php

namespace App\Services\Payment;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

class PaystackService
{
    private string $baseUrl = 'https://api.paystack.co';
    private string $secretKey;

    public function __construct()
    {
        $this->secretKey = config('services.paystack.secret_key', '');
    }

    /*
    |--------------------------------------------------------------------------
    | Transaction Initialisation
    |--------------------------------------------------------------------------
    */

    /**
     * Initialize a Paystack transaction.
     * Returns authorization_url the user is redirected to.
     */
    public function initializeTransaction(
        string $email,
        int $amountKobo,
        string $reference,
        array $metadata = [],
        array $channels = ['card', 'bank', 'ussd', 'bank_transfer']
    ): array {
        $response = $this->post('/transaction/initialize', [
            'email'      => $email,
            'amount'     => $amountKobo,
            'reference'  => $reference,
            'currency'   => 'NGN',
            'channels'   => $channels,
            'metadata'   => array_merge($metadata, [
                'cancel_action' => config('app.frontend_url') . '/customer/wallet',
            ]),
            'callback_url' => config('app.url') . '/api/webhooks/paystack/callback',
        ]);

        if (!$response['status']) {
            throw new \Exception('Paystack init failed: ' . ($response['message'] ?? 'Unknown error'));
        }

        Log::info('Paystack transaction initialized', [
            'reference' => $reference,
            'amount'    => $amountKobo,
        ]);

        return [
            'authorization_url' => $response['data']['authorization_url'],
            'access_code'       => $response['data']['access_code'],
            'reference'         => $response['data']['reference'],
        ];
    }

    /*
    |--------------------------------------------------------------------------
    | Transaction Verification
    |--------------------------------------------------------------------------
    */

    /**
     * Verify a Paystack transaction by reference.
     */
    public function verifyTransaction(string $reference): array
    {
        $response = $this->get("/transaction/verify/{$reference}");

        if (!$response['status']) {
            throw new \Exception('Paystack verification failed: ' . ($response['message'] ?? 'Unknown'));
        }

        $data = $response['data'];

        if ($data['status'] !== 'success') {
            throw new \Exception("Transaction not successful. Status: {$data['status']}");
        }

        return [
            'reference'    => $data['reference'],
            'amount'       => intdiv($data['amount'], 100),   // kobo → naira
            'amount_kobo'  => $data['amount'],
            'email'        => $data['customer']['email'],
            'status'       => $data['status'],
            'paid_at'      => $data['paid_at'],
            'channel'      => $data['channel'],
            'gateway_response' => $data['gateway_response'],
            'authorization' => $data['authorization'] ?? null,
            'metadata'     => $data['metadata'] ?? [],
        ];
    }

    /*
    |--------------------------------------------------------------------------
    | Charge Authorisation (recurring/saved cards)
    |--------------------------------------------------------------------------
    */

    /**
     * Charge a previously authorised card (saved card flow).
     */
    public function chargeAuthorization(
        string $authorizationCode,
        string $email,
        int $amountKobo,
        string $reference
    ): array {
        $response = $this->post('/transaction/charge_authorization', [
            'authorization_code' => $authorizationCode,
            'email'     => $email,
            'amount'    => $amountKobo,
            'reference' => $reference,
            'currency'  => 'NGN',
        ]);

        if (!$response['status'] || $response['data']['status'] !== 'success') {
            throw new \Exception('Charge failed: ' . ($response['message'] ?? 'Card declined'));
        }

        return $response['data'];
    }

    /*
    |--------------------------------------------------------------------------
    | Bank Account Verification
    |--------------------------------------------------------------------------
    */

    /**
     * Resolve a bank account number (name enquiry).
     */
    public function resolveAccountNumber(string $accountNumber, string $bankCode): array
    {
        $response = $this->get('/bank/resolve', [
            'account_number' => $accountNumber,
            'bank_code'      => $bankCode,
        ]);

        if (!$response['status']) {
            throw new \Exception('Could not resolve account: ' . ($response['message'] ?? 'Invalid details'));
        }

        return [
            'account_number' => $response['data']['account_number'],
            'account_name'   => $response['data']['account_name'],
            'bank_id'        => $response['data']['bank_id'],
        ];
    }

    /**
     * Get list of Nigerian banks (cached for 24 hours).
     */
    public function getBankList(): array
    {
        return Cache::remember('paystack_bank_list', 86400, function () {
            $response = $this->get('/bank', ['country' => 'nigeria', 'perPage' => 100]);
            return $response['status'] ? $response['data'] : [];
        });
    }

    /*
    |--------------------------------------------------------------------------
    | Transfers (Runner Withdrawals)
    |--------------------------------------------------------------------------
    */

    /**
     * Create or retrieve a transfer recipient for a runner's bank account.
     */
    public function createTransferRecipient(
        string $bankCode,
        string $accountNumber,
        string $accountName
    ): string {
        $response = $this->post('/transferrecipient', [
            'type'           => 'nuban',
            'name'           => $accountName,
            'account_number' => $accountNumber,
            'bank_code'      => $bankCode,
            'currency'       => 'NGN',
        ]);

        if (!$response['status']) {
            throw new \Exception('Recipient creation failed: ' . ($response['message'] ?? 'Unknown'));
        }

        return $response['data']['recipient_code'];
    }

    /**
     * Initiate a transfer to a runner (payout).
     */
    public function initiateTransfer(
        int $amountKobo,
        string $recipientCode,
        string $reference,
        string $reason = 'Errandly runner payout'
    ): array {
        $response = $this->post('/transfer', [
            'source'    => 'balance',
            'amount'    => $amountKobo,
            'recipient' => $recipientCode,
            'reason'    => $reason,
            'reference' => $reference,
            'currency'  => 'NGN',
        ]);

        if (!$response['status']) {
            throw new \Exception('Transfer initiation failed: ' . ($response['message'] ?? 'Unknown'));
        }

        return [
            'transfer_code' => $response['data']['transfer_code'],
            'reference'     => $response['data']['reference'],
            'status'        => $response['data']['status'],
        ];
    }

    /**
     * Verify transfer status.
     */
    public function verifyTransfer(string $reference): array
    {
        $response = $this->get("/transfer/verify/{$reference}");

        if (!$response['status']) {
            throw new \Exception('Transfer verification failed: ' . ($response['message'] ?? 'Unknown'));
        }

        return [
            'status'        => $response['data']['status'],
            'transfer_code' => $response['data']['transfer_code'],
            'amount'        => intdiv($response['data']['amount'], 100),
            'reference'     => $response['data']['reference'],
        ];
    }

    /*
    |--------------------------------------------------------------------------
    | Webhook Validation
    |--------------------------------------------------------------------------
    */

    /**
     * Validate that a webhook payload genuinely came from Paystack.
     */
    public function validateWebhookSignature(string $payload, string $signature): bool
    {
        $computed = hash_hmac('sha512', $payload, $this->secretKey);
        return hash_equals($computed, $signature);
    }

    /*
    |--------------------------------------------------------------------------
    | Refunds
    |--------------------------------------------------------------------------
    */

    /**
     * Issue a refund for a Paystack transaction.
     */
    public function refundTransaction(string $reference, ?int $amountKobo = null): array
    {
        $body = ['transaction' => $reference];
        if ($amountKobo !== null) {
            $body['amount'] = $amountKobo;
        }

        $response = $this->post('/refund', $body);

        if (!$response['status']) {
            throw new \Exception('Refund failed: ' . ($response['message'] ?? 'Unknown'));
        }

        return $response['data'];
    }

    /*
    |--------------------------------------------------------------------------
    | Helpers
    |--------------------------------------------------------------------------
    */

    private function post(string $endpoint, array $data): array
    {
        $response = Http::withToken($this->secretKey)
            ->acceptJson()
            ->post($this->baseUrl . $endpoint, $data);

        Log::debug('Paystack POST', [
            'endpoint' => $endpoint,
            'status'   => $response->status(),
        ]);

        return $response->json() ?? ['status' => false, 'message' => 'Empty response'];
    }

    private function get(string $endpoint, array $query = []): array
    {
        $response = Http::withToken($this->secretKey)
            ->acceptJson()
            ->get($this->baseUrl . $endpoint, $query);

        Log::debug('Paystack GET', [
            'endpoint' => $endpoint,
            'status'   => $response->status(),
        ]);

        return $response->json() ?? ['status' => false, 'message' => 'Empty response'];
    }
}
