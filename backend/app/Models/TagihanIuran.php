<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TagihanIuran extends Model
{
    use HasFactory;

    protected $table = 'tagihan_iuran';

    protected $fillable = [
        'iuran_id',
        'warga_id',
        'keluarga_id',
        'periode_bulan',
        'periode_tahun',
        'jumlah_bayar',
        'status_pembayaran',
        'tanggal_bayar',
        'payment_gateway_order_id',
    ];

    public function iuran()
    {
        return $this->belongsTo(Iuran::class, 'iuran_id');
    }

    public function warga()
    {
        return $this->belongsTo(Warga::class, 'warga_id');
    }

    public function keluarga()
    {
        return $this->belongsTo(Keluarga::class, 'keluarga_id');
    }
}
