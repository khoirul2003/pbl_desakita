<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Kegiatan;
use App\Models\Keuangan;
use App\Models\Warga;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;

class KegiatanController extends Controller
{
    public function index(Request $request)
    {
        $user = Auth::user();
        $query = Kegiatan::query();

        if (!$user->isAdmin()) {
            $warga = $user->warga;

            if ($warga) {
                $query->where(function ($q) use ($warga) {
                    $q->whereNull('rt')
                        ->orWhere('rw', $warga->rw)
                        ->orWhere(function ($q2) use ($warga) {
                            $q2->where('rt', $warga->rt)->where('rw', $warga->rw);
                        });
                });
            } else {

                if ($user->role !== 'admin') {
                    $query->whereRaw('1 = 0');
                }
            }
        }

        if ($request->has('search')) {
            $query->where('nama_kegiatan', 'like', '%' . $request->input('search') . '%');
        }

        return $query->with('pembuat')->latest('tanggal_mulai')->paginate(10);
    }


    /**
     * Simpan (buat) kegiatan baru. (Admin, RW, RT)
     * Endpoint: POST /api/v1/kegiatan
     */
    public function store(Request $request)
    {
        $user = Auth::user();
        if ($user->role == 'warga') {
            return response()->json(['message' => 'Akses ditolak.'], 403);
        }

        $validated = Validator::make($request->all(), [
            'nama_kegiatan' => 'required|string|max:255',
            'deskripsi' => 'required|string',
            'lokasi' => 'required|string',
            'tanggal_mulai' => 'required|date',
            'tanggal_selesai' => 'required|date|after_or_equal:tanggal_mulai',
            'rt' => 'nullable|string|max:3',
            'rw' => 'nullable|string|max:3',
            'total_biaya' => 'required|numeric|min:0',
        ]);

        if ($validated->fails()) {
            return response()->json(['errors' => $validated->errors()], 422);
        }

        $data = $validated->validated();
        $totalBiaya = $data['total_biaya'];
        $data['created_by_user_id'] = $user->id;


        if ($user->isRt() && ($data['rt'] != $user->warga->rt || $data['rw'] != $user->warga->rw)) {
            return response()->json(['message' => 'RT hanya bisa membuat kegiatan di lingkup RT-nya sendiri.'], 403);
        }

        DB::beginTransaction();
        try {

            $kegiatan = Kegiatan::create($data);


            if ($totalBiaya > 0) {
                $this->processFundAllocation($kegiatan, $totalBiaya, $user);
            }

            DB::commit();
            return response()->json($kegiatan, 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Gagal membuat kegiatan dan memproses dana: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Tampilkan detail kegiatan.
     * Endpoint: GET /api/v1/kegiatan/{id}
     */
    public function show(Kegiatan $kegiatan)
    {
        $user = Auth::user();
        $warga = $user->warga;

        if (
            $user->isAdmin() ||
            ($warga && (($kegiatan->rt == $warga->rt && $kegiatan->rw == $warga->rw) || ($kegiatan->rw == $warga->rw) || ($kegiatan->rt == null && $kegiatan->rw == null)))
        ) {
            return $kegiatan->load('pembuat');
        }

        return response()->json(['message' => 'Akses ditolak.'], 403);
    }

    /**
     * Update detail kegiatan.
     * Endpoint: PUT /api/v1/kegiatan/{id}
     */
    public function update(Request $request, Kegiatan $kegiatan)
    {
        $user = Auth::user();
        if (!$user->isAdmin() && !$user->isRw() && !$user->isRt()) {
            return response()->json(['message' => 'Akses ditolak. Hanya Admin/RW/RT yang bisa mengubah kegiatan.'], 403);
        }

        $validated = Validator::make($request->all(), [
            'nama_kegiatan' => 'sometimes|string|max:255',
            'deskripsi' => 'sometimes|string',
            'lokasi' => 'sometimes|string',
            'tanggal_mulai' => 'sometimes|date',
            'tanggal_selesai' => 'sometimes|date|after_or_equal:tanggal_mulai',
            'rt' => 'nullable|string|max:3',
            'rw' => 'nullable|string|max:3',
            'total_biaya' => 'sometimes|numeric|min:0',
        ]);

        if ($validated->fails()) {
            return response()->json(['errors' => $validated->errors()], 422);
        }

        $kegiatan->update($validated->validated());

        return response()->json($kegiatan, 200);
    }

    /**
     * Hapus kegiatan.
     * Endpoint: DELETE /api/v1/kegiatan/{id}
     */
    public function destroy(Kegiatan $kegiatan)
    {
        if (!Auth::user()->isAdmin()) {
            return response()->json(['message' => 'Akses ditolak. Hanya Admin.'], 403);
        }



        $kegiatan->delete();
        return response()->json(null, 204);
    }


    /**
     * Helper: Menghitung dan mencatat pengeluaran kas berdasarkan lingkup
     * Aturan Pembagian: RT (ambil dana RT) -> RW (bagi rata ke RT di RW) -> Desa (ambil dari kas umum)
     */
    private function processFundAllocation(Kegiatan $kegiatan, float $totalBiaya, $user)
    {
        $targetRt = $kegiatan->rt;
        $targetRw = $kegiatan->rw;
        $currentDate = now();
        $eventName = $kegiatan->nama_kegiatan;


        if ($targetRt !== null && $targetRw !== null) {

            Keuangan::create([
                'tipe' => 'PENGELUARAN',
                'jumlah' => $totalBiaya,
                'keterangan' => "Pengeluaran Kegiatan: {$eventName}",
                'tanggal' => $currentDate,
                'rt' => $targetRt,
                'rw' => $targetRw,
                'created_by_user_id' => $user->id,
            ]);
        } elseif ($targetRw !== null) {

            $rtList = Warga::where('rw', $targetRw)
                ->whereNotNull('rt')
                ->select('rt')
                ->distinct()
                ->pluck('rt')
                ->filter()
                ->toArray();

            $rtCount = count($rtList);
            if ($rtCount === 0) {

                $rtList = ['000'];
                $costPerRt = $totalBiaya;
            } else {
                $costPerRt = $totalBiaya / $rtCount;
            }

            foreach ($rtList as $rt) {

                Keuangan::create([
                    'tipe' => 'PENGELUARAN',
                    'jumlah' => $costPerRt,
                    'keterangan' => "Kontribusi Kegiatan RW: {$eventName} (Beban: RT {$rt})",
                    'tanggal' => $currentDate,
                    'rt' => $rt,
                    'rw' => $targetRw,
                    'created_by_user_id' => $user->id,
                ]);
            }
        } else {

            Keuangan::create([
                'tipe' => 'PENGELUARAN',
                'jumlah' => $totalBiaya,
                'keterangan' => "Pengeluaran Kegiatan Desa: {$eventName}",
                'tanggal' => $currentDate,
                'rt' => null,
                'rw' => null,
                'created_by_user_id' => $user->id,
            ]);
        }
    }
}
