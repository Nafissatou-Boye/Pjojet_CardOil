import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CardModel {
  final String id;
  final String reference;
  final double balance;     
  final int loyaltyPoints;    
  final String status;        
  final String compagnie;
  final String? clientName;
  final DateTime? expiryDate;

  CardModel({
    required this.id,
    required this.reference,
    required this.balance,
    required this.loyaltyPoints,
    required this.status,
    required this.compagnie,
    this.clientName,
    this.expiryDate,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id']?.toString() ?? '',
      reference: json['reference']?.toString() ??
          json['ref']?.toString() ??
          json['numero']?.toString() ?? '',
      balance: (json['solde'] ?? json['balance'] ?? json['montant'] ?? 0).toDouble(),
      loyaltyPoints: (json['pointsFidelite'] ?? json['loyaltyPoints'] ?? json['points'] ?? 0) as int,
      status: json['statut']?.toString() ??
          json['status']?.toString() ?? 'ACTIVE',
      compagnie: json['compagnie']?.toString() ??
          json['companyName']?.toString() ?? '',
      clientName: json['clientName']?.toString() ??
          json['porteurName']?.toString(),
      expiryDate: json['dateExpiration'] != null
          ? DateTime.tryParse(json['dateExpiration'].toString())
          : json['expiryDate'] != null
              ? DateTime.tryParse(json['expiryDate'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'reference': reference,
    'balance': balance,
    'loyaltyPoints': loyaltyPoints,
    'status': status,
    'compagnie': compagnie,
    if (clientName != null) 'clientName': clientName,
    if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
  };
}

class CardService {
  static const String _baseUrl = 'https://api.cardoil.io';
  static const String _tokenKey = 'auth_token';
  static const String _cardCacheKey = 'cached_card';

 
  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  
  Future<Map<String, dynamic>> getMyCard() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/cartes/me'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        final cardJson = json is Map && json.containsKey('data')
            ? json['data']
            : json;
        final card = CardModel.fromJson(cardJson as Map<String, dynamic>);

       
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cardCacheKey, jsonEncode(card.toJson()));

        return {'success': true, 'card': card};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Session expirée'};
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'Carte non trouvée', 'notFound': true};
      } else {
        return {'success': false, 'error': 'Erreur serveur (${response.statusCode})'};
      }
    } catch (e) {
     
      final cached = await _getCachedCard();
      if (cached != null) {
        return {'success': true, 'card': cached, 'fromCache': true};
      }
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  Future<Map<String, dynamic>> getCardByUserId(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/cartes/user/$userId'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final cardJson = json is Map && json.containsKey('data') ? json['data'] : json;
        final card = CardModel.fromJson(cardJson as Map<String, dynamic>);
        return {'success': true, 'card': card};
      }
      return {'success': false, 'error': 'Carte introuvable'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  Future<Map<String, dynamic>> getCardByReference(String reference) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/cartes/ref/$reference'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final cardJson = json is Map && json.containsKey('data') ? json['data'] : json;
        final card = CardModel.fromJson(cardJson as Map<String, dynamic>);
        return {'success': true, 'card': card};
      }
      return {'success': false, 'error': 'Carte introuvable'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  Future<Map<String, dynamic>> rechargeCard({
    required String porteurId,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/cartes/porteurs/$porteurId/recharge'),
        headers: await _headers(),
        body: jsonEncode({'montant': amount, 'amount': amount}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Invalider le cache après recharge
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_cardCacheKey);
        return {'success': true};
      }
      final error = response.body.isNotEmpty
          ? (jsonDecode(response.body)['message'] ?? 'Erreur de recharge')
          : 'Erreur de recharge';
      return {'success': false, 'error': error};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  // ── Cache local 
  Future<CardModel?> _getCachedCard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cardCacheKey);
      if (cached != null) return CardModel.fromJson(jsonDecode(cached));
    } catch (_) {}
    return null;
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cardCacheKey);
  }
}