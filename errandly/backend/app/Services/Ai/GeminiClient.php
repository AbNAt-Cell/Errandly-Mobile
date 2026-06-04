<?php

namespace App\Services\Ai;

use App\Services\Ai\Contracts\GeminiClientInterface;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class GeminiClient implements GeminiClientInterface
{
    public function generateContent(
        string $model,
        array $contents,
        array $tools = [],
        ?array $generationConfig = null,
    ): array {
        $apiKey = config('ai.api_key');
        if (empty($apiKey)) {
            throw new RuntimeException('GEMINI_API_KEY is not configured.');
        }

        $url = rtrim(config('ai.api_base'), '/') . '/models/' . $model . ':generateContent';

        $body = [
            'contents' => $contents,
        ];

        if ($tools !== []) {
            $body['tools'] = [['functionDeclarations' => $tools]];
            $body['toolConfig'] = [
                'functionCallingConfig' => ['mode' => 'AUTO'],
            ];
        }

        if ($generationConfig !== null) {
            $body['generationConfig'] = $generationConfig;
        }

        $started = microtime(true);
        $response = Http::timeout(60)
            ->withQueryParameters(['key' => $apiKey])
            ->post($url, $body);

        if (!$response->successful()) {
            throw new RuntimeException('Gemini API error: ' . $response->body());
        }

        $json = $response->json();
        $latencyMs = (int) ((microtime(true) - $started) * 1000);

        return [
            'raw' => $json,
            'contents' => $this->parseResponseParts($json),
            'model' => $model,
            'usage' => [
                'latency_ms' => $latencyMs,
                'prompt_tokens' => data_get($json, 'usageMetadata.promptTokenCount'),
                'output_tokens' => data_get($json, 'usageMetadata.candidatesTokenCount'),
            ],
        ];
    }

    public function embedContent(string $text, ?string $model = null): array
    {
        $apiKey = config('ai.api_key');
        $model ??= config('ai.models.embedding');

        $url = rtrim(config('ai.api_base'), '/') . '/models/' . $model . ':embedContent';

        $response = Http::timeout(30)
            ->withQueryParameters(['key' => $apiKey])
            ->post($url, [
                'content' => ['parts' => [['text' => $text]]],
            ]);

        if (!$response->successful()) {
            throw new RuntimeException('Gemini embed API error: ' . $response->body());
        }

        $values = data_get($response->json(), 'embedding.values');

        if (!is_array($values)) {
            throw new RuntimeException('Invalid embedding response from Gemini.');
        }

        return array_map('floatval', $values);
    }

  /**
     * @return array{text?: string, functionCalls?: array<int, array{name: string, args: array}>}
     */
    private function parseResponseParts(array $json): array
    {
        $parts = data_get($json, 'candidates.0.content.parts', []);
        $text = '';
        $functionCalls = [];

        foreach ($parts as $part) {
            if (isset($part['text'])) {
                $text .= $part['text'];
            }
            if (isset($part['functionCall'])) {
                $functionCalls[] = [
                    'name' => $part['functionCall']['name'],
                    'args' => $part['functionCall']['args'] ?? [],
                ];
            }
        }

        return [
            'text' => trim($text),
            'functionCalls' => $functionCalls,
        ];
    }
}
