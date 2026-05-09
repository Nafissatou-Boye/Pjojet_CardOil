// ═══════════════════════════════════════════════════════════════
// FICHIER 1 : lib/models/loyalty_model.dart
// ═══════════════════════════════════════════════════════════════

// lib/models/loyalty_model.dart

enum LoyaltyTier { bronze, silver, gold, platinum }

class LoyaltyAccountModel {
  final int id;
  final int clientId;
  final String cardNumber;
  final int points;
  final LoyaltyTier tier;
  final int totalEarned;
  final int totalRedeemed;
  final int companyId;
  final DateTime? lastTransactionDate;
  final DateTime createdAt;

  LoyaltyAccountModel({
    required this.id,
    required this.clientId,
    required this.cardNumber,
    required this.points,
    required this.tier,
    required this.totalEarned,
    required this.totalRedeemed,
    required this.companyId,
    this.lastTransactionDate,
    required this.createdAt,
  });

  String get tierLabel {
    switch (tier) {
      case LoyaltyTier.silver:   return 'Argent';
      case LoyaltyTier.gold:     return 'Or';
      case LoyaltyTier.platinum: return 'Platine';
      default:                   return 'Bronze';
    }
  }

  String get tierColorHex {
    switch (tier) {
      case LoyaltyTier.silver:   return '#94A3B8';
      case LoyaltyTier.gold:     return '#F59E0B';
      case LoyaltyTier.platinum: return '#6366F1';
      default:                   return '#CD7F32';
    }
  }

  int? get pointsToNextTier {
    switch (tier) {
      case LoyaltyTier.bronze:   return 500  - points;
      case LoyaltyTier.silver:   return 2000 - points;
      case LoyaltyTier.gold:     return 5000 - points;
      case LoyaltyTier.platinum: return null;
    }
  }

  double get tierProgress {
    switch (tier) {
      case LoyaltyTier.bronze:   return (points / 500).clamp(0.0, 1.0);
      case LoyaltyTier.silver:   return ((points - 500)  / 1500).clamp(0.0, 1.0);
      case LoyaltyTier.gold:     return ((points - 2000) / 3000).clamp(0.0, 1.0);
      case LoyaltyTier.platinum: return 1.0;
    }
  }

  String? get nextTierLabel {
    switch (tier) {
      case LoyaltyTier.bronze:   return 'Argent';
      case LoyaltyTier.silver:   return 'Or';
      case LoyaltyTier.gold:     return 'Platine';
      case LoyaltyTier.platinum: return null;
    }
  }

  factory LoyaltyAccountModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyAccountModel(
      id:            _i(json['id']),
      clientId:      _i(json['clientId']),
      cardNumber:    json['cardNumber']?.toString() ?? '',
      points:        _i(json['points']),
      tier:          _parseTier(json['tier']),
      totalEarned:   _i(json['totalEarned']),
      totalRedeemed: _i(json['totalRedeemed']),
      companyId:     _i(json['companyId']),
      lastTransactionDate: json['lastTransactionDate'] != null
          ? DateTime.tryParse(json['lastTransactionDate'].toString())
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static LoyaltyTier _parseTier(dynamic v) {
    switch (v?.toString().toUpperCase()) {
      case 'SILVER':   return LoyaltyTier.silver;
      case 'GOLD':     return LoyaltyTier.gold;
      case 'PLATINUM': return LoyaltyTier.platinum;
      default:         return LoyaltyTier.bronze;
    }
  }
}

class LoyaltyRewardModel {
  final int id;
  final String name;
  final String? description;
  final int pointsCost;
  final int stockAvailable;
  final String? imageUrl;
  final String category;
  final int companyId;
  final bool active;

  LoyaltyRewardModel({
    required this.id,
    required this.name,
    this.description,
    required this.pointsCost,
    required this.stockAvailable,
    this.imageUrl,
    required this.category,
    required this.companyId,
    required this.active,
  });

  bool get inStock => stockAvailable > 0;

  factory LoyaltyRewardModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyRewardModel(
      id:             _i(json['id']),
      name:           json['name']?.toString() ?? '',
      description:    json['description']?.toString(),
      pointsCost:     _i(json['pointsCost']),
      stockAvailable: _i(json['stockAvailable']),
      imageUrl:       json['imageUrl']?.toString(),
      category:       json['category']?.toString() ?? 'GIFT',
      companyId:      _i(json['companyId']),
      active:         json['active'] as bool? ?? true,
    );
  }

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}