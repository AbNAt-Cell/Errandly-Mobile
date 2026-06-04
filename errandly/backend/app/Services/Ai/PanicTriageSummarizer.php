<?php

namespace App\Services\Ai;

use App\Models\AiVisionAnalysis;
use App\Models\PanicEvent;
use App\Services\Ai\Contracts\GeminiClientInterface;

class PanicTriageSummarizer
{
    public function __construct(
        private GeminiClientInterface $gemini,
    ) {}

    public function summarize(PanicEvent $event): AiVisionAnalysis
    {
        $event->load(['errand.customer:id,first_name,last_name,phone', 'errand.runner:id,first_name,last_name,phone', 'triggeredBy:id,first_name,last_name']);

        $context = json_encode([
            'panic_id' => $event->id,
            'notes' => $event->notes,
            'location' => ['lat' => $event->latitude, 'lng' => $event->longitude],
            'errand' => $event->errand?->only(['public_id', 'title', 'status', 'pickup_address', 'destination_address']),
            'triggered_by' => $event->triggeredBy?->only(['id', 'first_name', 'last_name']),
        ], JSON_PRETTY_PRINT);

        $prompt = <<<TEXT
Triage an Errandly PANIC / safety alert for admin dispatch in Uyo, Nigeria.
Return JSON only:
{
  "urgency": "critical|high|standard",
  "immediate_actions": ["string"],
  "situation_summary": "string",
  "parties_to_contact": ["customer|runner|both|authorities"],
  "escalation_notes": "string"
}
Do not auto-resolve — support human emergency protocol.

CONTEXT:
{$context}
TEXT;

        $response = $this->gemini->generateContent(
            config('ai.models.agent'),
            [['role' => 'user', 'parts' => [['text' => $prompt]]]],
            [],
            ['responseMimeType' => 'application/json'],
        );

        $result = json_decode($response['contents']['text'] ?? '{}', true) ?: [];

        return AiVisionAnalysis::updateOrCreate(
            [
                'subject_type' => 'panic_event',
                'subject_id' => (string) $event->id,
            ],
            [
                'model' => config('ai.models.agent'),
                'result' => $result,
                'flags' => $result['immediate_actions'] ?? [],
            ],
        );
    }
}
