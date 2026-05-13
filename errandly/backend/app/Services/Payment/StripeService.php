<?php

namespace App\Services\Payment;

use Illuminate\Support\Facades\Log;
use Stripe\StripeClient;
use Stripe\Webhook;
use Stripe\Exception\SignatureVerificationException;

class StripeService
{
    private StripeClient $stripe;

    public function __construct()
    {
        $this->stripe = new StripeClient(config('services.stripe.secret', ''));
    }

    /*
    |--------------------------------------------------------------------------
    | Payment Intents
    |--------------------------------------------------------------------------
    */

    /**
     * Create a Stripe PaymentIntent.
     * Returns client_secret the mobile/web client uses to confirm.
     */
    public function createPaymentIntent(
        int $amountKobo,
        string $customerId = null,
        array $metadata = []
    ): array {
        $params = [
            'amount'   => $amountKobo,
            'currency' => 'ngn',
            'payment_method_types' => ['card'],
            'metadata' => $metadata,
        ];

        if ($customerId) {
            $params['customer'] = $customerId;
        }

        $intent = $this->stripe->paymentIntents->create($params);

        Log::info('Stripe PaymentIntent created', ['id' => $intent->id]);

        return [
            'client_secret'      => $intent->client_secret,
            'payment_intent_id'  => $intent->id,
            'amount'             => $intent->amount,
        ];
    }

    /**
     * Retrieve and verify a PaymentIntent.
     */
    public function verifyPaymentIntent(string $paymentIntentId): array
    {
        $intent = $this->stripe->paymentIntents->retrieve($paymentIntentId);

        if ($intent->status !== 'succeeded') {
            throw new \Exception("Payment not completed. Status: {$intent->status}");
        }

        return [
            'id'       => $intent->id,
            'amount'   => intdiv($intent->amount, 100),    // kobo → base unit
            'currency' => $intent->currency,
            'status'   => $intent->status,
            'metadata' => $intent->metadata->toArray(),
        ];
    }

    /*
    |--------------------------------------------------------------------------
    | Customer Management
    |--------------------------------------------------------------------------
    */

    /**
     * Create or retrieve a Stripe customer for a platform user.
     */
    public function createOrRetrieveCustomer(string $email, string $name, string $platformUserId): string
    {
        $existing = $this->stripe->customers->search([
            'query' => "metadata['platform_user_id']:'{$platformUserId}'",
        ]);

        if (!empty($existing->data)) {
            return $existing->data[0]->id;
        }

        $customer = $this->stripe->customers->create([
            'email' => $email,
            'name'  => $name,
            'metadata' => ['platform_user_id' => $platformUserId],
        ]);

        return $customer->id;
    }

    /*
    |--------------------------------------------------------------------------
    | Refunds
    |--------------------------------------------------------------------------
    */

    /**
     * Refund a Stripe payment.
     */
    public function refundPayment(string $paymentIntentId, ?int $amountKobo = null): array
    {
        $params = ['payment_intent' => $paymentIntentId];
        if ($amountKobo !== null) {
            $params['amount'] = $amountKobo;
        }

        $refund = $this->stripe->refunds->create($params);

        Log::info('Stripe refund created', ['id' => $refund->id, 'status' => $refund->status]);

        return [
            'id'     => $refund->id,
            'status' => $refund->status,
            'amount' => intdiv($refund->amount, 100),
        ];
    }

    /*
    |--------------------------------------------------------------------------
    | Payouts (Stripe Connect — for runner withdrawals)
    |--------------------------------------------------------------------------
    */

    /**
     * Create a payout to a connected account (Stripe Connect).
     * Note: requires runner to complete Stripe Express onboarding.
     */
    public function createConnectedPayout(
        string $stripeAccountId,
        int $amountKobo,
        string $description = 'Errandly runner earnings'
    ): array {
        $payout = $this->stripe->payouts->create(
            ['amount' => $amountKobo, 'currency' => 'ngn', 'description' => $description],
            ['stripe_account' => $stripeAccountId]
        );

        return [
            'id'     => $payout->id,
            'status' => $payout->status,
            'amount' => intdiv($payout->amount, 100),
        ];
    }

    /*
    |--------------------------------------------------------------------------
    | Webhook Validation
    |--------------------------------------------------------------------------
    */

    /**
     * Construct and validate a Stripe webhook event.
     */
    public function validateWebhook(string $payload, string $sigHeader): \Stripe\Event
    {
        try {
            return Webhook::constructEvent(
                $payload,
                $sigHeader,
                config('services.stripe.webhook_secret', '')
            );
        } catch (SignatureVerificationException $e) {
            throw new \Exception('Invalid Stripe webhook signature');
        }
    }
}
