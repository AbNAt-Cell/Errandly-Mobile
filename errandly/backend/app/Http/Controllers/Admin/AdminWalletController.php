<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\EscrowTransaction;
use App\Models\WalletTransaction;
use App\Models\User;
use App\Services\WalletService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class AdminWalletController extends Controller
{
    public function __construct(private WalletService $walletService) {}

    public function overview(Request $request): JsonResponse
    {
        $totalEscrow = EscrowTransaction::where('status', EscrowTransaction::STATUS_IN_ESCROW)->sum('total_amount');
        $totalFrozen = EscrowTransaction::where('status', EscrowTransaction::STATUS_FROZEN)->sum('total_amount');
        $totalRevenue = WalletTransaction::where('type', 'commission')->where('direction', 'credit')->sum('amount');
        $totalReleased = EscrowTransaction::where('status', EscrowTransaction::STATUS_RELEASED)->sum('runner_amount');

        return response()->json([
            'escrow_total' => $totalEscrow,
            'frozen_total' => $totalFrozen,
            'platform_revenue' => $totalRevenue,
            'total_released_to_runners' => $totalReleased,
            'pending_withdrawals' => \App\Models\Wallet::sum('pending_withdrawal'),
        ]);
    }

    public function escrow(Request $request): JsonResponse
    {
        $escrows = EscrowTransaction::with(['errand:id,title,status', 'customer:id,first_name,last_name', 'runner:id,first_name,last_name'])
            ->when($request->status, fn($q) => $q->where('status', $request->status))
            ->orderBy('created_at', 'desc')
            ->paginate(25);

        return response()->json($escrows);
    }

    public function transactions(Request $request): JsonResponse
    {
        $transactions = WalletTransaction::with('wallet.user:id,first_name,last_name')
            ->when($request->type, fn($q) => $q->where('type', $request->type))
            ->orderBy('created_at', 'desc')
            ->paginate(30);

        return response()->json($transactions);
    }

    public function refund(Request $request): JsonResponse
    {
        $request->validate([
            'errand_id' => 'required|integer|exists:errands,id',
            'amount' => 'required|integer|min:1',
            'reason' => 'required|string',
        ]);

        $errand = \App\Models\Errand::with('customer', 'escrow')->findOrFail($request->errand_id);

        DB::transaction(function () use ($errand, $request) {
            $this->walletService->processRefund($errand->customer, $errand, $request->amount);
        });

        return response()->json(['message' => "₦{$request->amount} refunded to customer wallet."]);
    }

    public function release(Request $request): JsonResponse
    {
        $request->validate(['errand_id' => 'required|integer|exists:errands,id']);

        $errand = \App\Models\Errand::with('runner', 'escrow')->findOrFail($request->errand_id);

        DB::transaction(function () use ($errand) {
            $this->walletService->releaseEscrow($errand);
        });

        return response()->json(['message' => 'Escrow released to runner.']);
    }

    public function freeze(Request $request, int $userId): JsonResponse
    {
        $request->validate(['reason' => 'required|string']);

        $user = User::findOrFail($userId);
        $this->walletService->freezeWallet($user, $request->reason, $request->user());

        return response()->json(['message' => 'Wallet frozen.']);
    }

    public function unfreeze(Request $request, int $userId): JsonResponse
    {
        $user = User::findOrFail($userId);
        $this->walletService->unfreezeWallet($user);

        return response()->json(['message' => 'Wallet unfrozen.']);
    }
}
