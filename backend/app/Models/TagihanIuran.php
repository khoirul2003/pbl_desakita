<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * @property-read \App\Models\Iuran|null $iuran
 * @property-read \App\Models\Keluarga|null $keluarga
 * @property-read \App\Models\Warga|null $warga
 * @method static \Illuminate\Database\Eloquent\Builder<static>|TagihanIuran newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|TagihanIuran newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|TagihanIuran query()
 * @mixin \Eloquent
 */
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

    /**
     * Dapatkan jenis iurannya.
     */
    public function iuran()
    {
        return $this->belongsTo(Iuran::class, 'iuran_id');
    }

    /**
     * Dapatkan data warga yang ditagih (jika iuran perorangan).
     */
    public function warga()
    {
        return $this->belongsTo(Warga::class, 'warga_id');
    }

    /**
     * Dapatkan data keluarga yang ditagih (jika iuran per KK).
     */
    public function keluarga()
    {
        return $this->belongsTo(Keluarga::class, 'keluarga_id');
    }
}
