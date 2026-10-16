<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('settings')
            ->where('key', 'min_errand_amount')
            ->update([
                'description' => 'Minimum budget for an errand (in Naira)',
                'updated_at' => now(),
            ]);

        DB::table('settings')
            ->where('key', 'min_withdrawal_amount')
            ->update([
                'description' => 'Minimum withdrawal amount (in Naira)',
                'updated_at' => now(),
            ]);
    }

    public function down(): void
    {
        DB::table('settings')
            ->where('key', 'min_errand_amount')
            ->update([
                'description' => 'Minimum budget for an errand (in kobo/pesewas)',
                'updated_at' => now(),
            ]);
    }
};
