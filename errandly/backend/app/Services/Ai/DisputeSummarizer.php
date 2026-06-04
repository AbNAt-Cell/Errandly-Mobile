<?php

namespace App\Services\Ai;

use App\Models\AiVisionAnalysis;
use App\Models\Dispute;
use App\Services\Ai\Contracts\GeminiClientInterface;

class DisputeSummarizer
{
    public function __construct(
        private GeminiClientInterface $gemini,
    ) {}

    public function summarize(Dispute $dispute): AiVisionAnalysis
    {
        $dispute->load([
            'errand.customer:id,first_name,last_name',
            'errand.runner:id,first_name,last_name',
            'errand.messages.sender:id,first_name,last_name',
            'errand.proofSubmissions',
            'errand.trackingLogs',
            'errand.statusHistory',
            'raisedBy:id,first_name,last_name',
            'evidenceFiles',
            'messages.sender:id,first_name,last_name',
        ]);

        $context = $this->buildContext($dispute);

        $response = $this->gemini->generateContent(
            config('ai.models.agent'),
            [
                [
                    'role' => 'user',
                    'parts' => [['text' => $context]],
                ],
            ],
            [],
            ['responseMimeType' => 'application/json'],
        );

        $result = json_decode($response['contents']['text'] ?? '{}', true) ?: [];

        return AiVisionAnalysis::updateOrCreate(
            [
                'subject_type' => 'dispute',
                'subject_id' => (string) $dispute->id,
            ],
            [
                'model' => config('ai.models.agent'),
                'result' => $result,
                'flags' => $result['key_evidence'] ?? [],
            ],
        );
    }

    private function buildContext(Dispute $dispute): string
    {
        $errand = $dispute->errand;
        $messages = $errand?->messages?->map(fn ($m) => [
            'from' => $m->sender?->first_name,
            'body' => mb_substr($m->content ?? '', 0, 500),
            'at' => $m->created_at?->toIso8601String(),
        ])->values()->all() ?? [];

        $proofAnalyses = AiVisionAnalysis::where('subject_type', 'proof_submission')
            ->whereIn('subject_id', $errand?->proofSubmissions?->pluck('id')->map(fn ($id) => (string) $id) ?? [])
            ->get()
            ->map(fn ($a) => $a->result)
            ->all();

        $payload = [
            'dispute' => [
                'id' => $dispute->id,
                'type' => $dispute->type,
                'status' => $dispute->status,
                'description' => $dispute->description,
                'raised_by' => $dispute->raisedBy?->only(['id', 'first_name', 'last_name']),
            ],
            'errand' => $errand?->only([
                'public_id', 'title', 'description', 'status', 'category', 'budget', 'payment_status',
            ]),
            'status_timeline' => $errand?->statusHistory?->map(fn ($h) => [
                'from' => $h->from_status,
                'to' => $h->to_status,
                'at' => $h->created_at?->toIso8601String(),
            ])->values()->all(),
            'chat_messages' => $messages,
            'proof_submissions' => $errand?->proofSubmissions?->map->only(['id', 'type', 'notes', 'submitted_at'])->all(),
            'proof_ai_analyses' => $proofAnalyses,
            'tracking_summary' => [
                'points' => $errand?->trackingLogs?->count() ?? 0,
            ],
            'dispute_evidence' => $dispute->evidenceFiles?->map->only(['type', 'description', 'url'])->all(),
        ];

        $json = json_encode($payload, JSON_PRETTY_PRINT);

        return <<<TEXT
You are an Errandly dispute resolution assistant for admins in Nigeria.
Analyze the dispute context below and return JSON only with:
timeline_summary (array of strings), customer_claim, runner_claim,
key_evidence (array of {source, citation}), suggested_resolution (refund|partial_refund|release|no_action),
suggested_partial_percent (integer|null), confidence (0-1), questions_for_admin (array of strings).
Do not decide final outcome — support human officers only.

CONTEXT:
{$json}
TEXT;
    }
}
