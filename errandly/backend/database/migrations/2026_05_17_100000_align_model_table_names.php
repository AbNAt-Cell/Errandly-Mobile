<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('errand_status_history') && ! Schema::hasTable('errand_status_histories')) {
            Schema::rename('errand_status_history', 'errand_status_histories');
        }

        if (! Schema::hasTable('errand_status_histories')) {
            Schema::create('errand_status_histories', function (Blueprint $table) {
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
        }

        if (! Schema::hasTable('dispute_messages')) {
            Schema::create('dispute_messages', function (Blueprint $table) {
                $table->id();
                $table->foreignId('dispute_id')->constrained()->cascadeOnDelete();
                $table->foreignId('sender_id')->constrained('users')->cascadeOnDelete();
                $table->text('content');
                $table->boolean('is_admin')->default(false);
                $table->timestamps();

                $table->index(['dispute_id', 'created_at']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('dispute_messages');

        if (Schema::hasTable('errand_status_histories') && ! Schema::hasTable('errand_status_history')) {
            Schema::rename('errand_status_histories', 'errand_status_history');
        }
    }
};
