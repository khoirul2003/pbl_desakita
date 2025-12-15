<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Acara;
use App\Models\Keuangan;
use App\Models\Warga;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;

class AcaraController extends Controller
{

    public function index(Request $request)
    {
        $user = Auth::user();
        $query = Acara::query()->with('pembuat');

        if ($user->isAdmin()) {
            return $query->latest('tanggal_mulai')->paginate(1000);
        }

        $warga = $user->warga;
        if ($warga) {
            $query->where(function ($q) use ($warga) {

                $q->whereNull('rt')
                    ->orWhere('rw', $warga->rw)
                    ->orWhere(function ($q2) use ($warga) {
                        $q2->where('rt', $warga->rt)->where('rw', $warga->rw);
                    });
            });
        }

        if ($request->has('search')) {
            $query->where('nama_acara', 'like', '%' . $request->input('search') . '%');
        }

        return $query->latest('tanggal_mulai')->paginate(1000);
    }


    /**
     * Simpan (buat) acara baru. (Admin, RW, RT)
     * Endpoint: POST /api/v1/acara
     */
    public function store(Request $request)
    {
        $user = Auth::user();
        if ($user->role == 'warga') {
            return response()->json(['message' => 'Akses ditolak.'], 403);
        }

        $validated = Validator::make($request->all(), [
            'nama_acara' => 'required|string|max:255',
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






        DB::beginTransaction();
        try {

            $acara = Acara::create($data);


            if ($totalBiaya > 0) {
                $this->processFundAllocation($acara, $totalBiaya, $user);
            }

            DB::commit();
            return response()->json($acara, 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Gagal membuat acara dan memproses dana: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Tampilkan detail acara.
     * Endpoint: GET /api/v1/acara/{id}
     */
    public function show(Acara $acara)
    {

        $user = Auth::user();
        $warga = $user->warga;

        if (
            $user->isAdmin() ||
            ($warga && (($acara->rt == $warga->rt && $acara->rw == $warga->rw) || ($acara->rw == $warga->rw) || ($acara->rt == null && $acara->rw == null)))
        ) {
            return $acara->load('pembuat');
        }

        return response()->json(['message' => 'Akses ditolak.'], 403);
    }

    /**
     * Update detail acara.
     * Endpoint: PUT /api/v1/acara/{id}
     */
    public function update(Request $request, Acara $acara)
    {
        $user = Auth::user();
        if (!$user->isAdmin() && !$user->isRw()) {
            return response()->json(['message' => 'Akses ditolak. Hanya Admin/RW yang bisa mengubah acara.'], 403);
        }

        $validated = Validator::make($request->all(), [
            'nama_acara' => 'sometimes|string|max:255',
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




        $acara->update($validated->validated());

        return response()->json($acara, 200);
    }

    /**
     * Hapus acara.
     * Endpoint: DELETE /api/v1/acara/{id}
     */
    public function destroy(Acara $acara)
    {
        $user = Auth::user();
        if (!$user->isAdmin() && !$user->isRt() && !$user->isRw()) {
            return response()->json(['message' => 'Akses ditolak. Hanya Admin.'], 403);
        }

        $acara->delete();
        return response()->json(null, 204);
    }


    /**
     * Helper: Menghitung dan mencatat pengeluaran kas berdasarkan lingkup (SAMA PERSIS DENGAN KEGIATAN)
     */
    private function processFundAllocation($event, float $totalBiaya, $user)
    {
        $targetRt = $event->rt;
        $targetRw = $event->rw;
        $currentDate = now();

        $eventName = $event->nama_acara ?? "Acara/Kegiatan ID: {$event->id}";

        if ($targetRt !== null && $targetRw !== null) {

            Keuangan::create([
                'tipe' => 'PENGELUARAN',
                'jumlah' => $totalBiaya,
                'keterangan' => "Pengeluaran {$eventName}",
                'tanggal' => $currentDate,
                'rt' => $targetRt,
                'rw' => $targetRw,
                'created_by_user_id' => $user->id,
            ]);
        } elseif ($targetRw !== null) {

            $rtList = Warga::where('rw', $targetRw)
                ->select('rt')
                ->distinct()
                ->pluck('rt')
                ->filter()
                ->toArray();

            $rtCount = count($rtList);
            if ($rtCount === 0) {
                throw new \Exception("Tidak ada RT terdaftar di RW {$targetRw} untuk menanggung biaya.");
            }

            $costPerRt = $totalBiaya / $rtCount;

            foreach ($rtList as $rt) {
                Keuangan::create([
                    'tipe' => 'PENGELUARAN',
                    'jumlah' => $costPerRt,
                    'keterangan' => "Kontribusi Acara RW: {$eventName}",
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
                'keterangan' => "Pengeluaran Acara Desa: {$eventName}",
                'tanggal' => $currentDate,
                'rt' => null,
                'rw' => null,
                'created_by_user_id' => $user->id,
            ]);
        }
    }
}
