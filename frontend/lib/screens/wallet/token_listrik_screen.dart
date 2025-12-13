import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TokenListrikScreen extends StatefulWidget {
  const TokenListrikScreen({super.key});

  @override
  State<TokenListrikScreen> createState() => _TokenListrikScreenState();
}

class _TokenListrikScreenState extends State<TokenListrikScreen> {
  // Ubah nama controller agar lebih generik
  final TextEditingController _numberController = TextEditingController(); 
  int? _selectedNominal;
  String? _numberError;

  final List<int> _nominalOptions = [
    20000,
    50000,
    100000,
    250000,
    500000,
    1000000,
  ];

  final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  void _validateAndSubmit() {
    setState(() {
      _numberError = null;
    });

    final String inputNumber = _numberController.text.trim();

    if (inputNumber.isEmpty) {
      setState(() {
        _numberError = 'Nomor Ponsel atau ID Pelanggan wajib diisi.';
      });
      return;
    }
    
    // Validasi diubah agar lebih longgar, asumsikan sebagai Nomor HP untuk kemudahan testing
    if (inputNumber.length < 5) { 
       setState(() {
        _numberError = 'Input terlalu pendek.';
      });
      return;
    }

    if (_selectedNominal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silahkan pilih nominal token terlebih dahulu.')),
      );
      return;
    }

    // --- Konsep Transaksi Instan (Mirip Pulsa) ---
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Pembelian Token"),
          content: Text(
              "Anda akan membeli Token Listrik sebesar ${_rupiahFormatter.format(_selectedNominal)} untuk No. Tujuan/ID: $inputNumber."),
          actions: <Widget>[
            TextButton(
              child: const Text("Batal"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text("Bayar Sekarang"),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog konfirmasi
                
                // Pindah ke layar konfirmasi pembayaran sukses/loading
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _PaymentProcessingScreen(
                      amount: _selectedNominal!,
                      target: inputNumber,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Token Listrik (Premium)"),
        backgroundColor: Theme.of(context).colorScheme.primary, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Bagian Input Nomor HP/ID (Elegance Card) ---
            _NumberInputCard(
              numberController: _numberController,
              numberError: _numberError,
            ),

            const SizedBox(height: 30),

            // --- Bagian Pilihan Nominal (Grid Mewah) ---
            Text(
              "Pilih Nominal Token",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _nominalOptions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3, 
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final nominal = _nominalOptions[index];
                final isSelected = _selectedNominal == nominal;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedNominal = nominal;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.amber.shade700 
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? Colors.amber.shade900 : Colors.grey.shade300,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        _rupiahFormatter.format(nominal),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 16,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // --- Tombol Lanjutkan Profesional ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _validateAndSubmit,
                icon: const Icon(Icons.flash_on, color: Colors.white),
                label: Text(
                  _selectedNominal == null
                      ? "PILIH NOMINAL"
                      : "BAYAR ${_rupiahFormatter.format(_selectedNominal)}",
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Theme.of(context).colorScheme.primary, 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 8, 
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget untuk Bagian Input Nomor HP/ID
class _NumberInputCard extends StatelessWidget {
  final TextEditingController numberController;
  final String? numberError;

  const _NumberInputCard({
    required this.numberController,
    this.numberError,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nomor Tujuan Pembelian Token",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: numberController,
              keyboardType: TextInputType.phone, // Ubah ke phone agar mudah input nomor HP
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone_android, color: Colors.amber), // Ikon HP
                hintText: "Contoh: 0812xxxxxx (No HP) atau 12345678901 (ID Pelanggan)",
                labelText: "Nomor Ponsel / ID Pelanggan",
                errorText: numberError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none, 
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.history, color: Colors.blueGrey),
                  onPressed: () {
                    // Logika untuk mengambil ID dari riwayat
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fitur riwayat ID belum tersedia.')));
                  },
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Masukkan ID pelanggan PLN atau Nomor Ponsel Anda.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Layar Simulasi Proses Pembayaran ---
class _PaymentProcessingScreen extends StatelessWidget {
  final int amount;
  final String target;
  final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  _PaymentProcessingScreen({required this.amount, required this.target});

  @override
  Widget build(BuildContext context) {
    // Simulasi loading selama 3 detik sebelum sukses
    Future.delayed(const Duration(seconds: 3), () {
      if (Navigator.of(context).mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => _PaymentSuccessScreen(amount: amount, target: target),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Proses Pembelian Token"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        automaticallyImplyLeading: false, // Nonaktifkan tombol kembali saat loading
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.amber),
            const SizedBox(height: 20),
            Text(
              "Memproses pembayaran ${_rupiahFormatter.format(amount)}...",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text("Tujuan: $target"),
            const SizedBox(height: 40),
            const Text(
              "Mohon tunggu, jangan tutup aplikasi.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Layar Sukses Pembayaran ---
class _PaymentSuccessScreen extends StatelessWidget {
  final int amount;
  final String target;
  final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  _PaymentSuccessScreen({required this.amount, required this.target});

  @override
  Widget build(BuildContext context) {
    // Angka token PLN simulasi
    const String tokenSimulasi = "4321-9876-5432-1098-7654"; 

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pembayaran Berhasil!"),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            Text(
              "Pembelian Token Listrik Sukses!",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Card Token Listrik yang Terlihat Mewah
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              color: Colors.amber.shade50, // Latar belakang sedikit emas
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Nominal", style: TextStyle(color: Colors.grey)),
                    Text(_rupiahFormatter.format(amount), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const Divider(),
                    const Text("No. Tujuan / ID Pelanggan", style: TextStyle(color: Colors.grey)),
                    Text(target, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 15),
                    const Text("Kode Token Listrik Anda:", style: TextStyle(color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText( // Gunakan SelectableText agar token bisa disalin
                        tokenSimulasi, 
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.w900, 
                          color: Colors.black87,
                          fontFamily: 'monospace', // Font monospasi untuk kode
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          // Simulasi salin token ke clipboard
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kode token berhasil disalin!')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text("SALIN KODE TOKEN"),
                      ),
                    )
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // Tombol Selesai
            ElevatedButton(
              onPressed: () {
                // Tutup semua layar transaksi dan kembali ke home
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("SELESAI", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}