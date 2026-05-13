<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\WalletService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class WalletController extends Controller
{
    public function __construct(private WalletService $walletService) {}

    public function show(Request $request): JsonResponse
    {
        $wallet = $request->user()->wallet()->with('transactions')->first();
        return response()->json([
            'balance' => $wallet->balance,
            'escrow_balance' => $wallet->escrow_balance,
            'available_balance' => $wallet->getAvailableBalance(),
            'pending_withdrawal' => $wallet->pending_withdrawal,
            'currency' => $wallet->currency,
            'is_frozen' => $wallet->is_frozen,
            'total_funded' => $wallet->total_funded,
            'total_earned' => $wallet->total_earned,
            'total_withdrawn' => $wallet->total_withdrawn,
        ]);
    }

    public function transactions(Request $request): JsonResponse
    {
        $transactions = $request->user()->wallet
            ->transactions()
            ->when($request->type, fn($q) => $q->where('type', $request->type))
            ->paginate(20);
        return response()->json($transactions);
    }

    public function fund(Request $request): JsonResponse
    {
        $request->validate([
            'amount' => 'required|integer|min:100',
            'payment_method' => 'required|in:card,bank_transfer,ussd',
        ]);

        // In production: initialize payment gateway (Paystack/Stripe)
        // Return payment initialization URL/reference
        $reference = 'ERR_' . strtoupper(uniqid());

        return response()->json([
            'message' => 'Payment initialized.',
            'reference' => $reference,
            'amount' => $request->amount,
            'payment_url' => "https://paystack.com/pay/{$reference}",
        ]);
    }

    public function verifyPayment(Request $request): JsonResponse
    {
        $request->validate(['reference' => 'required|string']);

        try {
            // Verify with payment gateway in production
            $transaction = $this->walletService->fundWallet(
                $request->user(),
                $request->amount ?? 0,
                $request->reference
            );
            return response()->json(['message' => 'Wallet funded successfully.', 'transaction' => $transaction]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function escrow(Request $request): JsonResponse
    {
        $escrows = \App\Models\EscrowTransaction::where('customer_id', $request->user()->id)
            ->orWhere('runner_id', $request->user()->id)
            ->with('errand:id,title,status')
            ->orderBy('created_at', 'desc')
            ->paginate(10);

        return response()->json($escrows);
    }
}
