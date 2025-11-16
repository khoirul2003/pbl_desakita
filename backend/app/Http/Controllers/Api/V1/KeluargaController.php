<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Keluarga;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;

class KeluargaController extends Controller
{
    /**
     * Tampilkan daftar keluarga, ter-filter berdasarkan role.
     */
    public function index(Request $request)
    {
        $user = Auth::user();
        $query = Keluarga::query()->with('kepalaKeluarga');

        if ($user->isRt()) {
            $query->where('rt', $user->warga->rt)
                ->where('rw', $user->warga->rw);
        } elseif ($user->isRw()) {
            $query->where('rw', $user->warga->rw);
        } elseif (!$user->isAdmin()) {
            return response()->json(['message' => 'Akses ditolak.'], 403);
        }

        if ($request->has('search')) {
            $search = $request->input('search');
            $query->where('no_kk', 'like', "%{$search}%")
                ->orWhereHas('kepalaKeluarga', function ($q) use ($search) {
                    $q->where('nama_lengkap', 'like', "%{$search}%");
                });
        }

        return $query->paginate(10);
    }

    /**
     * Simpan keluarga baru. (Hanya Admin / RT)
     * Note: Ini flow-nya kompleks. Pendaftaran KK baru seharusnya via AuthController@register
     * Endpoint ini mungkin tidak diperlukan, atau hanya untuk Admin.
     */
    public function store(Request $request)
    {
        if (!Auth::user()->isAdmin()) {
            return response()->json(['message' => 'Hanya Admin yang bisa menambah KK baru via endpoint ini.'], 403);
        }

        // ... Logika validasi dan pembuatan KK + Warga (Kepala Keluarga) + User ...
        // Mirip dengan AuthController@register
        return response()->json(['message' => 'Fitur belum diimplementasi. Gunakan endpoint /register.'], 501);
    }

    /**
     * Tampilkan detail 1 keluarga.
     */
    public function show(Keluarga $keluarga)
    {
        $user = Auth::user();

        // Otorisasi: Admin, atau RT/RW yang sesuai
        if (
            $user->isAdmin() ||
            ($user->isRt() && $user->warga->rt == $keluarga->rt && $user->warga->rw == $keluarga->rw) ||
            ($user->isRw() && $user->warga->rw == $keluarga->rw)
        ) {
            return $keluarga->load('kepalaKeluarga', 'anggota');
        }

        return response()->json(['message' => 'Akses ditolak.'], 403);
    }

    /**
     * Update data keluarga.
     */
    public function update(Request $request, Keluarga $keluarga)
    {
        $user = Auth::user();

        if (!$user->isAdmin() && !($user->isRt() && $user->warga->rt == $keluarga->rt && $user->warga->rw == $keluarga->rw)) {
            return response()->json(['message' => 'Akses ditolak.'], 403);
        }

        $validator = Validator::make($request->all(), [
            'no_kk' => 'string|max:50|unique:keluarga,no_kk,' . $keluarga->id,
            'alamat' => 'string',
            'rt' => 'string|max:3',
            'rw' => 'string|max:3',
            'kepala_keluarga_id' => 'exists:warga,id'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $keluarga->update($request->all());
        return response()->json($keluarga);
    }

    /**
     * Hapus data keluarga.
     */
    public function destroy(Keluarga $keluarga)
    {
        $user = Auth::user();

        if (!$user->isAdmin()) {
            return response()->json(['message' => 'Akses ditolak. Hanya Admin.'], 403);
        }

        // Hati-hati: Ini akan menghapus semua warga di dalamnya jika FK di-set cascade.
        // Sebaiknya di-set 'set null' di migrasi warga.
        $keluarga->anggota()->update(['keluarga_id' => null]);
        $keluarga->delete();

        return response()->json(null, 204);
    }
}
