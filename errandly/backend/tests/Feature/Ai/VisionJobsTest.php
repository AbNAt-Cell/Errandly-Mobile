<?php

namespace Tests\Feature\Ai;

use App\Jobs\AnalyzeKycSubmissionJob;
use App\Jobs\AnalyzeProofSubmissionJob;
use App\Jobs\SummarizeDisputeJob;
use App\Models\AiVisionAnalysis;
use App\Models\Dispute;
use App\Models\Errand;
use App\Models\ProofSubmission;
use App\Models\KycDocument;
use App\Services\Ai\DisputeSummarizer;
use App\Services\ErrandService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Bus;
use Tests\Concerns\CreatesAiTestUsers;
use Tests\TestCase;

class VisionJobsTest extends TestCase
{
    use CreatesAiTestUsers;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seedRoles();
    }

    public function test_proof_submission_dispatches_analysis_job(): void
    {
        Bus::fake([AnalyzeProofSubmissionJob::class]);

        $customer = $this->createCustomer();
        $runner = $this->createRunner();

        $errand = Errand::create([
            'customer_id' => $customer->id,
            'runner_id' => $runner->id,
            'title' => 'Test errand',
            'description' => 'Deliver item',
            'category' => Errand::CATEGORY_ITEM_DELIVERY,
            'pickup_address' => 'A',
            'pickup_latitude' => 5.0,
            'pickup_longitude' => 7.9,
            'destination_address' => 'B',
            'destination_latitude' => 5.1,
            'destination_longitude' => 7.8,
            'budget' => 3000,
            'platform_fee' => 450,
            'runner_earnings' => 3000,
            'status' => Errand::STATUS_IN_PROGRESS,
            'payment_status' => Errand::PAYMENT_FUNDED,
        ]);

        app(ErrandService::class)->submitProof($runner, $errand, [
            'type' => ProofSubmission::TYPE_PHOTO,
            'file_url' => 'https://example.com/proof.jpg',
            'notes' => 'Delivered',
        ]);

        Bus::assertDispatched(AnalyzeProofSubmissionJob::class);
    }

    public function test_kyc_submission_dispatches_analysis_job(): void
    {
        Bus::fake([AnalyzeKycSubmissionJob::class]);

        $customer = $this->createCustomer();

        app(\App\Services\KycService::class)->submitCustomerKyc($customer, [
            'id_type' => 'national_id',
            'id_number' => '12345678901',
            'id_document_url' => 'https://example.com/id.jpg',
            'selfie_url' => 'https://example.com/selfie.jpg',
        ]);

        Bus::assertDispatched(AnalyzeKycSubmissionJob::class);
    }

    public function test_dispute_summarizer_persists_analysis(): void
    {
        $customer = $this->createCustomer();
        $errand = Errand::create([
            'customer_id' => $customer->id,
            'title' => 'Disputed errand',
            'description' => 'Test',
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
            'description' => 'Item never arrived',
        ]);

        $analysis = app(DisputeSummarizer::class)->summarize($dispute);

        $this->assertSame('dispute', $analysis->subject_type);
        $this->assertNotEmpty($analysis->result['timeline_summary'] ?? []);
        $this->assertDatabaseHas('ai_vision_analyses', [
            'subject_type' => 'dispute',
            'subject_id' => (string) $dispute->id,
        ]);
    }
}
