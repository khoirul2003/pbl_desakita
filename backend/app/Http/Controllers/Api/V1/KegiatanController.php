<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Kegiatan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;

class KegiatanController extends Controller
{
    /**
     * Tampilkan daftar kegiatan, ter-filter.
     */
    public function index(Request $request)
    {
        $user = Auth::user();
        $query = Kegiatan::query();

        // Semua role bisa melihat kegiatan, tapi ter-filter
        $warga = $user->warga;
        $query->where(function ($q) use ($warga) {
            $q->whereNull('rt') // Kegiatan level desa
                ->orWhere('rw', $warga->rw) // Kegiatan level RW
                ->orWhere(function ($q2) use ($warga) {
                    $q2->where('rt', $warga->rt)->where('rw', $warga->rw); // Kegiatan level RT
                });
        });

        return $query->latest('tanggal_mulai')->paginate(10);
    }

    /**
     * Simpan kegiatan baru. (Admin, RW, RT)
     */
    public function store(Request $request)
    {
        $user = Auth::user();
        if ($user->role == 'warga') {
            return response()->json(['message' => 'Akses ditolak.'], 403);
        }

        $validator = Validator::make($request->all(), [
            'nama_kegiatan' => 'required|string|max:255',
            'deskripsi' => 'required|string',
            'tanggal_mulai' => 'required|date',
            'tanggal_selesai' => 'required|date|after_or_equal:tanggal_mulai',
            'lokasi' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $validator->validated();
        $data['created_by_user_id'] = $user->id;

        if ($user->isRt()) {
            $data['rt'] = $user->warga->rt;
            $data['rw'] = $user->warga->rw;
        } elseif ($user->isRw()) {
            $data['rt'] = null;
            $data['rw'] = $user->warga->rw;
        }

        $kegiatan = Kegiatan::create($data);
        return response()->json($kegiatan, 201);
    }

    // --- (Fungsi show, update, destroy mirip dengan controller lain) ---
    public function show(Kegiatan $kegiatan)
    {
        // ... tambahkan logika otorisasi ...
        return $kegiatan->load('pembuat');
    }

    public function update(Request $request, Kegiatan $kegiatan)
    {
        // ... tambahkan logika otorisasi ...
        $kegiatan->update($request->all());
        return $kegiatan;
    }

    public function destroy(Kegiatan $kegiatan)
    {
        // ... tambahkan logika otorisasi ...
        $kegiatan->delete();
        return response()->json(null, 204);
    }
}
