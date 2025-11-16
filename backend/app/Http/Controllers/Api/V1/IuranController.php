<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Iuran;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;
use App\Models\Warga;
use App\Models\Keluarga;
use App\Models\TagihanIuran;
use Carbon\Carbon;

class IuranController extends Controller
{
    /**
     * Tampilkan daftar iuran.
     */
    public function index(Request $request)
    {
        $user = Auth::user();
        $query = Iuran::query();

        if ($user->isRt()) {
            $query->where('rt', $user->warga->rt)
                ->where('rw', $user->warga->rw);
        } elseif ($user->isRw()) {
            $query->where('rw', $user->warga->rw);
        } elseif (!$user->isAdmin()) {

            $warga = $user->warga;
            $query->where(function ($q) use ($warga) {
                $q->whereNull('rt')
                    ->orWhere('rw', $warga->rw)
                    ->orWhere(function ($q2) use ($warga) {
                        $q2->where('rt', $warga->rt)->where('rw', $warga->rw);
                    });
            });
        }

        return $query->paginate(10);
    }

    /**
     * Buat Iuran baru. (Admin, RW, RT)
     */
    public function store(Request $request)
    {
        $user = Auth::user();
        if ($user->role == 'warga') {
            return response()->json(['message' => 'Akses ditolak.'], 403);
        }

        $validator = Validator::make($request->all(), [
            'nama_iuran' => 'required|string|max:255',
            'deskripsi' => 'nullable|string',
            'jumlah' => 'required|numeric|min:0',
            'tipe' => 'required|in:PER_WARGA,PER_KELUARGA',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $validator->validated();


        if ($user->isRt()) {
            $data['rt'] = $user->warga->rt;
            $data['rw'] = $user->warga->rw;
        } elseif ($user->isRw()) {
            $data['rt'] = null;
            $data['rw'] = $user->warga->rw;
        }


        $iuran = Iuran::create($data);




        return response()->json($iuran, 201);
    }



    public function show(Iuran $iuran)
    {

        return $iuran;
    }

    public function update(Request $request, Iuran $iuran)
    {

        $iuran->update($request->all());
        return $iuran;
    }

    public function destroy(Iuran $iuran)
    {

        $iuran->delete();
        return response()->json(null, 204);
    }


    private function generateTagihan(Iuran $iuran)
    {
        $bulanIni = Carbon::now()->month;
        $tahunIni = Carbon::now()->year;

        if ($iuran->tipe == 'PER_KELUARGA') {
            $query = Keluarga::query();
            if ($iuran->rt) $query->where('rt', $iuran->rt);
            if ($iuran->rw) $query->where('rw', $iuran->rw);

            $keluargas = $query->get();
            foreach ($keluargas as $keluarga) {
                TagihanIuran::firstOrCreate(
                    [
                        'iuran_id' => $iuran->id,
                        'keluarga_id' => $keluarga->id,
                        'periode_bulan' => $bulanIni,
                        'periode_tahun' => $tahunIni,
                    ],
                    ['jumlah_bayar' => $iuran->jumlah]
                );
            }
        }

    }
}
