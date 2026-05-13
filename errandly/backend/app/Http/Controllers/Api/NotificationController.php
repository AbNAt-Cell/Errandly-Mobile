<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class NotificationController extends Controller
{
    public function __construct(private NotificationService $notificationService) {}

    public function index(Request $request): JsonResponse
    {
        $notifications = AppNotification::where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        $unreadCount = AppNotification::where('user_id', $request->user()->id)
            ->whereNull('read_at')
            ->count();

        return response()->json([
            'notifications' => $notifications,
            'unread_count' => $unreadCount,
        ]);
    }

    public function markRead(Request $request, int $id): JsonResponse
    {
        AppNotification::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->update(['read_at' => now()]);

        return response()->json(['message' => 'Notification marked as read.']);
    }

    public function markAllRead(Request $request): JsonResponse
    {
        AppNotification::where('user_id', $request->user()->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json(['message' => 'All notifications marked as read.']);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        AppNotification::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->delete();

        return response()->json(['message' => 'Notification deleted.']);
    }

    public function broadcast(Request $request): JsonResponse
    {
        $request->validate([
            'title' => 'required|string|max:200',
            'body' => 'required|string|max:1000',
            'role' => 'nullable|in:customer,runner',
            'city' => 'nullable|string',
        ]);

        $count = $this->notificationService->broadcastAnnouncement(
            $request->title,
            $request->body,
            $request->only('role', 'city')
        );

        return response()->json(['message' => "Notification sent to {$count} users."]);
    }
}
