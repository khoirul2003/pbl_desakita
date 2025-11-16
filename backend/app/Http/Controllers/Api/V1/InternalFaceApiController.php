<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

/**
 * Controller ini HANYA untuk komunikasi server-ke-server
 * antara FastAPI dan Laravel.
 */
class InternalFaceApiController extends Controller
{
    /**
     * Simpan fitur wajah (base64) ke user.
     */
    public function storeFaceFeature(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|exists:users,email',
            'face_feature' => 'required|string', // base64 string
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $user = User::where('email', $request->email)->first();
        $user->face_features = $request->face_feature;
        $user->save();

        return response()->json(['message' => 'Fitur wajah berhasil disimpan.']);
    }

    /**
     * Ambil fitur wajah user berdasarkan email.
     */
    public function getFaceFeature(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|exists:users,email',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $user = User::where('email', $request->email)->first();

        if (empty($user->face_features)) {
            return response()->json(['message' => 'User tidak memiliki fitur wajah.'], 404);
        }

        return response()->json([
            'email' => $user->email,
            'face_feature' => $user->face_features
        ]);
    }
}
