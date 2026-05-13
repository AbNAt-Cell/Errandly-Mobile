<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Errand;
use App\Models\SavedAddress;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class CustomerController extends Controller
{
    public function dashboard(Request $request): JsonResponse
    {
        $user = $request->user()->load(['wallet', 'runnerProfile']);

        $activeErrand = Errand::where('customer_id', $user->id)
            ->whereIn('status', [
                Errand::STATUS_ACCEPTED, Errand::STATUS_RUNNER_EN_ROUTE,
                Errand::STATUS_ITEM_PICKED, Errand::STATUS_IN_PROGRESS,
                Errand::STATUS_AWAITING_CONFIRMATION,
            ])
            ->with(['runner:id,first_name,last_name,phone,profile_image', 'runner.runnerProfile'])
            ->first();

        $stats = [
            'total_errands' => Errand::where('customer_id', $user->id)->count(),
            'completed' => Errand::where('customer_id', $user->id)->where('status', Errand::STATUS_COMPLETED)->count(),
            'cancelled' => Errand::where('customer_id', $user->id)->where('status', Errand::STATUS_CANCELLED)->count(),
        ];

        return response()->json([
            'user' => [
                'id' => $user->id,
                'first_name' => $user->first_name,
                'last_name' => $user->last_name,
                'full_name' => $user->full_name,
                'profile_image' => $user->profile_image,
                'kyc_status' => $user->kyc_status,
            ],
            'wallet_balance' => $user->wallet?->balance,
            'escrow_balance' => $user->wallet?->escrow_balance,
            'active_errand' => $activeErrand,
            'stats' => $stats,
        ]);
    }

    public function savedAddresses(Request $request): JsonResponse
    {
        return response()->json($request->user()->savedAddresses()->orderBy('is_default', 'desc')->get());
    }

    public function storeAddress(Request $request): JsonResponse
    {
        $request->validate([
            'label' => 'required|string|max:50',
            'address' => 'required|string',
            'city' => 'nullable|string',
            'state' => 'nullable|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'is_default' => 'nullable|boolean',
        ]);

        if ($request->is_default) {
            $request->user()->savedAddresses()->update(['is_default' => false]);
        }

        $address = SavedAddress::create(array_merge(
            $request->only('label', 'address', 'city', 'state', 'latitude', 'longitude', 'is_default'),
            ['user_id' => $request->user()->id]
        ));

        return response()->json(['message' => 'Address saved.', 'address' => $address], 201);
    }

    public function deleteAddress(Request $request, int $id): JsonResponse
    {
        SavedAddress::where('id', $id)->where('user_id', $request->user()->id)->delete();
        return response()->json(['message' => 'Address deleted.']);
    }
}
