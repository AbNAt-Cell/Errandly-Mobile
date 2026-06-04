<?php

namespace App\Console\Commands;

use App\Services\Ai\AiAgentService;
use App\Services\Ai\Contracts\GeminiClientInterface;
use App\Services\Ai\DocumentIngestionService;
use App\Services\Ai\FakeGeminiClient;
use App\Services\Ai\PolicySearchService;
use App\Models\User;
use Illuminate\Console\Command;
use Symfony\Component\Process\Process;

class AiBenchmarkCommand extends Command
{
    protected $signature = 'ai:benchmark {--skip-tests : Skip PHPUnit suite} {--live : Use real Gemini API instead of fake responses}';

    protected $description = 'Run AI subsystem checks (ingest, search, agent) and optional PHPUnit benchmarks';

    public function handle(): int
    {
        if (!$this->option('live')) {
            $this->warn('Using FakeGeminiClient (pass --live to call Gemini API).');
            app()->instance(GeminiClientInterface::class, new FakeGeminiClient());
        } else {
            $this->info('Using live Gemini API.');
        }

        $ingestion = app(DocumentIngestionService::class);
        $search = app(PolicySearchService::class);
        $agent = app(AiAgentService::class);

        $this->info('=== Errandly AI Benchmark ===');

        $ingested = $ingestion->ingestCorpus('policy');
        $this->line("Policy ingest: {$ingested} new chunks");

        $chunks = $search->search('escrow OTP delivery', 3, ['customer']);
        $this->line('Policy search hits: ' . count($chunks));
        if ($chunks === []) {
            $this->warn('No policy chunks found — check ingest paths in config/ai.php');
        }

        try {
            $customer = User::role('customer')->first();
        } catch (\Throwable) {
            $customer = null;
        }

        if ($customer) {
            $chat = $agent->chat($customer, 'Tell me about escrow', null, []);
            $this->line('Agent reply length: ' . strlen($chat['reply'] ?? ''));
        } else {
            $this->warn('No customer user for agent smoke test — run: php artisan db:seed --class=RolesAndPermissionsSeeder && php artisan db:seed --class=TestUsersSeeder');
        }

        if (!$this->option('skip-tests')) {
            $this->info('Running PHPUnit AI tests...');

            // Run in a subprocess so flags like --live are not passed to `php artisan test`.
            $process = new Process(
                [PHP_BINARY, base_path('artisan'), 'test', '--testsuite=Feature', '--filter=Ai'],
                base_path(),
                null,
                null,
                120,
            );
            $process->run(function (string $type, string $buffer): void {
                $this->output->write($buffer);
            });

            return $process->isSuccessful() ? self::SUCCESS : self::FAILURE;
        }

        $this->info('Benchmark complete.');

        return self::SUCCESS;
    }
}
