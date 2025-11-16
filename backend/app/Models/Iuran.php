<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\TagihanIuran> $tagihan
 * @property-read int|null $tagihan_count
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Iuran newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Iuran newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Iuran query()
 * @mixin \Eloquent
 */
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
