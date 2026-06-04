<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Symfony\Component\HttpFoundation\Response;

class ThrottleAiRequests
{
    public function handle(Request $request, Closure $next): Response
    {
        $limit = (int) config('ai.rate_limits.agent_per_hour', 60);
        $key = 'ai:' . ($request->user()?->id ?? $request->ip());

        if (RateLimiter::tooManyAttempts($key, $limit)) {
            $seconds = RateLimiter::availableIn($key);

            return response()->json([
                'message' => 'Too many AI requests. Please try again later.',
                'retry_after_seconds' => $seconds,
            ], 429);
        }

        RateLimiter::hit($key, decaySeconds: 3600);

        return $next($request);
    }
}
