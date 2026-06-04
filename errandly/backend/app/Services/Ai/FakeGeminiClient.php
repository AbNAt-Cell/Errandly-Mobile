<?php

namespace App\Services\Ai;

use App\Services\Ai\Contracts\GeminiClientInterface;

/**
 * Deterministic Gemini stub for tests and local dev without API keys.
 */
class FakeGeminiClient implements GeminiClientInterface
{
    public function generateContent(
        string $model,
        array $contents,
        array $tools = [],
        ?array $generationConfig = null,
    ): array {
        $lastUserText = $this->extractLastUserText($contents);

        if ($generationConfig !== null && ($generationConfig['responseMimeType'] ?? null) === 'application/json') {
            return $this->jsonGenerationResponse($lastUserText, $model);
        }

        foreach ($contents as $content) {
            foreach ($content['parts'] ?? [] as $part) {
                if (isset($part['functionResponse'])) {
                    $name = $part['functionResponse']['name'] ?? '';
                    if ($name === 'get_my_errands') {
                        return $this->wrapResponse($model, 'You have errands in the system. Check the app for live status.');
                    }
                    if ($name === 'search_policy') {
                        return $this->wrapResponse($model, 'Funds stay in escrow until you confirm delivery with your OTP.');
                    }
                    if ($name === 'parse_errand_from_text') {
                        return $this->wrapResponse($model, 'I parsed your errand draft. Review the fields and confirm when ready.');
                    }
                }
            }
        }

        if (str_contains(strtolower($lastUserText), 'list my errands') || str_contains(strtolower($lastUserText), 'my errands')) {
            return $this->wrapResponse($model, '', [
                ['name' => 'get_my_errands', 'args' => ['limit' => 5]],
            ]);
        }

        if (str_contains(strtolower($lastUserText), 'escrow') || str_contains(strtolower($lastUserText), 'refund')) {
            return $this->wrapResponse($model, '', [
                ['name' => 'search_policy', 'args' => ['query' => 'escrow refund cancellation']],
            ]);
        }

        $errandIntent = str_contains(strtolower($lastUserText), 'buy ')
            || str_contains(strtolower($lastUserText), 'pick up')
            || str_contains(strtolower($lastUserText), 'deliver')
            || str_contains(strtolower($lastUserText), 'shoprite')
            || str_contains(strtolower($lastUserText), 'grocery')
            || str_contains(strtolower($lastUserText), 'errand');

        if ($errandIntent) {
            return $this->wrapResponse($model, 'Here is a draft for your errand — review the form and edit anything before posting.', [
                ['name' => 'parse_errand_from_text', 'args' => ['text' => $lastUserText]],
            ]);
        }

        return $this->wrapResponse($model, 'I am the Errandly assistant (test mode). Ask about your errands, policies, or posting a task.');
    }

    public function embedContent(string $text, ?string $model = null): array
    {
        $hash = crc32(mb_strtolower(trim($text)));
        $dims = 16;
        $vector = [];
        for ($i = 0; $i < $dims; $i++) {
            $vector[] = (($hash >> ($i % 16)) & 0xFF) / 255.0 - 0.5;
        }

        return $vector;
    }

    private function jsonGenerationResponse(string $text, string $model): array
    {
        if (str_contains(strtolower($text), 'moderate marketplace chat')) {
            return [
                'raw' => [],
                'contents' => ['text' => json_encode([
                    'severity' => 'none',
                    'categories' => [],
                    'action' => 'none',
                    'summary' => 'No policy violations detected (test mode).',
                ])],
                'model' => $model,
                'usage' => ['latency_ms' => 1, 'prompt_tokens' => 10, 'output_tokens' => 20],
            ];
        }

        if (str_contains(strtolower($text), 'panic / safety alert') || str_contains(strtolower($text), 'triage an errandly panic')) {
            return [
                'raw' => [],
                'contents' => ['text' => json_encode([
                    'urgency' => 'critical',
                    'immediate_actions' => ['Contact customer and runner', 'Review live map location'],
                    'situation_summary' => 'Active panic alert on errand (test mode).',
                    'parties_to_contact' => ['both'],
                    'escalation_notes' => 'Follow emergency SOP.',
                ])],
                'model' => $model,
                'usage' => ['latency_ms' => 1, 'prompt_tokens' => 10, 'output_tokens' => 30],
            ];
        }

        if (str_contains(strtolower($text), 'classify this errandly dispute')) {
            return [
                'raw' => [],
                'contents' => ['text' => json_encode([
                    'consistent_type' => true,
                    'suggested_type' => 'item_not_delivered',
                    'priority' => 'normal',
                    'tags' => [],
                    'routing_note' => 'Standard queue (test mode).',
                ])],
                'model' => $model,
                'usage' => ['latency_ms' => 1, 'prompt_tokens' => 10, 'output_tokens' => 25],
            ];
        }

        if (str_contains(strtolower($text), 'normalize this address')) {
            return [
                'raw' => [],
                'contents' => ['text' => json_encode([
                    'candidates' => [
                        [
                            'label' => 'Shoprite, Ikot Ekpene Road, Uyo',
                            'latitude' => 5.0379,
                            'longitude' => 7.9228,
                            'confidence' => 0.88,
                        ],
                    ],
                ])],
                'model' => $model,
                'usage' => ['latency_ms' => 1, 'prompt_tokens' => 10, 'output_tokens' => 40],
            ];
        }

        if (str_contains(strtolower($text), 'dispute resolution assistant')) {
            $payload = [
                'timeline_summary' => [
                    'Errand marked complete by runner.',
                    'Customer opened dispute citing delivery issue.',
                ],
                'customer_claim' => 'Item not received as described.',
                'runner_claim' => 'Proof of delivery submitted with receipt.',
                'key_evidence' => [
                    ['source' => 'proof', 'citation' => 'Receipt photo on file'],
                ],
                'suggested_resolution' => 'partial_refund',
                'suggested_partial_percent' => 50,
                'confidence' => 0.72,
                'questions_for_admin' => ['Verify OTP confirmation timestamp?'],
            ];

            return [
                'raw' => [],
                'contents' => ['text' => json_encode($payload)],
                'model' => $model,
                'usage' => ['latency_ms' => 1, 'prompt_tokens' => 50, 'output_tokens' => 80],
            ];
        }

        if (str_contains(strtolower($text), 'proof-of-errand')) {
            $payload = [
                'relevance_score' => 0.9,
                'matches_errand_description' => true,
                'receipt_detected' => true,
                'receipt_total_ngn' => 2500,
                'flags' => [],
                'summary' => 'Receipt appears consistent with errand (test mode).',
            ];

            return [
                'raw' => [],
                'contents' => ['text' => json_encode($payload)],
                'model' => $model,
                'usage' => ['latency_ms' => 1, 'prompt_tokens' => 10, 'output_tokens' => 30],
            ];
        }

        if (str_contains(strtolower($text), 'kyc submission') || str_contains(strtolower($text), 'identity document')) {
            $payload = [
                'document_type' => 'national_id',
                'name_match' => true,
                'expiry_valid' => true,
                'flags' => [],
                'summary' => 'Document readable; manual review still required (test mode).',
            ];

            return [
                'raw' => [],
                'contents' => ['text' => json_encode($payload)],
                'model' => $model,
                'usage' => ['latency_ms' => 1, 'prompt_tokens' => 10, 'output_tokens' => 30],
            ];
        }

        if (str_contains($text, 'Customer request:') || str_contains($text, 'Parse this customer errand')) {
            return $this->wrapJson($model, $this->stubErrandParseFromText($text));
        }

        if (str_contains($text, 'Look at the image') || str_contains($text, 'Extract errand details from this image')) {
            return $this->wrapJson($model, $this->stubErrandParseFromImage($text));
        }

        return $this->wrapJson($model, app(ErrandDraftNormalizer::class)->normalize([
            'title' => 'Grocery purchase',
            'category' => 'grocery_purchase',
            'urgency' => 'standard',
            'pickup_address' => 'Shoprite, Uyo',
            'pickup_latitude' => 5.0379,
            'pickup_longitude' => 7.9228,
            'destination_address' => 'Ewet Housing, Uyo',
            'destination_latitude' => 5.0210,
            'destination_longitude' => 7.9340,
            'budget' => 2500,
            'item_details' => "Peak milk (2 tins)\nBread (1 loaf)",
            'special_instructions' => null,
            'clarifying_questions' => [],
            'confidence' => 0.85,
        ], $text));
    }

    private function stubErrandParseFromText(string $prompt): array
    {
        $request = $prompt;
        if (preg_match('/Customer request:\s*(.+)$/s', $prompt, $m)) {
            $request = trim($m[1]);
        } elseif (preg_match('/Request:\s*(.+)$/s', $prompt, $m)) {
            $request = trim($m[1]);
        }

        return app(ErrandDraftNormalizer::class)->normalize([
            'title' => 'Grocery purchase',
            'category' => 'grocery_purchase',
            'urgency' => str_contains(strtolower($request), 'urgent') ? 'urgent' : 'standard',
            'pickup_address' => 'Shoprite, Uyo',
            'pickup_latitude' => 5.0379,
            'pickup_longitude' => 7.9228,
            'destination_address' => 'Ewet Housing, Uyo',
            'destination_latitude' => 5.0210,
            'destination_longitude' => 7.9340,
            'budget' => 2500,
            'item_details' => "Peak milk (2 tins)\nBread (1 loaf)",
            'special_instructions' => null,
            'clarifying_questions' => [],
            'confidence' => 0.88,
        ], $request);
    }

    private function stubErrandParseFromImage(string $prompt): array
    {
        $notes = null;
        if (preg_match('/Customer added notes:\s*(.+)$/s', $prompt, $m)) {
            $notes = trim($m[1]);
        } elseif (preg_match('/User notes:\s*(.+)$/s', $prompt, $m)) {
            $notes = trim($m[1]);
        }

        return app(ErrandDraftNormalizer::class)->normalize([
            'title' => 'Grocery run from shopping list',
            'category' => 'grocery_purchase',
            'urgency' => 'standard',
            'pickup_address' => 'Shoprite, Ikot Ekpene Road, Uyo',
            'pickup_latitude' => 5.0379,
            'pickup_longitude' => 7.9228,
            'destination_address' => 'Ewet Housing, Uyo',
            'destination_latitude' => 5.0210,
            'destination_longitude' => 7.9340,
            'budget' => 2800,
            'item_details' => "Peak milk (2 tins)\nGolden Penny bread (1)\nEggs (crate)",
            'special_instructions' => null,
            'clarifying_questions' => [],
            'confidence' => 0.82,
        ], null, $notes);
    }

  /**
     * @param  array<string, mixed>  $payload
     */
    private function wrapJson(string $model, array $payload): array
    {
        return [
            'raw' => [],
            'contents' => ['text' => json_encode($payload)],
            'model' => $model,
            'usage' => ['latency_ms' => 1, 'prompt_tokens' => 10, 'output_tokens' => 50],
        ];
    }

    /**
     * @param  array<int, array{name: string, args: array}>  $functionCalls
     */
    private function wrapResponse(string $model, string $text, array $functionCalls = []): array
    {
        return [
            'raw' => [],
            'contents' => [
                'text' => $text,
                'functionCalls' => $functionCalls,
            ],
            'model' => $model,
            'usage' => ['latency_ms' => 1, 'prompt_tokens' => 10, 'output_tokens' => 20],
        ];
    }

    private function extractLastUserText(array $contents): string
    {
        $text = '';
        foreach ($contents as $content) {
            if (($content['role'] ?? '') !== 'user') {
                continue;
            }
            foreach ($content['parts'] ?? [] as $part) {
                if (isset($part['text'])) {
                    $text = $part['text'];
                }
            }
        }

        return $text;
    }
}
