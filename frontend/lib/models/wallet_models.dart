import 'package:frontend/models/user_model.dart';
import 'dart:convert';

// --- Wallet Model ---
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
      id: int.tryParse(json['id'].toString()) ?? 0,
      wargaId: int.tryParse(json['warga_id'].toString()) ?? 0,
      desapayAccountNumber: json['desapay_account_number'],
      // Pastikan balance selalu double
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
    );
  }

  // === PERBAIKAN: Tambahkan _toJson() untuk serialisasi ===
  Map<String, dynamic> toJsonMap() => {
    'id': id,
    'warga_id': wargaId,
    'desapay_account_number': desapayAccountNumber,
    'balance': balance,
  };
}

// --- Transaction Model ---
class Transaction {
  final int id;
  final String type;
  final double amount;
  final double fee;
  final String? description;
  final DateTime createdAt;

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
    Warga? senderData = json['sender'] != null
        ? Warga.fromJson(json['sender'])
        : null;
    Warga? receiverData = json['receiver'] != null
        ? Warga.fromJson(json['receiver'])
        : null;

    return Transaction(
      id: json['id'],
      type: json['type'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      fee: double.tryParse(json['fee'].toString()) ?? 0.0,
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      sender: senderData,
      receiver: receiverData,
    );
  }

  // === PERBAIKAN: Tambahkan _toJson() untuk serialisasi ===
 Map<String, dynamic> toJsonMap() =>  {
    'id': id,
    'type': type,
    'amount': amount,
    'fee': fee,
    'description': description,
    'created_at': createdAt.toIso8601String(),
    'sender': sender?.toJsonMap(),
    'receiver': receiver?.toJsonMap(),
  };
}
