<?php

namespace Database\Seeders;


use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {

        DB::statement('SET FOREIGN_KEY_CHECKS=0;');


        \App\Models\User::truncate();
        \App\Models\Warga::truncate();
        \App\Models\Keluarga::truncate();
        \App\Models\Iuran::truncate();
        \App\Models\TagihanIuran::truncate();
        \App\Models\Keuangan::truncate();
        \App\Models\Kegiatan::truncate();
        \App\Models\Acara::truncate();


        DB::statement('SET FOREIGN_KEY_CHECKS=1;');

        DB::transaction(function () {

            $adminUser = \App\Models\User::create([
                'email' => 'admin@desa.com',
                'password' => Hash::make('password'),
                'role' => 'admin',
                'warga_id' => null,
            ]);
            $this->command->info('Akun Admin dibuat: admin@desa.com');


            $keluargaRW01 = \App\Models\Keluarga::create([
                'no_kk' => '3201010101000001',
                'alamat' => 'Jl. Balai Desa No. 1',
                'rt' => '001',
                'rw' => '001',
            ]);
            $wargaRW01 = \App\Models\Warga::create([
                'nik' => '3201010101900001',
                'nama_lengkap' => 'Bapak RW 01',
                'tempat_lahir' => 'Jakarta',
                'tanggal_lahir' => '1970-01-01',
                'jenis_kelamin' => 'L',
                'alamat_ktp' => 'Jl. Balai Desa No. 1',
                'agama' => 'Islam',
                'status_perkawinan' => 'Kawin',
                'pekerjaan' => 'PNS',
                'rt' => '001',
                'rw' => '001',
                'keluarga_id' => $keluargaRW01->id,
                'status_dalam_keluarga' => 'KEPALA_KELUARGA',
            ]);
            $keluargaRW01->update(['kepala_keluarga_id' => $wargaRW01->id]);
            $userRW01 = \App\Models\User::create([
                'email' => 'rw01@desa.com',
                'password' => Hash::make('password'),
                'role' => 'rw',
                'warga_id' => $wargaRW01->id,
            ]);
            $this->command->info('Akun RW 01 dibuat: rw01@desa.com');


            $keluargaRT01 = \App\Models\Keluarga::create([
                'no_kk' => '3201010101000002',
                'alamat' => 'Jl. Gang RT 01 No. 1',
                'rt' => '001',
                'rw' => '001',
            ]);
            $wargaRT01 = \App\Models\Warga::create([
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
            $userRT01 = \App\Models\User::create([
                'email' => 'rt01@desa.com',
                'password' => Hash::make('password'),
                'role' => 'rt',
                'warga_id' => $wargaRT01->id,
            ]);
            $this->command->info('Akun RT 001 dibuat: rt01@desa.com');


            $keluargaRT02 = \App\Models\Keluarga::create([
                'no_kk' => '3201010101000003',
                'alamat' => 'Jl. Gang RT 02 No. 1',
                'rt' => '002',
                'rw' => '001',
            ]);
            $wargaRT02 = \App\Models\Warga::create([
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
            $userRT02 = \App\Models\User::create([
                'email' => 'rt02@desa.com',
                'password' => Hash::make('password'),
                'role' => 'rt',
                'warga_id' => $wargaRT02->id,
            ]);
            $this->command->info('Akun RT 002 dibuat: rt02@desa.com');



            $keluargaWarga1 = \App\Models\Keluarga::create([
                'no_kk' => '3201010101000004',
                'alamat' => 'Jl. Gang RT 01 No. 10',
                'rt' => '001',
                'rw' => '001',
            ]);
            $warga1 = \App\Models\Warga::create([
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
            $userWarga1 = \App\Models\User::create([
                'email' => 'budi@desa.com',
                'password' => Hash::make('password'),
                'role' => 'warga',
                'warga_id' => $warga1->id,
            ]);

            \App\Models\Warga::create([
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
            $this->command->info('Akun Warga (Budi) dibuat: budi@desa.com');



            $iuranSampahRT01 = \App\Models\Iuran::create([
                'nama_iuran' => 'Iuran Sampah RT 001',
                'jumlah' => 25000,
                'tipe' => 'PER_KELUARGA',
                'rt' => '001',
                'rw' => '001',
            ]);
            $iuranKeamananRW01 = \App\Models\Iuran::create([
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
            $this->command->info('Tagihan dibuat untuk Budi.');


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
            $this->command->info('Data iuran, keuangan, kegiatan, & acara dibuat.');


        });

    }
}
