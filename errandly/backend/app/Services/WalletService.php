<?php

namespace App\Services;

use App\Models\User;
use App\Models\Wallet;
use App\Models\Errand;
use App\Models\EscrowTransaction;
use App\Models\WalletTransaction;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class WalletService
{
    public function createWalletForUser(User $user): Wallet
    {
        return Wallet::create([
            'user_id' => $user->id,
            'balance' => 0,
            'escrow_balance' => 0,
            'pending_withdrawal' => 0,
            'currency' => config('errandly.currency', 'NGN'),
        ]);
    }

    public function fundWallet(User $user, int $amount, string $reference): WalletTransaction
    {
        return DB::transaction(function () use ($user, $amount, $reference) {
            $wallet = $user->wallet()->lockForUpdate()->first();

            if ($wallet->is_frozen) {
                throw new \Exception('Your wallet is currently frozen. Contact support.');
            }

            $transaction = $wallet->credit(
                $amount,
                WalletTransaction::TYPE_FUNDING,
                "Wallet funded via payment reference: {$reference}",
            );

            $wallet->increment('total_funded', $amount);

            return $transaction;
        });
    }

    public function holdForEscrow(User $customer, int $amount, int $errandId): void
    {
        DB::transaction(function () use ($customer, $amount, $errandId) {
            $wallet = $customer->wallet()->lockForUpdate()->first();

            if (!$wallet->hasSufficientFunds($amount)) {
                throw new \Exception('Insufficient wallet balance.');
            }

            $wallet->debit(
                $amount,
                WalletTransaction::TYPE_PAYMENT,
                "Payment held in escrow for Errand #{$errandId}",
                $errandId,
                Errand::class
            );

            $wallet->increment('escrow_balance', $amount);
        });
    }

    public function releaseEscrow(Errand $errand): void
    {
        DB::transaction(function () use ($errand) {
            $escrow = $errand->escrow()->lockForUpdate()->first();

            if (!$escrow || !$escrow->canRelease()) {
                throw new \Exception('Escrow cannot be released at this time.');
            }

            $runner = $errand->runner;
            $runnerWallet = $runner->wallet()->lockForUpdate()->first();

            // Release runner earnings
            $runnerWallet->credit(
                $escrow->runner_amount,
                WalletTransaction::TYPE_EARNINGS,
                "Earnings for Errand #{$errand->id}: {$errand->title}",
                $errand->id,
                Errand::class
            );

            $runnerWallet->increment('total_earned', $escrow->runner_amount);

            // Update runner profile total earnings
            $runner->runnerProfile()->increment('total_earnings', $escrow->runner_amount);

            // Update escrow status
            $escrow->update([
                'status' => EscrowTransaction::STATUS_RELEASED,
                'released_at' => now(),
                'release_reason' => 'Task confirmed complete by customer',
            ]);

            // Decrement customer escrow balance
            $customerWallet = $errand->customer->wallet()->lockForUpdate()->first();
            $customerWallet->decrement('escrow_balance', $escrow->total_amount);

            // Update errand payment status
            $errand->update(['payment_status' => Errand::PAYMENT_RELEASED]);

            Log::info('Escrow released', [
                'errand_id' => $errand->id,
                'runner_id' => $runner->id,
                'amount' => $escrow->runner_amount,
            ]);
        });
    }

    public function processRefund(User $customer, Errand $errand, int $refundAmount): void
    {
        DB::transaction(function () use ($customer, $errand, $refundAmount) {
            $escrow = $errand->escrow()->lockForUpdate()->first();

            if (!$escrow || !$escrow->canRefund()) {
                return;
            }

            if ($refundAmount > 0) {
                $customerWallet = $customer->wallet()->lockForUpdate()->first();
                $customerWallet->credit(
                    $refundAmount,
                    WalletTransaction::TYPE_REFUND,
                    "Refund for cancelled Errand #{$errand->id}",
                    $errand->id,
                    Errand::class
                );
                $customerWallet->decrement('escrow_balance', $escrow->total_amount);
            }

            $escrow->update([
                'status' => EscrowTransaction::STATUS_REFUNDED,
                'refunded_at' => now(),
                'refund_reason' => 'Errand cancelled by customer',
            ]);

            $errand->update(['payment_status' => Errand::PAYMENT_REFUNDED]);
        });
    }

    public function freezeWallet(User $user, string $reason, User $admin): void
    {
        $user->wallet()->update([
            'is_frozen' => true,
            'frozen_reason' => $reason,
            'frozen_at' => now(),
        ]);

        Log::warning('Wallet frozen', ['user_id' => $user->id, 'reason' => $reason, 'by' => $admin->id]);
    }

    public function unfreezeWallet(User $user): void
    {
        $user->wallet()->update([
            'is_frozen' => false,
            'frozen_reason' => null,
            'frozen_at' => null,
        ]);
    }

    public function requestWithdrawal(User $runner, int $amount): WalletTransaction
    {
        return DB::transaction(function () use ($runner, $amount) {
            $wallet = $runner->wallet()->lockForUpdate()->first();

            if ($wallet->is_frozen) {
                throw new \Exception('Your wallet is frozen. Contact support.');
            }

            $available = $wallet->balance - $wallet->pending_withdrawal;
            if ($available < $amount) {
                throw new \Exception("Insufficient available balance. Available: {$available}");
            }

            // Check for active disputes
            $hasActiveDisputes = Errand::where('runner_id', $runner->id)
                ->where('status', Errand::STATUS_DISPUTED)
                ->exists();

            if ($hasActiveDisputes) {
                throw new \Exception('Withdrawals are blocked while you have active disputes.');
            }

            $wallet->increment('pending_withdrawal', $amount);

            return $wallet->debit(
                $amount,
                WalletTransaction::TYPE_WITHDRAWAL,
                "Withdrawal request for ₦{$amount}",
            );
        });
    }
}
