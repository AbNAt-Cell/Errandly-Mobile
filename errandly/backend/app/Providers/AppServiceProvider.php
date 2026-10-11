<?php

namespace App\Providers;

use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;
use App\Services\Payment\PaystackService;
use App\Services\Payment\FlutterwaveService;
use App\Services\Payment\StripeService;
use App\Services\PaymentService;
use App\Services\DeviceTokenService;
use App\Services\FcmService;
use App\Services\NotificationPreferenceService;
use App\Services\NotificationService;
use App\Services\WalletService;
use App\Services\Ai\Contracts\GeminiClientInterface;
use App\Services\Ai\FakeGeminiClient;
use App\Services\Ai\GeminiClient;

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

        $this->app->singleton(FcmService::class);
        $this->app->singleton(DeviceTokenService::class);
        $this->app->singleton(NotificationPreferenceService::class);
        $this->app->singleton(NotificationService::class);

        // Payment orchestrator — depends on all gateways + wallet
        $this->app->singleton(PaymentService::class, function ($app) {
            return new PaymentService(
                paystack:    $app->make(PaystackService::class),
                flutterwave: $app->make(FlutterwaveService::class),
                stripe:      $app->make(StripeService::class),
                walletService: $app->make(WalletService::class),
            );
        });

        $this->app->singleton(GeminiClientInterface::class, function () {
            if (config('ai.fake_responses')) {
                return new FakeGeminiClient();
            }

            return new GeminiClient();
        });
    }

    /**
     * Bootstrap application services.
     */
    public function boot(): void
    {
        if ($this->app->environment('production')) {
            URL::forceScheme('https');
        }
    }
}
