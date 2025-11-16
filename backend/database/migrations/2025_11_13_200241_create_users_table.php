<?php

// PENTING: Hapus file migrasi users bawaan Laravel
// (biasanya 2014_10_12_000000_create_users_table.php)
// dan gunakan file ini sebagai gantinya.

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
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('email')->unique();
            $table->string('password');
            $table->enum('role', ['admin', 'rw', 'rt', 'warga'])->default('warga');

            $table->foreignId('warga_id')->nullable()->unique()->constrained('warga')->onDelete('cascade');

            $table->text('face_features')->nullable(); // JSON string
            $table->rememberToken();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
