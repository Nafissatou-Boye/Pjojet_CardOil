import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/promotion_model.dart';

class PromotionService {
  static const String _baseUrl = 'https://api.cardoil.io';

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ─── HELPER INTERNE : charge une liste de promotions ─────────
  Future<List<PromotionModel>> _fetchPromotions({
    required String companyId,
    bool activeOnly = false,
    int? limit,
    String? token,
  }) async {
    try {
      final params = <String, String>{
        'compagnie': companyId,
        if (activeOnly) 'isActive': 'true',
        if (limit != null) 'limit': '$limit',
      };
      final uri = Uri.parse('$_baseUrl/api/promotions')
          .replace(queryParameters: params);

      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body is List
            ? body
            : (body['content'] ?? body['data'] ?? []) as List;
        return list
            .map((e) =>
                PromotionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('PromotionService._fetchPromotions error: $e');
    }
    return [];
  }

  // ─── STREAM PROMOTIONS ACTIVES (AVEC LIMITE) ─────────────────

  Stream<List<PromotionModel>> getPromotionsStream(
    String companyId, {
    int limit = 10,
    String? token,
  }) async* {
    yield await _fetchPromotions(
      companyId: companyId,
      activeOnly: true,
      limit: limit,
      token: token,
    );
  }

  // Future version (utilisée dans client_dashboard)
  Future<List<PromotionModel>> getPromotions(
    String companyId, {
    int limit = 10,
    String? token,
  }) =>
      _fetchPromotions(
        companyId: companyId,
        activeOnly: true,
        limit: limit,
        token: token,
      );

  // ─── STREAM TOUTES LES PROMOTIONS ────────────────────────────
  Stream<List<PromotionModel>> getAllPromotionsStream(
    String companyId, {
    String? token,
  }) async* {
    yield await _fetchPromotions(
        companyId: companyId, token: token);
  }

  Future<List<PromotionModel>> getAllPromotions(
    String companyId, {
    String? token,
  }) =>
      _fetchPromotions(companyId: companyId, token: token);

  // ─── STREAM UNE PROMOTION PAR ID ─────────────────────────────
  Stream<PromotionModel?> getPromotionStream(
    String promotionId, {
    String? token,
  }) async* {
    yield await getPromotion(promotionId, token: token);
  }

  Future<PromotionModel?> getPromotion(
    String promotionId, {
    String? token,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/promotions/$promotionId'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return PromotionModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
    } catch (e) {
      print('PromotionService.getPromotion error: $e');
    }
    return null;
  }

  // ─── VÉRIFIER SI L'UTILISATEUR A DÉJÀ PARTICIPÉ ──────────────
  Future<bool> hasParticipated(
    String promotionId, {
    String? token,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '$_baseUrl/api/promotions/$promotionId/participated'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['participated'] == true || data == true;
      }
    } catch (e) {
      print('PromotionService.hasParticipated error: $e');
    }
    return false;
  }

  // ─── PARTICIPER À UNE PROMOTION ──────────────────────────────
  Future<bool> participatePromotion(
    String promotionId, {
    String? token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
                '$_baseUrl/api/promotions/$promotionId/participate'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('PromotionService.participatePromotion error: $e');
      return false;
    }
  }

  // ─── CRÉER UNE PROMOTION (ADMIN) ─────────────────────────────
  Future<String?> createPromotion({
    required String compagnie,
    required String title,
    required String description,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    String? image,
    String conditions = '',
    String actionButton = 'Participer',
    String? token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/promotions'),
            headers: _headers(token),
            body: jsonEncode({
              'compagnie': compagnie,
              'title': title,
              'description': description,
              'type': type,
              'startDate': startDate.toIso8601String(),
              'endDate': endDate.toIso8601String(),
              if (image != null) 'image': image,
              'conditions': conditions,
              'actionButton': actionButton,
              'isActive': true,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['id']?.toString();
      }
    } catch (e) {
      print('PromotionService.createPromotion error: $e');
    }
    return null;
  }
}