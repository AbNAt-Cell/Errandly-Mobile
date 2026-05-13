<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Errand;
use App\Models\RunnerProfile;
use App\Models\Dispute;
use App\Models\KycDocument;
use App\Models\WalletTransaction;
use App\Models\PanicEvent;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class AdminDashboardController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $now = now();
        $today = $now->startOfDay()->copy();
        $thisMonth = $now->startOfMonth()->copy();
        $lastMonth = $now->subMonth()->startOfMonth()->copy();

        $metrics = [
            'users' => [
                'total' => User::count(),
                'customers' => User::role('customer')->count(),
                'runners' => User::role('runner')->count(),
                'new_today' => User::where('created_at', '>=', $today)->count(),
            ],
            'errands' => [
                'total' => Errand::count(),
                'active' => Errand::whereIn('status', [
                    Errand::STATUS_ACCEPTED, Errand::STATUS_RUNNER_EN_ROUTE,
                    Errand::STATUS_ITEM_PICKED, Errand::STATUS_IN_PROGRESS,
                ])->count(),
                'pending' => Errand::where('status', Errand::STATUS_PENDING_ASSIGNMENT)->count(),
                'completed' => Errand::where('status', Errand::STATUS_COMPLETED)->count(),
                'disputed' => Errand::where('status', Errand::STATUS_DISPUTED)->count(),
                'today' => Errand::where('created_at', '>=', $today)->count(),
            ],
            'runners' => [
                'online' => RunnerProfile::where('is_online', true)->count(),
                'verified' => RunnerProfile::where('verification_status', RunnerProfile::VERIFICATION_APPROVED)->count(),
                'pending_kyc' => KycDocument::where('status', KycDocument::STATUS_SUBMITTED)->count(),
            ],
            'disputes' => [
                'open' => Dispute::where('status', Dispute::STATUS_OPEN)->count(),
                'under_review' => Dispute::where('status', Dispute::STATUS_UNDER_REVIEW)->count(),
            ],
            'revenue' => [
                'today' => WalletTransaction::where('type', 'commission')
                    ->where('direction', 'credit')
                    ->where('created_at', '>=', $today)->sum('amount'),
                'this_month' => WalletTransaction::where('type', 'commission')
                    ->where('direction', 'credit')
                    ->where('created_at', '>=', $thisMonth)->sum('amount'),
            ],
            'incidents' => [
                'active_panics' => PanicEvent::where('status', PanicEvent::STATUS_ACTIVE)->count(),
            ],
        ];

        return response()->json($metrics);
    }

    public function metrics(Request $request): JsonResponse
    {
        $period = $request->get('period', '7days');
        $days = match($period) {
            '7days' => 7,
            '30days' => 30,
            '90days' => 90,
            default => 7,
        };

        // Errand volume by day
        $errandVolume = Errand::select(
            DB::raw('DATE(created_at) as date'),
            DB::raw('COUNT(*) as total'),
            DB::raw("COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed"),
        )
        ->where('created_at', '>=', now()->subDays($days))
        ->groupBy('date')
        ->orderBy('date')
        ->get();

        // Revenue by day
        $revenue = WalletTransaction::select(
            DB::raw('DATE(created_at) as date'),
            DB::raw('SUM(amount) as amount'),
        )
        ->where('type', 'commission')
        ->where('direction', 'credit')
        ->where('created_at', '>=', now()->subDays($days))
        ->groupBy('date')
        ->orderBy('date')
        ->get();

        // User growth
        $userGrowth = User::select(
            DB::raw('DATE(created_at) as date'),
            DB::raw('COUNT(*) as total'),
        )
        ->where('created_at', '>=', now()->subDays($days))
        ->groupBy('date')
        ->orderBy('date')
        ->get();

        // Top locations by errand count
        $topLocations = Errand::select('pickup_city', DB::raw('COUNT(*) as count'))
            ->whereNotNull('pickup_city')
            ->groupBy('pickup_city')
            ->orderByDesc('count')
            ->limit(10)
            ->get();

        // Category breakdown
        $categoryBreakdown = Errand::select('category', DB::raw('COUNT(*) as count'))
            ->groupBy('category')
            ->orderByDesc('count')
            ->get();

        return response()->json([
            'errand_volume' => $errandVolume,
            'revenue' => $revenue,
            'user_growth' => $userGrowth,
            'top_locations' => $topLocations,
            'category_breakdown' => $categoryBreakdown,
        ]);
    }

    public function liveMap(Request $request): JsonResponse
    {
        // All online runners with current locations
        $runners = RunnerProfile::with('user:id,first_name,last_name,profile_image')
            ->where('is_online', true)
            ->whereNotNull('current_latitude')
            ->whereNotNull('current_longitude')
            ->get(['user_id', 'current_latitude', 'current_longitude', 'trust_score', 'is_available', 'location_updated_at']);

        // All active errands
        $activeErrands = Errand::with([
            'customer:id,first_name,last_name',
            'runner:id,first_name,last_name',
        ])
        ->whereIn('status', [
            Errand::STATUS_ACCEPTED,
            Errand::STATUS_RUNNER_EN_ROUTE,
            Errand::STATUS_ITEM_PICKED,
            Errand::STATUS_IN_PROGRESS,
        ])
        ->get([
            'id', 'title', 'status', 'customer_id', 'runner_id',
            'pickup_latitude', 'pickup_longitude',
            'destination_latitude', 'destination_longitude',
        ]);

        // Active panics
        $activePanics = PanicEvent::with([
            'errand:id,title',
            'triggeredBy:id,first_name,last_name',
        ])
        ->where('status', PanicEvent::STATUS_ACTIVE)
        ->get();

        return response()->json([
            'runners' => $runners,
            'active_errands' => $activeErrands,
            'active_panics' => $activePanics,
            'timestamp' => now()->toIso8601String(),
        ]);
    }
}
