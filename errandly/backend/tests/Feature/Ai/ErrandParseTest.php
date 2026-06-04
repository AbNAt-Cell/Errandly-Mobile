<?php

namespace Tests\Feature\Ai;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesAiTestUsers;
use Tests\TestCase;

class ErrandParseTest extends TestCase
{
    use CreatesAiTestUsers;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seedRoles();
    }

    public function test_parse_text_returns_draft(): void
    {
        $customer = $this->createCustomer();
        Sanctum::actingAs($customer);

        $response = $this->postJson('/api/ai/errands/parse-text', [
            'text' => 'Buy milk and bread from Shoprite and deliver to Ewet Housing',
        ]);

        $response->assertOk()
            ->assertJsonPath('draft.title', 'Grocery purchase')
            ->assertJsonPath('draft.category', 'grocery_purchase');

        $description = $response->json('draft.description');
        $this->assertNotEmpty($description);
        $this->assertStringNotContainsString('Return JSON', $description);
        $this->assertStringNotContainsString('Extract errand details', $description);
        $this->assertGreaterThan(40, strlen($description));
    }

    public function test_parse_image_returns_runner_friendly_description(): void
    {
        $customer = $this->createCustomer();
        Sanctum::actingAs($customer);

        $response = $this->postJson('/api/ai/errands/parse-image', [
            'image_url' => 'data:image/jpeg;base64,/9j/4AAQ',
            'notes' => 'Need everything by 6pm',
        ]);

        $response->assertOk();
        $description = $response->json('draft.description');
        $this->assertNotEmpty($description);
        $this->assertStringNotContainsString('Return JSON', $description);
        $this->assertStringNotContainsString('shopping list, item photo', strtolower($description));
    }
}
