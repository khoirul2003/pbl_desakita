<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\TagihanIuran;
use App\Models\Kegiatan;
use App\Models\Acara;

class WargaFiturController extends Controller
{
    /**
     * Dapatkan semua tagihan untuk warga yang login.
     */
    public function getTagihan(Request $request)
    {
        $user = Auth::user();
        $warga = $user->warga;
        $keluarga = $warga->keluarga;

        $query = TagihanIuran::query()->with('iuran')
            ->where('status_pembayaran', '!=', 'LUNAS');

        $query->where(function ($q) use ($warga, $keluarga) {
            $q->where('warga_id', $warga->id);
            if ($keluarga) {
                $q->orWhere('keluarga_id', $keluarga->id);
            }
        });

        return $query->orderBy('periode_tahun')->orderBy('periode_bulan')->get();
    }

    /**
     * Dapatkan detail keluarga dari warga yang login.
     */
    public function getKeluarga(Request $request)
    {
        $keluarga = Auth::user()->warga->keluarga;

        if (!$keluarga) {
            return response()->json(['message' => 'Anda tidak terdaftar di keluarga manapun.'], 404);
        }

        return $keluarga->load('kepalaKeluarga', 'anggota');
    }

    /**
     * Dapatkan daftar kegiatan yang relevan untuk warga.
     */
    public function getKegiatan(Request $request)
    {
        $warga = Auth::user()->warga;

        $query = Kegiatan::query();
        $query->where(function ($q) use ($warga) {
            $q->whereNull('rt')
                ->orWhere('rw', $warga->rw)
                ->orWhere(function ($q2) use ($warga) {
                    $q2->where('rt', $warga->rt)->where('rw', $warga->rw);
                });
        })
            ->where('tanggal_selesai', '>=', now());

        return $query->latest('tanggal_mulai')->get();
    }

    public function getAcara(Request $request)
    {
        $warga = Auth::user()->warga;

        $query = Acara::query();
        $query->where(function ($q) use ($warga) {
            $q->whereNull('rt')
                ->orWhere('rw', $warga->rw)
                ->orWhere(function ($q2) use ($warga) {
                    $q2->where('rt', $warga->rt)->where('rw', $warga->rw);
                });
        })
            ->where('tanggal_selesai', '>=', now());

        return $query->latest('tanggal_mulai')->get();
    }

    public function bayarTagihan(Request $request, TagihanIuran $tagihan)
    {
        $user = Auth::user();
        $warga = $user->warga;

        $isMilikWarga = $tagihan->warga_id && $tagihan->warga_id == $warga->id;
        $isMilikKeluarga = $tagihan->keluarga_id && $tagihan->keluarga_id == $warga->keluarga_id;

        if (!$isMilikWarga && !$isMilikKeluarga) {
            return response()->json(['message' => 'Anda tidak berhak mengakses tagihan ini.'], 403);
        }


        if ($tagihan->status_pembayaran == 'LUNAS' || $tagihan->status_pembayaran == 'PENDING') {
            return response()->json(['message' => 'Tagihan ini sudah lunas atau sedang dalam proses pembayaran.'], 422);
        }

        $orderId = 'dummy-order-' . $tagihan->id . '-' . time();
        $snapToken = 'dummy-snap-token-' . $orderId;

        $tagihan->update([
            'status_pembayaran' => 'PENDING',
            'payment_gateway_order_id' => $orderId
        ]);

        return response()->json([
            'message' => 'Permintaan pembayaran dibuat.',
            'snap_token' => $snapToken,
            'payment_url' => null,
            'tagihan' => $tagihan
        ]);
    }
}
