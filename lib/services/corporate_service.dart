import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class CorporateAccountModel {
  final String id;
  final String fullName;
  final String email;
  final String employeeNumber;
  final String enterpriseId;
  final String enterpriseName;
  final String accountType; // 'capped' | 'cumulative'
  final double monthlyLimit;
  final double currentMonthUsage;
  final double balance; // solde cumulatif
  final String? department;
  final String? position;
  final bool isActive;

  CorporateAccountModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.employeeNumber,
    required this.enterpriseId,
    required this.enterpriseName,
    required this.accountType,
    required this.monthlyLimit,
    required this.currentMonthUsage,
    required this.balance,
    this.department,
    this.position,
    required this.isActive,
  });

  bool get isCapped => accountType.toLowerCase() == 'capped';
  double get remainingBalance => monthlyLimit - currentMonthUsage;
  double get usagePercentage =>
      monthlyLimit > 0 ? (currentMonthUsage / monthlyLimit * 100).clamp(0, 100) : 0;
  bool get hasReachedLimit => isCapped && currentMonthUsage >= monthlyLimit;

  String get usageLevel {
    if (usagePercentage >= 90) return 'red';
    if (usagePercentage >= 70) return 'yellow';
    return 'green';
  }

  factory CorporateAccountModel.fromJson(Map<String, dynamic> json) {
    return CorporateAccountModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ??
          json['firstname']?.toString() ??
          json['name']?.toString() ??
          '',
      email: json['email']?.toString() ?? '',
      employeeNumber: json['employeeNumber']?.toString() ??
          json['matricule']?.toString() ??
          '',
      enterpriseId: json['enterpriseId']?.toString() ?? json['compagnie']?.toString() ?? '',
      enterpriseName:
          json['enterpriseName']?.toString() ?? json['compagnieName']?.toString() ?? '',
      accountType: json['accountType']?.toString() ??
          json['typeCompte']?.toString() ??
          'capped',
      monthlyLimit: (json['monthlyLimit'] ?? json['plafond'] ?? 0).toDouble(),
      currentMonthUsage: (json['currentMonthUsage'] ?? json['depensesMois'] ?? 0).toDouble(),
      balance: (json['balance'] ?? json['solde'] ?? 0).toDouble(),
      department: json['department']?.toString() ?? json['departement']?.toString(),
      position: json['position']?.toString() ?? json['poste']?.toString(),
      isActive: json['isActive'] as bool? ?? json['actif'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'employeeNumber': employeeNumber,
        'enterpriseId': enterpriseId,
        'enterpriseName': enterpriseName,
        'accountType': accountType,
        'monthlyLimit': monthlyLimit,
        'currentMonthUsage': currentMonthUsage,
        'balance': balance,
        'isActive': isActive,
        if (department != null) 'department': department,
        if (position != null) 'position': position,
      };
}



class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['titre']?.toString() ?? '',
      message: json['message']?.toString() ?? json['contenu']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      isRead: json['isRead'] as bool? ?? json['lu'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}



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

 
 Future<Map<String, dynamic>> getMyAccount({String? myEmployeeNumber}) async {
  try {
    final response = await http
        .get(Uri.parse('$_baseUrl/api/entreprises/compte/compte-entreprise'),
            headers: await _headers())
        .timeout(const Duration(seconds: 10));

    print('📡 GET /api/entreprises/compte/compte-entreprise');
    print('📥 Status: ${response.statusCode}');
    print(
        '📥 Body: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      List<Map<String, dynamic>> accountsList = [];

      if (jsonData is List) {
        accountsList = jsonData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else if (jsonData is Map && jsonData.containsKey('data')) {
        final d = jsonData['data'];
        if (d is List) {
          accountsList = d.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else if (d is Map) {
          accountsList = [Map<String, dynamic>.from(d)];
        }
      } else if (jsonData is Map) {
        accountsList = [Map<String, dynamic>.from(jsonData)];
      } else {
        throw Exception('Format JSON inattendu pour le compte corporate');
      }

     
      Map<String, dynamic>? accountJson;
      if (myEmployeeNumber != null) {
        accountJson = accountsList.firstWhere(
          (acc) => acc['employeeNumber']?.toString() == myEmployeeNumber,
          orElse: () => {},
        );
      }

     
      accountJson = accountJson != null && accountJson.isNotEmpty
          ? accountJson
          : accountsList.isNotEmpty
              ? accountsList.first
              : _buildFallbackAccount().toJson();

      final account = CorporateAccountModel.fromJson(accountJson);

      // Cache local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accountCacheKey, jsonEncode(account.toJson()));

      return {'success': true, 'account': account};
    } else if (response.statusCode == 401) {
      return {'success': false, 'error': 'Session expirée'};
    } else if (response.statusCode == 500) {
      final cached = await _getCachedAccount();
      if (cached != null) {
        print('⚠️ API 500 — using cached account');
        return {'success': true, 'account': cached, 'fromCache': true};
      }
      final fallback = _buildFallbackAccount();
      return {'success': true, 'account': fallback, 'isFallback': true};
    }
    return {'success': false, 'error': 'Erreur serveur (${response.statusCode})'};
  } catch (e) {
    final cached = await _getCachedAccount();
    if (cached != null) return {'success': true, 'account': cached, 'fromCache': true};
    return {'success': false, 'error': 'Erreur réseau: $e'};
  }
}

  Future<CorporateAccountModel?> _getCachedAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_accountCacheKey);

      if (raw != null) {
        return CorporateAccountModel.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw)));
      }
    } catch (e) {
      print('❌ Cache error: $e');
    }
    return null;
  }

  
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/notifications'), headers: await _headers())
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
    } catch (e) {
      print('❌ getNotifications: $e');
    }
    return [];
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/API/notifications/non%20lu/compte'),
              headers: await _headers())
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is int) return body;
        if (body is Map) return (body['count'] ?? body['total'] ?? 0) as int;
      }
    } catch (e) {
      print('❌ getUnreadCount: $e');
    }
    return 0;
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await http
          .put(Uri.parse('$_baseUrl/api/notifications/$notificationId/read'),
              headers: await _headers())
          .timeout(const Duration(seconds: 8));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ markAsRead: $e');
    }
    return false;
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/api/notifications/$notificationId'),
              headers: await _headers())
          .timeout(const Duration(seconds: 8));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ deleteNotification: $e');
    }
    return false;
  }

  
  CorporateAccountModel _buildFallbackAccount() {
    return CorporateAccountModel(
      id: '',
      fullName: 'Compte Entreprise',
      email: '',
      employeeNumber: '',
      enterpriseId: '',
      enterpriseName: 'Entreprise',
      accountType: 'cumulative',
      monthlyLimit: 0,
      currentMonthUsage: 0,
      balance: 0,
      isActive: true,
    );
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accountCacheKey);
  }
}