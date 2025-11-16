<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('keluarga', function (Blueprint $table) {
            // Tambahkan kolom setelah 'no_kk'
            $table->foreignId('kepala_keluarga_id')->nullable()->unique()->after('no_kk')->constrained('warga')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('keluarga', function (Blueprint $table) {
            $table->dropForeign(['kepala_keluarga_id']);
            $table->dropColumn('kepala_keluarga_id');
        });
    }
};
