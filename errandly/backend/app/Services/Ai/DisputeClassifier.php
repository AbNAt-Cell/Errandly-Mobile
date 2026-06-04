<?php

namespace App\Services\Ai;

use App\Models\AiVisionAnalysis;
use App\Models\Dispute;
use App\Services\Ai\Contracts\GeminiClientInterface;

class DisputeClassifier
{
    public function __construct(
        private GeminiClientInterface $gemini,
    ) {}

    public function classify(Dispute $dispute): AiVisionAnalysis
    {
        $prompt = <<<TEXT
Classify this Errandly dispute for routing priority.
User-selected type: {$dispute->type}
Description: {$dispute->description}

Return JSON only:
{
  "consistent_type": true,
  "suggested_type": "{$dispute->type}",
  "priority": "normal|urgent",
  "tags": [],
  "routing_note": "..."
}
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
                'subject_type' => 'dispute_classification',
                'subject_id' => (string) $dispute->id,
            ],
            [
                'model' => config('ai.models.agent'),
                'result' => $result,
                'flags' => $result['tags'] ?? [],
            ],
        );
    }
}
