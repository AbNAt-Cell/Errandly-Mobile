<?php

namespace Tests\Feature\Ai;

use App\Jobs\ClassifyDisputeJob;
use App\Jobs\ScanMessageModerationJob;
use App\Models\AiFraudSignal;
use App\Models\AiVisionAnalysis;
use App\Models\Dispute;
use App\Models\Errand;
use App\Models\Message;
use App\Services\Ai\BudgetEtaSuggester;
use App\Services\Ai\DisputeClassifier;
use App\Services\Ai\FraudSignalAggregator;
use App\Services\Ai\MessageModerationScanner;
use App\Services\Ai\TrustScoreExplainer;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Bus;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesAiTestUsers;
use Tests\TestCase;

class Phase2FeaturesTest extends TestCase
{
    use CreatesAiTestUsers;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seedRoles();
    }

    public function test_budget_suggester_returns_estimate(): void
    {
        $suggester = app(BudgetEtaSuggester::class);
        $result = $suggester->suggest(
            Errand::CATEGORY_GROCERY,
            5.0379,
            7.9228,
            5.0210,
            7.9340,
        );

        $this->assertGreaterThan(0, $result['suggested_budget_kobo']);
        $this->assertGreaterThan(0, $result['suggested_eta_minutes']);
    }

    public function test_message_moderation_persists_analysis(): void
    {
        $customer = $this->createCustomer();
        $runner = $this->createRunner();
        $errand = Errand::create([
            'customer_id' => $customer->id,
            'runner_id' => $runner->id,
            'title' => 'Chat test',
            'description' => 'x',
            'category' => Errand::CATEGORY_GROCERY,
            'pickup_address' => 'A',
            'pickup_latitude' => 5.0,
            'pickup_longitude' => 7.9,
            'destination_address' => 'B',
            'destination_latitude' => 5.1,
            'destination_longitude' => 7.8,
            'budget' => 2000,
            'platform_fee' => 300,
            'runner_earnings' => 2000,
            'status' => Errand::STATUS_IN_PROGRESS,
            'payment_status' => Errand::PAYMENT_FUNDED,
        ]);

        $message = Message::create([
            'errand_id' => $errand->id,
            'sender_id' => $customer->id,
            'type' => Message::TYPE_TEXT,
            'content' => 'Please pay me on WhatsApp',
        ]);

        $analysis = app(MessageModerationScanner::class)->scan($message);

        $this->assertSame('message', $analysis->subject_type);
        $this->assertNotEmpty($analysis->result);
    }

    public function test_dispute_classifier_persists(): void
    {
        $customer = $this->createCustomer();
        $errand = Errand::create([
            'customer_id' => $customer->id,
            'title' => 'Dispute test',
            'description' => 'x',
            'category' => Errand::CATEGORY_GROCERY,
            'pickup_address' => 'A',
            'pickup_latitude' => 5.0,
            'pickup_longitude' => 7.9,
            'destination_address' => 'B',
            'destination_latitude' => 5.1,
            'destination_longitude' => 7.8,
            'budget' => 2000,
            'platform_fee' => 300,
            'runner_earnings' => 2000,
            'status' => Errand::STATUS_DISPUTED,
            'payment_status' => Errand::PAYMENT_FUNDED,
        ]);

        $dispute = Dispute::create([
            'errand_id' => $errand->id,
            'raised_by' => $customer->id,
            'type' => Dispute::TYPE_ITEM_NOT_DELIVERED,
            'status' => Dispute::STATUS_OPEN,
            'description' => 'Never received items',
        ]);

        app(DisputeClassifier::class)->classify($dispute);

        $this->assertDatabaseHas('ai_vision_analyses', [
            'subject_type' => 'dispute_classification',
            'subject_id' => (string) $dispute->id,
        ]);
    }

    public function test_trust_score_explainer_for_runner(): void
    {
        $runner = $this->createRunner();
        $explain = app(TrustScoreExplainer::class)->explain($runner);

        $this->assertArrayHasKey('score', $explain);
        $this->assertNotEmpty($explain['factors']);
    }

    public function test_suggest_budget_api(): void
    {
        $customer = $this->createCustomer();
        Sanctum::actingAs($customer);

        $this->postJson('/api/ai/errands/suggest-budget', [
            'category' => 'grocery_purchase',
            'pickup_latitude' => 5.0379,
            'pickup_longitude' => 7.9228,
            'destination_latitude' => 5.0210,
            'destination_longitude' => 7.9340,
        ])->assertOk()
            ->assertJsonStructure(['suggested_budget_kobo', 'suggested_eta_minutes']);
    }

    public function test_message_send_dispatches_moderation_job(): void
    {
        Bus::fake([ScanMessageModerationJob::class, ClassifyDisputeJob::class]);

        $customer = $this->createCustomer();
        $runner = $this->createRunner();
        Sanctum::actingAs($customer);

        $errand = Errand::create([
            'customer_id' => $customer->id,
            'runner_id' => $runner->id,
            'title' => 'Msg job test',
            'description' => 'x',
            'category' => Errand::CATEGORY_GROCERY,
            'pickup_address' => 'A',
            'pickup_latitude' => 5.0,
            'pickup_longitude' => 7.9,
            'destination_address' => 'B',
            'destination_latitude' => 5.1,
            'destination_longitude' => 7.8,
            'budget' => 2000,
            'platform_fee' => 300,
            'runner_earnings' => 2000,
            'status' => Errand::STATUS_IN_PROGRESS,
            'payment_status' => Errand::PAYMENT_FUNDED,
        ]);

        $this->postJson("/api/messages/conversations/{$errand->public_id}", [
            'content' => 'Hello runner',
        ])->assertCreated();

        Bus::assertDispatched(ScanMessageModerationJob::class);
    }

    public function test_fraud_aggregator_creates_repeat_dyad_signal(): void
    {
        $customer = $this->createCustomer();
        $runner = $this->createRunner();

        for ($i = 0; $i < 8; $i++) {
            Errand::create([
                'customer_id' => $customer->id,
                'runner_id' => $runner->id,
                'title' => "Repeat {$i}",
                'description' => 'x',
                'category' => Errand::CATEGORY_GROCERY,
                'pickup_address' => 'A',
                'pickup_latitude' => 5.0,
                'pickup_longitude' => 7.9,
                'destination_address' => 'B',
                'destination_latitude' => 5.1,
                'destination_longitude' => 7.8,
                'budget' => 2000,
                'platform_fee' => 300,
                'runner_earnings' => 2000,
                'status' => Errand::STATUS_COMPLETED,
                'payment_status' => Errand::PAYMENT_FUNDED,
                'completed_at' => now(),
            ]);
        }

        $created = app(FraudSignalAggregator::class)->aggregate();

        $this->assertGreaterThan(0, $created);
        $this->assertTrue(
            AiFraudSignal::where('signal_type', 'repeat_dyad')->exists()
        );
    }
}
