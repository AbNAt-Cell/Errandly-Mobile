<?php

namespace Tests\Feature\Ai;

use App\Models\AiDocumentChunk;
use App\Services\Ai\DocumentIngestionService;
use App\Services\Ai\PolicySearchService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesAiTestUsers;
use Tests\TestCase;

class PolicySearchTest extends TestCase
{
    use CreatesAiTestUsers;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seedRoles();
    }

    public function test_policy_search_returns_chunks_from_database(): void
    {
        AiDocumentChunk::create([
            'corpus' => 'policy',
            'source_path' => 'test.md',
            'chunk_index' => 0,
            'content' => 'Escrow holds funds until the customer confirms delivery with OTP.',
            'content_hash' => hash('sha256', 'escrow-otp-chunk'),
            'metadata' => ['roles' => ['all'], 'section' => 'escrow'],
            'embedding' => app(\App\Services\Ai\Contracts\GeminiClientInterface::class)->embedContent('escrow OTP'),
        ]);

        $service = app(PolicySearchService::class);
        $results = $service->search('escrow OTP', 3, ['customer']);

        $this->assertNotEmpty($results);
        $this->assertStringContainsStringIgnoringCase('escrow', $results[0]['content']);
    }

    public function test_policy_search_api_endpoint(): void
    {
        AiDocumentChunk::create([
            'corpus' => 'policy',
            'source_path' => 'test.md',
            'chunk_index' => 0,
            'content' => 'Refunds follow dispute resolution policy.',
            'content_hash' => hash('sha256', 'refund-chunk'),
            'metadata' => ['roles' => ['all']],
            'embedding' => [0.1, 0.2],
        ]);

        $customer = $this->createCustomer();
        Sanctum::actingAs($customer);

        $this->getJson('/api/ai/policy/search?query=refund')
            ->assertOk()
            ->assertJsonStructure(['chunks']);
    }

    public function test_document_ingest_is_idempotent(): void
    {
        $ingestion = app(DocumentIngestionService::class);
        $first = $ingestion->ingestCorpus('policy');
        $second = $ingestion->ingestCorpus('policy');

        $this->assertGreaterThanOrEqual(0, $first);
        $this->assertSame(0, $second);
    }
}
