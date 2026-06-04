<?php

namespace Tests\Feature;

use App\Models\Errand;
use App\Models\User;
use Illuminate\Support\Str;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesAiTestUsers;
use Tests\TestCase;

class ErrandLifecycleTest extends TestCase
{
    use CreatesAiTestUsers;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seedRoles();
    }

    public function test_customer_can_create_errand_with_funded_wallet(): void
    {
        $customer = $this->createCustomer();
        Sanctum::actingAs($customer);

        $response = $this->postJson('/api/customer/errands', [
            'title' => 'Test delivery',
            'description' => 'Bring package to office',
            'category' => 'item_delivery',
            'urgency' => 'standard',
            'pickup_address' => '1 Main St, Uyo',
            'pickup_latitude' => 5.0543,
            'pickup_longitude' => 7.9139,
            'pickup_city' => 'Uyo',
            'destination_address' => '2 Office Rd, Uyo',
            'destination_latitude' => 5.0720,
            'destination_longitude' => 7.9280,
            'destination_city' => 'Uyo',
            'budget' => 3000,
        ]);

        $response->assertCreated();
        $this->assertDatabaseHas('errands', [
            'customer_id' => $customer->id,
            'title' => 'Test delivery',
        ]);
    }

    public function test_runner_can_accept_posted_errand(): void
    {
        $customer = $this->createCustomer();
        $runner = $this->createRunner();

        $errand = Errand::create([
            'public_id' => (string) Str::uuid(),
            'customer_id' => $customer->id,
            'title' => 'Lifecycle test',
            'description' => 'Test',
            'category' => Errand::CATEGORY_ITEM_DELIVERY,
            'status' => Errand::STATUS_PENDING_ASSIGNMENT,
            'urgency' => Errand::URGENCY_STANDARD,
            'pickup_address' => 'Pickup',
            'pickup_latitude' => 5.05,
            'pickup_longitude' => 7.91,
            'pickup_city' => 'Uyo',
            'destination_address' => 'Dest',
            'destination_latitude' => 5.07,
            'destination_longitude' => 7.93,
            'destination_city' => 'Uyo',
            'budget' => 5000,
            'platform_fee' => 750,
            'runner_earnings' => 5000,
            'payment_status' => 'in_escrow',
        ]);

        Sanctum::actingAs($runner);
        $response = $this->postJson("/api/runner/errands/{$errand->public_id}/accept");
        $response->assertOk();
        $errand->refresh();
        $this->assertSame(Errand::STATUS_ACCEPTED, $errand->status);
        $this->assertSame($runner->id, $errand->runner_id);
    }
}
