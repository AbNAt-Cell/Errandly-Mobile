<?php

namespace App\Services\Payment;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

class FlutterwaveService
{
    private string $baseUrl = 'https://api.flutterwave.com/v3';
    private string $secretKey;
    private string $publicKey;
    private string $encryptionKey;

    public function __construct()
    {
        $this->secretKey     = config('services.flutterwave.secret_key', '');
        $this->publicKey     = config('services.flutterwave.public_key', '');
        $this->encryptionKey = config('services.flutterwave.encryption_key', '');
    }

    /*
    |--------------------------------------------------------------------------
    | Payment Initialisation
    |--------------------------------------------------------------------------
    */

    /**
     * Create a hosted payment link (redirect flow).
     */
    public function initializePayment(
        string $email,
        string $name,
        string $phone,
        int $amountNaira,
        string $reference,
        array $meta = []
    ): array {
        $response = $this->post('/payments', [
            'tx_ref'       => $reference,
            'amount'       => $amountNaira,
            'currency'     => 'NGN',
            'redirect_url' => config('app.frontend_url') . '/customer/wallet?ref=' . $reference,
            'payment_options' => 'card,banktransfer,ussd,mobilemoney',
            'customer' => [
                'email'       => $email,
                'name'        => $name,
                'phonenumber' => $phone,
            ],
            'customizations' => [
                'title'       => 'Errandly Wallet Top-Up',
                'description' => 'Fund your Errandly wallet',
                'logo'        => config('app.url') . '/logo.png',
            ],
            'meta' => $meta,
        ]);

        if ($response['status'] !== 'success') {
            throw new \Exception('Flutterwave init failed: ' . ($response['message'] ?? 'Unknown'));
        }

        return [
            'payment_link' => $response['data']['link'],
            'reference'    => $reference,
        ];
    }

    /*
    |--------------------------------------------------------------------------
    | Verification
    |--------------------------------------------------------------------------
    */

    /**
     * Verify a transaction by its Flutterwave transaction ID.
     */
    public function verifyTransaction(string $transactionId): array
    {
        $response = $this->get("/transactions/{$transactionId}/verify");

        if ($response['status'] !== 'success') {
            throw new \Exception('Flutterwave verification failed: ' . ($response['message'] ?? 'Unknown'));
        }

        $data = $response['data'];

        if ($data['status'] !== 'successful') {
            throw new \Exception("Transaction not successful. Status: {$data['status']}");
        }

        return [
            'transaction_id' => $data['id'],
            'reference'      => $data['tx_ref'],
            'amount'         => $data['amount'],
            'currency'       => $data['currency'],
            'status'         => $data['status'],
            'customer'       => $data['customer'],
            'payment_type'   => $data['payment_type'],
            'created_at'     => $data['created_at'],
        ];
    }

    /**
     * Verify by tx_ref (our reference) instead of Flutterwave ID.
     */
    public function verifyByReference(string $txRef): array
    {
        $response = $this->get('/transactions', ['tx_ref' => $txRef]);

        if ($response['status'] !== 'success' || empty($response['data'])) {
            throw new \Exception('Transaction not found for reference: ' . $txRef);
        }

        $data = $response['data'][0];

        if ($data['status'] !== 'successful') {
            throw new \Exception("Transaction not successful. Status: {$data['status']}");
        }

        return [
            'transaction_id' => $data['id'],
            'reference'      => $data['tx_ref'],
            'amount'         => $data['amount'],
            'status'         => $data['status'],
            'customer'       => $data['customer'],
        ];
    }

    /*
    |--------------------------------------------------------------------------
    | Bank Transfers (Nigerian Payouts)
    |--------------------------------------------------------------------------
    */

    /**
     * Get list of Nigerian banks (cached).
     */
    public function getBankList(): array
    {
        return Cache::remember('flutterwave_bank_list', 86400, function () {
            $response = $this->get('/banks/NG');
            return $response['status'] === 'success' ? $response['data'] : [];
        });
    }

    /**
     * Verify a bank account number (name enquiry).
     */
    public function resolveAccountNumber(string $accountNumber, string $bankCode): array
    {
        $response = $this->post('/accounts/resolve', [
            'account_number' => $accountNumber,
            'account_bank'   => $bankCode,
        ]);

        if ($response['status'] !== 'success') {
            throw new \Exception('Could not resolve account: ' . ($response['message'] ?? 'Invalid details'));
        }

        return [
            'account_number' => $response['data']['account_number'],
            'account_name'   => $response['data']['account_name'],
        ];
    }

    /**
     * Initiate a transfer to a runner (payout).
     */
    public function initiateTransfer(
        int $amountNaira,
        string $accountBank,
        string $accountNumber,
        string $accountName,
        string $reference,
        string $narration = 'Errandly runner payout'
    ): array {
        $response = $this->post('/transfers', [
            'account_bank'   => $accountBank,
            'account_number' => $accountNumber,
            'amount'         => $amountNaira,
            'narration'      => $narration,
            'currency'       => 'NGN',
            'reference'      => $reference,
            'debit_currency' => 'NGN',
            'meta'           => [['sender_id' => 'errandly', 'account_name' => $accountName]],
        ]);

        if ($response['status'] !== 'success') {
            throw new \Exception('Transfer failed: ' . ($response['message'] ?? 'Unknown'));
        }

        return [
            'id'        => $response['data']['id'],
            'reference' => $response['data']['reference'],
            'status'    => $response['data']['status'],
        ];
    }

    /**
     * Verify a transfer status by reference.
     */
    public function verifyTransfer(string $reference): array
    {
        $response = $this->get('/transfers', ['reference' => $reference]);

        if ($response['status'] !== 'success' || empty($response['data'])) {
            throw new \Exception('Transfer not found: ' . $reference);
        }

        $data = $response['data'][0];

        return [
            'id'        => $data['id'],
            'status'    => $data['status'],
            'amount'    => $data['amount'],
            'reference' => $data['reference'],
        ];
    }

    /*
    |--------------------------------------------------------------------------
    | Webhook Validation
    |--------------------------------------------------------------------------
    */

    /**
     * Validate that the webhook came from Flutterwave using the hash.
     */
    public function validateWebhookSignature(string $payload, string $hash): bool
    {
        $secretHash = config('services.flutterwave.webhook_secret', '');
        return hash_equals($secretHash, $hash);
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

        Log::debug('Flutterwave POST', ['endpoint' => $endpoint, 'status' => $response->status()]);

        return $response->json() ?? ['status' => 'error', 'message' => 'Empty response'];
    }

    private function get(string $endpoint, array $query = []): array
    {
        $response = Http::withToken($this->secretKey)
            ->acceptJson()
            ->get($this->baseUrl . $endpoint, $query);

        Log::debug('Flutterwave GET', ['endpoint' => $endpoint, 'status' => $response->status()]);

        return $response->json() ?? ['status' => 'error', 'message' => 'Empty response'];
    }
}
