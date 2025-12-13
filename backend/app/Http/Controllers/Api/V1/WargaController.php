<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Warga;
use App\Models\Keluarga;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;

class WargaController extends Controller
{

    public function index(Request $request)
    {
        $user = Auth::user();
        $query = Warga::query()->with('keluarga');

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
            $query->where(function ($q) use ($search) {
                $q->where('nama_lengkap', 'like', "%{$search}%")
                    ->orWhere('nik', 'like', "%{$search}%");
            });
        }

        return $query->paginate(10);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'nik' => 'required|string|max:50|unique:warga,nik',
            'nama_lengkap' => 'required|string|max:255',
            'tempat_lahir' => 'required|string',
            'tanggal_lahir' => 'required|date',
            'jenis_kelamin' => 'required|in:L,P',
            'alamat_ktp' => 'required|string',
            'agama' => 'required|string',
            'status_perkawinan' => 'required|string',
            'pekerjaan' => 'required|string',

            'rt' => 'required|string|max:3',
            'rw' => 'required|string|max:3',
            'keluarga_id' => 'required|exists:keluarga,id',
        ]);


        if ($validator->fails()) {
            return response()->json(['error' => $validator->errors()], 422);
        }

        $warga = new Warga($request->all());
        $warga->save();

        return response()->json($warga, 201);
    }

    public function show(Request $request, Warga $warga)
    {
        $user = Auth::user();

        if (
            $user->isAdmin() ||
            ($user->isRt() && $user->warga->rt == $warga->rt && $user->warga->rw == $warga->rw) ||
            ($user->isRw() && $user->warga->rw == $warga->rw)
        ) {
            return $warga->load('keluarga', 'user');
        }

        return response()->json(['message' => 'Akses ditolak.'], 403);
    }

    public function update(Request $request, Warga $warga)
    {
        $user = Auth::user();


        if (!$user->isAdmin() && !($user->isRt() && $user->warga->rt == $warga->rt && $user->warga->rw == $warga->rw)) {
            return response()->json(['message' => 'Akses ditolak.'], 403);
        }

        $validator = Validator::make($request->all(), [
            'nik' => 'string|max:50|unique:warga,nik,' . $warga->id,
            'nama_lengkap' => 'string|max:255',
            'keluarga_id' => 'exists:keluarga,id',

        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $warga->update($request->all());

        return response()->json($warga);
    }

    public function destroy(Warga $warga)
    {
        $user = Auth::user();

        if (!$user->isAdmin() && !($user->isRt() && $user->warga->rt == $warga->rt && $user->warga->rw == $warga->rw)) {
            return response()->json(['message' => 'Akses ditolak.'], 403);
        }

        $warga->delete();

        return response()->json(null, 204);
    }

    public function listRw()
    {
        return Warga::select('rw')
            ->distinct()
            ->orderBy('rw')
            ->pluck('rw');
    }

    public function listRtByRw(Request $request)
    {
        $request->validate(['rw' => 'required']);

        return Warga::where('rw', $request->rw)
            ->select('rt')
            ->distinct()
            ->orderBy('rt')
            ->pluck('rt');
    }


    
}
