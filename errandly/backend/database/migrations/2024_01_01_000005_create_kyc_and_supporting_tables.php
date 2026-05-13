<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('kyc_documents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->enum('type', ['customer', 'runner']);
            $table->enum('status', [
                'pending', 'submitted', 'under_review', 'approved', 'rejected', 'resubmission_required',
            ])->default('pending');
            $table->enum('id_type', ['national_id', 'drivers_license', 'passport', 'voters_card'])->nullable();
            $table->string('id_number')->nullable();
            $table->text('id_document_url')->nullable();
            $table->text('selfie_url')->nullable();
            $table->text('live_photo_url')->nullable();
            $table->text('address_proof_url')->nullable();
            $table->text('utility_bill_url')->nullable();
            $table->string('nin_number')->nullable();
            $table->string('bvn_number')->nullable();
            $table->timestamp('submitted_at')->nullable();
            $table->timestamp('reviewed_at')->nullable();
            $table->text('rejection_reason')->nullable();
            $table->text('resubmission_reason')->nullable();
            $table->text('notes')->nullable();
            $table->decimal('face_match_score', 5, 2)->nullable();
            $table->decimal('liveness_score', 5, 2)->nullable();
            $table->decimal('document_confidence', 5, 2)->nullable();
            $table->timestamps();
        });

        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('errand_id')->constrained()->cascadeOnDelete();
            $table->foreignId('sender_id')->constrained('users')->cascadeOnDelete();
            $table->enum('type', ['text', 'image', 'voice', 'system', 'location'])->default('text');
            $table->text('content')->nullable();
            $table->text('media_url')->nullable();
            $table->string('media_type')->nullable();
            $table->integer('duration_seconds')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->boolean('is_system')->default(false);
            $table->timestamps();

            $table->index(['errand_id', 'created_at']);
        });

        Schema::create('tracking_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('errand_id')->constrained()->cascadeOnDelete();
            $table->foreignId('runner_id')->constrained('users')->cascadeOnDelete();
            $table->decimal('latitude', 10, 8);
            $table->decimal('longitude', 11, 8);
            $table->decimal('speed', 5, 2)->nullable();
            $table->decimal('heading', 5, 2)->nullable();
            $table->decimal('accuracy', 8, 2)->nullable();
            $table->timestamp('logged_at');

            $table->index(['errand_id', 'logged_at']);
        });

        Schema::create('proof_submissions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('errand_id')->constrained()->cascadeOnDelete();
            $table->foreignId('runner_id')->constrained('users')->cascadeOnDelete();
            $table->enum('type', ['photo', 'receipt', 'signature', 'note']);
            $table->text('file_url')->nullable();
            $table->text('notes')->nullable();
            $table->timestamp('submitted_at');
            $table->timestamp('verified_at')->nullable();
            $table->timestamps();
        });

        Schema::create('ratings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('errand_id')->constrained()->cascadeOnDelete();
            $table->foreignId('rater_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('rated_id')->constrained('users')->cascadeOnDelete();
            $table->enum('role', ['customer_rates_runner', 'runner_rates_customer']);
            $table->decimal('overall_rating', 3, 2);
            $table->decimal('punctuality', 3, 2)->nullable();
            $table->decimal('professionalism', 3, 2)->nullable();
            $table->decimal('communication', 3, 2)->nullable();
            $table->decimal('accuracy', 3, 2)->nullable();
            $table->decimal('safety', 3, 2)->nullable();
            $table->decimal('trustworthiness', 3, 2)->nullable();
            $table->decimal('clarity', 3, 2)->nullable();
            $table->decimal('politeness', 3, 2)->nullable();
            $table->decimal('payment_reliability', 3, 2)->nullable();
            $table->decimal('honesty', 3, 2)->nullable();
            $table->text('comment')->nullable();
            $table->boolean('is_anonymous')->default(false);
            $table->timestamps();

            $table->unique(['errand_id', 'rater_id', 'role']);
            $table->index(['rated_id', 'role']);
        });

        Schema::create('disputes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('errand_id')->constrained()->cascadeOnDelete();
            $table->foreignId('raised_by')->constrained('users')->cascadeOnDelete();
            $table->foreignId('assigned_to')->nullable()->constrained('users')->nullOnDelete();
            $table->enum('type', [
                'item_not_delivered', 'item_damaged', 'wrong_task_execution',
                'harassment', 'fraudulent_completion', 'missing_payment', 'other',
            ]);
            $table->enum('status', ['open', 'under_review', 'awaiting_evidence', 'resolved', 'closed'])->default('open');
            $table->text('description');
            $table->text('resolution')->nullable();
            $table->enum('resolution_type', ['refund', 'release', 'partial_refund', 'no_action'])->nullable();
            $table->timestamp('resolved_at')->nullable();
            $table->bigInteger('refund_amount')->nullable();
            $table->boolean('penalty_applied')->default(false);
            $table->json('evidence')->nullable();
            $table->timestamp('closed_at')->nullable();
            $table->text('closing_notes')->nullable();
            $table->timestamps();
        });

        Schema::create('dispute_evidence', function (Blueprint $table) {
            $table->id();
            $table->foreignId('dispute_id')->constrained()->cascadeOnDelete();
            $table->foreignId('submitted_by')->constrained('users')->cascadeOnDelete();
            $table->enum('type', ['photo', 'video', 'document', 'text']);
            $table->text('url')->nullable();
            $table->text('description')->nullable();
            $table->timestamps();
        });

        Schema::create('panic_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('errand_id')->constrained()->cascadeOnDelete();
            $table->foreignId('triggered_by')->constrained('users')->cascadeOnDelete();
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->enum('status', ['active', 'responded', 'resolved'])->default('active');
            $table->text('notes')->nullable();
            $table->foreignId('admin_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('resolved_at')->nullable();
            $table->text('resolution_notes')->nullable();
            $table->timestamps();
        });

        Schema::create('errand_status_history', function (Blueprint $table) {
            $table->id();
            $table->foreignId('errand_id')->constrained()->cascadeOnDelete();
            $table->string('from_status')->nullable();
            $table->string('to_status');
            $table->foreignId('changed_by')->constrained('users')->cascadeOnDelete();
            $table->text('reason')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamp('created_at');

            $table->index(['errand_id', 'created_at']);
        });

        Schema::create('saved_addresses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('label');
            $table->text('address');
            $table->string('city')->nullable();
            $table->string('state')->nullable();
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->boolean('is_default')->default(false);
            $table->timestamps();
        });

        Schema::create('app_notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('type');
            $table->string('title');
            $table->text('body');
            $table->json('data')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->string('action_url')->nullable();
            $table->string('icon')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'read_at']);
        });

        Schema::create('settings', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();
            $table->text('value');
            $table->string('type')->default('string');
            $table->string('group')->default('general');
            $table->text('description')->nullable();
            $table->timestamps();
        });

        Schema::create('service_areas', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('city');
            $table->string('state');
            $table->string('country')->default('Nigeria');
            $table->decimal('center_latitude', 10, 8)->nullable();
            $table->decimal('center_longitude', 11, 8)->nullable();
            $table->integer('radius_km')->default(10);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('service_areas');
        Schema::dropIfExists('settings');
        Schema::dropIfExists('app_notifications');
        Schema::dropIfExists('saved_addresses');
        Schema::dropIfExists('errand_status_history');
        Schema::dropIfExists('panic_events');
        Schema::dropIfExists('dispute_evidence');
        Schema::dropIfExists('disputes');
        Schema::dropIfExists('ratings');
        Schema::dropIfExists('proof_submissions');
        Schema::dropIfExists('tracking_logs');
        Schema::dropIfExists('messages');
        Schema::dropIfExists('kyc_documents');
    }
};
