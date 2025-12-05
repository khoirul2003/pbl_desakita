import 'package:frontend/models/user_model.dart'; // Diperlukan untuk Warga Model
import 'dart:convert';

// --- Wallet Model (Saldo Desapay) ---
class Wallet {
  final int id;
  final int wargaId;
  final String? desapayAccountNumber;
  final double balance;

  Wallet({
    required this.id,
    required this.wargaId,
    this.desapayAccountNumber,
    required this.balance,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      // PENTING: Menggunakan tryParse agar aman dari String ID dari DB
      id: int.tryParse(json['id'].toString()) ?? 0,
      wargaId: int.tryParse(json['warga_id'].toString()) ?? 0,
      desapayAccountNumber: json['desapay_account_number'],
      // Parsing balance
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
    );
  }

  // Method untuk serialisasi (Dipanggil dari Warga Model)
  Map<String, dynamic> toJsonMap() => {
    'id': id,
    'warga_id': wargaId,
    'desapay_account_number': desapayAccountNumber,
    'balance': balance,
  };
}

// --- Transaction Model (Riwayat) ---
class Transaction {
  final int id;
  final String type;
  final double amount;
  final double fee;
  final String? description;
  final DateTime createdAt;

  // Relasi ke Warga (Sender/Receiver)
  final Warga? sender;
  final Warga? receiver;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.fee,
    this.description,
    required this.createdAt,
    this.sender,
    this.receiver,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Parsing sender dan receiver dari relasi
    Warga? senderData = json['sender'] != null
        ? Warga.fromJson(json['sender'])
        : null;
    Warga? receiverData = json['receiver'] != null
        ? Warga.fromJson(json['receiver'])
        : null;

    return Transaction(
      // PENTING: Menggunakan tryParse untuk ID
      id: int.tryParse(json['id'].toString()) ?? 0,
      type: json['type'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      fee: double.tryParse(json['fee'].toString()) ?? 0.0,
      description: json['description'],
      // Parsing dari string ISO ke DateTime
      createdAt: DateTime.parse(json['created_at']),
      sender: senderData,
      receiver: receiverData,
    );
  }

  // Method untuk serialisasi
  Map<String, dynamic> toJsonMap() => {
    'id': id,
    'type': type,
    'amount': amount,
    'fee': fee,
    'description': description,
    'created_at': createdAt.toIso8601String(),
    // Memanggil method publik dari Warga Model (toJsonMap)
    'sender': sender?.toJsonMap(),
    'receiver': receiver?.toJsonMap(),
  };
}
