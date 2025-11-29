import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

// Sesuaikan path ini
import 'package:frontend/services/api_service.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;

  // Daftar nominal cepat yang bisa diklik
  final List<double> _quickAmounts = [
    10000,
    20000,
    50000,
    100000,
    200000,
    500000,
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectQuickAmount(double amount) {
    setState(() {
      _amountController.text = amount.toStringAsFixed(0); // Hapus desimal
    });
  }

  Future<void> _submitTopUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() {
      _isLoading = true;
    });

    final apiService = context.read<ApiService>();

    try {
      final newBalance = await apiService.topUpWallet(amount);

      if (newBalance != null && mounted) {
        // Tampilkan notifikasi sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Top Up Rp ${amount.toStringAsFixed(0)} berhasil! Saldo baru: Rp ${newBalance.toStringAsFixed(0)}",
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        // Kembali ke layar sebelumnya (Home/Profile)
        Navigator.of(
          context,
        ).pop(true); // Pop dengan hasil true (perlu refresh)
      } else {
        throw Exception("Gagal mendapatkan saldo baru.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Top Up Gagal: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Isi Saldo Desapay (Demo)"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Masukkan Nominal Top Up",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: "Nominal",
                  prefixText: "Rp ",
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null || amount < 1000) {
                    return "Nominal minimal Rp 1.000";
                  }
                  if (amount > 1000000) {
                    return "Nominal maksimal Rp 1.000.000 (Demo)";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              Text(
                "Pilihan Cepat",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _quickAmounts.map((amount) {
                  return ActionChip(
                    label: Text("Rp ${amount.toStringAsFixed(0)}"),
                    onPressed: _isLoading
                        ? null
                        : () => _selectQuickAmount(amount),
                    backgroundColor:
                        _amountController.text == amount.toStringAsFixed(0)
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.grey[200],
                    side: BorderSide(
                      color: _amountController.text == amount.toStringAsFixed(0)
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitTopUp,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.payment),
                label: Text(_isLoading ? "MEMPROSES..." : "LANJUTKAN TOP UP"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Catatan: Ini adalah simulasi Top Up. Tidak ada integrasi Payment Gateway nyata.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
