<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Warga;
use App\Models\Keluarga;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    /**
     * Registrasi Warga Baru.
     * Ini adalah logic yang cukup kompleks karena membuat 3 data sekaligus:
     * 1. Keluarga (jika belum ada)
     * 2. Warga (sebagai Kepala Keluarga)
     * 3. User (akun untuk login)
     */
    public function register(Request $request)
    {
        $validatedData = $request->validate([
            'nama_lengkap' => 'required|string|max:255',
            'nik' => 'required|string|max:50|unique:warga,nik',
            'email' => 'required|string|email|max:255|unique:users,email',
            'password' => ['required', 'string', Password::min(8)],
            'no_kk' => 'required|string|max:50',
            'rt' => 'required|string|max:3',
            'rw' => 'required|string|max:3',
            'alamat' => 'required|string',




        ]);

        try {

            DB::beginTransaction();



            $keluarga = Keluarga::firstOrCreate(
                ['no_kk' => $validatedData['no_kk']],
                [
                    'alamat' => $validatedData['alamat'],
                    'rt' => $validatedData['rt'],
                    'rw' => $validatedData['rw'],
                ]
            );


            $warga = Warga::create([
                'nik' => $validatedData['nik'],
                'nama_lengkap' => $validatedData['nama_lengkap'],
                'rt' => $validatedData['rt'],
                'rw' => $validatedData['rw'],
                'keluarga_id' => $keluarga->id,
                'status_dalam_keluarga' => 'KEPALA_KELUARGA',

                'tempat_lahir' => $request->tempat_lahir ?? 'Data Belum Diisi',
                'tanggal_lahir' => $request->tanggal_lahir ?? '1990-01-01',
                'jenis_kelamin' => $request->jenis_kelamin ?? 'L',
                'alamat_ktp' => $validatedData['alamat'],
                'agama' => $request->agama ?? 'Data Belum Diisi',
                'status_perkawinan' => $request->status_perkawinan ?? 'Belum Kawin',
                'pekerjaan' => $request->pekerjaan ?? 'Data Belum Diisi',
                'no_hp' => $request->no_hp,
            ]);


            if (is_null($keluarga->kepala_keluarga_id)) {
                $keluarga->kepala_keluarga_id = $warga->id;
                $keluarga->save();
            }


            $user = User::create([
                'email' => $validatedData['email'],
                'password' => Hash::make($validatedData['password']),
                'warga_id' => $warga->id,
                'role' => 'warga',
            ]);


            DB::commit();

            return response()->json([
                'message' => 'Registrasi berhasil. Silakan lanjut verifikasi wajah.',
                'user' => $user->load('warga')
            ], 201);
        } catch (\Exception $e) {

            DB::rollBack();
            Log::error('Registrasi Gagal: ' . $e->getMessage());
            return response()->json([
                'message' => 'Terjadi kesalahan saat registrasi.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Login User (Email & Password)
     */
    public function login(Request $request)
    {
        $validatedData = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $validatedData['email'])->first();

        if (!$user || !Hash::check($validatedData['password'], $user->password)) {
            return response()->json([
                'message' => 'Email atau password salah.'
            ], 401);
        }


        $user->tokens()->delete();

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Login berhasil',
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => $user->load('warga')
        ]);
    }

    /**
     * Logout User
     */
    public function logout(Request $request)
    {

        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logout berhasil'
        ]);
    }

    /**
     * Update profile pengguna (Warga & User).
     */
    public function updateProfile(Request $request)
    {
        $user = Auth::user();
        $warga = $user->warga;

        $validator = Validator::make($request->all(), [

            'nama_lengkap' => 'sometimes|string|max:255',
            'no_hp' => 'sometimes|string|max:20|nullable',
            'tempat_lahir' => 'sometimes|string',
            'tanggal_lahir' => 'sometimes|date',
            'alamat_ktp' => 'sometimes|string',
            'agama' => 'sometimes|string',
            'status_perkawinan' => 'sometimes|string',
            'pekerjaan' => 'sometimes|string',



            'current_password' => 'sometimes|required_with:new_password',


            'new_password' => ['sometimes', 'required_with:current_password', \Illuminate\Validation\Rules\Password::min(8), 'confirmed'],
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $validator->validated();


        $passwordData = [];
        if (isset($data['new_password'])) {
            if (!Hash::check($data['current_password'], $user->password)) {
                return response()->json(['errors' => ['current_password' => ['Password saat ini salah.']]], 422);
            }
            $passwordData['password'] = Hash::make($data['new_password']);


            unset($data['current_password'], $data['new_password'], $data['new_password_confirmation']);
        }


        if ($warga) {
            $warga->update($data);
        }


        if (!empty($passwordData)) {
            $user->update($passwordData);
        }

        return response()->json([
            'message' => 'Profil berhasil diperbarui.',
            'user' => $user->fresh()->load('warga')
        ]);
    }

    public function registerFace(Request $request)
    {
        $validatedData = $request->validate([
            'face_features' => 'required|json', // Menerima JSON string dari Flutter
        ]);

        $user = Auth::user();

        // Simpan vektor fitur ke profil user
        $user->update([
            'face_features' => $validatedData['face_features']
        ]);

        return response()->json([
            'message' => 'Fitur wajah berhasil terdaftar.'
        ]);
    }

    /**
     * Mencoba login menggunakan fitur wajah.
     * (Skenario 2 - Login Wajah)
     */
    public function loginFace(Request $request)
    {
        $validatedData = $request->validate([
            'face_features' => 'required|json', // Vektor fitur "login" dari Flutter
        ]);

        // Ini adalah vektor (array 128 angka) dari percobaan login
        $loginVector = json_decode($validatedData['face_features']);

        // Ambil semua user yang SUDAH mendaftarkan wajah
        $usersWithFaces = User::whereNotNull('face_features')->get();

        $matchedUser = null;
        $lowestDistance = 1.0; // Jarak terjauh adalah 1.0

        // Threshold (ambang batas) kemiripan.
        // 0.6 adalah standar dlib. Di bawah 0.6 = mirip, di atas 0.6 = beda orang.
        $distanceThreshold = 0.6;

        foreach ($usersWithFaces as $user) {
            // Ambil vektor yang tersimpan di DB
            $storedVector = json_decode($user->face_features);

            // Hitung jarak antara vektor login dan vektor DB
            $distance = $this->_calculateEuclideanDistance($loginVector, $storedVector);

            if ($distance < $lowestDistance) {
                $lowestDistance = $distance;
                $matchedUser = $user;
            }
        }

        // Cek apakah user yang cocok lolos threshold
        if ($matchedUser && $lowestDistance < $distanceThreshold) {
            // --- LOGIN BERHASIL ---
            // Hapus token lama
            $matchedUser->tokens()->delete();
            // Buat token baru
            $token = $matchedUser->createToken('auth_token')->plainTextToken;

            Log::info("Login Wajah Berhasil: User {$matchedUser->email} (Jarak: {$lowestDistance})");

            return response()->json([
                'message' => 'Login berhasil',
                'token' => $token,
                'token_type' => 'Bearer',
                'user' => $matchedUser->load('warga')
            ]);
        }

        // --- LOGIN GAGAL ---
        Log::warning("Login Wajah Gagal: Wajah tidak dikenali. (Jarak terdekat: {$lowestDistance})");
        return response()->json([
            'message' => 'Wajah tidak dikenali.'
        ], 401);
    }

    /**
     * Helper function untuk menghitung Jarak Euclidean
     * antara dua vektor (array).
     */
    private function _calculateEuclideanDistance(array $vec1, array $vec2): float
    {
        if (count($vec1) != count($vec2)) {
            // Seharusnya tidak pernah terjadi jika datanya dari face_recognition
            return 2.0; // Angka error
        }

        $sum = 0.0;
        for ($i = 0; $i < count($vec1); $i++) {
            $sum += pow($vec1[$i] - $vec2[$i], 2);
        }

        return (float) sqrt($sum);
    }
}
