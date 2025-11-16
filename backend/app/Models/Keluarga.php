<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\Warga> $anggota
 * @property-read int|null $anggota_count
 * @property-read \App\Models\Warga|null $kepalaKeluarga
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\TagihanIuran> $tagihanIuran
 * @property-read int|null $tagihan_iuran_count
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Keluarga newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Keluarga newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Keluarga query()
 * @mixin \Eloquent
 */
class Keluarga extends Model
{
    use HasFactory;

    protected $table = 'keluarga';

    protected $fillable = [
        'no_kk',
        'kepala_keluarga_id',
        'alamat',
        'rt',
        'rw',
    ];

    /**
     * Dapatkan data warga yang menjadi kepala keluarga.
     */
    public function kepalaKeluarga()
    {
        return $this->belongsTo(Warga::class, 'kepala_keluarga_id');
    }

    /**
     * Dapatkan semua anggota keluarga ini.
     */
    public function anggota()
    {
        return $this->hasMany(Warga::class, 'keluarga_id');
    }

    /**
     * Dapatkan semua tagihan iuran untuk keluarga ini.
     */
    public function tagihanIuran()
    {
        return $this->hasMany(TagihanIuran::class, 'keluarga_id');
    }
}
