<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class RunnerVerifiedMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        $runner = $request->user();
        $profile = $runner?->runnerProfile;

        if (!$profile || !$profile->isVerified()) {
            return response()->json([
                'message' => 'Your runner account is pending verification. Complete your KYC to access this feature.',
                'verification_status' => $profile?->verification_status ?? 'pending',
            ], 403);
        }

        if ($runner->status !== \App\Models\User::STATUS_ACTIVE) {
            return response()->json([
                'message' => 'Your account is not active.',
                'status' => $runner->status,
            ], 403);
        }

        return $next($request);
    }
}
