<?php

namespace App\Services;

use App\Models\User;
use App\Models\PaymentTransaction;
use App\Models\RunnerProfile;
use App\Services\Payment\PaystackService;
use App\Services\Payment\FlutterwaveService;
use App\Services\Payment\StripeService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class PaymentService
{
    /**
     * Supported gateways. Paystack is the primary for NGN.
     */
    const GATEWAY_PAYSTACK     = 'paystack';
    const GATEWAY_FLUTTERWAVE  = 'flutterwave';
    const GATEWAY_STRIPE       = 'stripe';

    const DEFAULT_WALLET_GATEWAY   = self::GATEWAY_PAYSTACK;
    const DEFAULT_PAYOUT_GATEWAY   = self::GATEWAY_PAYSTACK;

    public function __construct(
        private PaystackService    $paystack,
        private FlutterwaveService $flutterwave,
        private StripeService      $stripe,
        private WalletService      $walletService,
    ) {}

    /*
    |--------------------------------------------------------------------------
    | Wallet Funding — Initialise
    |--------------------------------------------------------------------------
    */

    /**
     * Start a wallet funding flow. Returns payment details the client uses
     * to redirect the user to the payment gateway.
     */
    public function initializeWalletFunding(
        User $user,
        int $amountNaira,
        string $gateway = self::DEFAULT_WALLET_GATEWAY,
        array $options = []
    ): array {
        if ($amountNaira < config('errandly.min_errand_amount', 500)) {
            throw new \Exception("Minimum top-up amount is ₦" . config('errandly.min_errand_amount', 500));
        }

        $reference = $this->generateReference('FUND', $user->id);
        $amountKobo = $amountNaira * 100;

        $record = PaymentTransaction::create([
            'user_id'   => $user->id,
            'type'      => PaymentTransaction::TYPE_WALLET_FUNDING,
            'gateway'   => $gateway,
            'reference' => $reference,
            'amount'    => $amountNaira,
            'currency'  => 'NGN',
            'status'    => PaymentTransaction::STATUS_PENDING,
            'metadata'  => $options,
        ]);

        $gatewayData = match ($gateway) {
            self::GATEWAY_PAYSTACK => $this->paystack->initializeTransaction(
                email: $user->email,
                amountKobo: $amountKobo,
                reference: $reference,
                metadata: ['user_id' => $user->id, 'type' => 'wallet_funding'],
                channels: $options['channels'] ?? ['card', 'bank', 'ussd', 'bank_transfer'],
            ),

            self::GATEWAY_FLUTTERWAVE => $this->flutterwave->initializePayment(
                email: $user->email,
                name: $user->full_name,
                phone: $user->phone,
                amountNaira: $amountNaira,
                reference: $reference,
                meta: ['user_id' => $user->id, 'type' => 'wallet_funding'],
            ),

            self::GATEWAY_STRIPE => $this->stripe->createPaymentIntent(
                amountKobo: $amountKobo,
                metadata: ['user_id' => $user->id, 'reference' => $reference, 'type' => 'wallet_funding'],
            ),

            default => throw new \Exception("Unsupported payment gateway: {$gateway}"),
        };

        return array_merge($gatewayData, [
            'transaction_id' => $record->id,
            'reference'      => $reference,
            'gateway'        => $gateway,
            'amount'         => $amountNaira,
            'currency'       => 'NGN',
        ]);
    }

    /*
    |--------------------------------------------------------------------------
    | Wallet Funding — Verify
    |--------------------------------------------------------------------------
    */

    /**
     * Verify a completed payment and credit the user's wallet.
     * Idempotent — safe to call multiple times for the same reference.
     */
    public function verifyAndCreditWallet(
        User $user,
        string $reference,
        string $gateway = self::DEFAULT_WALLET_GATEWAY,
        ?string $gatewayTransactionId = null
    ): array {
        return DB::transaction(function () use ($user, $reference, $gateway, $gatewayTransactionId) {
            // Find our record
            $record = PaymentTransaction::where('reference', $reference)
                ->where('user_id', $user->id)
                ->lockForUpdate()
                ->firstOrFail();

            // Idempotency guard
            if ($record->status === PaymentTransaction::STATUS_SUCCESS) {
                return [
                    'message'     => 'Already verified.',
                    'amount'      => $record->amount,
                    'new_balance' => $user->wallet->fresh()->balance,
                ];
            }

            // Verify with gateway
            $gatewayData = match ($gateway) {
                self::GATEWAY_PAYSTACK => $this->paystack->verifyTransaction($reference),
                self::GATEWAY_FLUTTERWAVE => $gatewayTransactionId
                    ? $this->flutterwave->verifyTransaction($gatewayTransactionId)
                    : $this->flutterwave->verifyByReference($reference),
                self::GATEWAY_STRIPE => $this->stripe->verifyPaymentIntent($gatewayTransactionId ?? $reference),
                default => throw new \Exception("Unsupported gateway: {$gateway}"),
            };

            // Amount sanity check (within 1 naira tolerance for kobo rounding)
            $verifiedAmount = (int) $gatewayData['amount'];
            if (abs($verifiedAmount - $record->amount) > 1) {
                Log::warning('Payment amount mismatch', [
                    'expected' => $record->amount,
                    'received' => $verifiedAmount,
                    'reference' => $reference,
                ]);
                throw new \Exception('Payment amount mismatch. Please contact support.');
            }

            // Credit wallet
            $walletTx = $this->walletService->fundWallet($user, $verifiedAmount, $reference);

            // Update our record
            $record->update([
                'status'               => PaymentTransaction::STATUS_SUCCESS,
                'gateway_reference'    => $gatewayTransactionId ?? ($gatewayData['transaction_id'] ?? null),
                'gateway_response'     => $gatewayData,
                'processed_at'         => now(),
            ]);

            Log::info('Wallet funded successfully', [
                'user_id'    => $user->id,
                'amount'     => $verifiedAmount,
                'reference'  => $reference,
                'gateway'    => $gateway,
            ]);

            return [
                'message'        => 'Payment verified. Wallet funded.',
                'amount'         => $verifiedAmount,
                'new_balance'    => $user->wallet->fresh()->balance,
                'transaction_id' => $walletTx->id,
            ];
        });
    }

    /*
    |--------------------------------------------------------------------------
    | Runner Payouts (Withdrawals)
    |--------------------------------------------------------------------------
    */

    /**
     * Process a runner withdrawal to their bank account.
     */
    public function processRunnerWithdrawal(
        User $runner,
        int $amountNaira,
        string $gateway = self::DEFAULT_PAYOUT_GATEWAY
    ): array {
        $profile = $runner->runnerProfile;

        if (!$profile->bank_account_number || !$profile->bank_code) {
            throw new \Exception('Runner has no bank account on file. Please add bank details first.');
        }

        $reference = $this->generateReference('PAYOUT', $runner->id);

        return DB::transaction(function () use ($runner, $profile, $amountNaira, $gateway, $reference) {
            // Deduct from wallet first (handled by WalletService)
            $walletTx = $this->walletService->requestWithdrawal($runner, $amountNaira);

            // Record the payout attempt
            $record = PaymentTransaction::create([
                'user_id'   => $runner->id,
                'type'      => PaymentTransaction::TYPE_PAYOUT,
                'gateway'   => $gateway,
                'reference' => $reference,
                'amount'    => $amountNaira,
                'currency'  => 'NGN',
                'status'    => PaymentTransaction::STATUS_PENDING,
                'metadata'  => [
                    'bank_name'      => $profile->bank_name,
                    'account_number' => $profile->bank_account_number,
                    'account_name'   => $profile->bank_account_name,
                ],
            ]);

            // Initiate transfer via gateway
            $transferData = match ($gateway) {
                self::GATEWAY_PAYSTACK => $this->processPaystackPayout($profile, $amountNaira * 100, $reference),
                self::GATEWAY_FLUTTERWAVE => $this->processFlutterwavePayout($profile, $amountNaira, $reference),
                default => throw new \Exception("Unsupported payout gateway: {$gateway}"),
            };

            $record->update([
                'gateway_reference' => $transferData['reference'] ?? $transferData['id'] ?? null,
                'gateway_response'  => $transferData,
                'status'            => PaymentTransaction::STATUS_PROCESSING,
            ]);

            Log::info('Runner withdrawal initiated', [
                'runner_id'  => $runner->id,
                'amount'     => $amountNaira,
                'gateway'    => $gateway,
                'reference'  => $reference,
            ]);

            return [
                'message'        => 'Withdrawal initiated. Funds will be in your account within 1 business day.',
                'reference'      => $reference,
                'amount'         => $amountNaira,
                'gateway'        => $gateway,
                'status'         => 'processing',
                'transaction_id' => $record->id,
            ];
        });
    }

    /*
    |--------------------------------------------------------------------------
    | Bank Account Verification
    |--------------------------------------------------------------------------
    */

    /**
     * Verify a bank account number and return the account name.
     * Used before saving runner bank details.
     */
    public function verifyBankAccount(
        string $accountNumber,
        string $bankCode,
        string $gateway = self::DEFAULT_WALLET_GATEWAY
    ): array {
        return match ($gateway) {
            self::GATEWAY_PAYSTACK => $this->paystack->resolveAccountNumber($accountNumber, $bankCode),
            self::GATEWAY_FLUTTERWAVE => $this->flutterwave->resolveAccountNumber($accountNumber, $bankCode),
            default => throw new \Exception("Bank verification not supported for gateway: {$gateway}"),
        };
    }

    /**
     * Get the list of banks supported by a gateway.
     */
    public function getBankList(string $gateway = self::DEFAULT_WALLET_GATEWAY): array
    {
        return match ($gateway) {
            self::GATEWAY_PAYSTACK => $this->paystack->getBankList(),
            self::GATEWAY_FLUTTERWAVE => $this->flutterwave->getBankList(),
            default => $this->paystack->getBankList(),
        };
    }

    /*
    |--------------------------------------------------------------------------
    | Webhook Processing
    |--------------------------------------------------------------------------
    */

    /**
     * Handle and verify an incoming webhook from any gateway.
     * Called by the controller after signature validation.
     */
    public function handleWebhook(string $gateway, array $payload): void
    {
        match ($gateway) {
            self::GATEWAY_PAYSTACK => $this->handlePaystackWebhook($payload),
            self::GATEWAY_FLUTTERWAVE => $this->handleFlutterwaveWebhook($payload),
            self::GATEWAY_STRIPE => $this->handleStripeWebhook($payload),
            default => Log::warning('Unknown webhook gateway', ['gateway' => $gateway]),
        };
    }

    /*
    |--------------------------------------------------------------------------
    | Gateway Refunds
    |--------------------------------------------------------------------------
    */

    /**
     * Refund a payment through the originating gateway.
     */
    public function refundPayment(string $reference, ?int $amountNaira = null): void
    {
        $record = PaymentTransaction::where('reference', $reference)->firstOrFail();

        $amountKobo = $amountNaira ? $amountNaira * 100 : null;

        match ($record->gateway) {
            self::GATEWAY_PAYSTACK => $this->paystack->refundTransaction($reference, $amountKobo),
            self::GATEWAY_STRIPE   => $this->stripe->refundPayment(
                $record->gateway_reference ?? $reference,
                $amountKobo
            ),
            default => throw new \Exception("Refund not supported for gateway: {$record->gateway}"),
        };

        $record->update(['status' => PaymentTransaction::STATUS_REFUNDED]);
    }

    /*
    |--------------------------------------------------------------------------
    | Private: Payout Helpers
    |--------------------------------------------------------------------------
    */

    private function processPaystackPayout(RunnerProfile $profile, int $amountKobo, string $reference): array
    {
        $recipientCode = $this->paystack->createTransferRecipient(
            bankCode: $profile->bank_code,
            accountNumber: $profile->bank_account_number,
            accountName: $profile->bank_account_name,
        );

        return $this->paystack->initiateTransfer(
            amountKobo: $amountKobo,
            recipientCode: $recipientCode,
            reference: $reference,
            reason: 'Errandly runner payout',
        );
    }

    private function processFlutterwavePayout(RunnerProfile $profile, int $amountNaira, string $reference): array
    {
        return $this->flutterwave->initiateTransfer(
            amountNaira: $amountNaira,
            accountBank: $profile->bank_code,
            accountNumber: $profile->bank_account_number,
            accountName: $profile->bank_account_name,
            reference: $reference,
        );
    }

    /*
    |--------------------------------------------------------------------------
    | Private: Webhook Handlers
    |--------------------------------------------------------------------------
    */

    private function handlePaystackWebhook(array $payload): void
    {
        $event = $payload['event'] ?? '';
        $data  = $payload['data'] ?? [];

        Log::info('Paystack webhook', ['event' => $event, 'ref' => $data['reference'] ?? null]);

        match ($event) {
            'charge.success' => $this->onPaystackChargeSuccess($data),
            'transfer.success' => $this->onPaystackTransferSuccess($data),
            'transfer.failed'  => $this->onPaystackTransferFailed($data),
            'transfer.reversed' => $this->onPaystackTransferReversed($data),
            default => null,
        };
    }

    private function handleFlutterwaveWebhook(array $payload): void
    {
        $event = $payload['event'] ?? '';
        $data  = $payload['data'] ?? [];

        Log::info('Flutterwave webhook', ['event' => $event]);

        match ($event) {
            'charge.completed'       => $this->onFlutterwaveChargeCompleted($data),
            'transfer.completed'     => $this->onFlutterwaveTransferCompleted($data),
            default => null,
        };
    }

    private function handleStripeWebhook(array $payload): void
    {
        $event = $payload['type'] ?? '';
        $data  = $payload['data']['object'] ?? [];

        Log::info('Stripe webhook', ['event' => $event]);

        match ($event) {
            'payment_intent.succeeded' => $this->onStripePaymentSucceeded($data),
            'payment_intent.payment_failed' => $this->onStripePaymentFailed($data),
            default => null,
        };
    }

    private function onPaystackChargeSuccess(array $data): void
    {
        $reference = $data['reference'] ?? null;
        if (!$reference) return;

        $record = PaymentTransaction::where('reference', $reference)
            ->where('status', PaymentTransaction::STATUS_PENDING)
            ->first();

        if (!$record) return;

        $user = \App\Models\User::find($record->user_id);
        if (!$user) return;

        $amountNaira = intdiv((int) $data['amount'], 100);
        $this->walletService->fundWallet($user, $amountNaira, $reference);

        $record->update([
            'status'            => PaymentTransaction::STATUS_SUCCESS,
            'gateway_response'  => $data,
            'processed_at'      => now(),
        ]);
    }

    private function onPaystackTransferSuccess(array $data): void
    {
        PaymentTransaction::where('reference', $data['reference'] ?? '')
            ->update(['status' => PaymentTransaction::STATUS_SUCCESS, 'processed_at' => now()]);
    }

    private function onPaystackTransferFailed(array $data): void
    {
        $reference = $data['reference'] ?? '';
        $record = PaymentTransaction::where('reference', $reference)->first();
        if (!$record) return;

        $record->update(['status' => PaymentTransaction::STATUS_FAILED]);

        // Re-credit the runner's wallet since the transfer failed
        $runner = \App\Models\User::find($record->user_id);
        if ($runner) {
            $runner->wallet()->increment('balance', $record->amount);
            $runner->wallet()->decrement('pending_withdrawal', $record->amount);
        }

        Log::warning('Paystack transfer failed — wallet re-credited', ['reference' => $reference]);
    }

    private function onPaystackTransferReversed(array $data): void
    {
        $this->onPaystackTransferFailed($data); // same rollback logic
    }

    private function onFlutterwaveChargeCompleted(array $data): void
    {
        if ($data['status'] !== 'successful') return;

        $reference = $data['tx_ref'] ?? null;
        if (!$reference) return;

        $record = PaymentTransaction::where('reference', $reference)
            ->where('status', PaymentTransaction::STATUS_PENDING)
            ->first();

        if (!$record) return;

        $user = \App\Models\User::find($record->user_id);
        if ($user) {
            $this->walletService->fundWallet($user, (int) $data['amount'], $reference);
            $record->update([
                'status'           => PaymentTransaction::STATUS_SUCCESS,
                'gateway_response' => $data,
                'processed_at'     => now(),
            ]);
        }
    }

    private function onFlutterwaveTransferCompleted(array $data): void
    {
        if ($data['status'] === 'SUCCESSFUL') {
            PaymentTransaction::where('reference', $data['reference'] ?? '')
                ->update(['status' => PaymentTransaction::STATUS_SUCCESS, 'processed_at' => now()]);
        } else {
            $this->onPaystackTransferFailed(['reference' => $data['reference'] ?? '']);
        }
    }

    private function onStripePaymentSucceeded(array $data): void
    {
        $meta      = $data['metadata'] ?? [];
        $reference = $meta['reference'] ?? null;
        if (!$reference) return;

        $record = PaymentTransaction::where('reference', $reference)
            ->where('status', PaymentTransaction::STATUS_PENDING)
            ->first();

        if (!$record) return;

        $user = \App\Models\User::find($record->user_id ?? ($meta['user_id'] ?? null));
        if ($user) {
            $amountNaira = intdiv((int) $data['amount_received'], 100);
            $this->walletService->fundWallet($user, $amountNaira, $reference);
            $record->update([
                'status'           => PaymentTransaction::STATUS_SUCCESS,
                'gateway_response' => $data,
                'processed_at'     => now(),
            ]);
        }
    }

    private function onStripePaymentFailed(array $data): void
    {
        $meta      = $data['metadata'] ?? [];
        $reference = $meta['reference'] ?? null;
        if ($reference) {
            PaymentTransaction::where('reference', $reference)
                ->update(['status' => PaymentTransaction::STATUS_FAILED]);
        }
    }

    /*
    |--------------------------------------------------------------------------
    | Helpers
    |--------------------------------------------------------------------------
    */

    private function generateReference(string $prefix, int $userId): string
    {
        return strtoupper($prefix) . '_' . $userId . '_' . now()->format('YmdHis') . '_' . strtoupper(substr(uniqid(), -6));
    }
}
