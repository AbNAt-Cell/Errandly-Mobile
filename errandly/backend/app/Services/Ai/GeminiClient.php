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
        ?string $systemInstruction = null,
    ): array {
        $apiKey = config('ai.api_key');
        if (empty($apiKey)) {
            \Illuminate\Support\Facades\Log::info('GEMINI_API_KEY is not configured, using FakeGeminiClient.');
            return (new FakeGeminiClient())->generateContent($model, $contents, $tools, $generationConfig, $systemInstruction);
        }

        if ($model === 'gemini-2.0-flash' || $model === 'gemini-1.5-flash') {
            $model = 'gemini-2.5-flash';
        }

        $candidateModels = array_values(array_unique([
            $model,
            'gemini-2.5-flash',
            'gemini-3.7-flash',
            'gemini-3.5-flash-lite',
            'gemini-3.8-flash',
        ]));

        $body = [
            'contents' => $contents,
        ];

        if ($systemInstruction !== null && $systemInstruction !== '') {
            $body['systemInstruction'] = [
                'parts' => [['text' => $systemInstruction]],
            ];
        }

        if ($tools !== []) {
            $sanitizedTools = array_map(function ($tool) {
                if (isset($tool['parameters']) && is_array($tool['parameters'])) {
                    if (($tool['parameters']['type'] ?? '') === 'object' && empty($tool['parameters']['properties'])) {
                        $tool['parameters']['properties'] = (object) [];
                    }
                }
                return $tool;
            }, $tools);

            $body['tools'] = [['functionDeclarations' => $sanitizedTools]];
            $body['toolConfig'] = [
                'functionCallingConfig' => ['mode' => 'AUTO'],
            ];
        }

        if ($generationConfig !== null) {
            $body['generationConfig'] = $generationConfig;
        }

        $started = microtime(true);
        $lastError = null;
        $response = null;
        $successfulModel = $model;

        foreach ($candidateModels as $candidate) {
            $url = rtrim(config('ai.api_base'), '/') . '/models/' . $candidate . ':generateContent';

            for ($attempt = 1; $attempt <= 2; $attempt++) {
                try {
                    $response = Http::timeout(30)
                        ->withQueryParameters(['key' => $apiKey])
                        ->post($url, $body);

                    if ($response->successful()) {
                        $successfulModel = $candidate;
                        break 2;
                    }

                    $status = $response->status();
                    $errBody = $response->body();
                    $lastError = "[$candidate (HTTP $status)]: $errBody";

                    if ($status === 404 || $status === 429) {
                        \Illuminate\Support\Facades\Log::warning("Gemini model $candidate returned HTTP $status, trying next candidate.", [
                            'error' => mb_substr($errBody, 0, 300),
                        ]);
                        break;
                    }

                    if ($status === 503) {
                        sleep(1);
                    } else {
                        break;
                    }
                } catch (\Throwable $e) {
                    $lastError = "[$candidate (Exception)]: " . $e->getMessage();
                    break;
                }
            }
        }

        if (!$response || !$response->successful()) {
            \Illuminate\Support\Facades\Log::warning('All Gemini candidate models failed or exhausted quota. Falling back to FakeGeminiClient.', [
                'last_error' => $lastError,
            ]);

            return (new FakeGeminiClient())->generateContent($model, $contents, $tools, $generationConfig, $systemInstruction);
        }

        $json = $response->json();
        $latencyMs = (int) ((microtime(true) - $started) * 1000);

        return [
            'raw' => $json,
            'contents' => $this->parseResponseParts($json),
            'model' => $successfulModel,
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
