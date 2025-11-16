<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * @property-read \App\Models\User|null $pencatat
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Keuangan newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Keuangan newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|Keuangan query()
 * @mixin \Eloquent
 */
class Keuangan extends Model
{
    use HasFactory;

    protected $table = 'keuangan';

    protected $fillable = [
        'tipe',
        'jumlah',
        'keterangan',
        'tanggal',
        'rt',
        'rw',
        'created_by_user_id',
    ];

    /**
     * Dapatkan user yang mencatat transaksi ini.
     */
    public function pencatat()
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }
}
