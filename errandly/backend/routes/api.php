<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CustomerController;
use App\Http\Controllers\Api\RunnerController;
use App\Http\Controllers\Api\ErrandController;
use App\Http\Controllers\Api\WalletController;
use App\Http\Controllers\Api\MessageController;
use App\Http\Controllers\Api\RatingController;
use App\Http\Controllers\Api\DisputeController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\TrackingController;
use App\Http\Controllers\Api\KycController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Admin\AdminDashboardController;
use App\Http\Controllers\Admin\AdminUserController;
use App\Http\Controllers\Admin\AdminRunnerController;
use App\Http\Controllers\Admin\AdminErrandController;
use App\Http\Controllers\Admin\AdminKycController;
use App\Http\Controllers\Admin\AdminWalletController;
use App\Http\Controllers\Admin\AdminDisputeController;
use App\Http\Controllers\Admin\AdminReportController;
use App\Http\Controllers\Admin\AdminSettingsController;

/*
|--------------------------------------------------------------------------
| Public Auth Routes
|--------------------------------------------------------------------------
*/
Route::prefix('auth')->group(function () {
    Route::post('/register/customer', [AuthController::class, 'registerCustomer']);
    Route::post('/register/runner', [AuthController::class, 'registerRunner']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('/reset-password', [AuthController::class, 'resetPassword']);
    Route::post('/verify-phone', [AuthController::class, 'verifyPhone']);
    Route::post('/resend-otp', [AuthController::class, 'resendOtp']);
    Route::post('/refresh', [AuthController::class, 'refresh']);
});

/*
|--------------------------------------------------------------------------
| Authenticated User Routes
|--------------------------------------------------------------------------
*/
Route::middleware(['auth:sanctum'])->group(function () {

    // Auth
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::put('/auth/profile', [AuthController::class, 'updateProfile']);
    Route::put('/auth/password', [AuthController::class, 'changePassword']);
    Route::post('/auth/device-token', [AuthController::class, 'updateDeviceToken']);

    // KYC
    Route::prefix('kyc')->group(function () {
        Route::get('/', [KycController::class, 'status']);
        Route::post('/submit', [KycController::class, 'submit']);
        Route::post('/resubmit', [KycController::class, 'resubmit']);
        Route::get('/documents', [KycController::class, 'documents']);
    });

    // Notifications
    Route::prefix('notifications')->group(function () {
        Route::get('/', [NotificationController::class, 'index']);
        Route::put('/{id}/read', [NotificationController::class, 'markRead']);
        Route::put('/read-all', [NotificationController::class, 'markAllRead']);
        Route::delete('/{id}', [NotificationController::class, 'destroy']);
    });

    // Wallet
    Route::prefix('wallet')->group(function () {
        Route::get('/', [WalletController::class, 'show']);
        Route::get('/transactions', [WalletController::class, 'transactions']);
        Route::post('/fund', [WalletController::class, 'fund']);
        Route::post('/verify-payment', [WalletController::class, 'verifyPayment']);
        Route::get('/escrow', [WalletController::class, 'escrow']);
    });

    // Messages
    Route::prefix('messages')->group(function () {
        Route::get('/conversations', [MessageController::class, 'conversations']);
        Route::get('/conversations/{errandId}', [MessageController::class, 'show']);
        Route::post('/conversations/{errandId}', [MessageController::class, 'send']);
        Route::post('/conversations/{errandId}/voice', [MessageController::class, 'sendVoice']);
        Route::put('/conversations/{errandId}/read', [MessageController::class, 'markRead']);
    });

    // Ratings
    Route::prefix('ratings')->group(function () {
        Route::post('/', [RatingController::class, 'store']);
        Route::get('/my-ratings', [RatingController::class, 'myRatings']);
        Route::get('/given', [RatingController::class, 'given']);
    });

    // Disputes
    Route::prefix('disputes')->group(function () {
        Route::get('/', [DisputeController::class, 'index']);
        Route::post('/', [DisputeController::class, 'store']);
        Route::get('/{id}', [DisputeController::class, 'show']);
        Route::post('/{id}/evidence', [DisputeController::class, 'addEvidence']);
    });

    /*
    |--------------------------------------------------------------------------
    | Customer Routes
    |--------------------------------------------------------------------------
    */
    Route::middleware(['role:customer'])->prefix('customer')->group(function () {
        Route::get('/dashboard', [CustomerController::class, 'dashboard']);
        Route::get('/saved-addresses', [CustomerController::class, 'savedAddresses']);
        Route::post('/saved-addresses', [CustomerController::class, 'storeAddress']);
        Route::delete('/saved-addresses/{id}', [CustomerController::class, 'deleteAddress']);

        // Errands
        Route::prefix('errands')->group(function () {
            Route::get('/', [ErrandController::class, 'customerIndex']);
            Route::post('/', [ErrandController::class, 'store']);
            Route::get('/{id}', [ErrandController::class, 'show']);
            Route::put('/{id}', [ErrandController::class, 'update']);
            Route::post('/{id}/cancel', [ErrandController::class, 'cancel']);
            Route::post('/{id}/confirm-completion', [ErrandController::class, 'confirmCompletion']);
            Route::get('/{id}/tracking', [TrackingController::class, 'customerTrack']);
            Route::post('/{id}/panic', [ErrandController::class, 'panic']);
            Route::get('/{id}/proof', [ErrandController::class, 'getProof']);
            Route::post('/{id}/generate-delivery-otp', [ErrandController::class, 'generateDeliveryOtp']);
        });

        // Payments
        Route::prefix('payments')->group(function () {
            Route::post('/initialize', [PaymentController::class, 'initialize']);
            Route::post('/verify', [PaymentController::class, 'verify']);
            Route::get('/banks', [PaymentController::class, 'bankList']);
            Route::post('/verify-account', [PaymentController::class, 'verifyAccount']);
            Route::get('/history', [PaymentController::class, 'history']);
        });
    });

    /*
    |--------------------------------------------------------------------------
    | Runner Routes
    |--------------------------------------------------------------------------
    */
    Route::middleware(['role:runner', 'runner.verified'])->prefix('runner')->group(function () {
        Route::get('/dashboard', [RunnerController::class, 'dashboard']);
        Route::put('/availability', [RunnerController::class, 'updateAvailability']);
        Route::put('/location', [RunnerController::class, 'updateLocation']);
        Route::get('/profile', [RunnerController::class, 'profile']);
        Route::put('/profile', [RunnerController::class, 'updateProfile']);
        Route::get('/trust-score', [RunnerController::class, 'trustScore']);
        Route::get('/stats', [RunnerController::class, 'stats']);

        // Errands
        Route::prefix('errands')->group(function () {
            Route::get('/available', [ErrandController::class, 'available']);
            Route::get('/my-errands', [ErrandController::class, 'runnerIndex']);
            Route::get('/{id}', [ErrandController::class, 'show']);
            Route::post('/{id}/accept', [ErrandController::class, 'accept']);
            Route::post('/{id}/reject', [ErrandController::class, 'reject']);
            Route::post('/{id}/arrived', [ErrandController::class, 'arrived']);
            Route::post('/{id}/pickup-otp', [ErrandController::class, 'verifyPickupOtp']);
            Route::post('/{id}/start', [ErrandController::class, 'start']);
            Route::post('/{id}/complete', [ErrandController::class, 'complete']);
            Route::post('/{id}/cancel', [ErrandController::class, 'runnerCancel']);
            Route::post('/{id}/proof', [ErrandController::class, 'submitProof']);
            Route::post('/{id}/panic', [ErrandController::class, 'panic']);
            Route::put('/{id}/location', [TrackingController::class, 'updateLocation']);
        });

        // Earnings & payouts
        Route::prefix('earnings')->group(function () {
            Route::get('/', [RunnerController::class, 'earnings']);
            Route::get('/withdrawals', [RunnerController::class, 'withdrawals']);
            Route::put('/bank-account', [RunnerController::class, 'updateBankAccount']);
        });

        // Payments (runner-specific: withdrawals, bank verification)
        Route::prefix('payments')->group(function () {
            Route::post('/withdraw', [PaymentController::class, 'initiateWithdrawal']);
            Route::get('/banks', [PaymentController::class, 'bankList']);
            Route::post('/verify-account', [PaymentController::class, 'verifyAccount']);
            Route::get('/history', [PaymentController::class, 'history']);
        });
    });

    // Runner registration (before verification)
    Route::middleware(['role:runner'])->prefix('runner')->group(function () {
        Route::get('/verification-status', [RunnerController::class, 'verificationStatus']);
        Route::post('/kyc/submit', [KycController::class, 'submitRunnerKyc']);
    });

    /*
    |--------------------------------------------------------------------------
    | Admin Routes
    |--------------------------------------------------------------------------
    */
    Route::middleware(['role:admin|verification_officer'])->prefix('admin')->group(function () {

        Route::get('/dashboard', [AdminDashboardController::class, 'index']);
        Route::get('/metrics', [AdminDashboardController::class, 'metrics']);
        Route::get('/live-map', [AdminDashboardController::class, 'liveMap']);

        // Users
        Route::prefix('users')->group(function () {
            Route::get('/', [AdminUserController::class, 'index']);
            Route::get('/{id}', [AdminUserController::class, 'show']);
            Route::put('/{id}/suspend', [AdminUserController::class, 'suspend']);
            Route::put('/{id}/restore', [AdminUserController::class, 'restore']);
            Route::put('/{id}/blacklist', [AdminUserController::class, 'blacklist']);
            Route::put('/{id}/verify', [AdminUserController::class, 'verify']);
            Route::delete('/{id}', [AdminUserController::class, 'destroy']);
        });

        // Runners
        Route::prefix('runners')->group(function () {
            Route::get('/', [AdminRunnerController::class, 'index']);
            Route::get('/{id}', [AdminRunnerController::class, 'show']);
            Route::put('/{id}/approve', [AdminRunnerController::class, 'approve']);
            Route::put('/{id}/suspend', [AdminRunnerController::class, 'suspend']);
            Route::put('/{id}/trust-score', [AdminRunnerController::class, 'adjustTrustScore']);
        });

        // KYC
        Route::prefix('kyc')->group(function () {
            Route::get('/', [AdminKycController::class, 'index']);
            Route::get('/pending', [AdminKycController::class, 'pending']);
            Route::get('/{id}', [AdminKycController::class, 'show']);
            Route::put('/{id}/approve', [AdminKycController::class, 'approve']);
            Route::put('/{id}/reject', [AdminKycController::class, 'reject']);
            Route::put('/{id}/request-resubmission', [AdminKycController::class, 'requestResubmission']);
        });

        // Errands
        Route::prefix('errands')->group(function () {
            Route::get('/', [AdminErrandController::class, 'index']);
            Route::get('/{id}', [AdminErrandController::class, 'show']);
            Route::post('/{id}/reassign', [AdminErrandController::class, 'reassign']);
            Route::post('/{id}/cancel', [AdminErrandController::class, 'cancel']);
            Route::get('/{id}/timeline', [AdminErrandController::class, 'timeline']);
            Route::get('/{id}/tracking', [AdminErrandController::class, 'tracking']);
        });

        // Wallets & Finance
        Route::prefix('finance')->group(function () {
            Route::get('/overview', [AdminWalletController::class, 'overview']);
            Route::get('/escrow', [AdminWalletController::class, 'escrow']);
            Route::get('/transactions', [AdminWalletController::class, 'transactions']);
            Route::post('/refund', [AdminWalletController::class, 'refund']);
            Route::post('/release', [AdminWalletController::class, 'release']);
            Route::put('/wallets/{userId}/freeze', [AdminWalletController::class, 'freeze']);
            Route::put('/wallets/{userId}/unfreeze', [AdminWalletController::class, 'unfreeze']);
        });

        // Disputes
        Route::prefix('disputes')->group(function () {
            Route::get('/', [AdminDisputeController::class, 'index']);
            Route::get('/{id}', [AdminDisputeController::class, 'show']);
            Route::put('/{id}/assign', [AdminDisputeController::class, 'assign']);
            Route::post('/{id}/resolve', [AdminDisputeController::class, 'resolve']);
            Route::post('/{id}/close', [AdminDisputeController::class, 'close']);
        });

        // Reports
        Route::prefix('reports')->group(function () {
            Route::get('/revenue', [AdminReportController::class, 'revenue']);
            Route::get('/errands', [AdminReportController::class, 'errands']);
            Route::get('/users', [AdminReportController::class, 'users']);
            Route::get('/incidents', [AdminReportController::class, 'incidents']);
            Route::get('/fraud', [AdminReportController::class, 'fraud']);
            Route::post('/export', [AdminReportController::class, 'export']);
        });

        // Settings
        Route::prefix('settings')->group(function () {
            Route::get('/', [AdminSettingsController::class, 'index']);
            Route::put('/', [AdminSettingsController::class, 'update']);
            Route::get('/service-areas', [AdminSettingsController::class, 'serviceAreas']);
            Route::post('/service-areas', [AdminSettingsController::class, 'storeServiceArea']);
            Route::put('/service-areas/{id}', [AdminSettingsController::class, 'updateServiceArea']);
            Route::delete('/service-areas/{id}', [AdminSettingsController::class, 'deleteServiceArea']);
        });

        // Notifications
        Route::post('/notifications/broadcast', [NotificationController::class, 'broadcast']);
    });

});

// Webhooks (no auth — verified by gateway signature)
Route::prefix('webhooks')->group(function () {
    Route::post('/paystack', [PaymentController::class, 'paystackWebhook']);
    Route::post('/flutterwave', [PaymentController::class, 'flutterwaveWebhook']);
    Route::post('/stripe', [PaymentController::class, 'stripeWebhook']);
});
