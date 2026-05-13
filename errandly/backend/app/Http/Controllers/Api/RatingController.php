<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Rating;
use App\Models\Errand;
use App\Services\TrustScoreService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class RatingController extends Controller
{
    public function __construct(private TrustScoreService $trustScoreService) {}

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'errand_id' => 'required|integer|exists:errands,id',
            'overall_rating' => 'required|numeric|min:1|max:5',
            'punctuality' => 'nullable|numeric|min:1|max:5',
            'professionalism' => 'nullable|numeric|min:1|max:5',
            'communication' => 'nullable|numeric|min:1|max:5',
            'accuracy' => 'nullable|numeric|min:1|max:5',
            'safety' => 'nullable|numeric|min:1|max:5',
            'trustworthiness' => 'nullable|numeric|min:1|max:5',
            'clarity' => 'nullable|numeric|min:1|max:5',
            'politeness' => 'nullable|numeric|min:1|max:5',
            'payment_reliability' => 'nullable|numeric|min:1|max:5',
            'honesty' => 'nullable|numeric|min:1|max:5',
            'comment' => 'nullable|string|max:500',
            'is_anonymous' => 'nullable|boolean',
        ]);

        $errand = Errand::findOrFail($request->errand_id);
        $user = $request->user();

        if ($errand->status !== Errand::STATUS_COMPLETED) {
            return response()->json(['message' => 'Can only rate completed errands.'], 400);
        }

        // Determine role and rated user
        if ($user->id === $errand->customer_id) {
            $role = Rating::ROLE_CUSTOMER_TO_RUNNER;
            $ratedId = $errand->runner_id;
        } elseif ($user->id === $errand->runner_id) {
            $role = Rating::ROLE_RUNNER_TO_CUSTOMER;
            $ratedId = $errand->customer_id;
        } else {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        // Check existing rating
        if (Rating::where('errand_id', $errand->id)->where('rater_id', $user->id)->where('role', $role)->exists()) {
            return response()->json(['message' => 'You have already rated this errand.'], 400);
        }

        $rating = Rating::create([
            'errand_id' => $errand->id,
            'rater_id' => $user->id,
            'rated_id' => $ratedId,
            'role' => $role,
            'overall_rating' => $request->overall_rating,
            'punctuality' => $request->punctuality,
            'professionalism' => $request->professionalism,
            'communication' => $request->communication,
            'accuracy' => $request->accuracy,
            'safety' => $request->safety,
            'trustworthiness' => $request->trustworthiness,
            'clarity' => $request->clarity,
            'politeness' => $request->politeness,
            'payment_reliability' => $request->payment_reliability,
            'honesty' => $request->honesty,
            'comment' => $request->comment,
            'is_anonymous' => $request->is_anonymous ?? false,
        ]);

        // Recalculate trust score for runners
        if ($role === Rating::ROLE_CUSTOMER_TO_RUNNER) {
            $ratedUser = \App\Models\User::find($ratedId);
            if ($ratedUser?->runnerProfile) {
                $this->trustScoreService->recalculate($ratedUser->runnerProfile);
            }
        }

        return response()->json(['message' => 'Rating submitted. Thank you!', 'rating' => $rating], 201);
    }

    public function myRatings(Request $request): JsonResponse
    {
        $ratings = Rating::where('rated_id', $request->user()->id)
            ->with('rater:id,first_name,last_name,profile_image')
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        $summary = [
            'average' => Rating::where('rated_id', $request->user()->id)->avg('overall_rating'),
            'total' => Rating::where('rated_id', $request->user()->id)->count(),
        ];

        return response()->json(['summary' => $summary, 'ratings' => $ratings]);
    }

    public function given(Request $request): JsonResponse
    {
        $ratings = Rating::where('rater_id', $request->user()->id)
            ->with('rated:id,first_name,last_name', 'errand:id,title')
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json($ratings);
    }
}
