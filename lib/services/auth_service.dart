// lib/services/auth_service_complete.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AuthService {
  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION API CARDOIL
  // ═══════════════════════════════════════════════════════════════════════════
  static const String baseUrl = 'https://api.cardoil.io';  // HTTPS ✅
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/signup';
  static const String profileEndpoint = '/api/users/me';
  
  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String expiresKey = 'token_expires';

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADERS
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, String>> _getHeaders({bool needsAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (needsAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONNEXION PAR TÉLÉPHONE
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> checkCredentials({
    required String phone,
    required String password,
  }) async {
    try {
      print('🔐 checkCredentials: $phone');
      
      final body = {
        'phoneNumber': phone,
        'password': password,
        'loginIdentifier': phone,
      };

      print('📤 Request: $baseUrl$loginEndpoint');
      print('📤 Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl$loginEndpoint'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'error': 'Le serveur n\'a renvoyé aucune donnée',
        };
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (!data.containsKey('user') || !data.containsKey('token')) {
          return {
            'success': false,
            'error': 'Réponse du serveur mal formatée',
          };
        }

        final authResponse = AuthResponse.fromJson(data);
        await _saveAuthData(authResponse);

        return {
          'success': true,
          'user': authResponse.user,
          'token': authResponse.token,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Téléphone ou mot de passe incorrect',
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur de connexion (${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Error: $e');
      return {
        'success': false,
        'error': 'Erreur réseau: $e',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONNEXION PAR TÉLÉPHONE (Alias pour checkCredentials)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> signInWithPhone({
    required String phone,
    required String password,
    String? countryCode,
  }) async {
    return await checkCredentials(phone: phone, password: password);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONNEXION PAR LOGIN (Corporate)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> signInWithLogin({
    required String login,
    required String password,
  }) async {
    try {
      print('🔐 signInWithLogin: $login');
      
      final body = {
        'username': login,
        'loginIdentifier': login,
        'password': password,
      };

      final response = await http.post(
        Uri.parse('$baseUrl$loginEndpoint'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      print('📥 Status: ${response.statusCode}');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'error': 'Le serveur n\'a renvoyé aucune donnée',
        };
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(data);
        await _saveAuthData(authResponse);

        return {
          'success': true,
          'user': authResponse.user,
          'token': authResponse.token,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Login ou mot de passe incorrect',
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur de connexion (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: $e',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHARGER PROFIL UTILISATEUR (COMPATIBLE AVEC TES ÉCRANS)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> loadUserProfile() async {
    try {
      print('📂 Loading user profile...');
      
      // 1. Essayer de charger depuis le cache d'abord
      final cachedUser = await getCurrentUser();
      if (cachedUser != null) {
        print('✅ User loaded from cache');
        return {
          'success': true,
          'user': cachedUser,
        };
      }

      // 2. Si pas de cache, appeler l'API
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Non connecté',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl$profileEndpoint'),
        headers: await _getHeaders(needsAuth: true),
      ).timeout(const Duration(seconds: 10));

      print('📥 Profile Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = UserModel.fromApiJson(data['user']);
        
        // Sauvegarder en cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(userKey, user.toJsonString());

        return {
          'success': true,
          'user': user,
        };
      } else if (response.statusCode == 401) {
        await signOut();
        return {
          'success': false,
          'error': 'Session expirée',
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur lors de la récupération du profil',
        };
      }
    } catch (e) {
      print('❌ loadUserProfile error: $e');
      return {
        'success': false,
        'error': 'Erreur réseau: $e',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDATION TÉLÉPHONE + ENVOI SMS (Orange SMS API)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> validatePhone({
    required String phone,
  }) async {
    try {
      print('📱 validatePhone: $phone');
      
      final body = {
        'phoneNumber': phone,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/validate-phone'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      print('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Code SMS envoyé',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'error': data['message'] ?? 'Erreur lors de l\'envoi du SMS',
        };
      }
    } catch (e) {
      print('❌ validatePhone error: $e');
      return {
        'success': false,
        'error': 'Erreur réseau: $e',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INSCRIPTION AVEC CODE OTP
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> signupWithOtp({
    required String phone,
    required String fullName,
    required String password,
    required String countryCode,
    required String otpCode,
    required String companyId,  // ← Ajouté
  }) async {
    try {
      print('📝 signupWithOtp: $phone');
      
      final body = {
        'phoneNumber': phone,
        'firstname': fullName,
        'username': phone,
        'email': '',
        'role': 'CLIENT',
        'compagnie': int.tryParse(companyId) ?? 1,  // ← Utilise companyId
        'countryCode': countryCode,
        'generatedPassword': password,
        'validationCode': otpCode,
        'phoneVerified': true,
      };

      print('📤 Signup Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/signup'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(data);
        await _saveAuthData(authResponse);

        return {
          'success': true,
          'user': authResponse.user,
          'token': authResponse.token,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'error': data['message'] ?? 'Erreur d\'inscription',
        };
      }
    } catch (e) {
      print('❌ signupWithOtp error: $e');
      return {
        'success': false,
        'error': 'Erreur réseau: $e',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RENVOYER LE CODE OTP
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> resendOtp({
    required String phone,
  }) async {
    try {
      print('🔄 resendOtp: $phone');
      
      final body = {
        'phoneNumber': phone,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/resend-code'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      print('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Code renvoyé',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'error': data['message'] ?? 'Erreur lors du renvoi du code',
        };
      }
    } catch (e) {
      print('❌ resendOtp error: $e');
      return {
        'success': false,
        'error': 'Erreur réseau: $e',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INSCRIPTION
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> registerWithPhone({
    required String phone,
    required String fullName,
    required String password,
    required String country,
    required String selectedCompagnie,
    required String login,
    String userType = 'individual',
  }) async {
    try {
      final body = {
        'phoneNumber': phone,
        'firstname': fullName,
        'username': login,
        'password': password,
        'countryCode': country,
        'compagnie': int.tryParse(selectedCompagnie) ?? 0,
        'role': userType == 'corporate' ? 'corporate' : 'client',
      };

      final response = await http.post(
        Uri.parse('$baseUrl$registerEndpoint'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(data);
        await _saveAuthData(authResponse);

        return {
          'success': true,
          'user': authResponse.user,
          'token': authResponse.token,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'error': data['message'] ?? 'Erreur d\'inscription',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur réseau: $e',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAUVEGARDER AUTH DATA
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _saveAuthData(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(tokenKey, authResponse.token);
    await prefs.setString(userKey, authResponse.user.toJsonString());
    
    final expiresAt = DateTime.now().add(Duration(seconds: authResponse.expiresIn));
    await prefs.setString(expiresKey, expiresAt.toIso8601String());

    print('✅ Auth data saved');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RÉCUPÉRER TOKEN
  // ═══════════════════════════════════════════════════════════════════════════
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    
    if (token != null) {
      final expiresStr = prefs.getString(expiresKey);
      if (expiresStr != null) {
        final expiresAt = DateTime.parse(expiresStr);
        if (DateTime.now().isAfter(expiresAt)) {
          await signOut();
          return null;
        }
      }
    }
    
    return token;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RÉCUPÉRER UTILISATEUR ACTUEL
  // ═══════════════════════════════════════════════════════════════════════════
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(userKey);
    
    if (userJson != null) {
      try {
        return UserModel.fromJsonString(userJson);
      } catch (e) {
        print('❌ Error parsing user: $e');
        return null;
      }
    }
    
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAM UTILISATEUR
  // ═══════════════════════════════════════════════════════════════════════════
  Stream<UserModel?> getCurrentUserStream() async* {
    final user = await getCurrentUser();
    yield user;
  }

  Stream<UserModel?> get authStateChanges => getCurrentUserStream();
  UserModel? get currentUser => null; // Utilise getCurrentUser() à la place

  // ═══════════════════════════════════════════════════════════════════════════
  // VÉRIFIER SI CONNECTÉ
  // ═══════════════════════════════════════════════════════════════════════════
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DÉCONNEXION
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
    await prefs.remove(expiresKey);
    print('✅ User signed out');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS (compatibilité avec ton code existant)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<bool> phoneExists(String phone) async {
    // TODO: Implémenter selon ton API
    return false;
  }

  Future<void> updateUserFullName(String fullName) async {
    // TODO: Implémenter selon ton API
    final user = await getCurrentUser();
    if (user != null) {
      final updated = user.copyWith(fullName: fullName);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(userKey, updated.toJsonString());
    }
  }

  Future<bool> updateSelectedCompany(String companyName) async {
    // TODO: Implémenter selon ton API
    final user = await getCurrentUser();
    if (user != null) {
      final updated = user.copyWith(selectedCompagnie: companyName);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(userKey, updated.toJsonString());
      return true;
    }
    return false;
  }

  Future<void> addLoyaltyPoints(String compagnie, int points) async {
    // TODO: Implémenter selon ton API
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CRÉER PROFIL (pour compatibilité)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> createUserProfile({
    required String uid,
    required String phone,
    required String fullName,
    required String password,
    required String country,
    required String selectedCompagnie,
    required String login,
    required String userType,
  }) async {
    return await registerWithPhone(
      phone: phone,
      fullName: fullName,
      password: password,
      country: country,
      selectedCompagnie: selectedCompagnie,
      login: login,
      userType: userType,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// AUTH RESPONSE MODEL
/// ═══════════════════════════════════════════════════════════════════════════
class AuthResponse {
  final UserModel user;
  final String token;
  final int expiresIn;

  AuthResponse({
    required this.user,
    required this.token,
    required this.expiresIn,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromApiJson(json['user']),
      token: json['token'] ?? '',
      expiresIn: json['expiresIn'] ?? 3600,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toApiJson(),
      'token': token,
      'expiresIn': expiresIn,
    };
  }
}
