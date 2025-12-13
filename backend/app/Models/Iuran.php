<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Iuran extends Model
{
    use HasFactory;

    protected $table = 'iuran';

    protected $fillable = [
        'nama_iuran',
        'deskripsi',
        'jumlah',
        'tipe',
        'rt',
        'rw',
    ];

    public function tagihan()
    {
        return $this->hasMany(TagihanIuran::class, 'iuran_id');
    }
}
