<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Errand;
use App\Models\Message;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class MessageController extends Controller
{
    public function conversations(Request $request): JsonResponse
    {
        $user = $request->user();

        $errands = Errand::where(function ($q) use ($user) {
            $q->where('customer_id', $user->id)
              ->orWhere('runner_id', $user->id);
        })
        ->whereIn('status', [
            Errand::STATUS_ACCEPTED, Errand::STATUS_RUNNER_EN_ROUTE,
            Errand::STATUS_ITEM_PICKED, Errand::STATUS_IN_PROGRESS,
            Errand::STATUS_AWAITING_CONFIRMATION, Errand::STATUS_COMPLETED,
        ])
        ->with([
            'customer:id,first_name,last_name,profile_image',
            'runner:id,first_name,last_name,profile_image',
            'messages' => fn($q) => $q->latest()->limit(1),
        ])
        ->orderByDesc(function ($q) {
            $q->select('created_at')->from('messages')->whereColumn('errand_id', 'errands.id')->latest()->limit(1);
        })
        ->get();

        return response()->json($errands->map(fn($errand) => [
            'errand_id' => $errand->id,
            'title' => $errand->title,
            'status' => $errand->status,
            'other_party' => $user->id === $errand->customer_id ? $errand->runner : $errand->customer,
            'last_message' => $errand->messages->first(),
            'unread_count' => Message::where('errand_id', $errand->id)
                ->where('sender_id', '!=', $user->id)
                ->whereNull('read_at')->count(),
        ]));
    }

    public function show(Request $request, int $errandId): JsonResponse
    {
        $errand = Errand::findOrFail($errandId);
        $user = $request->user();

        if ($errand->customer_id !== $user->id && $errand->runner_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $messages = Message::where('errand_id', $errandId)
            ->with('sender:id,first_name,last_name,profile_image')
            ->orderBy('created_at', 'asc')
            ->paginate(50);

        // Mark as read
        Message::where('errand_id', $errandId)
            ->where('sender_id', '!=', $user->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json($messages);
    }

    public function send(Request $request, int $errandId): JsonResponse
    {
        $request->validate([
            'content' => 'required_without:media_url|string|max:2000',
            'media_url' => 'nullable|string|url',
            'type' => 'nullable|in:text,image',
        ]);

        $errand = Errand::findOrFail($errandId);
        $user = $request->user();

        if ($errand->customer_id !== $user->id && $errand->runner_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $message = Message::create([
            'errand_id' => $errandId,
            'sender_id' => $user->id,
            'type' => $request->type ?? ($request->media_url ? 'image' : 'text'),
            'content' => $request->content,
            'media_url' => $request->media_url,
        ]);

        broadcast(new \App\Events\NewMessage($message))->toOthers();

        return response()->json($message->load('sender:id,first_name,last_name,profile_image'), 201);
    }

    public function sendVoice(Request $request, int $errandId): JsonResponse
    {
        $request->validate([
            'media_url' => 'required|string|url',
            'duration_seconds' => 'required|integer|min:1|max:300',
        ]);

        $errand = Errand::findOrFail($errandId);
        $user = $request->user();

        if ($errand->customer_id !== $user->id && $errand->runner_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $message = Message::create([
            'errand_id' => $errandId,
            'sender_id' => $user->id,
            'type' => Message::TYPE_VOICE,
            'media_url' => $request->media_url,
            'duration_seconds' => $request->duration_seconds,
        ]);

        return response()->json($message->load('sender:id,first_name,last_name,profile_image'), 201);
    }

    public function markRead(Request $request, int $errandId): JsonResponse
    {
        Message::where('errand_id', $errandId)
            ->where('sender_id', '!=', $request->user()->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json(['message' => 'Messages marked as read.']);
    }
}
