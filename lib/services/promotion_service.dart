// lib/services/promotion_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/promotion_model.dart';

class PromotionService {
  static const String _baseUrl = 'https://api.cardoil.io';

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ── Helpers internes ─────────────────────────────────────────

  /// Parse la réponse API : gère { success, data: [...] } et les tableaux directs
  List<PromotionModel> _parseList(dynamic body) {
    List<dynamic> list;
    if (body is List) {
      list = body;
    } else if (body is Map) {
      final raw = body['data'];
      list = raw is List ? raw : [];
    } else {
      list = [];
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(PromotionModel.fromJson)
        .toList();
  }

  PromotionModel? _parseSingle(dynamic body) {
    if (body is Map<String, dynamic>) {
      final data = body.containsKey('data') ? body['data'] : body;
      if (data is Map<String, dynamic>) return PromotionModel.fromJson(data);
    }
    return null;
  }

  // ── Promotions fidélité (/api/fidelite/promotions) ────────────

  /// Toutes les promotions d'une compagnie
  Future<List<PromotionModel>> getAllPromotions(
    int companyId, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/fidelite/promotions')
          .replace(queryParameters: {'companyId': '$companyId'});

      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseList(jsonDecode(response.body));
      }
    } catch (e) {
      print('PromotionService.getAllPromotions error: $e');
    }
    return [];
  }

  /// Uniquement les promotions actives d'une compagnie
  Future<List<PromotionModel>> getActivePromotions(
    int companyId, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/fidelite/promotions/active')
          .replace(queryParameters: {'companyId': '$companyId'});

      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseList(jsonDecode(response.body));
      }
    } catch (e) {
      print('PromotionService.getActivePromotions error: $e');
    }
    return [];
  }

  /// Raccourci utilisé dans le dashboard (limit côté client)
  Future<List<PromotionModel>> getPromotions(
    int companyId, {
    int limit = 10,
    String? token,
  }) async {
    final all = await getActivePromotions(companyId, token: token);
    return limit > 0 && all.length > limit ? all.sublist(0, limit) : all;
  }

  /// Promotion par ID
  Future<PromotionModel?> getPromotion(
    int promotionId, {
    String? token,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/fidelite/promotions/$promotionId'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseSingle(jsonDecode(response.body));
      }
    } catch (e) {
      print('PromotionService.getPromotion error: $e');
    }
    return null;
  }

  /// Créer une promotion (admin)
  Future<PromotionModel?> createPromotion({
    required int companyId,
    required String name,
    required String description,
    required PromotionType type,
    required DateTime startDate,
    required DateTime endDate,
    double pointsMultiplier = 1.0,
    int pointsRequired = 0,
    double minPurchaseAmount = 0,
    String? token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/fidelite/promotions'),
            headers: _headers(token),
            body: jsonEncode({
              'companyId': companyId,
              'name': name,
              'description': description,
              'type': type.name.toUpperCase(),
              'startDate': startDate.toIso8601String(),
              'endDate': endDate.toIso8601String(),
              'pointsMultiplier': pointsMultiplier,
              'pointsRequired': pointsRequired,
              'minPurchaseAmount': minPurchaseAmount,
              'status': 'ACTIVE',
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _parseSingle(jsonDecode(response.body));
      }
    } catch (e) {
      print('PromotionService.createPromotion error: $e');
    }
    return null;
  }

  /// Modifier une promotion (admin)
  Future<PromotionModel?> updatePromotion(
    int promotionId, {
    required Map<String, dynamic> fields,
    String? token,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/api/fidelite/promotions/$promotionId'),
            headers: _headers(token),
            body: jsonEncode(fields),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _parseSingle(jsonDecode(response.body));
      }
    } catch (e) {
      print('PromotionService.updatePromotion error: $e');
    }
    return null;
  }

  /// Supprimer une promotion (admin)
  Future<bool> deletePromotion(int promotionId, {String? token}) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/api/fidelite/promotions/$promotionId'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('PromotionService.deletePromotion error: $e');
      return false;
    }
  }

  // ── Associations service ↔ promotion (/api/services/promotions) ──

  /// Promotions liées à un service spécifique
  Future<List<ServicePromotionLink>> getServicePromotions(
    int serviceId, {
    bool activeOnly = false,
    String? token,
  }) async {
    try {
      final path = activeOnly
          ? '$_baseUrl/api/services/promotions/service/$serviceId/active'
          : '$_baseUrl/api/services/promotions/service/$serviceId';

      final response = await http
          .get(Uri.parse(path), headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body is Map ? (body['data'] ?? []) : body;
        return (list as List)
            .whereType<Map<String, dynamic>>()
            .map(ServicePromotionLink.fromJson)
            .toList();
      }
    } catch (e) {
      print('PromotionService.getServicePromotions error: $e');
    }
    return [];
  }

  /// IDs des services avec badge promo actif (optimisation dashboard)
  Future<List<int>> getActivePromoServiceIds(
    int companyId, {
    String? token,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '$_baseUrl/api/services/promotions/company/$companyId/active-service-ids'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body is Map ? (body['data'] ?? []) : body;
        return (list as List).map((e) => int.tryParse('$e') ?? 0).toList();
      }
    } catch (e) {
      print('PromotionService.getActivePromoServiceIds error: $e');
    }
    return [];
  }
}

// ── Modèle d'association service ↔ promotion ────────────────────

class ServicePromotionLink {
  final int id;
  final int serviceId;
  final String serviceCode;
  final String serviceName;
  final String? serviceIconUrl;
  final String? serviceColorHex;
  final int promotionId;
  final String promotionName;
  final String promotionStatus;
  final DateTime promotionStart;
  final DateTime promotionEnd;
  final String? badgeLabel;
  final DateTime? displayFrom;
  final DateTime? displayUntil;
  final bool effectivelyActive;
  final bool active;
  final int companyId;

  ServicePromotionLink({
    required this.id,
    required this.serviceId,
    required this.serviceCode,
    required this.serviceName,
    this.serviceIconUrl,
    this.serviceColorHex,
    required this.promotionId,
    required this.promotionName,
    required this.promotionStatus,
    required this.promotionStart,
    required this.promotionEnd,
    this.badgeLabel,
    this.displayFrom,
    this.displayUntil,
    required this.effectivelyActive,
    required this.active,
    required this.companyId,
  });

  factory ServicePromotionLink.fromJson(Map<String, dynamic> j) {
    DateTime parseDate(dynamic v) =>
        v == null ? DateTime.now() : DateTime.tryParse('$v') ?? DateTime.now();

    return ServicePromotionLink(
      id: j['id'] ?? 0,
      serviceId: j['serviceId'] ?? 0,
      serviceCode: j['serviceCode'] ?? '',
      serviceName: j['serviceName'] ?? '',
      serviceIconUrl: j['serviceIconUrl'],
      serviceColorHex: j['serviceColorHex'],
      promotionId: j['promotionId'] ?? 0,
      promotionName: j['promotionName'] ?? '',
      promotionStatus: j['promotionStatus'] ?? '',
      promotionStart: parseDate(j['promotionStart']),
      promotionEnd: parseDate(j['promotionEnd']),
      badgeLabel: j['badgeLabel'],
      displayFrom: j['displayFrom'] != null ? parseDate(j['displayFrom']) : null,
      displayUntil: j['displayUntil'] != null ? parseDate(j['displayUntil']) : null,
      effectivelyActive: j['effectivelyActive'] == true,
      active: j['active'] == true,
      companyId: j['companyId'] ?? 0,
    );
  }
}