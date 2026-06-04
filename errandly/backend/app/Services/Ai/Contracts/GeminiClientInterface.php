<?php

namespace App\Services\Ai\Contracts;

interface GeminiClientInterface
{
    /**
     * @param  array<int, array<string, mixed>>  $contents  Gemini-format contents
     * @param  array<int, array<string, mixed>>  $tools  functionDeclarations
     * @return array{contents: array, model: string, usage: array<string, int|null>}
     */
    public function generateContent(
        string $model,
        array $contents,
        array $tools = [],
        ?array $generationConfig = null,
    ): array;

    /**
     * @return array<int, float>
     */
    public function embedContent(string $text, ?string $model = null): array;
}
