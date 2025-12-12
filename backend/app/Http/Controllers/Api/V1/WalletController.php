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

    public function getBalanceAndTransactions(Request $request)
    {
        $warga = Auth::user()->warga()->with('wallet')->first();

        if (!$warga || !$warga->wallet) {
            return response()->json(['message' => 'Akun warga tidak terdaftar.'], 404);
        }

        $wallet = $warga->wallet;

        $transactions = Transaction::where(function ($query) use ($warga) {
            $query->where('sender_warga_id', $warga->id)
                ->orWhere('receiver_warga_id', $warga->id);
        })
            ->orderBy('created_at', 'desc')
            ->with('sender', 'receiver')
            ->limit(10)
            ->get();

        return response()->json([
            'message' => 'Sukses mengambil data Desapay.',
            'wallet' => $wallet,
            'transactions' => $transactions,
        ]);
    }


    public function topUp(Request $request)
    {
        $validated = $request->validate([
            'amount' => 'required|numeric|min:1000|max:100000000',
        ]);

        $warga = Auth::user()->warga;

        $wallet = Wallet::where('warga_id', $warga->id)->firstOrFail();

        DB::beginTransaction();

        try {

            $wallet->balance += $validated['amount'];
            $wallet->save();

            Transaction::create([
                'sender_warga_id' => $warga->id,
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

    public function transfer(Request $request)
    {
        $warga = Auth::user()->warga;

        $validated = $request->validate([
            'account_number_receiver' => ['required', 'string', 'max:20', Rule::notIn([$warga->wallet->desapay_account_number])],
            'amount' => 'required|numeric|min:1000|max:50000000',
            'notes' => 'nullable|string|max:255',
        ]);

        $senderWallet = $warga->wallet;

        if ($senderWallet->balance < $validated['amount']) {
            return response()->json(['message' => 'Saldo Desapay tidak mencukupi.'], 422);
        }

        $receiverWallet = Wallet::where('desapay_account_number', $validated['account_number_receiver'])->first();

        if (!$receiverWallet) {
            return response()->json(['message' => 'Nomor akun Desapay tujuan tidak ditemukan.'], 404);
        }

        $fee = $validated['amount'] * 0.005;
        $totalAmount = $validated['amount'] + $fee;

        if ($senderWallet->balance < $totalAmount) {
            return response()->json(['message' => 'Saldo tidak cukup untuk biaya transaksi.'], 422);
        }

        DB::beginTransaction();
        try {

            $senderWallet->balance -= $totalAmount;
            $senderWallet->save();

            $receiverWallet->balance += $validated['amount'];
            $receiverWallet->save();

            Transaction::create([
                'sender_warga_id' => $warga->id,
                'receiver_warga_id' => $receiverWallet->warga_id,
                'type' => 'TRANSFER_OUT',
                'amount' => $validated['amount'],
                'fee' => $fee,
                'description' => $validated['notes'] ?? 'Transfer Desapay',
            ]);

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

    public function payPPOB(Request $request)
    {
        $validated = $request->validate([
            'amount' => 'required|numeric|min:10000',
            'product_name' => 'required|string|max:255',
            'target_number' => 'required|string|max:20',
            'fee' => 'required|numeric|min:0',
        ]);

        $user = Auth::user();
        $warga = $user->warga;
        $senderWallet = $warga->wallet;

        $totalCharge = $validated['amount'] + $validated['fee'];


        if ($senderWallet->balance < $totalCharge) {
            return response()->json(['message' => 'Saldo Desapay tidak mencukupi untuk transaksi ini.'], 422);
        }

        DB::beginTransaction();
        try {

            $senderWallet->balance -= $totalCharge;
            $senderWallet->save();


            Transaction::create([
                'sender_warga_id' => $warga->id,
                'type' => 'PAYMENT_PPOB',
                'amount' => $validated['amount'],
                'fee' => $validated['fee'],
                'description' => "Pembelian {$validated['product_name']} ke {$validated['target_number']}",
            ]);

            DB::commit();

            return response()->json([
                'message' => "Pembelian {$validated['product_name']} berhasil diproses.",
                'new_balance' => $senderWallet->balance,
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Pembayaran Gagal. Terjadi kesalahan sistem.',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
