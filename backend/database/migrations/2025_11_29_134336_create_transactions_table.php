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
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sender_warga_id')->nullable()->constrained('warga')->onDelete('set null'); // Pengirim
            $table->foreignId('receiver_warga_id')->nullable()->constrained('warga')->onDelete('set null'); // Penerima

            $table->enum('type', ['TOPUP', 'TRANSFER_IN', 'TRANSFER_OUT', 'PAYMENT_IURAN', 'PAYMENT_PPOB']);
            $table->decimal('amount', 15, 2);
            $table->decimal('fee', 15, 2)->default(0.00);
            $table->string('reference', 255)->nullable(); // Misal: ID tagihan iuran, atau nomor transaksi Desapay
            $table->text('description')->nullable();

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
