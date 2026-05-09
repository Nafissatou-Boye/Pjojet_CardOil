// lib/models/promotion_model.dart

enum PromotionStatus { active, expired, inactive }

enum PromotionType { gift, points, scratch }

class PromotionModel {
  final int id;
  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final double pointsMultiplier;
  final int pointsRequired;
  final double minPurchaseAmount;
  final PromotionStatus status;
  final int companyId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Champs étendus présents en BDD
  final PromotionType type;
  final bool antiAbuseEnabled;
  final String? applicableStations;
  final String? associatedGiftIds;
  final double clientCeilingAmount;
  final int dailyLimitPerClient;
  final String frequency; // DAILY | WEEKLY | UNLIMITED
  final double globalCeilingAmount;
  final int maxGiftsPerClient;
  final int maxParticipationsPerDay;
  final int maxParticipationsPerMonth;
  final int maxParticipationsPerWeek;
  final int minHoursBeforeRepeat;
  final String? timezone;
  final double totalBudgetConsumed;
  final int totalGiftsGenerated;
  final int totalParticipations;
  final double totalPointsEmitted;

  PromotionModel({
    required this.id,
    required this.name,
    this.description,
    required this.startDate,
    required this.endDate,
    required this.pointsMultiplier,
    required this.pointsRequired,
    required this.minPurchaseAmount,
    required this.status,
    required this.companyId,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    required this.antiAbuseEnabled,
    this.applicableStations,
    this.associatedGiftIds,
    required this.clientCeilingAmount,
    required this.dailyLimitPerClient,
    required this.frequency,
    required this.globalCeilingAmount,
    required this.maxGiftsPerClient,
    required this.maxParticipationsPerDay,
    required this.maxParticipationsPerMonth,
    required this.maxParticipationsPerWeek,
    required this.minHoursBeforeRepeat,
    this.timezone,
    required this.totalBudgetConsumed,
    required this.totalGiftsGenerated,
    required this.totalParticipations,
    required this.totalPointsEmitted,
  });

  // ── Getters utilitaires ──────────────────────────────────────

  bool get isActive => status == PromotionStatus.active;

  /// Compatibilité avec les widgets qui utilisaient promo.title
  String get title => name;

  /// Label affiché dans les badges / cards
  String get typeLabel {
    switch (type) {
      case PromotionType.gift:
        return 'CADEAU';
      case PromotionType.points:
        return 'POINTS';
      case PromotionType.scratch:
        return 'SCRATCH';
    }
  }

  // ── Désérialisation depuis l'API ─────────────────────────────

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    // L'API enveloppe parfois la réponse dans un champ "data"
    final data = json.containsKey('data') && json['data'] is Map
        ? json['data'] as Map<String, dynamic>
        : json;

    return PromotionModel(
      id: _parseInt(data['id']),
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString(),
      startDate: _parseDate(data['startDate']),
      endDate: _parseDate(data['endDate']),
      pointsMultiplier: _parseDouble(data['pointsMultiplier']),
      pointsRequired: _parseInt(data['pointsRequired']),
      minPurchaseAmount: _parseDouble(data['minPurchaseAmount']),
      status: _parseStatus(data['status']),
      companyId: _parseInt(data['companyId']),
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
      type: _parseType(data['type']),
      antiAbuseEnabled: data['antiAbuseEnabled'] == true || data['anti_abuse_enabled'] == true,
      applicableStations: data['applicableStations']?.toString() ?? data['applicable_stations']?.toString(),
      associatedGiftIds: data['associatedGiftIds']?.toString() ?? data['associated_gift_ids']?.toString(),
      clientCeilingAmount: _parseDouble(data['clientCeilingAmount'] ?? data['client_ceiling_amount']),
      dailyLimitPerClient: _parseInt(data['dailyLimitPerClient'] ?? data['daily_limit_per_client']),
      frequency: data['frequency']?.toString() ?? 'UNLIMITED',
      globalCeilingAmount: _parseDouble(data['globalCeilingAmount'] ?? data['global_ceiling_amount']),
      maxGiftsPerClient: _parseInt(data['maxGiftsPerClient'] ?? data['max_gifts_per_client']),
      maxParticipationsPerDay: _parseInt(data['maxParticipationsPerDay'] ?? data['max_participations_per_day']),
      maxParticipationsPerMonth: _parseInt(data['maxParticipationsPerMonth'] ?? data['max_participations_per_month']),
      maxParticipationsPerWeek: _parseInt(data['maxParticipationsPerWeek'] ?? data['max_participations_per_week']),
      minHoursBeforeRepeat: _parseInt(data['minHoursBeforeRepeat'] ?? data['min_hours_before_repeat']),
      timezone: data['timezone']?.toString(),
      totalBudgetConsumed: _parseDouble(data['totalBudgetConsumed'] ?? data['total_budget_consumed']),
      totalGiftsGenerated: _parseInt(data['totalGiftsGenerated'] ?? data['total_gifts_generated']),
      totalParticipations: _parseInt(data['totalParticipations'] ?? data['total_participations']),
      totalPointsEmitted: _parseDouble(data['totalPointsEmitted'] ?? data['total_points_emitted']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'pointsMultiplier': pointsMultiplier,
        'pointsRequired': pointsRequired,
        'minPurchaseAmount': minPurchaseAmount,
        'status': status.name.toUpperCase(),
        'companyId': companyId,
        'type': type.name.toUpperCase(),
      };

  // ── Helpers de parsing ───────────────────────────────────────

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }

  static PromotionStatus _parseStatus(dynamic v) {
    switch (v?.toString().toUpperCase()) {
      case 'ACTIVE':
        return PromotionStatus.active;
      case 'EXPIRED':
        return PromotionStatus.expired;
      default:
        return PromotionStatus.inactive;
    }
  }

  static PromotionType _parseType(dynamic v) {
    switch (v?.toString().toUpperCase()) {
      case 'GIFT':
        return PromotionType.gift;
      case 'SCRATCH':
        return PromotionType.scratch;
      default:
        return PromotionType.points;
    }
  }
}