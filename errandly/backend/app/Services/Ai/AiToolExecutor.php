<?php

namespace App\Services\Ai;

use App\Http\Controllers\Concerns\AuthorizesErrandAccess;
use App\Models\Dispute;
use App\Models\Errand;
use App\Models\User;
use App\Services\Ai\Vision\ErrandIntakeAnalyzer;
use App\Services\ErrandService;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Facades\Validator;
use InvalidArgumentException;

class AiToolExecutor
{
    use AuthorizesErrandAccess;

    public function __construct(
        private AiToolRegistry $registry,
        private PolicySearchService $policySearch,
        private AiProposalService $proposals,
        private ErrandIntakeAnalyzer $errandIntake,
        private ErrandService $errandService,
        private BudgetEtaSuggester $budgetEta,
        private AddressNormalizer $addressNormalizer,
        private ErrandTemplateSuggester $templateSuggester,
        private TrustScoreExplainer $trustExplainer,
        private DisputeSummarizer $disputeSummarizer,
    ) {}

    public function execute(User $user, string $name, array $args): array
    {
        if (!$this->registry->allows($user, $name)) {
            return $this->fail('FORBIDDEN', 'Tool not available for your account.');
        }

        $tier = $this->registry->tier($name);
        if ($tier === ToolTier::ConfirmWrite) {
            return $this->fail('CONFIRMATION_REQUIRED', 'Use the confirm endpoint for this action.');
        }

        try {
            $data = match ($name) {
                'get_me' => $this->getMe($user),
                'get_my_errands' => $this->getMyErrands($user, $args),
                'get_errand' => $this->getErrand($user, $args),
                'search_policy' => $this->searchPolicy($user, $args),
                'parse_errand_from_text' => $this->parseErrandFromText($user, $args),
                'propose_create_errand' => $this->proposeCreateErrand($user, $args),
                'propose_cancel_errand' => $this->proposeCancelErrand($user, $args),
                'suggest_budget_and_eta' => $this->suggestBudgetAndEta($user, $args),
                'normalize_address' => $this->normalizeAddress($user, $args),
                'suggest_errand_template' => $this->suggestErrandTemplate($user, $args),
                'explain_trust_score' => $this->explainTrustScore($user),
                'list_available_errands' => $this->listAvailableErrands($user, $args),
                'summarize_dispute' => $this->summarizeDispute($user, $args),
                'admin_report_errands' => $this->adminReportErrands($user, $args),
                default => throw new InvalidArgumentException("Unknown tool: {$name}"),
            };

            return $this->ok($data);
        } catch (ModelNotFoundException) {
            return $this->fail('NOT_FOUND', 'Resource not found.');
        } catch (InvalidArgumentException $e) {
            return $this->fail('VALIDATION_ERROR', $e->getMessage());
        }
    }

    private function getMe(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->full_name,
            'email' => $user->email,
            'roles' => $user->getRoleNames()->values()->all(),
            'kyc_status' => $user->kyc_status,
        ];
    }

    private function getMyErrands(User $user, array $args): array
    {
        $limit = min((int) ($args['limit'] ?? 10), 20);
        $query = $user->hasRole('runner')
            ? Errand::where('runner_id', $user->id)
            : Errand::where('customer_id', $user->id);

        if (!empty($args['status'])) {
            $query->where('status', $args['status']);
        }

        return [
            'errands' => $query->orderByDesc('created_at')->limit($limit)->get([
                'public_id', 'title', 'status', 'budget', 'created_at',
            ]),
        ];
    }

    private function getErrand(User $user, array $args): array
    {
        $errand = Errand::where('public_id', $args['public_id'])->firstOrFail();
        $this->authorizeErrandView($user, $errand);

        return ['errand' => $errand->only([
            'public_id', 'title', 'description', 'status', 'category', 'budget',
            'pickup_address', 'destination_address', 'payment_status',
        ])];
    }

    private function searchPolicy(User $user, array $args): array
    {
        $roles = $user->getRoleNames()->all();
        $chunks = $this->policySearch->search(
            $args['query'],
            (int) ($args['limit'] ?? 5),
            $roles,
        );

        return ['chunks' => $chunks];
    }

    private function parseErrandFromText(User $user, array $args): array
    {
        if (!$user->isKycApproved()) {
            throw new InvalidArgumentException('Complete identity verification before posting errands.');
        }

        return ['draft' => $this->errandIntake->parseText($args['text'])];
    }

    private function proposeCreateErrand(User $user, array $args): array
    {
        if (!$user->isKycApproved()) {
            throw new InvalidArgumentException('Complete identity verification before posting errands.');
        }

        $validated = Validator::make($args, [
            'title' => 'required|string|max:200',
            'description' => 'required|string|max:2000',
            'category' => 'required|string',
            'pickup_address' => 'required|string',
            'pickup_latitude' => 'required|numeric',
            'pickup_longitude' => 'required|numeric',
            'destination_address' => 'required|string',
            'destination_latitude' => 'required|numeric',
            'destination_longitude' => 'required|numeric',
            'budget' => 'required|integer|min:' . config('errandly.min_errand_amount', 500),
            'urgency' => 'nullable|string',
            'item_details' => 'nullable|string',
            'special_instructions' => 'nullable|string',
        ])->validate();

        $platformFee = (int) ceil($validated['budget'] * (config('errandly.commission_rate', 0.15)));
        $result = $this->proposals->createWithToken($user, 'create_errand', $validated);

        return [
            'proposal_id' => $result['proposal']->id,
            'confirmation_token' => $result['confirmation_token'],
            'expires_at' => $result['proposal']->expires_at->toIso8601String(),
            'estimated_total_kobo' => $validated['budget'] + $platformFee,
            'summary' => $validated['title'],
        ];
    }

    private function proposeCancelErrand(User $user, array $args): array
    {
        $errand = Errand::where('public_id', $args['public_id'])->firstOrFail();

        if ($user->hasRole('customer')) {
            $this->authorizeErrandCustomer($user, $errand);
        } elseif ($user->hasRole('runner')) {
            $this->authorizeErrandRunner($user, $errand);
        } else {
            abort(404);
        }

        $result = $this->proposals->createWithToken($user, 'cancel_errand', [
            'public_id' => $errand->public_id,
            'reason' => $args['reason'],
        ]);

        return [
            'proposal_id' => $result['proposal']->id,
            'confirmation_token' => $result['confirmation_token'],
            'expires_at' => $result['proposal']->expires_at->toIso8601String(),
            'errand_public_id' => $errand->public_id,
        ];
    }

    public function executeProposal(User $user, string $proposalId, string $plainToken): array
    {
        $proposal = $this->proposals->consume($user, $proposalId, $plainToken);

        return match ($proposal->type) {
            'create_errand' => $this->executeCreateErrand($user, $proposal->payload, $proposal),
            'cancel_errand' => $this->executeCancelErrand($user, $proposal->payload, $proposal),
            default => throw new InvalidArgumentException('Unsupported proposal type.'),
        };
    }

    private function executeCreateErrand(User $user, array $payload, $proposal): array
    {
        $errand = $this->errandService->createErrand($user, $payload);
        $proposal->update([
            'executed_reference' => $errand->public_id,
            'status' => 'confirmed',
        ]);

        return [
            'type' => 'create_errand',
            'errand' => $errand->only(['public_id', 'title', 'status', 'budget']),
            'message' => 'Errand posted successfully.',
        ];
    }

    private function executeCancelErrand(User $user, array $payload, $proposal): array
    {
        $errand = Errand::where('public_id', $payload['public_id'])->firstOrFail();

        if ($user->hasRole('customer')) {
            $errand = $this->errandService->cancelByCustomer($user, $errand, $payload['reason']);
        } else {
            $errand = $this->errandService->cancelByRunner($user, $errand, $payload['reason']);
        }

        $proposal->update(['executed_reference' => $errand->public_id]);

        return [
            'type' => 'cancel_errand',
            'errand' => $errand->only(['public_id', 'status']),
            'message' => 'Errand cancelled.',
        ];
    }

    private function suggestBudgetAndEta(User $user, array $args): array
    {
        return $this->budgetEta->suggest(
            $args['category'],
            (float) $args['pickup_latitude'],
            (float) $args['pickup_longitude'],
            (float) $args['destination_latitude'],
            (float) $args['destination_longitude'],
            $args['urgency'] ?? Errand::URGENCY_STANDARD,
        );
    }

    private function normalizeAddress(User $user, array $args): array
    {
        return $this->addressNormalizer->normalize(
            $args['free_text'],
            $args['city'] ?? $user->city ?? 'Uyo',
        );
    }

    private function suggestErrandTemplate(User $user, array $args): array
    {
        return $this->templateSuggester->suggest($user, $args['hint'] ?? null);
    }

    private function explainTrustScore(User $user): array
    {
        return $this->trustExplainer->explain($user);
    }

    private function listAvailableErrands(User $user, array $args): array
    {
        $profile = $user->runnerProfile;
        if (!$profile || !$profile->current_latitude) {
            throw new InvalidArgumentException('Update your location to see nearby errands.');
        }

        $limit = min((int) ($args['limit'] ?? 10), 20);
        $errands = Errand::whereIn('status', [Errand::STATUS_POSTED, Errand::STATUS_PENDING_ASSIGNMENT])
            ->orderByDesc('created_at')
            ->limit($limit)
            ->get(['public_id', 'title', 'category', 'budget', 'pickup_address', 'status']);

        return ['errands' => $errands];
    }

    private function summarizeDispute(User $user, array $args): array
    {
        $dispute = Dispute::findOrFail((int) $args['dispute_id']);
        $analysis = $this->disputeSummarizer->summarize($dispute);

        return ['analysis' => $analysis->result];
    }

    private function adminReportErrands(User $user, array $args): array
    {
        $period = $args['period'] ?? '30days';
        $days = match ($period) {
            '7days' => 7, '90days' => 90, '365days' => 365, default => 30,
        };

        return [
            'period' => $period,
            'total' => Errand::where('created_at', '>=', now()->subDays($days))->count(),
            'completed' => Errand::where('status', Errand::STATUS_COMPLETED)
                ->where('completed_at', '>=', now()->subDays($days))->count(),
            'cancelled' => Errand::where('status', Errand::STATUS_CANCELLED)
                ->where('cancelled_at', '>=', now()->subDays($days))->count(),
            'avg_budget' => (int) (Errand::where('created_at', '>=', now()->subDays($days))->avg('budget') ?? 0),
        ];
    }

    private function ok(mixed $data): array
    {
        return ['ok' => true, 'data' => $data];
    }

    private function fail(string $code, string $message): array
    {
        return ['ok' => false, 'error_code' => $code, 'message' => $message];
    }
}
