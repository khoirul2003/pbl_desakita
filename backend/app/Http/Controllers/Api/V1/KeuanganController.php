<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Keuangan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;

class KeuanganController extends Controller
{
    /**
     * Tampilkan catatan keuangan, ter-filter.
     */
    public function index(Request $request)
    {
        $user = Auth::user();
        $query = Keuangan::query()->with('pencatat');

        if ($user->isRt()) {
            $query->where('rt', $user->warga->rt)
                ->where('rw', $user->warga->rw);
        } elseif ($user->isRw()) {
            $query->where('rw', $user->warga->rw);
        } elseif (!$user->isAdmin()) {
            // Warga biasa bisa lihat, tapi ter-filter
            $warga = $user->warga;
            $query->where(function ($q) use ($warga) {
                $q->whereNull('rt') // Keuangan level desa
                    ->orWhere('rw', $warga->rw); // Keuangan level RW
                // Warga tidak bisa lihat kas RT lain
            });
        }

        return $query->latest('tanggal')->paginate(15);
    }

    /**
     * Simpan catatan keuangan baru. (Admin, RW, RT)
     */
    public function store(Request $request)
    {
        $user = Auth::user();
        if ($user->role == 'warga') {
            return response()->json(['message' => 'Akses ditolak.'], 403);
        }

        $validator = Validator::make($request->all(), [
            'tipe' => 'required|in:PEMASUKAN,PENGELUARAN',
            'jumlah' => 'required|numeric|min:0',
            'keterangan' => 'required|string',
            'tanggal' => 'required|date',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $validator->validated();
        $data['created_by_user_id'] = $user->id;

        // Set RT/RW otomatis sesuai pembuat
        if ($user->isRt()) {
            $data['rt'] = $user->warga->rt;
            $data['rw'] = $user->warga->rw;
        } elseif ($user->isRw()) {
            $data['rt'] = null; // Kas level RW
            $data['rw'] = $user->warga->rw;
        }
        // Admin (kas desa) tidak set rt/rw

        $keuangan = Keuangan::create($data);
        return response()->json($keuangan, 201);
    }

    // --- (Fungsi show, update, destroy mirip dengan controller lain) ---

    public function show(Keuangan $keuangan)
    {
        // ... tambahkan logika otorisasi ...
        return $keuangan->load('pencatat');
    }

    public function update(Request $request, Keuangan $keuangan)
    {
        // ... tambahkan logika otorisasi ...
        $keuangan->update($request->all());
        return $keuangan;
    }

    public function destroy(Keuangan $keuangan)
    {
        // ... tambahkan logika otorisasi ...
        $keuangan->delete();
        return response()->json(null, 204);
    }
}
