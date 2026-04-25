// lib/models/notification_model.dart

import 'dart:convert';

class NotificationMetadata {
  final int? transactionId;
  final double? amount;
  final String? stationName;
  final String? productName;
  final String? status;
  final String? accountType;
  final double? previousBalance;
  final double? newBalance;
  final int? pointsEarned;
  final String? username;

  const NotificationMetadata({
    this.transactionId,
    this.amount,
    this.stationName,
    this.productName,
    this.status,
    this.accountType,
    this.previousBalance,
    this.newBalance,
    this.pointsEarned,
    this.username,
  });

  // ── Getters métier ──────────────────────────────────────────────────────

  /// Liste blanche des carburants connus → même logique que StationTransactionModel
  bool get isRecharge {
    final product = productName?.trim() ?? '';
    // Carburants connus → paiement
    const knownFuels = {'gasoil', 'super', 'diesel', 'essence', 'sp95', 'sp98'};
    if (knownFuels.contains(product.toLowerCase())) return false;
    // Pas de produit ou "Recharge" → recharge
    return product.isEmpty || product.toLowerCase() == 'recharge';
  }

  String get typeLabel => isRecharge ? 'Recharge' : 'Paiement';
  String get sign => isRecharge ? '+' : '-';

  factory NotificationMetadata.fromJson(Map<String, dynamic> json) {
    return NotificationMetadata(
      transactionId: (json['transactionId'] as num?)?.toInt(),
      amount: (json['amount'] as num?)?.toDouble(),
      stationName: json['stationName'] as String?,
      productName: json['productName'] as String?,
      status: json['status'] as String?,
      accountType: json['accountType'] as String?,
      previousBalance: (json['previousBalance'] as num?)?.toDouble(),
      newBalance: (json['newBalance'] as num?)?.toDouble(),
      pointsEarned: (json['pointsEarned'] as num?)?.toInt(),
      username: json['username'] as String?,
    );
  }

  static NotificationMetadata? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return NotificationMetadata.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class NotificationModel {
  final String id;
  final int userId;
  final int? transactionId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? rawMetadata;
  final String? notificationType; // ← NOUVEAU : champ "type" de l'API

  const NotificationModel({
    required this.id,
    required this.userId,
    this.transactionId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.rawMetadata,
    this.notificationType,        // ← NOUVEAU
  });

  NotificationMetadata? get parsedMetadata =>
      NotificationMetadata.tryParse(rawMetadata);

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      transactionId: (json['transactionId'] as num?)?.toInt(),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'] as String)
          : null,
      rawMetadata: json['metadata'] as String?,
      notificationType: json['type'] as String?, // ← NOUVEAU
    );
  }

  NotificationModel copyWith({bool? isRead, DateTime? readAt}) {
    return NotificationModel(
      id: id,
      userId: userId,
      transactionId: transactionId,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      rawMetadata: rawMetadata,
      notificationType: notificationType, // ← NOUVEAU
    );
  }
}