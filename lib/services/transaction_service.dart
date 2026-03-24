// lib/services/transaction_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';
import '../models/receipt_model.dart';

class TransactionService {
  static const String _baseUrl = 'https://api.cardoil.io';

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ─── TRANSACTIONS DE L'UTILISATEUR CONNECTÉ ──────────────────
  // GET /api/transactions/me
  Future<List<TransactionModel>> getTransactions({String? token}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/transactions/me'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body is List
            ? body
            : (body['content'] ?? body['data'] ?? []) as List;
        return list
            .map((e) =>
                TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('TransactionService.getTransactions error: $e');
    }
    return [];
  }

  // ─── CRÉER UNE TRANSACTION VENTE ─────────────────────────────
  // POST /api/transactions/vente/{username}/{clientId}/{amount}/{productId}
  // Body : { "id": stationId, "companyName": "string" }
  Future<Map<String, dynamic>> createVente({
    required String token,
    required String username,
    required int clientId,
    required String amount,
    required String productId,
    required int stationId,
    required String companyName,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/api/transactions/vente'
              '/$username'
              '/$clientId'
              '/$amount'
              '/$productId',
            ),
            headers: _headers(token),
            body: jsonEncode({
              'id': stationId,
              'companyName': companyName,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : <String, dynamic>{};
        return {'success': true, 'data': data};
      }
      if (response.statusCode == 400) {
        return {'success': false, 'error': 'Requête invalide (400)'};
      }
      if (response.statusCode == 401) {
        return {'success': false, 'error': 'Non authentifié (401)'};
      }
      return {
        'success': false,
        'error': 'Erreur serveur (${response.statusCode})'
      };
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  // ─── REÇU D'UNE TRANSACTION ──────────────────────────────────
  // GET /api/transactions/{id}
  //
  // receipt_screen.dart utilise un StreamBuilder<ReceiptModel?>, donc on
  // expose une version Stream ET une version Future.
  //
  // ✅ Version Stream — compatible avec receipt_screen.dart
  Stream<ReceiptModel?> getReceiptByTransaction(
    String transactionId, {
    String? token,
  }) async* {
    yield await _fetchReceipt(transactionId: transactionId, token: token);
  }

  // ✅ Version Future — utilisable depuis d'autres endroits
  Future<ReceiptModel?> fetchReceipt({
    required String transactionId,
    String? token,
  }) =>
      _fetchReceipt(transactionId: transactionId, token: token);

  Future<ReceiptModel?> _fetchReceipt({
    required String transactionId,
    String? token,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/transactions/$transactionId'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json =
            jsonDecode(response.body) as Map<String, dynamic>;
        return ReceiptModel.fromJson(json);
      }
    } catch (e) {
      print('TransactionService._fetchReceipt error: $e');
    }
    return null;
  }

  // ─── TRANSACTIONS GÉRANT / POMPISTE ──────────────────────────
  // GET /api/transactions/transactionsForGerantAndPompiste
  Future<List<TransactionModel>> getTransactionsForGerantAndPompiste({
    required String token,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '$_baseUrl/api/transactions/transactionsForGerantAndPompiste'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body is List
            ? body
            : (body['content'] ?? body['data'] ?? []) as List;
        return list
            .map((e) =>
                TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print(
          'TransactionService.getTransactionsForGerantAndPompiste error: $e');
    }
    return [];
  }

  // ─── TRANSACTIONS D'UNE COMPAGNIE ────────────────────────────
  // GET /api/transactions/transactionsForCompagnie/{companyId}
  Future<List<TransactionModel>> getTransactionsForCompagnie({
    required String token,
    required String companyId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '$_baseUrl/api/transactions/transactionsForCompagnie/$companyId'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body is List
            ? body
            : (body['content'] ?? body['data'] ?? []) as List;
        return list
            .map((e) =>
                TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print(
          'TransactionService.getTransactionsForCompagnie error: $e');
    }
    return [];
  }

  // ─── COMPATIBILITÉ STREAM ─────────────────────────────────────
  Stream<List<TransactionModel>> getTransactionsStream({
    String? token,
  }) async* {
    yield await getTransactions(token: token);
  }
}