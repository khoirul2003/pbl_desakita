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
        Schema::create('warga', function (Blueprint $table) {
            $table->id();
            $table->string('nik', 50)->unique();
            $table->string('nama_lengkap');
            $table->string('tempat_lahir');
            $table->date('tanggal_lahir');
            $table->enum('jenis_kelamin', ['L', 'P']);
            $table->text('alamat_ktp');
            $table->string('agama');
            $table->string('status_perkawinan');
            $table->string('pekerjaan');
            $table->string('kewarganegaraan')->default('WNI');
            $table->string('rt', 3);
            $table->string('rw', 3);

            $table->foreignId('keluarga_id')->nullable()->constrained('keluarga')->onDelete('set null');

            $table->enum('status_dalam_keluarga', ['KEPALA_KELUARGA', 'ISTRI', 'ANAK', 'LAINNYA']);
            $table->string('no_hp')->nullable();
            $table->string('foto_ktp')->nullable(); // Path/URL
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('warga');
    }
};
