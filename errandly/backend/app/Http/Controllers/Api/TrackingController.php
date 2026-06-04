<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\AuthorizesErrandAccess;
use App\Http\Controllers\Controller;
use App\Models\Errand;
use App\Models\TrackingLog;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class TrackingController extends Controller
{
    use AuthorizesErrandAccess;

    public function updateLocation(Request $request, Errand $errand): JsonResponse
    {
        $request->validate([
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'speed' => 'nullable|numeric',
            'heading' => 'nullable|numeric',
            'accuracy' => 'nullable|numeric',
        ]);

        $runner = $request->user();
        $this->authorizeErrandRunner($runner, $errand);

        if (!$errand->isActive()) {
            return response()->json(['message' => 'Errand is not active.'], 400);
        }

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

        $runner->runnerProfile()->update([
            'current_latitude' => $request->latitude,
            'current_longitude' => $request->longitude,
            'location_updated_at' => now(),
        ]);

        broadcast(new \App\Events\RunnerLocationUpdated($errand, $runner, $request->latitude, $request->longitude));

        return response()->json(['message' => 'Location updated.']);
    }

    public function customerTrack(Request $request, Errand $errand): JsonResponse
    {
        $this->authorizeErrandCustomer($request->user(), $errand);

        $errand->load([
            'runner:id,first_name,last_name,phone,profile_image',
            'runner.runnerProfile:user_id,current_latitude,current_longitude,transport_type,trust_score,average_rating,location_updated_at',
        ]);

        $runnerLocation = null;
        if ($errand->runner && $errand->runner->runnerProfile) {
            $runnerLocation = [
                'latitude' => $errand->runner->runnerProfile->current_latitude,
                'longitude' => $errand->runner->runnerProfile->current_longitude,
                'updated_at' => $errand->runner->runnerProfile->location_updated_at,
            ];
        }

        $recentPath = TrackingLog::where('errand_id', $errand->id)
            ->orderBy('logged_at', 'desc')
            ->limit(50)
            ->get(['latitude', 'longitude', 'logged_at'])
            ->reverse()
            ->values();

        return response()->json([
            'errand' => [
                'public_id' => $errand->public_id,
                'status' => $errand->status,
                'pickup_latitude' => $errand->pickup_latitude,
                'pickup_longitude' => $errand->pickup_longitude,
                'pickup_address' => $errand->pickup_address,
                'destination_latitude' => $errand->destination_latitude,
                'destination_longitude' => $errand->destination_longitude,
                'destination_address' => $errand->destination_address,
            ],
            'runner' => $errand->runner ? [
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
