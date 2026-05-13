<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('first_name');
            $table->string('last_name');
            $table->string('email')->unique();
            $table->string('phone')->unique();
            $table->string('password');
            $table->timestamp('email_verified_at')->nullable();
            $table->timestamp('phone_verified_at')->nullable();
            $table->string('profile_image')->nullable();
            $table->date('date_of_birth')->nullable();
            $table->enum('gender', ['male', 'female', 'other'])->nullable();
            $table->text('address')->nullable();
            $table->string('city')->nullable();
            $table->string('state')->nullable();
            $table->string('country')->default('Nigeria');
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->string('emergency_contact_name')->nullable();
            $table->string('emergency_contact_phone')->nullable();
            $table->string('referral_code')->unique()->nullable();
            $table->foreignId('referred_by')->nullable()->constrained('users')->nullOnDelete();
            $table->enum('status', ['active', 'pending', 'suspended', 'blacklisted'])->default('pending');
            $table->enum('kyc_status', ['pending', 'submitted', 'approved', 'rejected'])->default('pending');
            $table->boolean('is_online')->default(false);
            $table->timestamp('last_seen_at')->nullable();
            $table->string('device_token')->nullable();
            $table->enum('device_type', ['ios', 'android', 'web'])->nullable();
            $table->text('suspension_reason')->nullable();
            $table->timestamp('suspended_at')->nullable();
            $table->timestamp('suspended_until')->nullable();
            $table->rememberToken();
            $table->softDeletes();
            $table->timestamps();
        });

        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->string('email')->primary();
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });

        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignId('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sessions');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('users');
    }
};
