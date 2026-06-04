<?php

namespace Tests\Feature\Ai;

use App\Models\AiDocumentChunk;
use App\Services\Ai\AiAgentService;
use App\Services\Ai\PolicySearchService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesAiTestUsers;
use Tests\TestCase;

class AiBenchmarkTest extends TestCase
{
    use CreatesAiTestUsers;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seedRoles();
    }

    public function test_benchmark_smoke_checks(): void
    {
        AiDocumentChunk::create([
            'corpus' => 'policy',
            'source_path' => 'bench.md',
            'chunk_index' => 0,
            'content' => 'Escrow OTP delivery confirmation releases payment to runner.',
            'content_hash' => hash('sha256', 'bench-escrow'),
            'metadata' => ['roles' => ['all']],
            'embedding' => app(\App\Services\Ai\Contracts\GeminiClientInterface::class)->embedContent('escrow'),
        ]);

        $search = app(PolicySearchService::class);
        $hits = $search->search('escrow OTP delivery', 3, ['customer']);
        $this->assertNotEmpty($hits);

        $customer = $this->createCustomer();
        $agent = app(AiAgentService::class);
        $chat = $agent->chat($customer, 'Tell me about escrow', null, []);

        $this->assertNotEmpty($chat['reply']);
        $this->assertNotEmpty($chat['session_id']);
    }
}
