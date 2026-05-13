<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payment_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();

            // Transaction classification
            $table->string('type');        // wallet_funding | payout | refund
            $table->string('gateway');     // paystack | flutterwave | stripe
            $table->string('status')->default('pending'); // pending | processing | success | failed | refunded

            // References
            $table->string('reference')->unique();          // our internal reference
            $table->string('gateway_reference')->nullable(); // gateway's transaction/transfer ID

            // Financials
            $table->unsignedInteger('amount');     // naira
            $table->string('currency')->default('NGN');

            // Raw data from gateway
            $table->json('gateway_response')->nullable();
            $table->json('metadata')->nullable();          // extra context (bank details, user meta, etc.)

            $table->timestamp('processed_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'type']);
            $table->index(['user_id', 'status']);
            $table->index('gateway');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_transactions');
    }
};
