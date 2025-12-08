import 'package:frontend/models/user_model.dart';

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
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJsonMap() => {
    'id': id,
    'warga_id': wargaId,
    'desapay_account_number': desapayAccountNumber,
    'balance': balance,
  };
}

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
      id: int.tryParse(json['id'].toString()) ?? 0,
      type: json['type'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      fee: double.tryParse(json['fee'].toString()) ?? 0.0,
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      sender: senderData,
      receiver: receiverData,
    );
  }

  Map<String, dynamic> toJsonMap() => {
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

class WalletSummary {
  final Wallet wallet;
  final List<Transaction> transactions;

  WalletSummary({required this.wallet, required this.transactions});

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    final walletJson = json['wallet'] as Map<String, dynamic>;
    final txListJson = (json['transactions'] as List<dynamic>? ?? []);
    final txList = txListJson.map((e) => Transaction.fromJson(e)).toList();

    return WalletSummary(
      wallet: Wallet.fromJson(walletJson),
      transactions: txList,
    );
  }
}
