<?php

namespace App\Services\Ai\Vision;

use App\Models\AiVisionAnalysis;
use App\Models\KycDocument;
use App\Services\Ai\Contracts\GeminiClientInterface;

class KycDocumentAnalyzer
{
    public function __construct(
        private GeminiClientInterface $gemini,
    ) {}

    public function analyze(KycDocument $kyc): AiVisionAnalysis
    {
        $prompt = <<<'TEXT'
Analyze KYC submission for Errandly runner onboarding in Nigeria.
Return JSON: document_quality, face_match_score (0-1 if selfie+ID compared), id_extracted (masked id_number),
flags (array), recommendation (review|likely_approve|likely_reject), officer_summary.
Do not include full NIN/BVN in output — mask identifiers.
TEXT;

        $parts = [['text' => $prompt]];
        foreach (['id_document_url', 'selfie_url', 'live_photo_url'] as $field) {
            if (!empty($kyc->{$field})) {
                $parts[] = ['inlineData' => $this->inlineFromUrl($kyc->{$field})];
            }
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
                'subject_type' => 'kyc_document',
                'subject_id' => (string) $kyc->id,
            ],
            [
                'model' => config('ai.models.vision'),
                'result' => $result,
                'flags' => $result['flags'] ?? [],
            ],
        );
    }

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
