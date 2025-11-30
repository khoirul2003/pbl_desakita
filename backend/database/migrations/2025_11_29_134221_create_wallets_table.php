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
        Schema::create('wallets', function (Blueprint $table) {
            $table->id();
            // Setiap warga (warga_id) punya 1 wallet.
            $table->foreignId('warga_id')->unique()->constrained('warga')->onDelete('cascade');
            $table->string('desapay_account_number', 20)->unique()->nullable(); // Nomor akun Desapay (misal: NIK atau nomor random)
            $table->decimal('balance', 15, 2)->default(0.00); // Saldo
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('wallets');
    }
};
