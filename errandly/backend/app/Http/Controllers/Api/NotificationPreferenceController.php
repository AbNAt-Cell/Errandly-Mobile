<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\NotificationPreferenceService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationPreferenceController extends Controller
{
    public function __construct(
        private NotificationPreferenceService $preferences,
    ) {}

    public function show(Request $request): JsonResponse
    {
        $prefs = $this->preferences->getOrCreate($request->user());

        return response()->json([
            'preferences' => $this->preferences->toArray($prefs),
            'categories' => [
                'push_enabled' => 'Master switch for all push notifications',
                'errand_updates' => 'Errand offers, assignments, status updates',
                'payments' => 'Payments released, wallet activity',
                'account' => 'KYC results, account status',
                'marketing' => 'Announcements and promotions',
                'alerts' => 'Panic alerts, disputes, safety',
            ],
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'push_enabled' => 'sometimes|boolean',
            'errand_updates' => 'sometimes|boolean',
            'payments' => 'sometimes|boolean',
            'account' => 'sometimes|boolean',
            'marketing' => 'sometimes|boolean',
            'alerts' => 'sometimes|boolean',
        ]);

        $prefs = $this->preferences->getOrCreate($request->user());
        $prefs->update($validated);

        return response()->json([
            'message' => 'Notification preferences updated.',
            'preferences' => $this->preferences->toArray($prefs->fresh()),
        ]);
    }
}
