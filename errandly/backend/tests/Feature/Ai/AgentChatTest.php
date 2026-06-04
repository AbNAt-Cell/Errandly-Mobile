<?php

namespace Tests\Feature\Ai;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesAiTestUsers;
use Tests\TestCase;

class AgentChatTest extends TestCase
{
    use CreatesAiTestUsers;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seedRoles();
    }

    public function test_agent_returns_escrow_guidance(): void
    {
        $customer = $this->createCustomer();
        Sanctum::actingAs($customer);

        $response = $this->postJson('/api/ai/agent', [
            'message' => 'How does escrow work?',
        ]);

        $response->assertOk()
            ->assertJsonStructure(['session_id', 'reply', 'proposals']);

        $this->assertStringContainsStringIgnoringCase('escrow', $response->json('reply'));
    }

    public function test_agent_disabled_returns_503(): void
    {
        config(['ai.agent_enabled' => false]);
        $customer = $this->createCustomer();
        Sanctum::actingAs($customer);

        $this->postJson('/api/ai/agent', ['message' => 'hello'])
            ->assertStatus(503);
    }
}
