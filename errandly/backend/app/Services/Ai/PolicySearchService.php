<?php

namespace App\Services\Ai;

use App\Models\AiDocumentChunk;
use App\Services\Ai\Contracts\GeminiClientInterface;

class PolicySearchService
{
    public function __construct(
        private GeminiClientInterface $gemini,
    ) {}

    /**
     * @param  array<int, string>  $roles
     * @return array<int, array{content: string, score: float, section: string|null}>
     */
    public function search(string $query, int $limit = 5, array $roles = []): array
    {
        $query = trim($query);
        if ($query === '') {
            return [];
        }

        $chunks = AiDocumentChunk::query()
            ->where('corpus', 'policy')
            ->get();

        if ($chunks->isEmpty()) {
            return $this->keywordFallbackFromFiles($query, $limit);
        }

        $queryEmbedding = null;
        try {
            $queryEmbedding = $this->gemini->embedContent($query);
        } catch (\Throwable) {
            // fall through to keyword
        }

        $scored = [];
        foreach ($chunks as $chunk) {
            $roleOk = $this->chunkVisibleToRoles($chunk, $roles);
            if (!$roleOk) {
                continue;
            }

            $score = 0.0;
            if ($queryEmbedding !== null && is_array($chunk->embedding) && $chunk->embedding !== []) {
                $score = $this->cosineSimilarity($queryEmbedding, $chunk->embedding);
            }

            if (stripos($chunk->content, $query) !== false) {
                $score += 0.25;
            }

            $scored[] = [
                'content' => $chunk->content,
                'score' => $score,
                'section' => $chunk->metadata['section'] ?? null,
            ];
        }

        usort($scored, fn ($a, $b) => $b['score'] <=> $a['score']);

        return array_slice($scored, 0, $limit);
    }

    private function chunkVisibleToRoles(AiDocumentChunk $chunk, array $roles): bool
    {
        $allowed = $chunk->metadata['roles'] ?? ['all'];
        if (in_array('all', $allowed, true)) {
            return true;
        }

        return count(array_intersect($allowed, $roles)) > 0;
    }

    /**
     * @param  array<int, float>  $a
     * @param  array<int, float>  $b
     */
    private function cosineSimilarity(array $a, array $b): float
    {
        $len = min(count($a), count($b));
        if ($len === 0) {
            return 0.0;
        }

        $dot = 0.0;
        $normA = 0.0;
        $normB = 0.0;
        for ($i = 0; $i < $len; $i++) {
            $dot += $a[$i] * $b[$i];
            $normA += $a[$i] ** 2;
            $normB += $b[$i] ** 2;
        }

        if ($normA == 0.0 || $normB == 0.0) {
            return 0.0;
        }

        return $dot / (sqrt($normA) * sqrt($normB));
    }

    private function keywordFallbackFromFiles(string $query, int $limit): array
    {
        $results = [];
        foreach (config('ai.ingest_paths.policy', []) as $path) {
            if (!is_readable($path)) {
                continue;
            }
            $content = file_get_contents($path);
            if (stripos($content, $query) !== false) {
                $results[] = [
                    'content' => mb_substr($content, 0, 500),
                    'score' => 0.5,
                    'section' => basename($path),
                ];
            }
        }

        return array_slice($results, 0, $limit);
    }
}
