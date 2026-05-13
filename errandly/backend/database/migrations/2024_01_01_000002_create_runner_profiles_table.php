<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('runner_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('nin')->nullable();
            $table->string('bank_name')->nullable();
            $table->string('bank_account_number')->nullable();
            $table->string('bank_account_name')->nullable();
            $table->string('bank_code')->nullable();
            $table->string('next_of_kin_name')->nullable();
            $table->string('next_of_kin_phone')->nullable();
            $table->string('next_of_kin_relationship')->nullable();
            $table->string('guarantor_name')->nullable();
            $table->string('guarantor_phone')->nullable();
            $table->text('guarantor_address')->nullable();
            $table->enum('transport_type', ['foot', 'bicycle', 'motorcycle', 'car'])->default('foot');
            $table->integer('service_radius_km')->default(10);
            $table->string('service_city')->nullable();
            $table->string('service_state')->nullable();
            $table->json('skills')->nullable();
            $table->json('available_days')->nullable();
            $table->time('available_hours_start')->default('08:00:00');
            $table->time('available_hours_end')->default('20:00:00');
            $table->boolean('is_available')->default(false);
            $table->boolean('is_online')->default(false);
            $table->boolean('is_verified')->default(false);
            $table->enum('verification_status', ['pending', 'submitted', 'approved', 'rejected'])->default('pending');
            $table->timestamp('verified_at')->nullable();
            $table->decimal('trust_score', 5, 2)->default(70.00);
            $table->decimal('completion_rate', 5, 2)->default(100.00);
            $table->integer('total_errands')->default(0);
            $table->integer('cancelled_errands')->default(0);
            $table->decimal('average_rating', 3, 2)->default(0.00);
            $table->bigInteger('total_earnings')->default(0);
            $table->decimal('current_latitude', 10, 8)->nullable();
            $table->decimal('current_longitude', 11, 8)->nullable();
            $table->timestamp('location_updated_at')->nullable();
            $table->enum('background_check_status', ['pending', 'cleared', 'failed'])->default('pending');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('runner_profiles');
    }
};
