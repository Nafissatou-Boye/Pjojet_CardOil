// lib/services/transaction_service.dart

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../models/receipt_model.dart';
import 'loyalty_service.dart';

class TransactionService {
  static const String _baseUrl = 'https://api.cardoil.io';
  static const String _tokenKey = 'auth_token';
  static const String _txCacheKey = 'cached_transactions';
  static const String _userKey = 'user_data'; // ✅ même clé qu'AuthService

  final _loyaltyService = LoyaltyService();

  // ── Headers ───────────────────────────────────────────────────────────────

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  List _extractList(dynamic body) {
    if (body is List) return body;
    if (body is Map) {
      for (final k in ['content', 'data', 'transactions', 'results']) {
        if (body[k] is List) return body[k] as List;
      }
    }
    return [];
  }

  // ── Récupère clientId et companyId depuis user_data ───────────────────────
  //
  // UserModel.toApiJson() sérialise :
  //   'id'               → clientId numérique
  //   'compagnie'        → int? (ex: 1)
  //   'selectedCompagnie'→ String (ex: "1" ou "TOTAL") — ajouté après fix
  //
  // On essaie plusieurs champs pour être robuste.

  Future<({int clientId, int companyId})> _getClientContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_userKey);
      if (raw == null) return (clientId: 0, companyId: 0);

      final json = jsonDecode(raw) as Map<String, dynamic>;

      // clientId : champ 'id'
      final clientId = _parseInt(json['id'] ?? json['userId']);

      // companyId : essayer dans l'ordre
      //   1. 'compagnie' (int) — toujours présent
      //   2. 'selectedCompagnie' (String) — présent après le fix UserModel
      int companyId = _parseInt(json['compagnie']);
      if (companyId == 0) {
        companyId = _parseInt(json['selectedCompagnie']);
      }

      debugPrint('🔍 loyalty context → clientId=$clientId companyId=$companyId');
      return (clientId: clientId, companyId: companyId);
    } catch (e) {
      debugPrint('⚠️ _getClientContext error: $e');
      return (clientId: 0, companyId: 0);
    }
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  // ── Résoudre le product_type depuis l'API ─────────────────────────────────

  Future<String> _resolveProductType(int productId) async {
    if (productId == 0) return 'CARBURANT';
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/products/$productId'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body is Map && body.containsKey('data') ? body['data'] : body;
        return (data['productType'] ?? data['product_type'] ?? 'CARBURANT')
            .toString()
            .toUpperCase();
      }
    } catch (_) {}
    return 'CARBURANT'; // Gasoil/Super/Essence = CARBURANT par défaut
  }

  // ── Créditer les points (silencieux — ne bloque jamais le paiement) ───────

  Future<void> _creditLoyaltyPoints({
    required int productId,
    required double amount,
    String? productName,
    int? overrideClientId,
    int? overrideCompanyId,
  }) async {
    try {
      int clientId;
      int companyId;

      if (overrideClientId != null && overrideClientId > 0 &&
          overrideCompanyId != null && overrideCompanyId > 0) {
        clientId = overrideClientId;
        companyId = overrideCompanyId;
      } else {
        final ctx = await _getClientContext();
        clientId = ctx.clientId;
        companyId = ctx.companyId;
      }

      if (clientId == 0 || companyId == 0) {
        debugPrint('⚠️ loyalty skip: clientId=$clientId companyId=$companyId');
        return;
      }

      final productType = await _resolveProductType(productId);

      final pts = await _loyaltyService.processTransactionPoints(
        productType: productType,
        amount: amount,
        clientId: clientId,
        companyId: companyId,
        productName: productName,
      );

      if (pts > 0) debugPrint('🏆 +$pts points fidélité crédités (client $clientId)');
    } catch (e) {
      debugPrint('⚠️ _creditLoyaltyPoints silenced: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GET TRANSACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<StationTransactionModel>> getTransactions({bool forceRefresh = false}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/transactions/me'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final list = _extractList(jsonDecode(response.body));
        final transactions = list
            .map((e) => StationTransactionModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _txCacheKey,
          jsonEncode(transactions.map((t) => t.toJson()).toList()),
        );

        return transactions;
      }

      if (response.statusCode == 401) {
        debugPrint('❌ Token expiré — transactions');
      } else {
        debugPrint('❌ getTransactions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ getTransactions: $e');
    }
    return await _cachedTransactions();
  }

  Future<List<StationTransactionModel>> getAllTransactions({bool forceRefresh = false}) =>
      getTransactions(forceRefresh: forceRefresh);

  Future<List<StationTransactionModel>> _cachedTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_txCacheKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        return list
            .map((e) => StationTransactionModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAKE CLIENT PAYMENT
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> makeClientPayment({
    required String cardReference,
    required double amount,
    required int productId,
    required int stationId,
    String? pompisteUsername,
    String? clientUserId,
    String? stationName,
    String? productName,
  }) async {
    debugPrint('💳 makeClientPayment | amount=$amount productId=$productId');

    // ── Stratégie 1 : createByClient ───────────────────────────────────────
    if (pompisteUsername != null && pompisteUsername.isNotEmpty &&
        clientUserId != null && clientUserId.isNotEmpty &&
        int.tryParse(clientUserId) != null) {

      final amountStr = amount.toStringAsFixed(0);
      final uri = Uri.parse(
        '$_baseUrl/api/transactions/createByClient'
        '/$pompisteUsername/$clientUserId/$amountStr/$productId',
      );

      debugPrint('🚀 POST $uri');

      try {
        final res = await http.post(
          uri,
          headers: await _headers(),
          body: jsonEncode({'id': stationId, 'companyName': stationName ?? ''}),
        ).timeout(const Duration(seconds: 45));

        debugPrint('   ← ${res.statusCode}: ${res.body}');

        if (res.statusCode == 200 || res.statusCode == 201) {
          await clearCache();

          String transactionId = '';
          try {
            final data = jsonDecode(res.body);
            transactionId = data is Map ? data['id']?.toString() ?? '' : '';
          } catch (_) {}

          // ✅ Points fidélité — non bloquant
          unawaited(_creditLoyaltyPoints(
            productId: productId,
            amount: amount,
            productName: productName,
          ));

          return {'success': true, 'transactionId': transactionId, 'data': res.body};
        }
      } on http.ClientException catch (e) {
        if (e.message.contains('Failed host lookup') || e.message.contains('errno = 7')) {
          return {'success': false, 'error': 'Pas de connexion internet.\nVérifiez votre WiFi ou données mobiles.'};
        }
      } on TimeoutException {
        debugPrint('⚠️ createByClient timeout → fallback /create');
      } catch (e) {
        debugPrint('⚠️ createByClient error: $e → fallback');
      }
    }

    // ── Stratégie 2 : /create ───────────────────────────────────────────────
    const typesToTry = ['CLIENT_VENTE', 'VENTE', 'DEBIT', 'PAIEMENT'];

    for (final type in typesToTry) {
      try {
        final res = await http.post(
          Uri.parse('$_baseUrl/api/transactions/create'),
          headers: await _headers(),
          body: jsonEncode({
            'type': type,
            'cardReference': cardReference,
            'amount': amount,
            'productId': productId,
            'stationId': stationId,
          }),
        ).timeout(const Duration(seconds: 45));

        debugPrint('   ← ${res.statusCode}: ${res.body}');

        if (res.statusCode == 200 || res.statusCode == 201) {
          await clearCache();

          String transactionId = '';
          try {
            final data = jsonDecode(res.body);
            transactionId = data is Map ? data['id']?.toString() ?? '' : '';
          } catch (_) {}

          // ✅ Points fidélité — non bloquant
          unawaited(_creditLoyaltyPoints(
            productId: productId,
            amount: amount,
            productName: productName,
          ));

          return {'success': true, 'transactionId': transactionId, 'data': res.body};
        }

        String errorMsg = 'Erreur (${res.statusCode})';
        try {
          final err = jsonDecode(res.body) as Map;
          errorMsg = err['message']?.toString() ?? err['error']?.toString() ?? errorMsg;
        } catch (_) {}

        final errLower = errorMsg.toLowerCase();
        if (errLower.contains('compagnie') || errLower.contains('compte') ||
            errLower.contains('type') || errLower.contains('inconnu') ||
            errLower.contains('introuvable')) {
          continue;
        }

        return {'success': false, 'error': errorMsg};
      } on http.ClientException catch (e) {
        if (e.message.contains('Failed host lookup') || e.message.contains('errno = 7')) {
          return {'success': false, 'error': 'Pas de connexion internet.\nVérifiez votre WiFi ou données mobiles.'};
        }
      } on TimeoutException {
        continue;
      } catch (e) {
        debugPrint('   Exception: $e');
      }
    }

    return {
      'success': false,
      'error': 'Paiement impossible.\nVérifiez votre connexion internet ou contactez votre administrateur.',
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAKE POMPISTE PAYMENT
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> makePompistePayment({
    required String username,
    required int clientId,
    required String amount,
    required String productId,
    required int stationId,
    required String companyName,
    String? productName,
  }) async {
    debugPrint('🚀 POMPISTE PAYMENT → createByClient/$username/$clientId/$amount/$productId');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/transactions/createByClient/'
            '$username/$clientId/$amount/$productId'),
        headers: await _headers(),
        body: jsonEncode({'id': stationId, 'companyName': companyName}),
      ).timeout(const Duration(seconds: 15));

      debugPrint('📥 Pompiste Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        await clearCache();

        final ctx = await _getClientContext();

        // ✅ Points pour le CLIENT (clientId passé en paramètre)
        unawaited(_creditLoyaltyPoints(
          productId: int.tryParse(productId) ?? 0,
          amount: double.tryParse(amount) ?? 0.0,
          productName: productName,
          overrideClientId: clientId,
          overrideCompanyId: ctx.companyId,
        ));

        return {
          'success': true,
          'data': response.body.isNotEmpty ? jsonDecode(response.body) : {},
        };
      }

      return {'success': false, 'error': 'Pompiste ${response.statusCode}: ${response.body}'};
    } catch (e) {
      return {'success': false, 'error': 'Pompiste réseau: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTRES MÉTHODES — inchangées
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<ReceiptModel?> getReceiptByTransaction(String transactionId) async* {
    yield await fetchReceipt(transactionId: transactionId);
  }

  Future<ReceiptModel?> fetchReceipt({required String transactionId}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/transactions/$transactionId'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json is Map && json.containsKey('data') ? json['data'] : json;
        return ReceiptModel.fromJson(Map<String, dynamic>.from(data as Map));
      }
    } catch (e) {
      debugPrint('❌ fetchReceipt: $e');
    }
    return null;
  }

  Future<List<StationTransactionModel>> getTransactionsForStaff() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/transactions/transactionsForGerantAndPompiste'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _extractList(jsonDecode(response.body))
            .map((e) => StationTransactionModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('❌ getForStaff: $e');
    }
    return [];
  }

  Future<List<StationTransactionModel>> getTransactionsForCompany({required String companyId}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/transactions/transactionsForCompagnie/$companyId'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _extractList(jsonDecode(response.body))
            .map((e) => StationTransactionModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('❌ getForCompany: $e');
    }
    return [];
  }

  Future<List<StationTransactionModel>> getTransactionsForEntreprise() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/transactions/transactionsForAdminEntreprise'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _extractList(jsonDecode(response.body))
            .map((e) => StationTransactionModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('❌ getTransactionsForEntreprise: $e');
    }
    return [];
  }

  Future<List<StationTransactionModel>> refreshTransactions() =>
      getTransactions(forceRefresh: true);

  Stream<List<StationTransactionModel>> get transactionsStream async* {
    yield await getTransactions();
  }

  Stream<List<StationTransactionModel>> get paymentsStream async* {
    final all = await getTransactions();
    yield all.where((tx) => tx.transactionType == TransactionType.payment).toList();
  }

  Stream<List<StationTransactionModel>> get rechargesStream async* {
    final all = await getTransactions();
    yield all.where((tx) => tx.transactionType == TransactionType.recharge).toList();
  }

  void dispose() {}

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_txCacheKey);
  }
}