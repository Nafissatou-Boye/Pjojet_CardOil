// lib/models/service_model.dart

enum ServiceStatus { brouillon, actif, inactif, archive }

class CategoryModel {
  final int id;
  final String name;
  final String type; // ENERGIE_CARBURANT, etc.
  final String? description;
  final String? iconUrl;
  final String? colorHex;
  final int companyId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.iconUrl,
    this.colorHex,
    required this.companyId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final d = json.containsKey('data') && json['data'] is Map
        ? json['data'] as Map<String, dynamic>
        : json;
    return CategoryModel(
      id: _i(d['id']),
      name: d['name']?.toString() ?? '',
      type: d['type']?.toString() ?? '',
      description: d['description']?.toString(),
      iconUrl: d['iconUrl']?.toString(),
      colorHex: d['colorHex']?.toString(),
      companyId: _i(d['companyId']),
      createdAt: _dt(d['createdAt']),
      updatedAt: _dt(d['updatedAt']),
    );
  }

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }

  static DateTime _dt(dynamic v) =>
      v == null ? DateTime.now() : DateTime.tryParse('$v') ?? DateTime.now();
}

class ServiceModel {
  final int id;
  final String code;
  final String name;
  final int categoryId;
  final String? categoryName;
  final String? description;
  final String? iconUrl;
  final String? colorHex;
  final ServiceStatus status;
  final bool mandatory;
  final int defaultDisplayOrder;
  final int companyId;
  final List<String> allowedInteractionTypes;
  final int loyaltyPointsOnUse;
  final bool allowStationCustomization;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  ServiceModel({
    required this.id,
    required this.code,
    required this.name,
    required this.categoryId,
    this.categoryName,
    this.description,
    this.iconUrl,
    this.colorHex,
    required this.status,
    required this.mandatory,
    required this.defaultDisplayOrder,
    required this.companyId,
    required this.allowedInteractionTypes,
    required this.loyaltyPointsOnUse,
    required this.allowStationCustomization,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
  });

  bool get isActive => status == ServiceStatus.actif;

  /// Couleur du service : celle de l'API ou une couleur par défaut selon le code
  String get effectiveColorHex => colorHex ?? _defaultColor();

  String _defaultColor() {
    final c = code.toLowerCase();
    if (c.contains('wash') || c.contains('lavage')) return '#0EA5E9';
    if (c.contains('fuel') || c.contains('carburant')) return '#DC2626';
    if (c.contains('maintenance') || c.contains('entretien')) return '#F59E0B';
    if (c.contains('shop') || c.contains('boutique')) return '#8B5CF6';
    return '#2563EB';
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final d = json.containsKey('data') && json['data'] is Map
        ? json['data'] as Map<String, dynamic>
        : json;

    // allowedInteractionTypes peut être une String JSON ou une List
    List<String> parseInteractions(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => '$e').toList();
      if (v is String && v.isNotEmpty) {
        try {
          // parfois c'est une string JSON: '["QR","NFC"]'
          final clean = v.replaceAll("'", '"');
          if (clean.startsWith('[')) {
            return (clean
                    .substring(1, clean.length - 1)
                    .split(',')
                    .map((e) => e.trim().replaceAll('"', ''))
                    .where((e) => e.isNotEmpty)
                    .toList());
          }
          return [v];
        } catch (_) {
          return [v];
        }
      }
      return [];
    }

    return ServiceModel(
      id: _i(d['id']),
      code: d['code']?.toString() ?? '',
      name: d['name']?.toString() ?? '',
      categoryId: _i(d['categoryId']),
      categoryName: d['categoryName']?.toString(),
      description: d['description']?.toString(),
      iconUrl: d['iconUrl']?.toString(),
      colorHex: d['colorHex']?.toString(),
      status: _parseStatus(d['status']),
      mandatory: d['mandatory'] == true,
      defaultDisplayOrder: _i(d['defaultDisplayOrder']),
      companyId: _i(d['companyId']),
      allowedInteractionTypes:
          parseInteractions(d['allowedInteractionTypesList'] ?? d['allowedInteractionTypes']),
      loyaltyPointsOnUse: _i(d['loyaltyPointsOnUse']),
      allowStationCustomization: d['allowStationCustomization'] == true,
      createdAt: _dt(d['createdAt']),
      updatedAt: _dt(d['updatedAt']),
      publishedAt: d['publishedAt'] != null ? _dt(d['publishedAt']) : null,
    );
  }

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }

  static DateTime _dt(dynamic v) =>
      v == null ? DateTime.now() : DateTime.tryParse('$v') ?? DateTime.now();

  static ServiceStatus _parseStatus(dynamic v) {
    switch (v?.toString().toUpperCase()) {
      case 'ACTIF':
        return ServiceStatus.actif;
      case 'INACTIF':
        return ServiceStatus.inactif;
      case 'ARCHIVE':
        return ServiceStatus.archive;
      default:
        return ServiceStatus.brouillon;
    }
  }
}