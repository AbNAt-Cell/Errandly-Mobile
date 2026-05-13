<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Errand;
use App\Models\User;
use App\Models\WalletTransaction;
use App\Models\PanicEvent;
use App\Models\Dispute;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class AdminReportController extends Controller
{
    public function revenue(Request $request): JsonResponse
    {
        $period = $request->get('period', '30days');
        $days = match($period) { '7days' => 7, '30days' => 30, '90days' => 90, '365days' => 365, default => 30 };

        $revenue = WalletTransaction::select(
            DB::raw('DATE(created_at) as date'),
            DB::raw('SUM(amount) as revenue'),
            DB::raw('COUNT(*) as transactions'),
        )
        ->where('type', 'commission')
        ->where('direction', 'credit')
        ->where('created_at', '>=', now()->subDays($days))
        ->groupBy('date')
        ->orderBy('date')
        ->get();

        $total = WalletTransaction::where('type', 'commission')->where('direction', 'credit')
            ->where('created_at', '>=', now()->subDays($days))->sum('amount');

        return response()->json(['data' => $revenue, 'total' => $total, 'period' => $period]);
    }

    public function errands(Request $request): JsonResponse
    {
        $period = $request->get('period', '30days');
        $days = match($period) { '7days' => 7, '30days' => 30, '90days' => 90, default => 30 };

        $stats = [
            'total' => Errand::where('created_at', '>=', now()->subDays($days))->count(),
            'completed' => Errand::where('status', Errand::STATUS_COMPLETED)->where('completed_at', '>=', now()->subDays($days))->count(),
            'cancelled' => Errand::where('status', Errand::STATUS_CANCELLED)->where('cancelled_at', '>=', now()->subDays($days))->count(),
            'disputed' => Errand::where('status', Errand::STATUS_DISPUTED)->where('created_at', '>=', now()->subDays($days))->count(),
            'avg_budget' => Errand::where('created_at', '>=', now()->subDays($days))->avg('budget'),
            'by_category' => Errand::select('category', DB::raw('COUNT(*) as count'))
                ->where('created_at', '>=', now()->subDays($days))
                ->groupBy('category')->get(),
            'by_city' => Errand::select('pickup_city', DB::raw('COUNT(*) as count'))
                ->where('created_at', '>=', now()->subDays($days))
                ->whereNotNull('pickup_city')
                ->groupBy('pickup_city')
                ->orderByDesc('count')
                ->limit(10)->get(),
            'completion_rate' => function () use ($days) {
                $total = Errand::where('created_at', '>=', now()->subDays($days))->count();
                $completed = Errand::where('status', Errand::STATUS_COMPLETED)->where('created_at', '>=', now()->subDays($days))->count();
                return $total > 0 ? round(($completed / $total) * 100, 1) : 0;
            },
        ];

        // Evaluate the closure
        $stats['completion_rate'] = $stats['completion_rate']();

        return response()->json($stats);
    }

    public function users(Request $request): JsonResponse
    {
        $period = $request->get('period', '30days');
        $days = match($period) { '7days' => 7, '30days' => 30, '90days' => 90, default => 30 };

        $growth = User::select(DB::raw('DATE(created_at) as date'), DB::raw('COUNT(*) as total'))
            ->where('created_at', '>=', now()->subDays($days))
            ->groupBy('date')->orderBy('date')->get();

        return response()->json([
            'growth' => $growth,
            'total_customers' => User::role('customer')->count(),
            'total_runners' => User::role('runner')->count(),
            'active_customers' => User::role('customer')->where('status', 'active')->count(),
            'verified_runners' => User::role('runner')->whereHas('runnerProfile', fn($q) => $q->where('verification_status', 'approved'))->count(),
        ]);
    }

    public function incidents(Request $request): JsonResponse
    {
        return response()->json([
            'active_panics' => PanicEvent::with(['errand:id,title', 'triggeredBy:id,first_name,last_name'])
                ->where('status', PanicEvent::STATUS_ACTIVE)->get(),
            'recent_panics' => PanicEvent::with(['errand:id,title', 'triggeredBy:id,first_name,last_name'])
                ->where('created_at', '>=', now()->subDays(30))
                ->orderBy('created_at', 'desc')->limit(20)->get(),
            'total_incidents' => PanicEvent::count(),
        ]);
    }

    public function fraud(Request $request): JsonResponse
    {
        return response()->json([
            'multiple_cancellations' => \App\Models\RunnerProfile::where('cancelled_errands', '>', 5)->with('user:id,first_name,last_name,phone')->limit(20)->get(),
            'open_disputes' => Dispute::with(['errand:id,title', 'raisedBy:id,first_name,last_name'])->where('status', Dispute::STATUS_OPEN)->get(),
            'low_trust_runners' => \App\Models\RunnerProfile::where('trust_score', '<', 40)->with('user:id,first_name,last_name,phone')->limit(20)->get(),
        ]);
    }

    public function export(Request $request): JsonResponse
    {
        $request->validate(['type' => 'required|in:revenue,errands,users', 'period' => 'nullable|string']);

        // In production: generate CSV/Excel and return download URL
        return response()->json(['message' => 'Export queued. Download link will be sent to your email.']);
    }
}
