<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

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

    public function kepalaKeluarga()
    {
        return $this->belongsTo(Warga::class, 'kepala_keluarga_id');
    }

    public function anggota()
    {
        return $this->hasMany(Warga::class, 'keluarga_id');
    }

    public function tagihanIuran()
    {
        return $this->hasMany(TagihanIuran::class, 'keluarga_id');
    }
}
