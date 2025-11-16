<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;


class Acara extends Model
{
    use HasFactory;

    protected $table = 'acara';

    protected $fillable = [
        'nama_acara',
        'deskripsi',
        'tanggal_mulai',
        'tanggal_selesai',
        'lokasi',
        'rt',
        'rw',
        'created_by_user_id',
    ];

    /**
     * Dapatkan user yang membuat acara ini.
     */
    public function pembuat()
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }
}
