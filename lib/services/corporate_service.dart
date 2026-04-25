import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/corporate_employee_model.dart';


class CorporateService {
  static const String _baseUrl = 'https://api.cardoil.io';
  static const String _tokenKey = 'auth_token';
  static const String _accountCacheKey = 'cached_corporate_account';

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
  

  
Future<Map<String, dynamic>> getMyAccount() async {
  try {
    final results = await Future.wait([
      http.get(
        Uri.parse('$_baseUrl/api/entreprises/compte/compte-entreprise'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10)),
      http.get(
        Uri.parse('$_baseUrl/api/users/me'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10)),
    ]);

    final compteResp = results[0];
    final userResp   = results[1];

    print('📡 /compte-entreprise → ${compteResp.statusCode}');
    print('📡 /users/me         → ${userResp.statusCode}');

    // ── Parser le compte ─────────────────────────────
    Map<String, dynamic> compteJson = {};
    if (compteResp.statusCode == 200) {
      final raw = jsonDecode(compteResp.body);

      if (raw is List && raw.isNotEmpty) {
        compteJson = Map<String, dynamic>.from(raw.first as Map);
      } else if (raw is Map) {
        compteJson = Map<String, dynamic>.from(raw);
      }

      // ✅ DEBUG ICI (CORRECT)
      print('💰 soldeReel       = ${compteJson['soldeReel']}');
      print('💰 soldeDisponible = ${compteJson['soldeDisponible']}');
      print('💰 solde           = ${compteJson['solde']}');
      print('💰 TOUS LES CHAMPS: $compteJson');
    }

    // ── Parser user ─────────────────────────────
    Map<String, dynamic> userJson = {};
    if (userResp.statusCode == 200) {
      final raw = jsonDecode(userResp.body);

      if (raw is List && raw.isNotEmpty) {
        userJson = Map<String, dynamic>.from(raw.first as Map);
      } else if (raw is Map && raw.containsKey('user')) {
        userJson = Map<String, dynamic>.from(raw['user'] as Map);
      } else if (raw is Map) {
        userJson = Map<String, dynamic>.from(raw);
      }
    }

    print('📋 compteJson: $compteJson');
    print('📋 userJson.firstname: ${userJson['firstname']}');

    // ── Construire modèle ─────────────────────────────
    final account = CorporateAccountModel.fromCombined(
      compteJson: compteJson,
      userJson: userJson,
    );

    print('✅ Account: ${account.fullName} | ${account.balance} FCFA');

    // Cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountCacheKey, jsonEncode(account.toJson()));

    return {'success': true, 'account': account};

  } catch (e) {
    print('❌ getMyAccount: $e');

    final cached = await _getCachedAccount();
    if (cached != null) {
      return {'success': true, 'account': cached, 'fromCache': true};
    }

    return await _fallbackFromProfile();
  }
}

  // ── Fallback si les deux endpoints échouent ────────────────────────────
  Future<Map<String, dynamic>> _fallbackFromProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/me'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body);
        Map<String, dynamic> userJson;
        if (raw is List && raw.isNotEmpty) {
          userJson = Map<String, dynamic>.from(raw.first as Map);
        } else if (raw is Map && raw.containsKey('user')) {
          userJson = Map<String, dynamic>.from(raw['user'] as Map);
        } else {
          userJson = Map<String, dynamic>.from(raw as Map);
        }

        final account = CorporateAccountModel.fromCombined(
          compteJson: {},
          userJson: userJson,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accountCacheKey, jsonEncode(account.toJson()));
        return {'success': true, 'account': account, 'isFallback': true};
      }
    } catch (e) {
      print('❌ _fallbackFromProfile: $e');
    }

    return {
      'success': true,
      'account': CorporateAccountModel(
        id: '', fullName: 'Mon Compte', email: '',
        matriculePlaque: '', enterpriseId: '', enterpriseName: 'Entreprise',
        accountType: 'cumulative', monthlyLimit: 0, currentMonthUsage: 0,
        balance: 0, isActive: true,
      ),
      'isFallback': true,
    };
  }

  // ── Cache ──────────────────────────────────────────────────────────────
  Future<CorporateAccountModel?> _getCachedAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_accountCacheKey);
      if (raw != null) {
        return CorporateAccountModel.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw)));
      }
    } catch (e) { print('❌ Cache error: $e'); }
    return null;
  }

  // ── Notifications ──────────────────────────────────────────────────────
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/notifications'), headers: await _headers())
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body is List
            ? body
            : (body['content'] ?? body['data'] ?? body['notifications'] ?? []) as List;
        return list
            .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) { print('❌ getNotifications: $e'); }
    return [];
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/API/notifications/non%20lu/compte'),
        headers: await _headers()).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is int) return body;
        if (body is Map) return (body['count'] ?? body['total'] ?? 0) as int;
      }
    } catch (e) { print('❌ getUnreadCount: $e'); }
    return 0;
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/notifications/$notificationId/read'),
        headers: await _headers()).timeout(const Duration(seconds: 8));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) { print('❌ markAsRead: $e'); }
    return false;
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/notifications/$notificationId'),
        headers: await _headers()).timeout(const Duration(seconds: 8));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) { print('❌ deleteNotification: $e'); }
    return false;
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accountCacheKey);
  }

  
}