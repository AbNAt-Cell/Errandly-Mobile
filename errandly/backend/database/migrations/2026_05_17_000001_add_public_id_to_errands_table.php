<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('errands', function (Blueprint $table) {
            $table->uuid('public_id')->nullable()->unique()->after('id');
        });

        DB::table('errands')->whereNull('public_id')->orderBy('id')->each(function ($errand) {
            DB::table('errands')
                ->where('id', $errand->id)
                ->update(['public_id' => (string) Str::uuid()]);
        });
    }

    public function down(): void
    {
        Schema::table('errands', function (Blueprint $table) {
            $table->dropUnique(['public_id']);
            $table->dropColumn('public_id');
        });
    }
};
