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
        Schema::create('keluarga', function (Blueprint $table) {
            $table->id();
            $table->string('no_kk', 50)->unique();
            $table->text('alamat');
            $table->string('rt', 3);
            $table->string('rw', 3);
            // Kolom kepala_keluarga_id akan ditambahkan di migrasi terpisah
            // untuk menghindari masalah circular foreign key dependency.
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('keluarga');
    }
};
