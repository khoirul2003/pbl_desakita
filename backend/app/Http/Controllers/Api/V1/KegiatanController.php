<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Kegiatan;
use App\Models\Keuangan; // Tambahkan Keuangan Model
use App\Models\Warga; // Tambahkan Warga Model
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;

class KegiatanController extends Controller
{
    /**
     * Tampilkan daftar kegiatan, ter-filter berdasarkan role.
     * Endpoint: GET /api/v1/kegiatan
     */
    public function index(Request $request)
    {
        $user = Auth::user();
        $query = Kegiatan::query();

        // 1. Logika Filter Otorisasi 
        if (!$user->isAdmin()) {
            $warga = $user->warga;

            // Hanya terapkan filter scope jika user adalah RT, RW, atau Warga
            if ($warga) {
                $query->where(function ($q) use ($warga) {
                    $q->whereNull('rt') // Kegiatan level Desa
                        ->orWhere('rw', $warga->rw) // Kegiatan level RW
                        ->orWhere(function ($q2) use ($warga) {
                            // Kegiatan level RT tertentu
                            $q2->where('rt', $warga->rt)->where('rw', $warga->rw);
                        });
                });
            } else {
                // Jika user bukan Admin, tapi tidak terhubung ke data Warga (seperti Admin baru)
                // Ini akan mencegah user melihat data apapun, yang merupakan perilaku aman.
                if ($user->role !== 'admin') {
                    $query->whereRaw('1 = 0'); // Trik untuk mengembalikan set data kosong
                }
            }
        }
        // JIKA ADMIN, KODE AKAN MELEWATI BLOK IF DI ATAS DAN MENGAMBIL SEMUA DATA

        if ($request->has('search')) {
            $query->where('nama_kegiatan', 'like', '%' . $request->input('search') . '%');
        }

        // Eager load pembuat
        // Jika 500 error masih terjadi, coba hapus ->with('pembuat') dan jalankan ulang
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
            return response()->json(['message' => 'RT hanya bisa membuat kegiatan di lingkup RT-nya sendiri.'], 403);
        }

        DB::beginTransaction();
        try {
            // 1. Buat Kegiatan
            $kegiatan = Kegiatan::create($data);

            // 2. Catat Pengeluaran Kas Otomatis
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

        // TODO: Tambahkan LOGIKA untuk MENGEMBALIKAN DANA jika kegiatan dihapus.

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

        // Logika Pengambilan Dana Berjenjang
        if ($targetRt !== null && $targetRw !== null) {
            // Kas RT Tertentu (Lingkup RT)
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
            // Kas RW Tertentu (Lingkup RW)
            $rtList = Warga::where('rw', $targetRw)
                ->whereNotNull('rt') // Hanya RT yang terdaftar
                ->select('rt')
                ->distinct()
                ->pluck('rt')
                ->filter()
                ->toArray();

            $rtCount = count($rtList);
            if ($rtCount === 0) {
                // Jika tidak ada RT terdaftar, dana dianggap diambil dari Kas RW (RT null)
                $rtList = ['000']; // Default RT untuk Kas RW Umum
                $costPerRt = $totalBiaya;
            } else {
                $costPerRt = $totalBiaya / $rtCount;
            }

            foreach ($rtList as $rt) {
                // Catat pengeluaran di masing-masing kas RT
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
            // Kas Desa (Lingkup Umum)
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
