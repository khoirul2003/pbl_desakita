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
        Schema::create('tagihan_iuran', function (Blueprint $table) {
            $table->id();
            $table->foreignId('iuran_id')->constrained('iuran')->onDelete('cascade');
            $table->foreignId('warga_id')->nullable()->constrained('warga')->onDelete('cascade');
            $table->foreignId('keluarga_id')->nullable()->constrained('keluarga')->onDelete('cascade');

            $table->integer('periode_bulan');
            $table->integer('periode_tahun');
            $table->decimal('jumlah_bayar', 15, 2);
            $table->enum('status_pembayaran', ['BELUM_BAYAR', 'PENDING', 'LUNAS', 'GAGAL'])->default('BELUM_BAYAR');
            $table->dateTime('tanggal_bayar')->nullable();
            $table->string('payment_gateway_order_id')->nullable();

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tagihan_iuran');
    }
};
