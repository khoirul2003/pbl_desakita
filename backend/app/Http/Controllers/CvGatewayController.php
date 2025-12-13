<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class CvGatewayController extends Controller
{

    public function extractFeatures(Request $request)
    {
        if (!$request->hasFile('file')) {
            return response()->json([
                'message' => 'File tidak ditemukan'
            ], 400);
        }

        try {
            $file = $request->file('file');

            $response = Http::timeout(120)
                ->attach(
                    'file',
                    file_get_contents($file->getRealPath()),
                    $file->getClientOriginalName()
                )
                ->post('http://127.0.0.1:8001/extract-features');

            return response()->json(
                $response->json(),
                $response->status()
            );
        } catch (\Exception $e) {
            Log::error('Extract Features Error', [
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'message' => 'Gagal extract face features',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    public function checkLiveness(Request $request)
    {
        // Pastikan field 'files' ada
        if (!$request->hasFile('files')) {
            return response()->json([
                'message' => 'File frames tidak ditemukan'
            ], 422);
        }

        $files = $request->file('files');

        // Validasi minimal 5 frame (SESUAI FastAPI)
        if (count($files) < 5) {
            return response()->json([
                'message' => 'Minimal 5 frame diperlukan untuk liveness detection'
            ], 422);
        }

        try {
            $http = Http::timeout(120);

            foreach ($files as $file) {
                $http->attach(
                    'files',
                    fopen($file->getRealPath(), 'r'),
                    $file->getClientOriginalName()
                );
            }

            $response = $http->post('http://127.0.0.1:8001/check-liveness');

            return response()->json(
                $response->json(),
                $response->status()
            );
        } catch (\Exception $e) {
            \Log::error('Check Liveness Gateway Error', [
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'message' => 'Gagal check liveness',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    public function predict(Request $request)
    {
        try {
            $response = Http::timeout(120)->post(
                'http://127.0.0.1:8001/predict',
                $request->all()
            );

            return response()->json(
                $response->json(),
                $response->status()
            );
        } catch (\Exception $e) {
            Log::error('Predict Error', [
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'message' => 'Gagal melakukan prediksi',
                'error'   => $e->getMessage()
            ], 500);
        }
    }
}
