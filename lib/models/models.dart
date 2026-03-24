// lib/models/user_model_hybrid.dart

import 'dart:convert';

/// ═══════════════════════════════════════════════════════════════════════════
/// USER MODEL HYBRIDE - Compatible API REST + Firebase
/// ═══════════════════════════════════════════════════════════════════════════

enum UserType { individual, corporate }

class UserModel {
  // ───── Identifiants (API + Firebase) ─────
  final String uid;           // Pour Firebase
  final int? id;           // Pour API (id numérique)
  
  // ───── Champs communs ─────
  final String phone;
  final String fullName;
  final String email;
  final String selectedCompagnie;
  final String qrCode;
  final double balance;
  final String status;
  final bool isActive;
  final bool phoneVerified;
  final DateTime createdAt;
  final DateTime? lastLogin;

  // ───── Type utilisateur ─────
  final UserType userType;

  // ───── Champs API ─────
  final String? username;     // API username
  final String? role;         // API role (client, corporate, gerant, pompiste, admin)
  final int? compagnie;       // API compagnie (int)
  final String? countryCode;  // API country code

  // ───── Champs corporate ─────
  final String? enterpriseId;
  final String? enterpriseName;
  final String? employeeNumber;
  final double? monthlyLimit;
  final double? currentMonthUsage;
  final bool? profileLocked;
  final bool? isCumulative;
  final String? department;
  final String? position;

  // ───── Fidélité ─────
  final Map<String, int> loyaltyPoints;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTRUCTOR
  // ═══════════════════════════════════════════════════════════════════════════
  UserModel({
    required this.uid,
    this.id,
    required this.phone,
    required this.fullName,
    required this.email,
    required String selectedCompagnie,
    this.qrCode = '',
    this.balance = 0,
    this.status = 'ACTIVE',
    this.isActive = true,
    this.phoneVerified = false,
    DateTime? createdAt,
    this.lastLogin,
    this.userType = UserType.individual,
    
    // API fields
    this.username,
    this.role,
    this.compagnie,
    this.countryCode,
    
    // Corporate
    this.enterpriseId,
    this.enterpriseName,
    this.employeeNumber,
    this.monthlyLimit,
    this.currentMonthUsage = 0,
    this.profileLocked,
    this.isCumulative,
    this.department,
    this.position,
    
    // Loyalty
    Map<String, int>? loyaltyPoints,
  }) : loyaltyPoints = loyaltyPoints ?? {},
       selectedCompagnie = selectedCompagnie.toUpperCase(),
       createdAt = createdAt ?? DateTime.now();

  // ═══════════════════════════════════════════════════════════════════════════
  // FROM API JSON (Swagger Response)
  // ═══════════════════════════════════════════════════════════════════════════
  factory UserModel.fromApiJson(Map<String, dynamic> json) {
    // Déterminer le type selon le role
    UserType type = UserType.individual;
    final role = (json['role'] ?? '').toString().toLowerCase();
    if (role == 'corporate' || role == 'employee') {
      type = UserType.corporate;
    }

    return UserModel(
      uid: json['id']?.toString() ?? '',       // Convertir int en String
      id: json['id'],                       // Garder l'ID numérique
      username: json['username'],
      phone: json['phoneNumber'] ?? '',
      fullName: json['firstname'] ?? json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'],
      compagnie: json['compagnie'],
      selectedCompagnie: json['compagnie']?.toString() ?? 'TOTAL',
      countryCode: json['countryCode'],
      phoneVerified: json['phoneVerified'] ?? false,
      userType: type,
      
      // Balance pas dans l'API, on met 0 par défaut
      balance: 0,
      qrCode: '',
      status: 'ACTIVE',
      isActive: true,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TO API JSON
  // ═══════════════════════════════════════════════════════════════════════════
  Map<String, dynamic> toApiJson() {
    return {
      'id': id,
      'username': username,
      'firstname': fullName,
      'email': email,
      'role': role,
      'compagnie': compagnie,
      'phoneNumber': phone,
      'countryCode': countryCode,
      'phoneVerified': phoneVerified,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TO/FROM STRING (SharedPreferences)
  // ═══════════════════════════════════════════════════════════════════════════
  String toJsonString() => jsonEncode(toApiJson());
  
  factory UserModel.fromJsonString(String jsonString) {
    return UserModel.fromApiJson(jsonDecode(jsonString));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════════════════
  
  bool get isIndividual => userType == UserType.individual;
  bool get isCorporate => userType == UserType.corporate;
  
  // Getters pour les rôles API
  bool get isGerant => role?.toLowerCase() == 'gerant' || role?.toLowerCase() == 'manager';
  bool get isPompiste => role?.toLowerCase() == 'pompiste' || role?.toLowerCase() == 'attendant';
  bool get isAdmin => role?.toLowerCase() == 'admin';

  double get availableBalance {
    if (isCorporate && monthlyLimit != null && currentMonthUsage != null) {
      return monthlyLimit! - currentMonthUsage!;
    }
    return balance;
  }

  bool get hasReachedLimit {
    if (isCorporate && monthlyLimit != null && currentMonthUsage != null) {
      return currentMonthUsage! >= monthlyLimit!;
    }
    return false;
  }

  double get usagePercentage {
    if (isCorporate && monthlyLimit != null && monthlyLimit! > 0 && currentMonthUsage != null) {
      return (currentMonthUsage! / monthlyLimit! * 100).clamp(0, 100);
    }
    return 0;
  }

  int getLoyaltyPoints(String companyId) {
    final key = companyId.toUpperCase().trim();
    return loyaltyPoints[key] ?? 0;
  }

  int get currentCompanyPoints => getLoyaltyPoints(selectedCompagnie);

  List<Map<String, dynamic>> getAllLoyaltyPoints() {
    return loyaltyPoints.entries
        .map((e) => {'compagnie': e.key, 'points': e.value})
        .toList()
      ..sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
  }

  bool hasCompany(String compagnie) => 
      loyaltyPoints.containsKey(compagnie.toUpperCase().trim());

  int get totalLoyaltyPoints => 
      loyaltyPoints.values.fold(0, (sum, p) => sum + p);

  String get formattedPhone => countryCode != null && countryCode!.isNotEmpty
      ? '+$countryCode$phone'
      : phone;

  // ═══════════════════════════════════════════════════════════════════════════
  // COPY WITH
  // ═══════════════════════════════════════════════════════════════════════════
  UserModel copyWith({
    String? phone,
    String? fullName,
    String? email,
    double? balance,
    String? selectedCompagnie,
    String? status,
    bool? isActive,
    bool? phoneVerified,
    UserType? userType,
    String? role,
    int? compagnie,
    String? enterpriseId,
    String? enterpriseName,
    String? employeeNumber,
    double? monthlyLimit,
    double? currentMonthUsage,
    bool? profileLocked,
    bool? isCumulative,
    String? department,
    String? position,
    Map<String, int>? loyaltyPoints,
  }) {
    return UserModel(
      uid: uid,
      id: id,
      username: username,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      selectedCompagnie: (selectedCompagnie ?? this.selectedCompagnie).toUpperCase(),
      qrCode: qrCode,
      balance: balance ?? this.balance,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      createdAt: createdAt,
      lastLogin: lastLogin,
      userType: userType ?? this.userType,
      role: role ?? this.role,
      compagnie: compagnie ?? this.compagnie,
      countryCode: countryCode,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      enterpriseName: enterpriseName ?? this.enterpriseName,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currentMonthUsage: currentMonthUsage ?? this.currentMonthUsage,
      profileLocked: profileLocked ?? this.profileLocked,
      isCumulative: isCumulative ?? this.isCumulative,
      department: department ?? this.department,
      position: position ?? this.position,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// AUTH RESPONSE MODEL (API)
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