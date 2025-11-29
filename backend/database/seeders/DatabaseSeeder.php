<?php

use Illuminate\Database\Seeder; // KOREKSI: Gunakan namespace Laravel yang benar
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use App\Models\Keluarga;
use App\Models\Warga;
use App\Models\User;
use App\Models\Iuran;
use App\Models\Wallet;
use App\Models\Transaction; // Tambahkan jika Anda menggunakan transaksi di seeder

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Pindahkan $this ke variabel lokal agar bisa diakses di dalam closure
        $command = $this->command;

        // ------------------------------------
        // 0. RESET DAN PERSIAPAN
        // ------------------------------------
        DB::statement('SET FOREIGN_KEY_CHECKS=0;');

        // Kosongkan semua tabel utama
        Warga::truncate();
        Keluarga::truncate();
        User::truncate();
        Iuran::truncate();
        \App\Models\TagihanIuran::truncate();
        \App\Models\Keuangan::truncate();
        \App\Models\Kegiatan::truncate();
        \App\Models\Acara::truncate();
        Wallet::truncate(); // Hapus Wallet juga

        DB::statement('SET FOREIGN_KEY_CHECKS=1;');

        DB::transaction(function () use ($command) {
            // ------------------------------------
            // 1. AKUN UTAMA & DATA DUMMY ADMIN (UNTUK WALLET)
            // ------------------------------------

            // Buat Keluarga Dummy untuk Admin
            $keluargaAdmin = Keluarga::create([
                'no_kk' => '0000000000000000',
                'alamat' => 'Kantor Desa',
                'rt' => '000',
                'rw' => '000',
            ]);

            // Buat Warga Dummy untuk Admin
            $wargaAdmin = Warga::create([
                'nik' => '0000000000000000',
                'nama_lengkap' => 'Administrator Desa',
                'tempat_lahir' => 'Sistem',
                'tanggal_lahir' => '2023-01-01',
                'jenis_kelamin' => 'L',
                'alamat_ktp' => 'Kantor Desa',
                'agama' => 'Sistem',
                'status_perkawinan' => 'Sistem',
                'pekerjaan' => 'Sistem Administrator',
                'rt' => '000',
                'rw' => '000',
                'keluarga_id' => $keluargaAdmin->id, // Hubungkan ke Keluarga Dummy
                'status_dalam_keluarga' => 'KEPALA_KELUARGA',
            ]);
            $keluargaAdmin->update(['kepala_keluarga_id' => $wargaAdmin->id]);

            // Akun User Admin
            $adminUser = User::create([
                'email' => 'admin@gmail.com',
                'password' => Hash::make('password'),
                'role' => 'admin',
                'warga_id' => $wargaAdmin->id, // Hubungkan ke Warga Dummy
            ]);
            $command->info('Akun Admin dibuat: admin@gmail.com (Hub. Warga: Admin Desa)');


            // ------------------------------------
            // 2. AKUN RW 01
            // ------------------------------------
            $keluargaRW01 = Keluarga::create([
                'no_kk' => '3201010101000001',
                'alamat' => 'Jl. Balai gmail No. 1',
                'rt' => '001',
                'rw' => '001',
            ]);
            $wargaRW01 = Warga::create([
                'nik' => '3201010101900001',
                'nama_lengkap' => 'Bapak RW 01',
                'tempat_lahir' => 'Jakarta',
                'tanggal_lahir' => '1970-01-01',
                'jenis_kelamin' => 'L',
                'alamat_ktp' => 'Jl. Balai gmail No. 1',
                'agama' => 'Islam',
                'status_perkawinan' => 'Kawin',
                'pekerjaan' => 'PNS',
                'rt' => '001',
                'rw' => '001',
                'keluarga_id' => $keluargaRW01->id,
                'status_dalam_keluarga' => 'KEPALA_KELUARGA',
            ]);
            $keluargaRW01->update(['kepala_keluarga_id' => $wargaRW01->id]);
            $userRW01 = User::create([
                'email' => 'rw01@gmail.com',
                'password' => Hash::make('password'),
                'role' => 'rw',
                'warga_id' => $wargaRW01->id,
            ]);
            $command->info('Akun RW 01 dibuat: rw01@gmail.com');


            // ------------------------------------
            // 3. AKUN RT 001
            // ------------------------------------
            $keluargaRT01 = Keluarga::create([
                'no_kk' => '3201010101000002',
                'alamat' => 'Jl. Gang RT 01 No. 1',
                'rt' => '001',
                'rw' => '001',
            ]);
            $wargaRT01 = Warga::create([
                'nik' => '3201010101900002',
                'nama_lengkap' => 'Bapak RT 001',
                'tempat_lahir' => 'Bandung',
                'tanggal_lahir' => '1980-01-01',
                'jenis_kelamin' => 'L',
                'alamat_ktp' => 'Jl. Gang RT 01 No. 1',
                'agama' => 'Islam',
                'status_perkawinan' => 'Kawin',
                'pekerjaan' => 'Wiraswasta',
                'rt' => '001',
                'rw' => '001',
                'keluarga_id' => $keluargaRT01->id,
                'status_dalam_keluarga' => 'KEPALA_KELUARGA',
            ]);
            $keluargaRT01->update(['kepala_keluarga_id' => $wargaRT01->id]);
            $userRT01 = User::create([
                'email' => 'rt01@gmail.com',
                'password' => Hash::make('password'),
                'role' => 'rt',
                'warga_id' => $wargaRT01->id,
            ]);
            $command->info('Akun RT 001 dibuat: rt01@gmail.com');


            // ------------------------------------
            // 4. AKUN RT 002
            // ------------------------------------
            $keluargaRT02 = Keluarga::create([
                'no_kk' => '3201010101000003',
                'alamat' => 'Jl. Gang RT 02 No. 1',
                'rt' => '002',
                'rw' => '001',
            ]);
            $wargaRT02 = Warga::create([
                'nik' => '3201010101900003',
                'nama_lengkap' => 'Bapak RT 002',
                'tempat_lahir' => 'Surabaya',
                'tanggal_lahir' => '1985-01-01',
                'jenis_kelamin' => 'L',
                'alamat_ktp' => 'Jl. Gang RT 02 No. 1',
                'agama' => 'Kristen',
                'status_perkawinan' => 'Kawin',
                'pekerjaan' => 'Karyawan Swasta',
                'rt' => '002',
                'rw' => '001',
                'keluarga_id' => $keluargaRT02->id,
                'status_dalam_keluarga' => 'KEPALA_KELUARGA',
            ]);
            $keluargaRT02->update(['kepala_keluarga_id' => $wargaRT02->id]);
            $userRT02 = User::create([
                'email' => 'rt02@gmail.com',
                'password' => Hash::make('password'),
                'role' => 'rt',
                'warga_id' => $wargaRT02->id,
            ]);
            $command->info('Akun RT 002 dibuat: rt02@gmail.com');


            // ------------------------------------
            // 5. WARGA BIASA (RT 001)
            // ------------------------------------
            $keluargaWarga1 = Keluarga::create([
                'no_kk' => '3201010101000004',
                'alamat' => 'Jl. Gang RT 01 No. 10',
                'rt' => '001',
                'rw' => '001',
            ]);
            $warga1 = Warga::create([
                'nik' => '3201010101900004',
                'nama_lengkap' => 'Budi Gunawan',
                'tempat_lahir' => 'Medan',
                'tanggal_lahir' => '1990-01-01',
                'jenis_kelamin' => 'L',
                'alamat_ktp' => 'Jl. Gang RT 01 No. 10',
                'agama' => 'Islam',
                'status_perkawinan' => 'Kawin',
                'pekerjaan' => 'Programmer',
                'rt' => '001',
                'rw' => '001',
                'keluarga_id' => $keluargaWarga1->id,
                'status_dalam_keluarga' => 'KEPALA_KELUARGA',
            ]);
            $keluargaWarga1->update(['kepala_keluarga_id' => $warga1->id]);
            $userWarga1 = User::create([
                'email' => 'budi@gmail.com',
                'password' => Hash::make('password'),
                'role' => 'warga',
                'warga_id' => $warga1->id,
            ]);

            Warga::create([
                'nik' => '3201010101900005',
                'nama_lengkap' => 'Siti Aminah',
                'tempat_lahir' => 'Medan',
                'tanggal_lahir' => '1992-01-01',
                'jenis_kelamin' => 'P',
                'alamat_ktp' => 'Jl. Gang RT 01 No. 10',
                'agama' => 'Islam',
                'status_perkawinan' => 'Kawin',
                'pekerjaan' => 'Ibu Rumah Tangga',
                'rt' => '001',
                'rw' => '001',
                'keluarga_id' => $keluargaWarga1->id,
                'status_dalam_keluarga' => 'ISTRI',
            ]);
            $command->info('Akun Warga (Budi & Siti) dibuat: budi@gmail.com');


            // ------------------------------------
            // 6. IURAN, KEUANGAN, KEGIATAN, & ACARA
            // ------------------------------------

            $iuranSampahRT01 = Iuran::create([
                'nama_iuran' => 'Iuran Sampah RT 001',
                'jumlah' => 25000,
                'tipe' => 'PER_KELUARGA',
                'rt' => '001',
                'rw' => '001',
            ]);
            $iuranKeamananRW01 = Iuran::create([
                'nama_iuran' => 'Iuran Keamanan RW 01',
                'jumlah' => 50000,
                'tipe' => 'PER_KELUARGA',
                'rt' => null,
                'rw' => '001',
            ]);

            \App\Models\TagihanIuran::create([
                'iuran_id' => $iuranSampahRT01->id,
                'keluarga_id' => $keluargaWarga1->id,
                'periode_bulan' => now()->month,
                'periode_tahun' => now()->year,
                'jumlah_bayar' => $iuranSampahRT01->jumlah,
                'status_pembayaran' => 'BELUM_BAYAR',
            ]);
            \App\Models\TagihanIuran::create([
                'iuran_id' => $iuranKeamananRW01->id,
                'keluarga_id' => $keluargaWarga1->id,
                'periode_bulan' => now()->month,
                'periode_tahun' => now()->year,
                'jumlah_bayar' => $iuranKeamananRW01->jumlah,
                'status_pembayaran' => 'BELUM_BAYAR',
            ]);
            $command->info('Tagihan dibuat untuk Budi.');

            // Keuangan RT 001
            \App\Models\Keuangan::create([
                'tipe' => 'PEMASUKAN',
                'jumlah' => 500000,
                'keterangan' => 'Dana kas awal RT 001',
                'tanggal' => now(),
                'rt' => '001',
                'rw' => '001',
                'created_by_user_id' => $userRT01->id,
            ]);
            \App\Models\Keuangan::create([
                'tipe' => 'PENGELUARAN',
                'jumlah' => 100000,
                'keterangan' => 'Beli sapu untuk kerja bakti',
                'tanggal' => now(),
                'rt' => '001',
                'rw' => '001',
                'created_by_user_id' => $userRT01->id,
            ]);

            // Kegiatan & Acara
            \App\Models\Kegiatan::create([
                'nama_kegiatan' => 'Kerja Bakti RT 001',
                'deskripsi' => 'Membersihkan selokan dan taman RT 001.',
                'tanggal_mulai' => now()->addDays(7),
                'tanggal_selesai' => now()->addDays(7)->addHours(3),
                'lokasi' => 'Lingkungan RT 001',
                'rt' => '001',
                'rw' => '001',
                'created_by_user_id' => $userRT01->id,
            ]);
            \App\Models\Acara::create([
                'nama_acara' => 'Lomba 17an RW 01',
                'deskripsi' => 'Perlombaan merayakan hari kemerdekaan.',
                'tanggal_mulai' => now()->addDays(30),
                'tanggal_selesai' => now()->addDays(30)->addHours(8),
                'lokasi' => 'Lapangan Utama RW 01',
                'rt' => null,
                'rw' => '001',
                'created_by_user_id' => $userRW01->id,
            ]);
            $command->info('Data iuran, keuangan, kegiatan, & acara dibuat.');


            // ------------------------------------
            // 7. BUAT WALLET UNTUK SEMUA WARGA/USER
            // ------------------------------------
            $allWarga = Warga::all();
            $counter = 1;
            foreach ($allWarga as $warga) {
                // Cek apakah user terkait ada (hanya buat wallet jika ada akun login)
                $user = User::where('warga_id', $warga->id)->first();

                if ($user) {
                    // Buat nomor akun Desapay (misal: format 00001)
                    $accountNumber = str_pad($counter, 5, '0', STR_PAD_LEFT);

                    Wallet::create([
                        'warga_id' => $warga->id,
                        'desapay_account_number' => $accountNumber,
                        'balance' => ($user->role == 'warga' ? 100000.00 : 500000.00), // Warga biasa saldo 100rb, pengelola 500rb
                    ]);
                    $counter++;
                }
            }
            $command->info('Wallet Desapay berhasil di-seed.');
        });
    }
}
