<?php

namespace Tests\Feature\Ai;

use App\Jobs\NotifyNearbyRunners;
use App\Services\Ai\AiToolExecutor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Bus;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesAiTestUsers;
use Tests\TestCase;

class ProposalConfirmTest extends TestCase
{
    use CreatesAiTestUsers;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seedRoles();
    }

    public function test_propose_and_confirm_create_errand(): void
    {
        Bus::fake([NotifyNearbyRunners::class]);
        $customer = $this->createCustomer();
        $executor = app(AiToolExecutor::class);

        $payload = [
            'title' => 'Test grocery run',
            'description' => 'Buy items and deliver',
            'category' => 'grocery_purchase',
            'pickup_address' => 'Shoprite Uyo',
            'pickup_latitude' => 5.0379,
            'pickup_longitude' => 7.9228,
            'destination_address' => 'Ewet Housing',
            'destination_latitude' => 5.0210,
            'destination_longitude' => 7.9340,
            'budget' => 2500,
        ];

        $propose = $executor->execute($customer, 'propose_create_errand', $payload);
        $this->assertTrue($propose['ok']);

        $proposalId = $propose['data']['proposal_id'];
        $token = $propose['data']['confirmation_token'];

        $confirm = $executor->executeProposal($customer, $proposalId, $token);
        $this->assertSame('create_errand', $confirm['type']);
        $this->assertNotEmpty($confirm['errand']['public_id']);

        $this->assertDatabaseHas('errands', [
            'customer_id' => $customer->id,
            'title' => 'Test grocery run',
        ]);
    }

    public function test_confirm_endpoint_via_api(): void
    {
        Bus::fake([NotifyNearbyRunners::class]);
        $customer = $this->createCustomer();
        Sanctum::actingAs($customer);

        $executor = app(AiToolExecutor::class);
        $propose = $executor->execute($customer, 'propose_create_errand', [
            'title' => 'API confirm errand',
            'description' => 'Deliver package',
            'category' => 'item_delivery',
            'pickup_address' => 'A',
            'pickup_latitude' => 5.0,
            'pickup_longitude' => 7.9,
            'destination_address' => 'B',
            'destination_latitude' => 5.1,
            'destination_longitude' => 7.8,
            'budget' => 3000,
        ]);

        $this->postJson('/api/ai/confirm', [
            'proposal_id' => $propose['data']['proposal_id'],
            'confirmation_token' => $propose['data']['confirmation_token'],
        ])->assertOk()
            ->assertJsonPath('type', 'create_errand');
    }

    public function test_invalid_token_rejected(): void
    {
        $customer = $this->createCustomer();
        Sanctum::actingAs($customer);

        $executor = app(AiToolExecutor::class);
        $propose = $executor->execute($customer, 'propose_create_errand', [
            'title' => 'Bad token errand',
            'description' => 'x',
            'category' => 'grocery_purchase',
            'pickup_address' => 'A',
            'pickup_latitude' => 5.0,
            'pickup_longitude' => 7.9,
            'destination_address' => 'B',
            'destination_latitude' => 5.1,
            'destination_longitude' => 7.8,
            'budget' => 2000,
        ]);

        $this->postJson('/api/ai/confirm', [
            'proposal_id' => $propose['data']['proposal_id'],
            'confirmation_token' => 'invalid-token',
        ])->assertStatus(422);
    }
}
