<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('errands', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('runner_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('title');
            $table->text('description');
            $table->enum('category', [
                'package_pickup', 'item_delivery', 'grocery_purchase', 'queue_standing',
                'document_submission', 'document_collection', 'shopping_assistance',
                'prescription_pickup', 'personal_assistance', 'custom_errand',
            ]);
            $table->enum('status', [
                'draft', 'posted', 'pending_assignment', 'accepted', 'runner_en_route',
                'item_picked', 'in_progress', 'awaiting_confirmation',
                'completed', 'cancelled', 'failed', 'disputed', 'refunded',
            ])->default('draft');
            $table->enum('urgency', ['standard', 'urgent', 'scheduled'])->default('standard');
            $table->text('pickup_address');
            $table->decimal('pickup_latitude', 10, 8);
            $table->decimal('pickup_longitude', 11, 8);
            $table->string('pickup_city')->nullable();
            $table->text('destination_address');
            $table->decimal('destination_latitude', 10, 8);
            $table->decimal('destination_longitude', 11, 8);
            $table->string('destination_city')->nullable();
            $table->string('recipient_name')->nullable();
            $table->string('recipient_phone')->nullable();
            $table->text('item_details')->nullable();
            $table->text('special_instructions')->nullable();
            $table->bigInteger('budget');
            $table->bigInteger('platform_fee')->default(0);
            $table->bigInteger('runner_earnings')->default(0);
            $table->timestamp('scheduled_at')->nullable();
            $table->timestamp('accepted_at')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->timestamp('failed_at')->nullable();
            $table->text('cancellation_reason')->nullable();
            $table->enum('cancellation_by', ['customer', 'runner', 'admin'])->nullable();
            $table->text('failure_reason')->nullable();
            $table->string('pickup_otp')->nullable();
            $table->timestamp('pickup_otp_verified_at')->nullable();
            $table->string('delivery_otp')->nullable();
            $table->timestamp('delivery_otp_verified_at')->nullable();
            $table->boolean('is_recurring')->default(false);
            $table->json('recurring_schedule')->nullable();
            $table->timestamp('panic_triggered_at')->nullable();
            $table->foreignId('panic_triggered_by')->nullable()->constrained('users')->nullOnDelete();
            $table->enum('payment_status', [
                'pending_funding', 'funded', 'in_escrow', 'released', 'refunded', 'frozen',
            ])->default('pending_funding');
            $table->unsignedBigInteger('escrow_id')->nullable();
            $table->json('attachments')->nullable();
            $table->integer('estimated_duration_minutes')->nullable();
            $table->softDeletes();
            $table->timestamps();

            // Indexes for performance
            $table->index(['status', 'created_at']);
            $table->index(['customer_id', 'status']);
            $table->index(['runner_id', 'status']);
            $table->index(['pickup_latitude', 'pickup_longitude']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('errands');
    }
};
