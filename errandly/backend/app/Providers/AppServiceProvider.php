<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Services\Payment\PaystackService;
use App\Services\Payment\FlutterwaveService;
use App\Services\Payment\StripeService;
use App\Services\PaymentService;
use App\Services\WalletService;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register application service bindings.
     */
    public function register(): void
    {
        // Payment gateway services (singletons — one HTTP client per request lifecycle)
        $this->app->singleton(PaystackService::class, fn () => new PaystackService());
        $this->app->singleton(FlutterwaveService::class, fn () => new FlutterwaveService());
        $this->app->singleton(StripeService::class, fn () => new StripeService());

        // Wallet service
        $this->app->singleton(WalletService::class, fn () => new WalletService());

        // Payment orchestrator — depends on all gateways + wallet
        $this->app->singleton(PaymentService::class, function ($app) {
            return new PaymentService(
                paystack:    $app->make(PaystackService::class),
                flutterwave: $app->make(FlutterwaveService::class),
                stripe:      $app->make(StripeService::class),
                walletService: $app->make(WalletService::class),
            );
        });
    }

    /**
     * Bootstrap application services.
     */
    public function boot(): void
    {
        //
    }
}
