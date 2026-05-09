// lib/services/service_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/service_model.dart';

class ServiceService {
  static const String _baseUrl = 'https://api.cardoil.io';

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ── Helpers ───────────────────────────────────────────────────

  List<ServiceModel> _parseServiceList(dynamic body) {
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
        .map(ServiceModel.fromJson)
        .toList();
  }

  List<CategoryModel> _parseCategoryList(dynamic body) {
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
        .map(CategoryModel.fromJson)
        .toList();
  }

  // ── Catalogue (/api/services/catalogue) ──────────────────────

  /// Tous les services d'une compagnie
  Future<List<ServiceModel>> getAllServices(
    int companyId, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/services/catalogue')
          .replace(queryParameters: {'companyId': '$companyId'});

      print('>>> SERVICE REQUEST: $uri');

      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      print('>>> SERVICE STATUS: ${response.statusCode}');
      print('>>> SERVICE BODY: ${response.body}');

      if (response.statusCode == 200) {
        return _parseServiceList(jsonDecode(response.body));
      }
    } catch (e) {
      print('ServiceService.getAllServices error: $e');
    }
    return [];
  }

  /// Services actifs uniquement (triés : obligatoires en premier)
  Future<List<ServiceModel>> getActiveServices(
    int companyId, {
    String? token,
  }) async {
   try {
    final uri = Uri.parse('$_baseUrl/api/services/catalogue/active')
        .replace(queryParameters: {'companyId': '$companyId'});

    print('>>> ACTIVE URL: $uri');  // ← voir l'URL exacte

    final response = await http.get(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 10));

    print('>>> ACTIVE STATUS: ${response.statusCode}');
    print('>>> ACTIVE BODY: ${response.body}');

      if (response.statusCode == 200) {
        return _parseServiceList(jsonDecode(response.body));
      }
    } catch (e) {
      print('ServiceService.getActiveServices error: $e');
    }
    return [];
  }

  /// Services filtrés par statut
  Future<List<ServiceModel>> getServicesByStatus(
    int companyId,
    String status, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/services/catalogue/by-status')
          .replace(queryParameters: {
        'companyId': '$companyId',
        'status': status,
      });

      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseServiceList(jsonDecode(response.body));
      }
    } catch (e) {
      print('ServiceService.getServicesByStatus error: $e');
    }
    return [];
  }

  /// Un service par ID
  Future<ServiceModel?> getService(int serviceId, {String? token}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/services/catalogue/$serviceId'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body is Map && body.containsKey('data')
            ? body['data'] as Map<String, dynamic>
            : body as Map<String, dynamic>;
        return ServiceModel.fromJson(data);
      }
    } catch (e) {
      print('ServiceService.getService error: $e');
    }
    return null;
  }

  // ── Catégories (/api/services/categories) ────────────────────

  /// Catégories disponibles pour une compagnie
  Future<List<CategoryModel>> getCategories(
    int companyId, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/services/categories')
          .replace(queryParameters: {'companyId': '$companyId'});

      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseCategoryList(jsonDecode(response.body));
      }
    } catch (e) {
      print('ServiceService.getCategories error: $e');
    }
    return [];
  }

  /// Catégorie par ID
  Future<CategoryModel?> getCategory(int categoryId, {String? token}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/services/categories/$categoryId'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body is Map && body.containsKey('data')
            ? body['data'] as Map<String, dynamic>
            : body as Map<String, dynamic>;
        return CategoryModel.fromJson(data);
      }
    } catch (e) {
      print('ServiceService.getCategory error: $e');
    }
    return null;
  }

  // ── Services groupés par catégorie (utile pour la page dédiée) ─

  Future<Map<CategoryModel, List<ServiceModel>>> getServicesGroupedByCategory(
    int companyId, {
    bool activeOnly = true,
    String? token,
  }) async {
    final results = await Future.wait([
      activeOnly
          ? getActiveServices(companyId, token: token)
          : getAllServices(companyId, token: token),
      getCategories(companyId, token: token),
    ]);

    final services = results[0] as List<ServiceModel>;
    final categories = results[1] as List<CategoryModel>;

    final Map<CategoryModel, List<ServiceModel>> grouped = {};

    for (final category in categories) {
      final categoryServices =
          services.where((s) => s.categoryId == category.id).toList();
      if (categoryServices.isNotEmpty) {
        grouped[category] = categoryServices;
      }
    }

    // Services sans catégorie connue
    final allCategoryIds = categories.map((c) => c.id).toSet();
    final orphans =
        services.where((s) => !allCategoryIds.contains(s.categoryId)).toList();
    if (orphans.isNotEmpty) {
      grouped[CategoryModel(
        id: 0,
        name: 'Autres',
        type: 'AUTRE',
        companyId: companyId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )] = orphans;
    }

    return grouped;
  }
}