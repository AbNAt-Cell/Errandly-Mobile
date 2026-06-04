<?php

namespace App\Console\Commands;

use App\Services\Ai\DocumentIngestionService;
use Illuminate\Console\Command;

class AiIngestDocsCommand extends Command
{
    protected $signature = 'ai:ingest-docs {corpus=policy : Corpus name to ingest}';

    protected $description = 'Ingest markdown documentation into AI vector chunks';

    public function handle(DocumentIngestionService $ingestion): int
    {
        $corpus = $this->argument('corpus');
        $count = $ingestion->ingestCorpus($corpus);
        $this->info("Ingested {$count} new chunks for corpus [{$corpus}].");

        return self::SUCCESS;
    }
}
