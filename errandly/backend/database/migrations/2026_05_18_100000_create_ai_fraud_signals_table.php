<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_fraud_signals', function (Blueprint $table) {
            $table->id();
            $table->string('signal_type', 64);
            $table->string('subject_type', 64);
            $table->string('subject_id', 64);
            $table->enum('severity', ['low', 'medium', 'high'])->default('low');
            $table->string('status', 20)->default('open');
            $table->json('evidence')->nullable();
            $table->text('summary')->nullable();
            $table->timestamps();

            $table->index(['status', 'severity']);
            $table->index(['subject_type', 'subject_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_fraud_signals');
    }
};
