<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Models\Wallet;
use App\Models\Warga;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class WalletController extends Controller
{
    /**
     * Dapatkan saldo dan riwayat transaksi Desapay
     * Endpoint: GET /api/v1/wallet/balance
     */
    public function getBalanceAndTransactions(Request $request)
    {
        $warga = Auth::user()->warga;

        if (!$warga) {
            return response()->json(['message' => 'Akun warga tidak terdaftar.'], 404);
        }

        $wallet = Wallet::where('warga_id', $warga->id)->first();

        // Riwayat transaksi (sebagai pengirim atau penerima)
        $transactions = Transaction::where(function ($query) use ($warga) {
            $query->where('sender_warga_id', $warga->id)
                ->orWhere('receiver_warga_id', $warga->id);
        })
            ->orderBy('created_at', 'desc')
            ->with('sender', 'receiver') // Load relasi untuk nama
            ->limit(10)
            ->get();

        return response()->json([
            'message' => 'Sukses mengambil data Desapay.',
            'wallet' => $wallet,
            'transactions' => $transactions,
        ]);
    }

    /**
     * Isi Saldo (TOPUP Demo/Simulasi)
     * Endpoint: POST /api/v1/wallet/topup
     */
    public function topUp(Request $request)
    {
        $validated = $request->validate([
            'amount' => 'required|numeric|min:1000|max:1000000', // Batasan 1 Juta
        ]);

        $warga = Auth::user()->warga;

        // Ambil Wallet (diasumsikan sudah ada dari Seeder/Register)
        $wallet = Wallet::where('warga_id', $warga->id)->firstOrFail();

        // Gunakan Transaction untuk memastikan konsistensi saldo
        DB::beginTransaction();

        try {
            // 1. Tambah saldo
            $wallet->balance += $validated['amount'];
            $wallet->save();

            // 2. Catat transaksi
            Transaction::create([
                'sender_warga_id' => $warga->id, // Topup dianggap pengirim ke dirinya sendiri (opsional)
                'receiver_warga_id' => $warga->id,
                'type' => 'TOPUP',
                'amount' => $validated['amount'],
                'description' => 'Isi Saldo Desapay (Simulasi)',
            ]);

            DB::commit();

            return response()->json([
                'message' => 'Top Up Berhasil!',
                'new_balance' => $wallet->balance,
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Top Up Gagal. Terjadi kesalahan sistem.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Transfer Saldo Antar Desapay
     * Endpoint: POST /api/v1/wallet/transfer
     */
    public function transfer(Request $request)
    {
        $warga = Auth::user()->warga;

        $validated = $request->validate([
            'account_number_receiver' => ['required', 'string', 'max:20', Rule::notIn([$warga->wallet->desapay_account_number])],
            'amount' => 'required|numeric|min:1000|max:5000000',
            'notes' => 'nullable|string|max:255',
        ]);

        $senderWallet = $warga->wallet;

        // 1. Cek saldo pengirim
        if ($senderWallet->balance < $validated['amount']) {
            return response()->json(['message' => 'Saldo Desapay tidak mencukupi.'], 422);
        }

        // 2. Cari penerima berdasarkan nomor akun
        $receiverWallet = Wallet::where('desapay_account_number', $validated['account_number_receiver'])->first();

        if (!$receiverWallet) {
            return response()->json(['message' => 'Nomor akun Desapay tujuan tidak ditemukan.'], 404);
        }

        $fee = $validated['amount'] * 0.005; // Contoh biaya 0.5%
        $totalAmount = $validated['amount'] + $fee;

        if ($senderWallet->balance < $totalAmount) {
            return response()->json(['message' => 'Saldo tidak cukup untuk biaya transaksi.'], 422);
        }

        DB::beginTransaction();
        try {
            // DEBIT Pengirim
            $senderWallet->balance -= $totalAmount;
            $senderWallet->save();

            // KREDIT Penerima
            $receiverWallet->balance += $validated['amount'];
            $receiverWallet->save();

            // Catat Transaksi Pengirim (TRANSFER_OUT)
            Transaction::create([
                'sender_warga_id' => $warga->id,
                'receiver_warga_id' => $receiverWallet->warga_id,
                'type' => 'TRANSFER_OUT',
                'amount' => $validated['amount'],
                'fee' => $fee,
                'description' => $validated['notes'] ?? 'Transfer Desapay',
            ]);

            // Catat Transaksi Penerima (TRANSFER_IN)
            Transaction::create([
                'sender_warga_id' => $warga->id,
                'receiver_warga_id' => $receiverWallet->warga_id,
                'type' => 'TRANSFER_IN',
                'amount' => $validated['amount'],
                'fee' => 0,
                'description' => 'Terima Transfer Desapay',
            ]);

            DB::commit();

            return response()->json([
                'message' => 'Transfer berhasil.',
                'new_balance' => $senderWallet->balance,
                'fee_charged' => $fee,
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Transfer Gagal. Terjadi kesalahan sistem.',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
