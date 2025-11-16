<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens; // Pastikan use ini ada

/**
 * @property int $id
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\Acara> $acaraDibuat
 * @property-read int|null $acara_dibuat_count
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \App\Models\Kegiatan> $kegiatanDibuat
 * @property-read int|null $kegiatan_dibuat_count
 * @property-read \Illuminate\Notifications\DatabaseNotificationCollection<int, \Illuminate\Notifications\DatabaseNotification> $notifications
 * @property-read int|null $notifications_count
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \Laravel\Sanctum\PersonalAccessToken> $tokens
 * @property-read int|null $tokens_count
 * @property-read \App\Models\Warga|null $warga
 * @method static \Database\Factories\UserFactory factory($count = null, $state = [])
 * @method static \Illuminate\Database\Eloquent\Builder<static>|User newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|User newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|User query()
 * @method static \Illuminate\Database\Eloquent\Builder<static>|User whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|User whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder<static>|User whereUpdatedAt($value)
 * @mixin \Eloquent
 */
class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'users';

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'email',
        'password',
        'role',
        'warga_id',
        'face_features',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
        'face_features', // Sembunyikan data wajah dari response API
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
    ];

    /**
     * Dapatkan data warga yang terkait dengan user ini.
     */
    public function warga()
    {
        return $this->belongsTo(Warga::class, 'warga_id');
    }

    // --- FUNGSI PENTING UNTUK ROLE ---

    /**
     * Cek apakah user adalah Admin.
     */
    public function isAdmin()
    {
        return $this->role === 'admin';
    }

    /**
     * Cek apakah user adalah RW.
     */
    public function isRw()
    {
        return $this->role === 'rw';
    }

    /**
     * Cek apakah user adalah RT.
     */
    public function isRt()
    {
        return $this->role === 'rt';
    }

    // --- AKHIR FUNGSI ROLE ---


    /**
     * Dapatkan semua kegiatan yang dibuat oleh user ini.
     */
    public function kegiatanDibuat()
    {
        return $this->hasMany(Kegiatan::class, 'created_by_user_id');
    }

    /**
     * Dapatkan semua acara yang dibuat oleh user ini.
     */
    public function acaraDibuat()
    {
        return $this->hasMany(Acara::class, 'created_by_user_id');
    }
}
