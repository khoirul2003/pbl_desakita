<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * @property-read \App\Models\Keluarga|null $keluarga
 * @property-read \App\Models\Keluarga|null $kepalaDariKeluarga
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\TagihanIuran> $tagihanIuran
 * @property-read int|null $tagihan_iuran_count
 * @property-read \App\Models\User|null $user
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Warga newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Warga newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Warga query()
 * @mixin \Eloquent
 */
class Warga extends Model
{
    use HasFactory;

    protected $table = 'warga';

    protected $fillable = [
        'nik',
        'nama_lengkap',
        'tempat_lahir',
        'tanggal_lahir',
        'jenis_kelamin',
        'alamat_ktp',
        'agama',
        'status_perkawinan',
        'pekerjaan',
        'kewarganegaraan',
        'rt',
        'rw',
        'keluarga_id',
        'status_dalam_keluarga',
        'no_hp',
        'foto_ktp',
    ];

    /**
     * Dapatkan akun user yang terkait dengan data warga ini.
     */
    public function user()
    {
        return $this->hasOne(User::class, 'warga_id');
    }

    /**
     * Dapatkan keluarga tempat warga ini terdaftar.
     */
    public function keluarga()
    {
        return $this->belongsTo(Keluarga::class, 'keluarga_id');
    }

    /**
     * Dapatkan keluarga jika warga ini adalah kepala keluarganya.
     */
    public function kepalaDariKeluarga()
    {
        return $this->hasOne(Keluarga::class, 'kepala_keluarga_id');
    }

    /**
     * Dapatkan semua tagihan iuran untuk warga ini.
     */
    public function tagihanIuran()
    {
        return $this->hasMany(TagihanIuran::class, 'warga_id');
    }
}
