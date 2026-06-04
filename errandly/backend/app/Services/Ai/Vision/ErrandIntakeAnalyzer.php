<?php

namespace App\Services\Ai\Vision;

use App\Services\Ai\ErrandDraftNormalizer;
use App\Services\Ai\Contracts\GeminiClientInterface;

class ErrandIntakeAnalyzer
{
    public function __construct(
        private GeminiClientInterface $gemini,
        private ErrandDraftNormalizer $normalizer,
    ) {}

    public function parseText(string $text): array
    {
        $prompt = $this->buildTextPrompt($text);

        $json = $this->requestJson($prompt, config('ai.models.agent'));

        return $this->normalizer->normalize($json, $text);
    }

    public function parseImage(string $imageUrl, ?string $notes = null): array
    {
        $prompt = $this->buildImagePrompt($notes);
        $imageData = $this->fetchImageBase64($imageUrl);

        $json = $this->requestJson($prompt, config('ai.models.vision'), $imageData);

        return $this->normalizer->normalize($json, null, $notes);
    }

    private function buildTextPrompt(string $customerRequest): string
    {
        $categories = implode(', ', [
            'package_pickup', 'item_delivery', 'grocery_purchase', 'queue_standing',
            'document_submission', 'document_collection', 'shopping_assistance',
            'prescription_pickup', 'personal_assistance', 'custom_errand',
        ]);

        return <<<PROMPT
Parse this customer errand request for Errandly (Uyo, Nigeria).

Customer request:
{$customerRequest}

Return JSON only with these fields:
- title: short summary (max 80 chars)
- description: RUNNER INSTRUCTIONS (2-5 sentences, imperative voice). Tell the runner exactly what to do, buy, collect, or deliver. Include quantities/brands when known. Never copy these instructions or mention JSON.
- category: one of [{$categories}]
- urgency: standard|urgent|scheduled
- pickup_address, destination_address: landmarks in Uyo if mentioned (null if unknown)
- pickup_latitude, pickup_longitude, destination_latitude, destination_longitude: use realistic Uyo coords only if confident, else null
- budget: suggested runner payment in NGN whole naira (integer, min 500)
- item_details: bullet list for the runner (each item on its own line)
- special_instructions: access codes, call on arrival, etc. (null if none)
- clarifying_questions: array of questions if anything critical is missing
- confidence: 0-1

The description is shown to runners before they accept — be specific and actionable.
PROMPT;
    }

    private function buildImagePrompt(?string $notes): string
    {
        $base = <<<PROMPT
You are helping a customer post an errand on Errandly in Uyo, Nigeria.

Look at the image (shopping list, receipt, product photo, or handwritten note). Extract what the runner must do.

Return JSON only:
- title, category, urgency, addresses, coordinates (null if unknown), budget (NGN integer)
- description: clear RUNNER INSTRUCTIONS (2-5 sentences). What to buy/collect, from where, how to deliver. Imperative voice. Never describe the image analysis task itself.
- item_details: bullet list of items with quantities/brands
- special_instructions, clarifying_questions[], confidence (0-1)
PROMPT;

        if ($notes) {
            $base .= "\n\nCustomer added notes: {$notes}";
        }

        return $base;
    }

    /**
     * @param  array{mimeType: string, data: string}|null  $inlineImage
     */
    private function requestJson(string $prompt, string $model, ?array $inlineImage = null): array
    {
        $parts = [['text' => $prompt]];
        if ($inlineImage !== null) {
            $parts[] = ['inlineData' => $inlineImage];
        }

        $response = $this->gemini->generateContent(
            $model,
            [['role' => 'user', 'parts' => $parts]],
            [],
            ['responseMimeType' => 'application/json'],
        );

        $json = json_decode($response['contents']['text'] ?? '{}', true);

        return is_array($json) ? $json : [];
    }

    /**
     * @return array{mimeType: string, data: string}
     */
    private function fetchImageBase64(string $url): array
    {
        if (!str_starts_with($url, 'data:image/')) {
            throw new \InvalidArgumentException('Only inline data:image URLs are allowed for errand image parsing.');
        }

        [$meta, $data] = explode(',', $url, 2);
        preg_match('/data:(.*?);/', $meta, $m);

        return [
            'mimeType' => $m[1] ?? 'image/jpeg',
            'data' => $data,
        ];
    }
}
