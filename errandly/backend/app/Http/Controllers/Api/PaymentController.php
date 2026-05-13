<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\WalletService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    public function __construct(private WalletService $walletService) {}

    public function initialize(Request $request): JsonResponse
    {
        $request->validate([
            'amount' => 'required|integer|min:100',
            'payment_method' => 'required|in:card,bank_transfer,ussd,paystack,stripe',
        ]);

        // Initialize with Paystack (primary payment processor for Nigeria)
        $reference = 'ERR_' . strtoupper(uniqid()) . '_' . $request->user()->id;

        // In production: call Paystack API to initialize transaction
        // $paystackResponse = Http::withToken(config('services.paystack.secret'))
        //     ->post('https://api.paystack.co/transaction/initialize', [
        //         'email' => $request->user()->email,
        //         'amount' => $request->amount * 100, // kobo
        //         'reference' => $reference,
        //         'callback_url' => config('app.url') . '/payment/callback',
        //     ]);

        return response()->json([
            'message' => 'Payment initialized.',
            'reference' => $reference,
            'amount' => $request->amount,
            'currency' => 'NGN',
            'authorization_url' => "https://checkout.paystack.com/{$reference}",
        ]);
    }

    public function verify(Request $request): JsonResponse
    {
        $request->validate(['reference' => 'required|string']);

        // In production: verify with Paystack
        // $response = Http::withToken(config('services.paystack.secret'))
        //     ->get("https://api.paystack.co/transaction/verify/{$request->reference}");

        try {
            $transaction = $this->walletService->fundWallet(
                $request->user(),
                $request->amount ?? 5000, // use actual amount from gateway
                $request->reference
            );

            return response()->json([
                'message' => 'Payment verified and wallet funded.',
                'transaction' => $transaction,
                'new_balance' => $request->user()->wallet->fresh()->balance,
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function stripeWebhook(Request $request): JsonResponse
    {
        $payload = $request->getContent();
        $sigHeader = $request->header('Stripe-Signature');
        $secret = config('services.stripe.webhook_secret');

        try {
            // $event = \Stripe\Webhook::constructEvent($payload, $sigHeader, $secret);

            // Handle event
            Log::info('Stripe webhook received', ['type' => $request->input('type')]);

            return response()->json(['received' => true]);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Webhook error'], 400);
        }
    }

    public function paystackWebhook(Request $request): JsonResponse
    {
        $hash = hash_hmac('sha512', $request->getContent(), config('services.paystack.secret'));

        if ($hash !== $request->header('x-paystack-signature')) {
            return response()->json(['message' => 'Invalid signature'], 400);
        }

        $event = $request->input('event');
        $data = $request->input('data');

        Log::info('Paystack webhook', ['event' => $event, 'reference' => $data['reference'] ?? null]);

        if ($event === 'charge.success') {
            // Find user by email or reference metadata and fund wallet
            $user = \App\Models\User::where('email', $data['customer']['email'])->first();
            if ($user) {
                $amount = intval($data['amount'] / 100); // kobo to naira
                $this->walletService->fundWallet($user, $amount, $data['reference']);
            }
        }

        return response()->json(['received' => true]);
    }
}
