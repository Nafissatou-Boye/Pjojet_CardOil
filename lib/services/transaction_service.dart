import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
      for (final key in ['content', 'data', 'transactions', 'results']) {
        if (body[key] is List) return body[key] as List;
      }
    }
    return [];
  }

  Future<List<TransactionModel>> getTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/transactions/me'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final list = _extractList(jsonDecode(response.body));
        final transactions = list
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
        // Cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_txCacheKey,
            jsonEncode(transactions.map((t) => t.toJson()).toList()));
        return transactions;
      }
    } catch (e) {
      print('❌ getTransactions: $e');
    }
    return await _cachedTransactions();
  }

  Future<List<TransactionModel>> _cachedTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_txCacheKey);
      if (raw != null) {
        return (jsonDecode(raw) as List)
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
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
        return ReceiptModel.fromJson(data as Map<String, dynamic>);
      }
    } catch (e) {
      print('❌ fetchReceipt: $e');
    }
    return null;
  }

  Future<List<TransactionModel>> getTransactionsForGerantAndPompiste() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/transactions/transactionsForGerantAndPompiste'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return _extractList(jsonDecode(response.body))
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) { print('❌ getForGerant: $e'); }
    return [];
  }

  Future<List<TransactionModel>> getTransactionsForCompagnie({
    required String companyId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/transactions/transactionsForCompagnie/$companyId'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return _extractList(jsonDecode(response.body))
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) { print('❌ getForCompagnie: $e'); }
    return [];
  }

  Future<Map<String, dynamic>> createVente({
    required String username,
    required int clientId,
    required String amount,
    required String productId,
    required int stationId,
    required String companyName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/transactions/vente/$username/$clientId/$amount/$productId'),
        headers: await _headers(),
        body: jsonEncode({'id': stationId, 'companyName': companyName}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.body.isNotEmpty ? jsonDecode(response.body) : {}};
      }
      return {'success': false, 'error': 'Erreur serveur (${response.statusCode})'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  Stream<List<TransactionModel>> getTransactionsStream() async* {
    yield await getTransactions();
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_txCacheKey);
  }
}