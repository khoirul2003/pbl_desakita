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
    /**
     * Tampilkan daftar acara, ter-filter berdasarkan role.
     * Endpoint: GET /api/v1/acara
     */
    public function index(Request $request)
    {
        $user = Auth::user();
        $query = Acara::query()->with('pembuat'); // Memuat user yang membuat acara

        // Logika Filter Otorisasi (Sama seperti KegiatanController)
        $warga = $user->warga;
        if ($warga) {
            $query->where(function ($q) use ($warga) {
                $q->whereNull('rt') // Acara level desa
                    ->orWhere('rw', $warga->rw) // Acara level RW
                    ->orWhere(function ($q2) use ($warga) {
                        $q2->where('rt', $warga->rt)->where('rw', $warga->rw); // Acara level RT
                    });
            });
        }

        // Filter Pencarian
        if ($request->has('search')) {
            $query->where('nama_acara', 'like', '%' . $request->input('search') . '%');
        }

        return $query->latest('tanggal_mulai')->paginate(10);
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
            'total_biaya' => 'required|numeric|min:0', // Biaya untuk pendanaan otomatis
        ]);

        if ($validated->fails()) {
            return response()->json(['errors' => $validated->errors()], 422);
        }

        $data = $validated->validated();
        $totalBiaya = $data['total_biaya'];
        $data['created_by_user_id'] = $user->id;

        // Otorisasi lingkup penambahan data
        if ($user->isRt() && ($data['rt'] != $user->warga->rt || $data['rw'] != $user->warga->rw)) {
            return response()->json(['message' => 'RT hanya bisa membuat acara di lingkup RT-nya sendiri.'], 403);
        }

        DB::beginTransaction();
        try {
            // 1. Buat Acara
            $acara = Acara::create($data);

            // 2. Catat Pengeluaran Kas Otomatis
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
        // Otorisasi Tampilan (Sama dengan index)
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

        // TODO: Anda mungkin ingin membuat LOGIKA UNTUK MEREVERSE PENGELUARAN LAMA 
        // DAN MEMPROSES PENGELUARAN BARU jika total_biaya berubah.

        $acara->update($validated->validated());

        return response()->json($acara, 200);
    }

    /**
     * Hapus acara.
     * Endpoint: DELETE /api/v1/acara/{id}
     */
    public function destroy(Acara $acara)
    {
        if (!Auth::user()->isAdmin()) {
            return response()->json(['message' => 'Akses ditolak. Hanya Admin.'], 403);
        }

        // TODO: Tambahkan LOGIKA untuk MENGEMBALIKAN DANA ke kas RT/RW
        // yang terlibat sebelum menghapus.

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
        // Fallback jika Acara Model tidak memiliki nama_kegiatan
        $eventName = $event->nama_acara ?? "Acara/Kegiatan ID: {$event->id}";

        if ($targetRt !== null && $targetRw !== null) {
            // Kas RT Tertentu (Lingkup RT)
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
            // Kas RW Tertentu (Lingkup RW)
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
            // Kas Desa (Lingkup Umum)
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
