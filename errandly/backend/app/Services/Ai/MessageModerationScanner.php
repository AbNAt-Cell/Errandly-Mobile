<?php

namespace App\Services\Ai;

use App\Models\AiVisionAnalysis;
use App\Models\Message;
use App\Services\Ai\Contracts\GeminiClientInterface;

class MessageModerationScanner
{
    public function __construct(
        private GeminiClientInterface $gemini,
    ) {}

    public function scan(Message $message): AiVisionAnalysis
    {
        $text = trim($message->content ?? '');
        if ($text === '' && $message->type === Message::TYPE_VOICE) {
            $text = '[voice message — moderate if transcript available]';
        }

        $prompt = <<<TEXT
Moderate marketplace chat for Errandly (Uyo, Nigeria). Flag off-platform payment, harassment, scams, personal contact solicitation.
Message type: {$message->type}
Content: {$text}

Return JSON only:
{"severity":"none|low|medium|high","categories":[],"action":"none|flag|urgent_flag","summary":"..."}
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
                'subject_type' => 'message',
                'subject_id' => (string) $message->id,
            ],
            [
                'model' => config('ai.models.agent'),
                'result' => $result,
                'flags' => $result['categories'] ?? [],
            ],
        );
    }
}
