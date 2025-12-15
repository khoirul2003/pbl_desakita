<?php

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use App\Models\Keluarga;
use App\Models\Warga;
use App\Models\User;
use App\Models\Iuran;
use App\Models\Wallet;
use App\Models\Keuangan;
use App\Models\Kegiatan;
use App\Models\Acara;
use App\Models\TagihanIuran;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $command = $this->command;

        DB::statement('SET FOREIGN_KEY_CHECKS=0;');

        Warga::truncate();
        Keluarga::truncate();
        User::truncate();
        Iuran::truncate();
        TagihanIuran::truncate();
        Keuangan::truncate();
        Kegiatan::truncate();
        Acara::truncate();
        Wallet::truncate();

        DB::statement('SET FOREIGN_KEY_CHECKS=1;');

        DB::transaction(function () use ($command) {
            $adminAccounts = [];
            // Create 4 Admin accounts
            for ($i = 1; $i <= 4; $i++) {
                $kk = str_pad($i, 16, '0', STR_PAD_LEFT);
                $nik = str_pad($i, 16, '1', STR_PAD_LEFT);
                $email = "admin{$i}@gmail.com";

                $keluarga = Keluarga::create([
                    'no_kk' => $kk,
                    'alamat' => 'Kantor Desa - Admin ' . $i,
                    'rt' => '000',
                    'rw' => '000',
                ]);

                $warga = Warga::create([
                    'nik' => $nik,
                    'nama_lengkap' => 'Administrator ' . $i,
                    'tempat_lahir' => 'Sistem',
                    'tanggal_lahir' => '2023-01-01',
                    'jenis_kelamin' => 'L',
                    'alamat_ktp' => 'Kantor Desa',
                    'agama' => 'Sistem',
                    'status_perkawinan' => 'Sistem',
                    'pekerjaan' => 'Admin Sistem',
                    'rt' => '000',
                    'rw' => '000',
                    'keluarga_id' => $keluarga->id,
                    'status_dalam_keluarga' => 'KEPALA_KELUARGA',
                ]);
                $keluarga->update(['kepala_keluarga_id' => $warga->id]);

                $user = User::create([
                    'email' => $email,
                    'password' => Hash::make('password'),
                    'role' => 'admin',
                    'warga_id' => $warga->id,
                ]);
                $adminAccounts[] = $user;
                $command->info("Akun Admin {$i} dibuat: {$email}");
            }

            // Create RW, RT, Warga, Iuran, Tagihan, Keuangan, Kegiatan, Acara
            for ($rw = 1; $rw <= 4; $rw++) {
                $keluargaRW = Keluarga::create([
                    'no_kk' => "32010101010000{$rw}",
                    'alamat' => "Alamat RW {$rw}",
                    'rt' => '000',
                    'rw' => str_pad($rw, 3, '0', STR_PAD_LEFT),
                ]);
                $wargaRW = Warga::create([
                    'nik' => "32010101019000{$rw}",
                    'nama_lengkap' => "Bapak RW {$rw}",
                    'tempat_lahir' => 'Jakarta',
                    'tanggal_lahir' => '1970-01-01',
                    'jenis_kelamin' => 'L',
                    'alamat_ktp' => "Alamat RW {$rw}",
                    'agama' => 'Islam',
                    'status_perkawinan' => 'Kawin',
                    'pekerjaan' => 'PNS',
                    'rt' => '000',
                    'rw' => str_pad($rw, 3, '0', STR_PAD_LEFT),
                    'keluarga_id' => $keluargaRW->id,
                    'status_dalam_keluarga' => 'KEPALA_KELUARGA',
                ]);
                $keluargaRW->update(['kepala_keluarga_id' => $wargaRW->id]);
                $userRW = User::create([
                    'email' => "rw{$rw}@gmail.com",
                    'password' => Hash::make('password'),
                    'role' => 'rw',
                    'warga_id' => $wargaRW->id,
                ]);
                $command->info("Akun RW {$rw} dibuat: rw{$rw}@gmail.com");

                for ($rt = 1; $rt <= 4; $rt++) {
                    // Create RT
                    $keluargaRT = Keluarga::create([
                        'no_kk' => "32010101010000{$rw}{$rt}",
                        'alamat' => "Alamat RT {$rt} RW {$rw}",
                        'rt' => str_pad($rt, 3, '0', STR_PAD_LEFT),
                        'rw' => str_pad($rw, 3, '0', STR_PAD_LEFT),
                    ]);

                    for ($wargaIndex = 1; $wargaIndex <= 10; $wargaIndex++) {
                        // Create Warga for each RT
                        $nik = "32010101019000{$rw}{$rt}{$wargaIndex}";
                        $nama = "Warga {$wargaIndex} RT {$rt} RW {$rw}";
                        $warga = Warga::create([
                            'nik' => $nik,
                            'nama_lengkap' => $nama,
                            'tempat_lahir' => 'Bandung',
                            'tanggal_lahir' => '1990-01-01',
                            'jenis_kelamin' => 'L',
                            'alamat_ktp' => "Alamat RT {$rt} RW {$rw}",
                            'agama' => 'Islam',
                            'status_perkawinan' => 'Kawin',
                            'pekerjaan' => 'Wiraswasta',
                            'rt' => str_pad($rt, 3, '0', STR_PAD_LEFT),
                            'rw' => str_pad($rw, 3, '0', STR_PAD_LEFT),
                            'keluarga_id' => $keluargaRT->id,
                            'status_dalam_keluarga' => 'KEPALA_KELUARGA',
                        ]);
                    }

                    // Create Iuran for each RT
                    for ($iuranIndex = 1; $iuranIndex <= 10; $iuranIndex++) {
                        $iuran = Iuran::create([
                            'nama_iuran' => "Iuran RT {$rt} RW {$rw} - {$iuranIndex}",
                            'jumlah' => 25000 * $iuranIndex,
                            'tipe' => 'PER_KELUARGA',
                            'rt' => str_pad($rt, 3, '0', STR_PAD_LEFT),
                            'rw' => str_pad($rw, 3, '0', STR_PAD_LEFT),
                        ]);

                        foreach ($keluargaRT->anggota as $keluargaMember) {
                            TagihanIuran::create([
                                'iuran_id' => $iuran->id,
                                'keluarga_id' => $keluargaMember->keluarga_id,
                                'periode_bulan' => now()->month,
                                'periode_tahun' => now()->year,
                                'jumlah_bayar' => $iuran->jumlah,
                                'status_pembayaran' => 'BELUM_BAYAR',
                            ]);
                        }
                    }

                    // Create Keuangan for each RT
                    Keuangan::create([
                        'tipe' => 'PEMASUKAN',
                        'jumlah' => 500000,
                        'keterangan' => 'Dana kas awal RT',
                        'tanggal' => now(),
                        'rt' => str_pad($rt, 3, '0', STR_PAD_LEFT),
                        'rw' => str_pad($rw, 3, '0', STR_PAD_LEFT),
                        'created_by_user_id' => $userRW->id,
                    ]);
                    Keuangan::create([
                        'tipe' => 'PENGELUARAN',
                        'jumlah' => 100000,
                        'keterangan' => 'Beli sapu untuk kerja bakti',
                        'tanggal' => now(),
                        'rt' => str_pad($rt, 3, '0', STR_PAD_LEFT),
                        'rw' => str_pad($rw, 3, '0', STR_PAD_LEFT),
                        'created_by_user_id' => $userRW->id,
                    ]);

                    // Create Kegiatan and Acara for each RT
                    Kegiatan::create([
                        'nama_kegiatan' => "Kerja Bakti RT {$rt} RW {$rw}",
                        'deskripsi' => "Membersihkan selokan dan taman RT {$rt} RW {$rw}.",
                        'tanggal_mulai' => now()->addDays(7),
                        'tanggal_selesai' => now()->addDays(7)->addHours(3),
                        'lokasi' => "Lingkungan RT {$rt} RW {$rw}",
                        'rt' => str_pad($rt, 3, '0', STR_PAD_LEFT),
                        'rw' => str_pad($rw, 3, '0', STR_PAD_LEFT),
                        'created_by_user_id' => $userRW->id,
                    ]);
                    Acara::create([
                        'nama_acara' => "Lomba 17an RW {$rw}",
                        'deskripsi' => "Perlombaan merayakan hari kemerdekaan.",
                        'tanggal_mulai' => now()->addDays(30),
                        'tanggal_selesai' => now()->addDays(30)->addHours(8),
                        'lokasi' => "Lapangan Utama RW {$rw}",
                        'rt' => null,
                        'rw' => str_pad($rw, 3, '0', STR_PAD_LEFT),
                        'created_by_user_id' => $userRW->id,
                    ]);

                    $command->info("Iuran, Keuangan, Kegiatan, and Acara for RT {$rt} RW {$rw} created.");
                }
            }

            // Create Wallet for each warga
            $allWarga = Warga::all();
            $counter = 1;
            foreach ($allWarga as $warga) {
                $user = User::where('warga_id', $warga->id)->first();
                if ($user) {
                    $accountNumber = str_pad($counter, 5, '0', STR_PAD_LEFT);
                    Wallet::create([
                        'warga_id' => $warga->id,
                        'desapay_account_number' => $accountNumber,
                        'balance' => ($user->role == 'warga' ? 100000.00 : 500000.00),
                    ]);
                    $counter++;
                }
            }
            $command->info('Wallet Desapay berhasil di-seed.');
        });
    }
}
