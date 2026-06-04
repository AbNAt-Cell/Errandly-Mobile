<?php

namespace App\Services\Ai;

use App\Services\Ai\Contracts\GeminiClientInterface;

class AddressNormalizer
{
    public function __construct(
        private GeminiClientInterface $gemini,
    ) {}

    /**
     * @return array{candidates: array<int, array{label: string, latitude: float, longitude: float, confidence: float}>, city: string}
     */
    public function normalize(string $freeText, string $city = 'Uyo'): array
    {
        $freeText = trim($freeText);
        if ($freeText === '') {
            return ['candidates' => [], 'city' => $city];
        }

        $prompt = <<<TEXT
Normalize this address or landmark in {$city}, Akwa Ibom, Nigeria for a delivery app.
Input: {$freeText}

Return JSON only:
{
  "candidates": [
    {"label": "full address string", "latitude": 5.0379, "longitude": 7.9228, "confidence": 0.9}
  ]
}
Provide 1-3 candidates. Use realistic coordinates in Uyo metro area.
TEXT;

        $response = $this->gemini->generateContent(
            config('ai.models.agent'),
            [['role' => 'user', 'parts' => [['text' => $prompt]]]],
            [],
            ['responseMimeType' => 'application/json'],
        );

        $json = json_decode($response['contents']['text'] ?? '{}', true);

        return [
            'candidates' => $json['candidates'] ?? [],
            'city' => $city,
        ];
    }
}
