<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Acara;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;

class AcaraController extends Controller
{
    /**
     * Tampilkan daftar acara, ter-filter.
     * (Logika sama persis dengan KegiatanController)
     */
    public function index(Request $request)
    {
        $user = Auth::user();
        $query = Acara::query();

        $warga = $user->warga;
        $query->where(function ($q) use ($warga) {
            $q->whereNull('rt')
                ->orWhere('rw', $warga->rw)
                ->orWhere(function ($q2) use ($warga) {
                    $q2->where('rt', $warga->rt)->where('rw', $warga->rw);
                });
        });

        return $query->latest('tanggal_mulai')->paginate(10);
    }

    /**
     * Simpan acara baru. (Admin, RW, RT)
     * (Logika sama persis dengan KegiatanController)
     */
    public function store(Request $request)
    {
        $user = Auth::user();
        if ($user->role == 'warga') {
            return response()->json(['message' => 'Akses ditolak.'], 403);
        }

        $validator = Validator::make($request->all(), [
            'nama_acara' => 'required|string|max:255',
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

        $acara = Acara::create($data);
        return response()->json($acara, 201);
    }

    // --- (Fungsi show, update, destroy mirip dengan controller lain) ---
    public function show(Acara $acara)
    {
        return $acara->load('pembuat');
    }

    public function update(Request $request, Acara $acara)
    {
        $acara->update($request->all());
        return $acara;
    }

    public function destroy(Acara $acara)
    {
        $acara->delete();
        return response()->json(null, 204);
    }
}
