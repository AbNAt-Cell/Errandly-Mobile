<?php

namespace App\Services\Ai\Vision;

use App\Models\AiVisionAnalysis;
use App\Models\Errand;
use App\Models\ProofSubmission;
use App\Services\Ai\Contracts\GeminiClientInterface;

class ProofAnalyzer
{
    public function __construct(
        private GeminiClientInterface $gemini,
    ) {}

    public function analyze(ProofSubmission $proof): AiVisionAnalysis
    {
        $errand = $proof->errand ?? Errand::find($proof->errand_id);

        $prompt = <<<TEXT
Analyze proof-of-errand for Errandly. Errand: {$errand->title}. Description: {$errand->description}.
Category: {$errand->category}. Budget kobo: {$errand->budget}.
Return JSON with relevance_score (0-1), matches_errand_description (bool), receipt_detected (bool),
receipt_total_ngn (int|null), flags (array of {code, severity, detail}), summary (string).
TEXT;

        $parts = [['text' => $prompt]];
        if ($proof->file_url) {
            $parts[] = ['inlineData' => $this->inlineFromUrl($proof->file_url)];
        }

        $response = $this->gemini->generateContent(
            config('ai.models.vision'),
            [['role' => 'user', 'parts' => $parts]],
            [],
            ['responseMimeType' => 'application/json'],
        );

        $result = json_decode($response['contents']['text'] ?? '{}', true) ?: [];

        return AiVisionAnalysis::updateOrCreate(
            [
                'subject_type' => 'proof_submission',
                'subject_id' => (string) $proof->id,
            ],
            [
                'model' => config('ai.models.vision'),
                'result' => $result,
                'flags' => $result['flags'] ?? [],
            ],
        );
    }

    /**
     * @return array{mimeType: string, data: string}
     */
    private function inlineFromUrl(string $url): array
    {
        $bytes = @file_get_contents($url);
        if ($bytes === false) {
            return ['mimeType' => 'image/jpeg', 'data' => ''];
        }
        $finfo = new \finfo(FILEINFO_MIME_TYPE);

        return [
            'mimeType' => $finfo->buffer($bytes) ?: 'image/jpeg',
            'data' => base64_encode($bytes),
        ];
    }
}
