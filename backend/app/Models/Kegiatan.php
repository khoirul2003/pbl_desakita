<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Kegiatan extends Model
{
    use HasFactory;

    protected $table = 'kegiatan';

    protected $fillable = [
        'nama_kegiatan',
        'deskripsi',
        'tanggal_mulai',
        'tanggal_selesai',
        'lokasi',
        'rt',
        'rw',
        'total_biaya',
        'created_by_user_id',
    ];

    public function pembuat()
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }
}
