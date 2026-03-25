

class TransactionModel {
  final String id;
  final String clientId;
  final String compagnie;
  final String type;
  final double amount;
  final double cashbackEarned;
  final String method;
  final String? stationId;
  final String receiptNumber;
  final String status;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.clientId,
    required this.compagnie,
    required this.type,
    required this.amount,
    required this.cashbackEarned,
    required this.method,
    this.stationId,
    required this.receiptNumber,
    required this.status,
    required this.createdAt,
  });

  // ─── CONVERSION JSON → MODEL ─────────────────────────
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id']?.toString() ?? '',
      clientId: json['clientId']?.toString() ?? '',
      compagnie: json['compagnie'] ?? '',
      type: json['type'] ?? 'PAYMENT',
      amount: (json['amount'] ?? 0).toDouble(),
      cashbackEarned: (json['cashbackEarned'] ?? 0).toDouble(),
      method: json['method'] ?? 'QR_SCAN',
      stationId: json['stationId']?.toString(),
      receiptNumber: json['receiptNumber'] ?? '',
      status: json['status'] ?? 'completed',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // ─── MODEL → JSON (pour POST API) ─────────────────────
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'compagnie': compagnie,
      'type': type,
      'amount': amount,
      'cashbackEarned': cashbackEarned,
      'method': method,
      'stationId': stationId,
      'receiptNumber': receiptNumber,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}