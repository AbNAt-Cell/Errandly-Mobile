<?php

namespace App\Services\Ai;

use App\Models\AiFraudSignal;
use App\Models\Errand;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class FraudSignalAggregator
{
    /**
     * Run heuristic fraud checks and persist open signals.
     */
    public function aggregate(): int
    {
        $created = 0;
        $created += $this->detectRepeatDyads();
        $created += $this->detectRapidWithdrawPatterns();

        return $created;
    }

    private function detectRepeatDyads(): int
    {
        $pairs = Errand::query()
            ->select('customer_id', 'runner_id', DB::raw('COUNT(*) as cnt'))
            ->where('status', Errand::STATUS_COMPLETED)
            ->whereNotNull('runner_id')
            ->where('completed_at', '>=', now()->subDays(30))
            ->groupBy('customer_id', 'runner_id')
            ->havingRaw('COUNT(*) >= 8')
            ->get();

        $created = 0;
        foreach ($pairs as $pair) {
            $subjectId = "{$pair->customer_id}:{$pair->runner_id}";
            $exists = AiFraudSignal::where('signal_type', 'repeat_dyad')
                ->where('subject_id', $subjectId)
                ->where('status', AiFraudSignal::STATUS_OPEN)
                ->exists();

            if ($exists) {
                continue;
            }

            AiFraudSignal::create([
                'signal_type' => 'repeat_dyad',
                'subject_type' => 'user_pair',
                'subject_id' => $subjectId,
                'severity' => 'medium',
                'status' => AiFraudSignal::STATUS_OPEN,
                'evidence' => [
                    'customer_id' => $pair->customer_id,
                    'runner_id' => $pair->runner_id,
                    'completed_count' => $pair->cnt,
                ],
                'summary' => "Customer #{$pair->customer_id} and runner #{$pair->runner_id} completed {$pair->cnt} errands together in 30 days.",
            ]);
            $created++;
        }

        return $created;
    }

    private function detectRapidWithdrawPatterns(): int
    {
        return 0;
    }
}
