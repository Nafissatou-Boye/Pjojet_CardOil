import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../models/receipt_model.dart';

class TransactionService {
  static const String _baseUrl = 'https://api.cardoil.io';
  static const String _tokenKey = 'auth_token';
  static const String _txCacheKey = 'cached_transactions';


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

  
  Future<List<StationTransactionModel>> getTransactions({bool forceRefresh = false}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/transactions/me'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final list = _extractList(jsonDecode(response.body));
        final transactions = list
            .map((e) => StationTransactionModel.fromJson(
                Map<String, dynamic>.from(e as Map)))
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
        print('❌ Token expiré — transactions');
      } else {
        print('❌ getTransactions: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ getTransactions: $e');
    }

    return await _cachedTransactions();
  }

  // Alias
  Future<List<StationTransactionModel>> getAllTransactions({bool forceRefresh = false}) =>
      getTransactions(forceRefresh: forceRefresh);

  
  Future<List<StationTransactionModel>> _cachedTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_txCacheKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        return list
            .map((e) => StationTransactionModel.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

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
      print('❌ fetchReceipt: $e');
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
            .map((e) => StationTransactionModel.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) { 
      print('❌ getForStaff: $e'); 
    }
    return [];
  }

  Future<List<StationTransactionModel>> getTransactionsForCompany(
      {required String companyId}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/transactions/transactionsForCompagnie/$companyId'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _extractList(jsonDecode(response.body))
            .map((e) => StationTransactionModel.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) { 
      print('❌ getForCompany: $e'); 
    }
    return [];
  }
Future<Map<String, dynamic>> makeClientPayment({
  required String cardReference,
  required double amount,
  required int productId,
  required int stationId,
  String? pompisteUsername,
  String? clientUserId,
  String? stationName,
}) async {
  debugPrint('💳 makeClientPayment:');
  debugPrint('   pompisteUsername: $pompisteUsername');
  debugPrint('   clientUserId: $clientUserId');
  debugPrint('   cardRef: $cardReference | amount: $amount');

  // ── Stratégie 1 : createByClient ─────────────────────────────────────
  if (pompisteUsername != null && pompisteUsername.isNotEmpty &&
      clientUserId != null && clientUserId.isNotEmpty &&
      int.tryParse(clientUserId) != null) {

    final amountStr = amount.toStringAsFixed(0);
    final uri = Uri.parse(
      '$_baseUrl/api/transactions/createByClient'
      '/$pompisteUsername/$clientUserId/$amountStr/$productId',
    );

    debugPrint('🚀 POST $uri');

// Dans makeClientPayment — remplacer le bloc try du createByClient
try {
  final res = await http.post(
    uri,
    headers: await _headers(),
    body: jsonEncode({
      'id':          stationId,
      'companyName': stationName ?? '',
    }),
  ).timeout(const Duration(seconds: 45));

  debugPrint('   ← ${res.statusCode}: ${res.body}');

  if (res.statusCode == 200 || res.statusCode == 201) {
    await clearCache();
    
    // ✅ FIX : l'API peut renvoyer du texte brut OU du JSON
    String transactionId = '';
    try {
      final data = jsonDecode(res.body);
      transactionId = data is Map ? data['id']?.toString() ?? '' : '';
    } catch (_) {
      // Réponse texte brut = succès quand même, pas d'ID à extraire
      debugPrint('   ℹ️ Réponse texte (pas JSON) — succès confirmé');
    }
    
    return {
      'success': true,
      'transactionId': transactionId,
      'data': res.body,
    };
        
       
      }

    } 
    on http.ClientException catch (e) {
      if (e.message.contains('Failed host lookup') ||
          e.message.contains('errno = 7')) {
        return {
          'success': false,
          'error': 'Pas de connexion internet.\nVérifiez votre WiFi ou données mobiles.',
        };
      }
    } on TimeoutException {
      // Timeout sur createByClient → essayer /create
      debugPrint('⚠️ createByClient timeout → fallback /create');
    } catch (e) {
      debugPrint('⚠️ createByClient error: $e → fallback');
    }
  }

  // ── Stratégie 2 : /create ─────────────────────────────────────────────
  const typesToTry = ['CLIENT_VENTE', 'VENTE', 'DEBIT', 'PAIEMENT'];

  for (final type in typesToTry) {
    try {
      final body = {
        'type':          type,
        'cardReference': cardReference,
        'amount':        amount,
        'productId':     productId,
        'stationId':     stationId,
      };

      debugPrint('🚀 POST /api/transactions/create type=$type');

      final res = await http.post(
        Uri.parse('$_baseUrl/api/transactions/create'),
        headers: await _headers(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 45)); // ✅ timeout augmenté

      debugPrint('   ← ${res.statusCode}: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        await clearCache();
        // APRÈS — résistant au texte brut
String transactionId = '';
try {
  final data = jsonDecode(res.body);
  transactionId = data is Map ? data['id']?.toString() ?? '' : '';
} catch (_) {
  debugPrint('   ℹ️ Réponse texte brut — succès confirmé');
}
return {'success': true, 'transactionId': transactionId, 'data': res.body};
      }

      String errorMsg = 'Erreur (${res.statusCode})';
      try {
        final err = jsonDecode(res.body) as Map;
        errorMsg = err['message']?.toString() ?? err['error']?.toString() ?? errorMsg;
      } catch (_) {}

      debugPrint('   erreur: $errorMsg');

      // Continuer si erreur de type/compte
      final errLower = errorMsg.toLowerCase();
      if (errLower.contains('compagnie') || errLower.contains('compte') ||
          errLower.contains('type') || errLower.contains('inconnu') ||
          errLower.contains('introuvable')) {
        continue;
      }

      return {'success': false, 'error': errorMsg};

    } on http.ClientException catch (e) {
      if (e.message.contains('Failed host lookup') || e.message.contains('errno = 7')) {
        return {
          'success': false,
          'error': 'Pas de connexion internet.\nVérifiez votre WiFi ou données mobiles.',
        };
      }
    } on TimeoutException {
      debugPrint('   Timeout type=$type');
      // Continuer avec type suivant
      continue;
    } catch (e) {
      debugPrint('   Exception: $e');
    }
  }

  return {
    'success': false,
    'error': 'Paiement impossible.\n'
        'Vérifiez votre connexion internet ou contactez votre administrateur.',
  };
}

  Future<Map<String, dynamic>> makePompistePayment({
    required String username,      // Pompiste username
    required int clientId,        // Client ID
    required String amount,       // Montant string
    required String productId,    // Product ID string
    required int stationId,
    required String companyName,
  }) async {
    print('🚀 POMPISTE PAYMENT → POST /api/transactions/createByClient/...');
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/transactions/createByClient/'
            '$username/$clientId/$amount/$productId'),
        headers: await _headers(),
        body: jsonEncode({
          'id': stationId,
          'companyName': companyName,
        }),
      ).timeout(const Duration(seconds: 15));

      print('📥 Pompiste Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        await clearCache();
        return {
          'success': true,
          'data': response.body.isNotEmpty ? jsonDecode(response.body) : {},
        };
      }
      return {
        'success': false,
        'error': 'Pompiste ${response.statusCode}: ${response.body}',
      };
    } catch (e) {
      return {'success': false, 'error': 'Pompiste réseau: $e'};
    }
  }

  // ─── GET TRANSACTIONS FOR ADMIN ENTREPRISE ─────────────────
  Future<List<StationTransactionModel>> getTransactionsForEntreprise() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/transactions/transactionsForAdminEntreprise'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _extractList(jsonDecode(response.body))
            .map((e) => StationTransactionModel.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) { 
      print('❌ getTransactionsForEntreprise: $e'); 
    }
    return [];
  }

  // ─── REFRESH ──────────────────────────────────────────────────────────────
  Future<List<StationTransactionModel>> refreshTransactions() =>
      getTransactions(forceRefresh: true);

  // ─── STREAMS ──────────────────────────────────────────────────────────────
  Stream<List<StationTransactionModel>> get transactionsStream async* {
    yield await getTransactions();
  }

Stream<List<StationTransactionModel>> get paymentsStream async* {
  final all = await getTransactions();

  yield all.where((tx) =>
      tx.transactionType == TransactionType.payment
  ).toList();
}

Stream<List<StationTransactionModel>> get rechargesStream async* {
  final all = await getTransactions();

  yield all.where((tx) =>
      tx.transactionType == TransactionType.recharge
  ).toList();
}
  void dispose() {}

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_txCacheKey);
  }
}