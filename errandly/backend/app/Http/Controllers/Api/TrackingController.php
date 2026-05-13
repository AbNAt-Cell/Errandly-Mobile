<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Errand;
use App\Models\TrackingLog;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class TrackingController extends Controller
{
    public function updateLocation(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'speed' => 'nullable|numeric',
            'heading' => 'nullable|numeric',
            'accuracy' => 'nullable|numeric',
        ]);

        $errand = Errand::findOrFail($id);
        $runner = $request->user();

        if ($errand->runner_id !== $runner->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        if (!$errand->isActive()) {
            return response()->json(['message' => 'Errand is not active.'], 400);
        }

        // Log tracking point
        TrackingLog::create([
            'errand_id' => $errand->id,
            'runner_id' => $runner->id,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'speed' => $request->speed,
            'heading' => $request->heading,
            'accuracy' => $request->accuracy,
            'logged_at' => now(),
        ]);

        // Update runner's current location
        $runner->runnerProfile()->update([
            'current_latitude' => $request->latitude,
            'current_longitude' => $request->longitude,
            'location_updated_at' => now(),
        ]);

        // Broadcast via Pusher for real-time tracking
        broadcast(new \App\Events\RunnerLocationUpdated($errand, $runner, $request->latitude, $request->longitude));

        return response()->json(['message' => 'Location updated.']);
    }

    public function customerTrack(Request $request, int $id): JsonResponse
    {
        $errand = Errand::with([
            'runner:id,first_name,last_name,phone,profile_image',
            'runner.runnerProfile:user_id,current_latitude,current_longitude,transport_type,trust_score,average_rating,location_updated_at',
        ])->findOrFail($id);

        if ($errand->customer_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $runnerLocation = null;
        if ($errand->runner && $errand->runner->runnerProfile) {
            $runnerLocation = [
                'latitude' => $errand->runner->runnerProfile->current_latitude,
                'longitude' => $errand->runner->runnerProfile->current_longitude,
                'updated_at' => $errand->runner->runnerProfile->location_updated_at,
            ];
        }

        // Recent tracking path (last 50 points)
        $recentPath = TrackingLog::where('errand_id', $errand->id)
            ->orderBy('logged_at', 'desc')
            ->limit(50)
            ->get(['latitude', 'longitude', 'logged_at'])
            ->reverse()
            ->values();

        return response()->json([
            'errand' => [
                'id' => $errand->id,
                'status' => $errand->status,
                'pickup_latitude' => $errand->pickup_latitude,
                'pickup_longitude' => $errand->pickup_longitude,
                'pickup_address' => $errand->pickup_address,
                'destination_latitude' => $errand->destination_latitude,
                'destination_longitude' => $errand->destination_longitude,
                'destination_address' => $errand->destination_address,
            ],
            'runner' => $errand->runner ? [
                'id' => $errand->runner->id,
                'name' => $errand->runner->full_name,
                'phone' => $errand->runner->phone,
                'profile_image' => $errand->runner->profile_image,
                'transport_type' => $errand->runner->runnerProfile?->transport_type,
                'trust_score' => $errand->runner->runnerProfile?->trust_score,
                'rating' => $errand->runner->runnerProfile?->average_rating,
            ] : null,
            'runner_location' => $runnerLocation,
            'tracking_path' => $recentPath,
        ]);
    }
}
