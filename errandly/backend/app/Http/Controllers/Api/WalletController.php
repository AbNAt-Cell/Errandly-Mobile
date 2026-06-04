<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\PaymentService;
use App\Services\WalletService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class WalletController extends Controller
{
    public function __construct(
        private WalletService $walletService,
        private PaymentService $paymentService,
    ) {}

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

    /**
     * @deprecated Use POST /api/customer/payments/initialize instead.
     */
    public function fund(Request $request): JsonResponse
    {
        return response()->json([
            'message' => 'Use POST /api/customer/payments/initialize to fund your wallet securely.',
        ], 410);
    }

    public function verifyPayment(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'reference' => 'required|string',
            'gateway' => 'sometimes|in:paystack,flutterwave,stripe',
            'gateway_transaction_id' => 'sometimes|string',
        ]);

        try {
            $result = $this->paymentService->verifyAndCreditWallet(
                user: $request->user(),
                reference: $validated['reference'],
                gateway: $validated['gateway'] ?? PaymentService::DEFAULT_WALLET_GATEWAY,
                gatewayTransactionId: $validated['gateway_transaction_id'] ?? null,
            );

            return response()->json($result);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
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
