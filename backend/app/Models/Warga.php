<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

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

    public function user()
    {
        return $this->hasOne(User::class, 'warga_id');
    }

    public function keluarga()
    {
        return $this->belongsTo(Keluarga::class, 'keluarga_id');
    }

    public function kepalaDariKeluarga()
    {
        return $this->hasOne(Keluarga::class, 'kepala_keluarga_id');
    }

    public function tagihanIuran()
    {
        return $this->hasMany(TagihanIuran::class, 'warga_id');
    }

    public function wallet()
    {

        return $this->hasOne(Wallet::class, 'warga_id');
    }
}
