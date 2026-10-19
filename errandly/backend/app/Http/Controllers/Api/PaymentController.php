<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\PaymentService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    public function __construct(private PaymentService $paymentService) {}

    /*
    |--------------------------------------------------------------------------
    | Wallet Funding
    |--------------------------------------------------------------------------
    */

    /**
     * POST /api/payments/initialize
     * Initialise a wallet top-up with a chosen gateway.
     * Returns the gateway's redirect URL or client_secret.
     */
    public function initialize(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'amount'  => 'required|integer|min:100',
            'gateway' => 'sometimes|in:paystack,flutterwave,stripe',
            'channels' => 'sometimes|array',
            'channels.*' => 'in:card,bank,ussd,bank_transfer',
        ]);

        $origin = $request->header('origin') ?: $request->header('referer');
        $frontendUrl = null;
        if ($origin) {
            $parsed = parse_url($origin);
            if (isset($parsed['scheme']) && isset($parsed['host'])) {
                $port = isset($parsed['port']) ? ":{$parsed['port']}" : '';
                $frontendUrl = "{$parsed['scheme']}://{$parsed['host']}{$port}";
            }
        }

        try {
            $result = $this->paymentService->initializeWalletFunding(
                user:    $request->user(),
                amountNaira: (int) $validated['amount'],
                gateway: $validated['gateway'] ?? PaymentService::DEFAULT_WALLET_GATEWAY,
                options: [
                    'channels'     => $validated['channels'] ?? null,
                    'frontend_url' => $frontendUrl ?? config('app.frontend_url', 'https://errandly-web.vercel.app'),
                ],
            );

            return response()->json($result, 201);
        } catch (\Exception $e) {
            Log::warning('Payment initialization failed', [
                'user_id' => $request->user()->id,
                'error'   => $e->getMessage(),
            ]);
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * POST /api/payments/verify
     * Verify a completed payment and credit the user's wallet.
     */
    public function verify(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'reference'            => 'required|string',
            'gateway'              => 'sometimes|in:paystack,flutterwave,stripe',
            'gateway_transaction_id' => 'sometimes|string', // Flutterwave / Stripe ID
        ]);

        try {
            $result = $this->paymentService->verifyAndCreditWallet(
                user:                 $request->user(),
                reference:            $validated['reference'],
                gateway:              $validated['gateway'] ?? PaymentService::DEFAULT_WALLET_GATEWAY,
                gatewayTransactionId: $validated['gateway_transaction_id'] ?? null,
            );

            return response()->json($result);
        } catch (\Exception $e) {
            Log::warning('Payment verification failed', [
                'user_id'   => $request->user()->id,
                'reference' => $validated['reference'],
                'error'     => $e->getMessage(),
            ]);
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /*
    |--------------------------------------------------------------------------
    | Runner Withdrawals
    |--------------------------------------------------------------------------
    */

    /**
     * POST /api/runner/payments/withdraw
     * Initiate a bank transfer payout to the authenticated runner.
     */
    public function initiateWithdrawal(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'amount'  => 'required|integer|min:1000',
            'gateway' => 'sometimes|in:paystack,flutterwave',
        ]);

        try {
            $result = $this->paymentService->processRunnerWithdrawal(
                runner:      $request->user(),
                amountNaira: (int) $validated['amount'],
                gateway:     $validated['gateway'] ?? PaymentService::DEFAULT_PAYOUT_GATEWAY,
            );

            return response()->json($result, 201);
        } catch (\Exception $e) {
            Log::warning('Withdrawal failed', [
                'runner_id' => $request->user()->id,
                'error'     => $e->getMessage(),
            ]);
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /*
    |--------------------------------------------------------------------------
    | Bank Account Utilities
    |--------------------------------------------------------------------------
    */

    /**
     * GET /api/payments/banks?gateway=paystack
     * Returns list of banks for the given gateway (cached).
     */
    public function bankList(Request $request): JsonResponse
    {
        $gateway = $request->query('gateway', PaymentService::DEFAULT_WALLET_GATEWAY);

        try {
            $banks = $this->paymentService->getBankList($gateway);
            return response()->json(['data' => $banks]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * POST /api/payments/verify-account
     * Name-enquiry for a runner's bank account before saving it.
     */
    public function verifyAccount(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'account_number' => 'required|string|size:10',
            'bank_code'      => 'required|string',
            'gateway'        => 'sometimes|in:paystack,flutterwave',
        ]);

        try {
            $result = $this->paymentService->verifyBankAccount(
                accountNumber: $validated['account_number'],
                bankCode:      $validated['bank_code'],
                gateway:       $validated['gateway'] ?? PaymentService::DEFAULT_WALLET_GATEWAY,
            );

            return response()->json($result);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    /**
     * GET /api/payments/history
     * Paginated payment transaction history for the authenticated user.
     */
    public function history(Request $request): JsonResponse
    {
        $transactions = $request->user()
            ->paymentTransactions()
            ->latest()
            ->paginate(20);

        return response()->json($transactions);
    }

    /*
    |--------------------------------------------------------------------------
    | Webhooks (unauthenticated — verified by signature)
    |--------------------------------------------------------------------------
    */

    /**
     * POST /api/webhooks/paystack
     */
    public function paystackWebhook(Request $request): JsonResponse
    {
        $payload   = $request->getContent();
        $signature = $request->header('x-paystack-signature', '');

        if (!app(\App\Services\Payment\PaystackService::class)->validateWebhookSignature($payload, $signature)) {
            Log::warning('Invalid Paystack webhook signature');
            return response()->json(['message' => 'Invalid signature'], 401);
        }

        try {
            $this->paymentService->handleWebhook(PaymentService::GATEWAY_PAYSTACK, $request->all());
        } catch (\Exception $e) {
            Log::error('Paystack webhook processing error', ['error' => $e->getMessage()]);
        }

        return response()->json(['received' => true]);
    }

    /**
     * GET /api/webhooks/paystack/callback
     * Paystack redirects the customer browser here after transaction completion.
     */
    public function paystackCallback(Request $request)
    {
        $reference = $request->query('reference') ?? $request->query('trxref');
        $errand = null;
        $isErrandPayment = false;

        if ($reference) {
            try {
                $tx = \App\Models\PaymentTransaction::where('reference', $reference)->first();
                if ($tx) {
                    if ($tx->type === \App\Models\PaymentTransaction::TYPE_ERRAND_PAYMENT) {
                        $isErrandPayment = true;
                        $errandService = app(\App\Services\ErrandService::class);
                        $errand = $errandService->activatePaidErrand(
                            $tx->metadata['errand_id'] ?? $tx->metadata['errand_public_id'],
                            $reference
                        );
                    } elseif ($tx->status !== \App\Models\PaymentTransaction::STATUS_SUCCESS) {
                        $this->paymentService->verifyAndCreditWallet(
                            user: $tx->user,
                            reference: $reference,
                            gateway: PaymentService::GATEWAY_PAYSTACK,
                        );
                    }
                }
            } catch (\Exception $e) {
                Log::warning('Paystack callback verify notice', ['error' => $e->getMessage()]);
            }
        }

        $defaultFrontend = config('app.frontend_url') ?: 'https://errandly-errand-web-cgokap-9d112b-169-58-145-66.sslip.io';
        $frontendUrl = rtrim($tx?->metadata['frontend_url'] ?? $defaultFrontend, '/');

        if ($isErrandPayment) {
            $errandPublicId = $errand?->public_id ?? ($tx?->metadata['errand_public_id'] ?? '');
            $targetUrl = "{$frontendUrl}/customer/errands/{$errandPublicId}?payment=success" . ($reference ? "&reference={$reference}" : "");
            $headline = "Payment Successful!";
            $subtext = "Your errand has been paid and broadcast to nearby runners. Redirecting...";
            $btnText = "View Errand";
        } else {
            $targetUrl = "{$frontendUrl}/customer/wallet?payment=success" . ($reference ? "&reference={$reference}" : "");
            $headline = "Payment Successful!";
            $subtext = "Your wallet has been credited. Redirecting you back to Errandly...";
            $btnText = "Return to Wallet";
        }

        return response(<<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{$headline} - Errandly</title>
    <meta http-equiv="refresh" content="2;url={$targetUrl}">
    <script>
        setTimeout(function() {
            window.location.href = "{$targetUrl}";
        }, 1200);
    </script>
    <style>
        body { font-family: system-ui, -apple-system, sans-serif; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; background: #f9fafb; }
        .card { background: white; padding: 2.5rem; border-radius: 1.25rem; box-shadow: 0 10px 25px rgba(0,0,0,0.06); text-align: center; max-width: 420px; width: 90%; }
        .icon { width: 56px; height: 56px; background: #dcfce7; color: #16a34a; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center; font-size: 28px; margin: 0 auto 1rem; }
        h2 { margin: 0 0 0.5rem; color: #111827; font-size: 1.5rem; }
        p { color: #6b7280; font-size: 0.95rem; margin-bottom: 1.5rem; }
        .btn { display: inline-block; background: #f97316; color: white; padding: 0.75rem 1.75rem; border-radius: 0.75rem; text-decoration: none; font-weight: 600; font-size: 0.95rem; }
    </style>
</head>
<body>
    <div class="card">
        <div class="icon">✓</div>
        <h2>{$headline}</h2>
        <p>{$subtext}</p>
        <a class="btn" href="{$targetUrl}">{$btnText}</a>
    </div>
</body>
</html>
HTML
        , 200, ['Content-Type' => 'text/html']);
    }

    /**
     * GET /api/webhooks/flutterwave/callback
     */
    public function flutterwaveCallback(Request $request)
    {
        $reference = $request->query('tx_ref');
        $transactionId = $request->query('transaction_id');
        $tx = null;

        if ($reference) {
            try {
                $tx = \App\Models\PaymentTransaction::where('reference', $reference)->first();
                if ($tx && $tx->status !== \App\Models\PaymentTransaction::STATUS_SUCCESS) {
                    $this->paymentService->verifyAndCreditWallet(
                        user: $tx->user,
                        reference: $reference,
                        gateway: PaymentService::GATEWAY_FLUTTERWAVE,
                        gatewayTransactionId: $transactionId,
                    );
                }
            } catch (\Exception $e) {
                Log::warning('Flutterwave callback verify notice', ['error' => $e->getMessage()]);
            }
        }

        $frontendUrl = $tx?->metadata['frontend_url'] 
            ?? config('app.frontend_url') 
            ?? 'https://errandly-web.vercel.app';
        
        $frontendUrl = rtrim($frontendUrl, '/');
        if (empty($frontendUrl) || str_contains($frontendUrl, 'sslip.io') || str_contains($frontendUrl, 'localhost:8000')) {
            $frontendUrl = 'https://errandly-web.vercel.app';
        }

        $targetUrl = "{$frontendUrl}/customer/wallet?payment=success" . ($reference ? "&reference={$reference}" : "");

        return redirect($targetUrl);
    }

    /**
     * POST /api/webhooks/flutterwave
     */
    public function flutterwaveWebhook(Request $request): JsonResponse
    {
        $hash = $request->header('verif-hash', '');

        if (!app(\App\Services\Payment\FlutterwaveService::class)->validateWebhookSignature($request->getContent(), $hash)) {
            Log::warning('Invalid Flutterwave webhook signature');
            return response()->json(['message' => 'Invalid signature'], 401);
        }

        try {
            $this->paymentService->handleWebhook(PaymentService::GATEWAY_FLUTTERWAVE, $request->all());
        } catch (\Exception $e) {
            Log::error('Flutterwave webhook processing error', ['error' => $e->getMessage()]);
        }

        return response()->json(['received' => true]);
    }

    /**
     * POST /api/webhooks/stripe
     */
    public function stripeWebhook(Request $request): JsonResponse
    {
        $payload   = $request->getContent();
        $sigHeader = $request->header('Stripe-Signature', '');

        try {
            $event = app(\App\Services\Payment\StripeService::class)->validateWebhook($payload, $sigHeader);
            $this->paymentService->handleWebhook(
                PaymentService::GATEWAY_STRIPE,
                ['type' => $event->type, 'data' => $event->data->toArray()]
            );
        } catch (\Exception $e) {
            Log::error('Stripe webhook error', ['error' => $e->getMessage()]);
            return response()->json(['message' => $e->getMessage()], 400);
        }

        return response()->json(['received' => true]);
    }
}
