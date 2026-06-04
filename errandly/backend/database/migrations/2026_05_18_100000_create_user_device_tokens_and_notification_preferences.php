<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_device_tokens', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('device_id', 64);
            $table->text('token');
            $table->enum('device_type', ['ios', 'android', 'web'])->default('android');
            $table->string('device_name')->nullable();
            $table->timestamp('last_used_at')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'device_id']);
            $table->index('token');
        });

        Schema::create('user_notification_preferences', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->boolean('push_enabled')->default(true);
            $table->boolean('errand_updates')->default(true);
            $table->boolean('payments')->default(true);
            $table->boolean('account')->default(true);
            $table->boolean('marketing')->default(false);
            $table->boolean('alerts')->default(true);
            $table->timestamps();
        });

        if (Schema::hasColumn('users', 'device_token')) {
            $rows = DB::table('users')
                ->whereNotNull('device_token')
                ->where('device_token', '!=', '')
                ->select('id', 'device_token', 'device_type', 'updated_at')
                ->get();

            foreach ($rows as $row) {
                DB::table('user_device_tokens')->insert([
                    'user_id' => $row->id,
                    'device_id' => 'legacy-' . $row->id,
                    'token' => $row->device_token,
                    'device_type' => in_array($row->device_type, ['ios', 'android', 'web'], true)
                        ? $row->device_type
                        : 'android',
                    'device_name' => 'Migrated device',
                    'last_used_at' => $row->updated_at ?? now(),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('user_notification_preferences');
        Schema::dropIfExists('user_device_tokens');
    }
};
