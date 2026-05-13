<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('wallets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->bigInteger('balance')->default(0);
            $table->bigInteger('escrow_balance')->default(0);
            $table->bigInteger('pending_withdrawal')->default(0);
            $table->string('currency', 3)->default('NGN');
            $table->boolean('is_frozen')->default(false);
            $table->text('frozen_reason')->nullable();
            $table->timestamp('frozen_at')->nullable();
            $table->bigInteger('total_funded')->default(0);
            $table->bigInteger('total_withdrawn')->default(0);
            $table->bigInteger('total_earned')->default(0);
            $table->timestamps();
        });

        Schema::create('escrow_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('errand_id')->constrained()->cascadeOnDelete();
            $table->foreignId('customer_id')->constrained('users');
            $table->foreignId('runner_id')->nullable()->constrained('users')->nullOnDelete();
            $table->bigInteger('total_amount');
            $table->bigInteger('runner_amount');
            $table->bigInteger('platform_fee');
            $table->enum('status', ['pending_funding', 'funded', 'in_escrow', 'released', 'refunded', 'frozen'])->default('pending_funding');
            $table->timestamp('funded_at')->nullable();
            $table->timestamp('released_at')->nullable();
            $table->timestamp('refunded_at')->nullable();
            $table->timestamp('frozen_at')->nullable();
            $table->text('frozen_reason')->nullable();
            $table->text('release_reason')->nullable();
            $table->text('refund_reason')->nullable();
            $table->string('payment_method')->nullable();
            $table->string('payment_reference')->nullable();
            $table->json('gateway_response')->nullable();
            $table->timestamps();
        });

        Schema::create('wallet_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('wallet_id')->constrained()->cascadeOnDelete();
            $table->enum('type', [
                'funding', 'errand_payment', 'earnings', 'refund',
                'withdrawal', 'commission', 'bonus', 'tip', 'freeze',
            ]);
            $table->enum('direction', ['credit', 'debit']);
            $table->bigInteger('amount');
            $table->text('description');
            $table->nullableMorphs('reference');
            $table->bigInteger('balance_after');
            $table->enum('status', ['pending', 'completed', 'failed'])->default('completed');
            $table->json('metadata')->nullable();
            $table->timestamps();

            $table->index(['wallet_id', 'created_at']);
            $table->index(['type', 'direction']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('wallet_transactions');
        Schema::dropIfExists('escrow_transactions');
        Schema::dropIfExists('wallets');
    }
};
