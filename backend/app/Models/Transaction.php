<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'sender_warga_id',
        'receiver_warga_id',
        'type',
        'amount',
        'fee',
        'reference',
        'description',
    ];

    public function sender()
    {
        return $this->belongsTo(Warga::class, 'sender_warga_id');
    }

    public function receiver()
    {
        return $this->belongsTo(Warga::class, 'receiver_warga_id');
    }
}
