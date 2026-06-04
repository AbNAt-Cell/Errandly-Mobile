<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_sessions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('channel')->default('customer_app');
            $table->json('metadata')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'updated_at']);
        });

        Schema::create('ai_messages', function (Blueprint $table) {
            $table->id();
            $table->uuid('session_id');
            $table->foreign('session_id')->references('id')->on('ai_sessions')->cascadeOnDelete();
            $table->string('role', 20);
            $table->text('content')->nullable();
            $table->string('tool_name')->nullable();
            $table->json('tool_payload')->nullable();
            $table->timestamps();

            $table->index(['session_id', 'id']);
        });

        Schema::create('ai_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->uuid('session_id')->nullable();
            $table->string('feature', 64);
            $table->string('model', 64)->nullable();
            $table->unsignedInteger('input_tokens')->nullable();
            $table->unsignedInteger('output_tokens')->nullable();
            $table->unsignedInteger('latency_ms')->nullable();
            $table->string('status', 20)->default('success');
            $table->string('error_code')->nullable();
            $table->timestamps();

            $table->index(['feature', 'created_at']);
        });

        Schema::create('ai_tool_calls', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ai_request_id')->constrained('ai_requests')->cascadeOnDelete();
            $table->string('tool_name');
            $table->json('arguments');
            $table->boolean('result_ok')->default(false);
            $table->text('result_summary')->nullable();
            $table->timestamps();
        });

        Schema::create('ai_proposals', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('type', 64);
            $table->json('payload');
            $table->string('payload_hash', 64);
            $table->string('status', 20)->default('pending');
            $table->string('confirmation_token', 64);
            $table->timestamp('expires_at');
            $table->timestamp('confirmed_at')->nullable();
            $table->string('executed_reference')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
        });

        Schema::create('ai_document_chunks', function (Blueprint $table) {
            $table->id();
            $table->string('corpus', 64);
            $table->string('source_path');
            $table->unsignedInteger('chunk_index');
            $table->text('content');
            $table->string('content_hash', 64);
            $table->json('metadata')->nullable();
            $table->json('embedding')->nullable();
            $table->timestamps();

            $table->unique(['corpus', 'content_hash']);
            $table->index('corpus');
        });

        Schema::create('ai_vision_analyses', function (Blueprint $table) {
            $table->id();
            $table->string('subject_type', 64);
            $table->string('subject_id', 64);
            $table->string('model', 64)->nullable();
            $table->json('result');
            $table->json('flags')->nullable();
            $table->timestamps();

            $table->index(['subject_type', 'subject_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_vision_analyses');
        Schema::dropIfExists('ai_document_chunks');
        Schema::dropIfExists('ai_proposals');
        Schema::dropIfExists('ai_tool_calls');
        Schema::dropIfExists('ai_requests');
        Schema::dropIfExists('ai_messages');
        Schema::dropIfExists('ai_sessions');
    }
};
