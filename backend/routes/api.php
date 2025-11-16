<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\Api\V1\WargaController;
use App\Http\Controllers\Api\V1\KeluargaController;
use App\Http\Controllers\Api\V1\IuranController;
use App\Http\Controllers\Api\V1\KeuanganController;
use App\Http\Controllers\Api\V1\KegiatanController;
use App\Http\Controllers\Api\V1\AcaraController;
use App\Http\Controllers\Api\V1\WargaFiturController;


Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::post('/login-face', [AuthController::class, 'loginFace']);

Route::prefix('v1')->middleware('auth:sanctum')->group(function () {


    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/profile', function (Request $request) {
        return $request->user()->load(['warga' => function ($query) {
            $query->with('keluarga');
        }]);
    });

    Route::put('/profile', [AuthController::class, 'updateProfile']);
    
    Route::post('/profile/register-face', [AuthController::class, 'registerFace']);

    Route::apiResource('/warga', WargaController::class);
    Route::apiResource('/keluarga', KeluargaController::class);
    Route::apiResource('/iuran', IuranController::class);
    Route::apiResource('/keuangan', KeuanganController::class);
    Route::apiResource('/kegiatan', KegiatanController::class);
    Route::apiResource('/acara', AcaraController::class);


    Route::prefix('fitur')->group(function () {
        Route::get('/tagihan', [WargaFiturController::class, 'getTagihan']);
        Route::get('/keluarga', [WargaFiturController::class, 'getKeluarga']);
        Route::get('/kegiatan', [WargaFiturController::class, 'getKegiatan']);
        Route::get('/acara', [WargaFiturController::class, 'getAcara']);
        Route::post('/tagihan/{tagihan}/bayar', [WargaFiturController::class, 'bayarTagihan']);
    });
});
