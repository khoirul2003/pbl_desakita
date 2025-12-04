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
        Schema::table('kegiatan', function (Blueprint $table) {
            // Tambahkan kolom total_biaya untuk mencatat dana yang dikeluarkan
            $table->decimal('total_biaya', 15, 2)->default(0.00)->after('lokasi');
        });

        Schema::table('acara', function (Blueprint $table) {
            // Tambahkan kolom total_biaya untuk mencatat dana yang dikeluarkan
            $table->decimal('total_biaya', 15, 2)->default(0.00)->after('lokasi');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('kegiatan', function (Blueprint $table) {
            $table->dropColumn('total_biaya');
        });

        Schema::table('acara', function (Blueprint $table) {
            $table->dropColumn('total_biaya');
        });
    }
};
