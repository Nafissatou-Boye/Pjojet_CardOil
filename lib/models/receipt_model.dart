// lib/models/receipt_model.dart
//
// ✅ Remplace fromFirestore() par fromJson() pour l'API REST.
// Les champs sont identiques à ceux utilisés dans receipt_screen.dart.

class ReceiptModel {
  final String id;
  final String receiptNumber;
  final String transactionId;
  final DateTime date;
  final double amount;
  final double cashback;
  final String compagnie;
  final String paymentMethod;
  final String clientName;
  final String? qrCode;

  ReceiptModel({
    required this.id,
    required this.receiptNumber,
    required this.transactionId,
    required this.date,
    required this.amount,
    required this.cashback,
    required this.compagnie,
    required this.paymentMethod,
    required this.clientName,
    this.qrCode,
  });

  // ── Depuis la réponse API REST (/api/transactions/{id}) ───────
  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      id: json['id']?.toString() ?? '',
      receiptNumber: json['receiptNumber']?.toString() ??
          json['numero']?.toString() ??
          json['id']?.toString() ??
          '',
      transactionId: json['transactionId']?.toString() ??
          json['id']?.toString() ??
          '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
      amount: (json['amount'] ?? json['montant'] ?? 0).toDouble(),
      cashback: (json['cashback'] ?? 0).toDouble(),
      compagnie: json['compagnie']?.toString() ??
          json['companyName']?.toString() ??
          '',
      paymentMethod: json['paymentMethod']?.toString() ??
          json['methodePaiement']?.toString() ??
          'QR Code',
      clientName: json['clientName']?.toString() ??
          json['client']?.toString() ??
          '',
      qrCode: json['qrCode']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'receiptNumber': receiptNumber,
        'transactionId': transactionId,
        'date': date.toIso8601String(),
        'amount': amount,
        'cashback': cashback,
        'compagnie': compagnie,
        'paymentMethod': paymentMethod,
        'clientName': clientName,
        if (qrCode != null) 'qrCode': qrCode,
      };
}