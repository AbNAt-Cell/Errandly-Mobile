<?php

namespace App\Services\Ai;

use App\Models\AiDocumentChunk;
use App\Services\Ai\Contracts\GeminiClientInterface;

class DocumentIngestionService
{
    public function __construct(
        private GeminiClientInterface $gemini,
    ) {}

    public function ingestCorpus(string $corpus): int
    {
        $paths = config("ai.ingest_paths.{$corpus}", config('ai.ingest_paths.policy', []));
        $count = 0;

        foreach ($paths as $path) {
            if (!is_readable($path)) {
                continue;
            }
            $count += $this->ingestFile($corpus, $path);
        }

        return $count;
    }

    private function ingestFile(string $corpus, string $path): int
    {
        $content = file_get_contents($path);
        $chunks = $this->chunkText($content);
        $ingested = 0;

        foreach ($chunks as $index => $chunk) {
            $hash = hash('sha256', $chunk);
            $existing = AiDocumentChunk::where('corpus', $corpus)->where('content_hash', $hash)->first();
            if ($existing) {
                continue;
            }

            $embedding = $this->gemini->embedContent($chunk);

            AiDocumentChunk::create([
                'corpus' => $corpus,
                'source_path' => $path,
                'chunk_index' => $index,
                'content' => $chunk,
                'content_hash' => $hash,
                'metadata' => [
                    'roles' => ['all'],
                    'section' => basename($path),
                ],
                'embedding' => $embedding,
            ]);

            $ingested++;
        }

        return $ingested;
    }

    /**
     * @return array<int, string>
     */
    private function chunkText(string $text, int $maxChars = 1200): array
    {
        $paragraphs = preg_split('/\n\s*\n/', trim($text)) ?: [];
        $chunks = [];
        $buffer = '';

        foreach ($paragraphs as $paragraph) {
            $paragraph = trim($paragraph);
            if ($paragraph === '') {
                continue;
            }
            if (mb_strlen($buffer . "\n\n" . $paragraph) > $maxChars && $buffer !== '') {
                $chunks[] = trim($buffer);
                $buffer = $paragraph;
            } else {
                $buffer = $buffer === '' ? $paragraph : $buffer . "\n\n" . $paragraph;
            }
        }

        if ($buffer !== '') {
            $chunks[] = trim($buffer);
        }

        return $chunks;
    }
}
