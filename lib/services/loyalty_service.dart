// lib/services/loyalty_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/loyalty_model.dart';

class LoyaltyService {
  static const String _baseUrl = 'https://api.cardoil.io';
  static const String _tokenKey = 'auth_token';

  // ── Règles locales miroir de fidelity_rule en DB ──────────────────────────
  static const List<Map<String, dynamic>> _rules = [
    {'applicable_to': 'CARBURANT',  'points': 10, 'min_amount': 1000},
    {'applicable_to': 'LUBRIFIANT', 'points': 5,  'min_amount': 500},
    {'applicable_to': 'AUTRE',      'points': 2,  'min_amount': 200},
  ];

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── 1. Compte fidélité du client ──────────────────────────────────────────

  Future<LoyaltyAccountModel?> getMyLoyaltyAccount({
    required int clientId,
    required int companyId,
  }) async {
    if (clientId == 0 || companyId == 0) return null;
    try {
      final uri = Uri.parse('$_baseUrl/api/fidelite/accounts/client/$clientId')
          .replace(queryParameters: {'companyId': '$companyId'});

      final response = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body is Map && body.containsKey('data')
            ? body['data'] as Map<String, dynamic>
            : body as Map<String, dynamic>;
        return LoyaltyAccountModel.fromJson(data);
      }
    } catch (e) {
      print('LoyaltyService.getMyLoyaltyAccount error: $e');
    }
    return null;
  }

  // ── 2. Calculer les points pour une transaction ───────────────────────────

  int calculatePoints({required String productType, required double amount}) {
    final type = productType.toUpperCase().trim();

    // Cherche une règle qui matche exactement
    for (final rule in _rules) {
      if (rule['applicable_to'] == type &&
          amount >= (rule['min_amount'] as num).toDouble()) {
        return rule['points'] as int;
      }
    }

    // Fallback → règle AUTRE si montant suffisant
    final autreRule = _rules.firstWhere(
      (r) => r['applicable_to'] == 'AUTRE',
      orElse: () => {'points': 0, 'min_amount': 999999},
    );
    if (amount >= (autreRule['min_amount'] as num).toDouble()) {
      return autreRule['points'] as int;
    }

    return 0;
  }

  // ── 3. Créditer les points via API ────────────────────────────────────────

  Future<bool> addPoints({
    required int loyaltyAccountId,
    required int points,
    required String description,
  }) async {
    if (loyaltyAccountId == 0 || points <= 0) return false;
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/fidelite/accounts/$loyaltyAccountId/points'),
            headers: await _headers(),
            body: jsonEncode({'points': points, 'description': description}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ LoyaltyService: +$points pts (account $loyaltyAccountId)');
        return true;
      }
      print('❌ LoyaltyService.addPoints: ${response.statusCode} ${response.body}');
    } catch (e) {
      print('❌ LoyaltyService.addPoints error: $e');
    }
    return false;
  }

  // ── 4. Calculer + créditer en une seule méthode ───────────────────────────

  Future<int> processTransactionPoints({
    required String productType,
    required double amount,
    required int clientId,
    required int companyId,
    String? productName,
  }) async {
    final points = calculatePoints(productType: productType, amount: amount);
    if (points <= 0) return 0;

    final account = await getMyLoyaltyAccount(
      clientId: clientId,
      companyId: companyId,
    );
    if (account == null) return 0;

    final label = productName ?? productType;
    final success = await addPoints(
      loyaltyAccountId: account.id,
      points: points,
      description: 'Points gagnés — $label (${amount.toStringAsFixed(0)} FCFA)',
    );

    return success ? points : 0;
  }

  // ── 5. Récompenses ────────────────────────────────────────────────────────

  Future<List<LoyaltyRewardModel>> getActiveRewards(int companyId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/fidelite/rewards/active')
          .replace(queryParameters: {'companyId': '$companyId'});

      final response = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body is Map ? (body['data'] as List? ?? []) : body as List;
        return list.whereType<Map<String, dynamic>>().map(LoyaltyRewardModel.fromJson).toList();
      }
    } catch (e) {
      print('LoyaltyService.getActiveRewards error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> redeemReward({
    required int loyaltyAccountId,
    required int rewardId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/fidelite/accounts/$loyaltyAccountId/redeem'),
            headers: await _headers(),
            body: jsonEncode({'rewardId': rewardId, 'description': 'Échange de récompense'}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) return {'success': true};
      final err = jsonDecode(response.body);
      return {'success': false, 'error': err['message'] ?? 'Erreur'};
    } catch (e) {
      return {'success': false, 'error': '$e'};
    }
  }
}