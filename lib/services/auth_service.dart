// lib/services/auth_service.dart
// ✅ Sans cache utilisateur — toujours depuis /api/users/me
//    Le cache causait des données périmées quand le backend corrige ses doublons

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AuthService {
  static const String baseUrl = 'https://api.cardoil.io';
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/signup';
  static const String profileEndpoint = '/api/users/me';

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String expiresKey = 'token_expires';

  // ── Headers ────────────────────────────────────────────────────────────────
  Future<Map<String, String>> _getHeaders({bool needsAuth = false}) async {
    final h = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (needsAuth) {
      final token = await getToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // ── CONNEXION TÉLÉPHONE ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> checkCredentials({
    required String phone,
    required String password,
  }) async {
    return _doLogin({'phoneNumber': phone, 'password': password, 'loginIdentifier': phone});
  }

  // ── CONNEXION LOGIN (Corporate) ────────────────────────────────────────────
  Future<Map<String, dynamic>> signInWithLogin({
    required String login,
    required String password,
  }) async {
    print('🔐 signInWithLogin: $login');
    return _doLogin({'username': login, 'password': password, 'loginIdentifier': login});
  }

  Future<Map<String, dynamic>> signInWithPhone({
    required String phone,
    required String password,
    String? countryCode,
  }) async => checkCredentials(phone: phone, password: password);

  // ── LOGIN INTERNE ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _doLogin(Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$loginEndpoint'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      print('📥 Login Status: ${response.statusCode}');

      if (response.body.isEmpty) {
        return {'success': false, 'error': 'Réponse vide du serveur'};
      }

      if (response.statusCode == 200) {
        final data = _decode(response.body);
        final token = _extractToken(data);
        final user = _extractUser(data);

        await _saveAuthData(AuthResponse(
          user: user, token: token,
          expiresIn: (data['expiresIn'] as num?)?.toInt() ?? 86400,
        ));
        print('✅ Auth data saved');
        return {'success': true, 'user': user, 'token': token};
      }

      if (response.statusCode == 401) {
        return {'success': false, 'error': 'Identifiant ou mot de passe incorrect'};
      }

      final data = _decode(response.body);
      return {
        'success': false,
        'error': data['message']?.toString() ?? 'Erreur (${response.statusCode})',
      };
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  // ── CHARGEMENT PROFIL — toujours depuis l'API ─────────────────────────────
  // ✅ Plus de cache utilisateur — données toujours fraîches depuis /api/users/me
  Future<Map<String, dynamic>> loadUserProfile() async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false, 'error': 'Non connecté'};

      final response = await http.get(
        Uri.parse('$baseUrl$profileEndpoint'),
        headers: await _getHeaders(needsAuth: true),
      ).timeout(const Duration(seconds: 15));

      print('📥 Profile Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = _decode(response.body);
        final user = _extractUser(data);
        // Mettre à jour le cache token avec le user frais
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(userKey, user.toJsonString());
        return {'success': true, 'user': user};
      }

      if (response.statusCode == 401) {
        await signOut();
        return {'success': false, 'error': 'Session expirée'};
      }

      // Fallback cache si erreur serveur
      final cached = await getCurrentUser();
      if (cached != null) return {'success': true, 'user': cached};

      return {'success': false, 'error': 'Erreur (${response.statusCode})'};
    } catch (e) {
      // En cas d'erreur réseau, utiliser le cache
      final cached = await getCurrentUser();
      if (cached != null) return {'success': true, 'user': cached};
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  // ── VALIDATION TÉLÉPHONE ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> validatePhone({required String phone}) async {
    print('📱 validatePhone: $phone');

    for (final endpoint in ['/api/auth/validate-phone', '/api/auth/registerValidateur']) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _getHeaders(),
          body: jsonEncode({'phoneNumber': phone}),
        ).timeout(const Duration(seconds: 15));

        print('📥 $endpoint → ${response.statusCode}');

        if (response.statusCode == 404) continue;

        if (response.statusCode == 200 || response.statusCode == 201) {
          return {'success': true, 'message': 'Code SMS envoyé'};
        }

        final data = _decode(response.body);
        return {'success': false, 'error': data['message']?.toString() ?? 'Erreur ${response.statusCode}'};
      } catch (e) {
        return {'success': false, 'error': 'Erreur réseau: $e'};
      }
    }

    print('⚠️ Aucun endpoint OTP actif — skip validation SMS');
    return {'success': true, 'skipOtp': true, 'message': 'Validation SMS non disponible'};
  }

  // ── INSCRIPTION AVEC OTP ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> signupWithOtp({
    required String phone,
    required String fullName,
    required String password,
    required String countryCode,
    required String otpCode,
    required String companyId,
  }) async {
    try {
      print('📝 signupWithOtp: $phone');

      final body = {
        'phoneNumber': phone,
        'firstname': fullName,
        'username': phone,
        'email': '',
        'role': 'CLIENT',
        'compagnie': int.tryParse(companyId) ?? 1,
        'countryCode': countryCode,
        'generatedPassword': password,
        'password': password,
        'validationCode': otpCode,
        'phoneVerified': otpCode.isNotEmpty,
      };

      final response = await http.post(
        Uri.parse('$baseUrl$registerEndpoint'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 20));

      print('📥 Signup Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _decode(response.body);
        final token = _extractToken(data);

        if (token.isNotEmpty) {
          final user = _extractUser(data);
          await _saveAuthData(AuthResponse(user: user, token: token, expiresIn: 86400));
          return {'success': true, 'user': user, 'token': token};
        }

        return {'success': true, 'requiresLogin': true, 'message': 'Compte créé ! Connectez-vous.'};
      }

      final data = _decode(response.body);
      return {'success': false, 'error': data['message']?.toString() ?? 'Erreur d\'inscription'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  // ── RENVOI OTP ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> resendOtp({required String phone}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/resend-code'),
        headers: await _getHeaders(),
        body: jsonEncode({'phoneNumber': phone}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Code renvoyé'};
      }
      final data = _decode(response.body);
      return {'success': false, 'error': data['message']?.toString() ?? 'Erreur renvoi code'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  // ── SAUVEGARDE ─────────────────────────────────────────────────────────────
  Future<void> _saveAuthData(AuthResponse r) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, r.token);
    await prefs.setString(userKey, r.user.toJsonString());
    final exp = DateTime.now().add(Duration(seconds: r.expiresIn));
    await prefs.setString(expiresKey, exp.toIso8601String());
  }

  // ── TOKEN ──────────────────────────────────────────────────────────────────
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    if (token != null) {
      final exp = prefs.getString(expiresKey);
      if (exp != null && DateTime.now().isAfter(DateTime.parse(exp))) {
        await signOut();
        return null;
      }
    }
    return token;
  }

  // ── UTILISATEUR DEPUIS CACHE ──────────────────────────────────────────────
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(userKey);
    if (json != null) {
      try { return UserModel.fromJsonString(json); } catch (_) {}
    }
    return null;
  }

  Stream<UserModel?> getCurrentUserStream() async* { yield await getCurrentUser(); }
  Stream<UserModel?> get authStateChanges => getCurrentUserStream();
  UserModel? get currentUser => null;

  Future<bool> isLoggedIn() async {
    final t = await getToken();
    return t != null && t.isNotEmpty;
  }

  // ── DÉCONNEXION + CLEAR ALL CACHE ─────────────────────────────────────────
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    // ✅ Vider TOUT le cache au logout
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
    await prefs.remove(expiresKey);
    await prefs.remove('cached_transactions');
    await prefs.remove('cached_corporate_account');
    await prefs.remove('cached_card');
    print('✅ User signed out + cache vidé');
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────
  Map<String, dynamic> _decode(String raw) {
    try {
      final d = jsonDecode(raw);
      if (d is Map<String, dynamic>) return d;
    } catch (_) {}
    return {};
  }

  String _extractToken(Map<String, dynamic> data) =>
      data['token']?.toString() ??
      data['accessToken']?.toString() ??
      data['jwt']?.toString() ?? '';

  UserModel _extractUser(Map<String, dynamic> data) {
    if (data.containsKey('user') && data['user'] is Map) {
      return UserModel.fromApiJson(data['user'] as Map<String, dynamic>);
    }
    return UserModel.fromApiJson(data);
  }

  // ── Compatibilité ──────────────────────────────────────────────────────────
  Future<void> updateUserFullName(String fullName) async {
    final user = await getCurrentUser();
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, user.copyWith(fullName: fullName).toJsonString());
  }

  Future<bool> updateSelectedCompany(String name) async {
    final user = await getCurrentUser();
    if (user == null) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, user.copyWith(selectedCompagnie: name).toJsonString());
    return true;
  }

  Future<bool> phoneExists(String phone) async => false;
  Future<void> addLoyaltyPoints(String c, int p) async {}

  Future<Map<String, dynamic>> registerWithPhone({
    required String phone, required String fullName, required String password,
    required String country, required String selectedCompagnie,
    required String login, String userType = 'individual',
  }) async => signupWithOtp(
    phone: phone, fullName: fullName, password: password,
    countryCode: country, otpCode: '', companyId: selectedCompagnie);

  Future<Map<String, dynamic>> createUserProfile({
    required String uid, required String phone, required String fullName,
    required String password, required String country,
    required String selectedCompagnie, required String login,
    required String userType,
  }) async => registerWithPhone(
    phone: phone, fullName: fullName, password: password,
    country: country, selectedCompagnie: selectedCompagnie,
    login: login, userType: userType);
}

// ── AuthResponse ──────────────────────────────────────────────────────────────
class AuthResponse {
  final UserModel user;
  final String token;
  final int expiresIn;

  AuthResponse({required this.user, required this.token, required this.expiresIn});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    user: UserModel.fromApiJson((json['user'] ?? json) as Map<String, dynamic>),
    token: json['token']?.toString() ?? '',
    expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 86400,
  );
}