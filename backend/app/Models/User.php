<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $table = 'users';

    protected $fillable = [
        'email',
        'password',
        'role',
        'warga_id',
        'face_features',
    ];

    protected $hidden = [
        'password',
        'remember_token',
        'face_features',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
    ];

    protected $with = ['warga'];

    public function isAdmin()
    {
        return $this->role === 'admin';
    }

    public function isRw()
    {
        return $this->role === 'rw';
    }

    public function isRt()
    {
        return $this->role === 'rt';
    }

    public function kegiatanDibuat()
    {
        return $this->hasMany(Kegiatan::class, 'created_by_user_id');
    }

    public function acaraDibuat()
    {
        return $this->hasMany(Acara::class, 'created_by_user_id');
    }

    public function warga()
    {
        return $this->belongsTo(Warga::class, 'warga_id')->with('wallet');
    }
}
