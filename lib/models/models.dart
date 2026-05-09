// lib/models/user_model_hybrid.dart
// ✅ Nettoyé : plus aucune trace Firebase (uid remplacé par stringId)

import 'dart:convert';

enum UserType { individual, corporate }

class UserModel {
  // ── Identifiants DB uniquement ───────────────────────────────────────────
  final int? id;            // ID numérique DB (ex: 42)  ← CLEF PRINCIPALE
  final String stringId;    // id.toString() pour compatibilité (remplace uid)

  // ── Champs communs ───────────────────────────────────────────────────────
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
  final UserType userType;

  // ── Champs API ───────────────────────────────────────────────────────────
  final String? username;
  final String? role;
  final int? compagnie;
  final String? countryCode;

  // ── Champs corporate ────────────────────────────────────────────────────
  final String? enterpriseId;
  final String? enterpriseName;
  final String? employeeNumber;
  final double? monthlyLimit;
  final double? currentMonthUsage;
  final bool? profileLocked;
  final bool? isCumulative;
  final String? department;
  final String? position;

  // ── Fidélité ─────────────────────────────────────────────────────────────
  final Map<String, int> loyaltyPoints;

  UserModel({
    this.id,
    String? stringId,
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
    this.username,
    this.role,
    this.compagnie,
    this.countryCode,
    this.enterpriseId,
    this.enterpriseName,
    this.employeeNumber,
    this.monthlyLimit,
    this.currentMonthUsage = 0,
    this.profileLocked,
    this.isCumulative,
    this.department,
    this.position,
    Map<String, int>? loyaltyPoints,
  })  : stringId = stringId ?? id?.toString() ?? '',
        selectedCompagnie = selectedCompagnie.toUpperCase(),
        createdAt = createdAt ?? DateTime.now(),
        loyaltyPoints = loyaltyPoints ?? {};

  // ── FROM API ─────────────────────────────────────────────────────────────
  factory UserModel.fromApiJson(Map<String, dynamic> json) {
    final role = (json['role'] ?? '').toString().toLowerCase();
    final userType = (role == 'corporate' || role == 'employee')
        ? UserType.corporate
        : UserType.individual;

    // ✅ id numérique DB — cherche dans plusieurs champs
    final rawId = json['id'] ?? json['userId'] ?? json['dbId'];
    final numericId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '');

    return UserModel(
      id: numericId,
      stringId: numericId?.toString() ?? '',
      username: json['username']?.toString(),
      phone: json['phoneNumber']?.toString() ?? '',
      fullName: json['firstname']?.toString() ??
          json['fullName']?.toString() ??
          json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString(),
      compagnie: (json['compagnie'] as num?)?.toInt(),
      selectedCompagnie: json['compagnie']?.toString() ?? 'TOTAL',
      countryCode: json['countryCode']?.toString(),
      phoneVerified: json['phoneVerified'] as bool? ?? false,
      userType: userType,
      balance: 0,
      qrCode: '',
      status: 'ACTIVE',
      isActive: true,
    );
  }

  // ── SÉRIALISATION ────────────────────────────────────────────────────────
Map<String, dynamic> toApiJson() => {
  'id': id,
  'username': username,
  'firstname': fullName,
  'email': email,
  'role': role,
  'compagnie': compagnie,
  'selectedCompagnie': selectedCompagnie,   // ← AJOUTER cette ligne
  'phoneNumber': phone,
  'countryCode': countryCode,
  'phoneVerified': phoneVerified,
};
  String toJsonString() => jsonEncode(toApiJson());

  factory UserModel.fromJsonString(String jsonString) =>
      UserModel.fromApiJson(jsonDecode(jsonString) as Map<String, dynamic>);

  // ── GETTERS ──────────────────────────────────────────────────────────────
  bool get isIndividual => userType == UserType.individual;
  bool get isCorporate => userType == UserType.corporate;
  bool get isGerant =>
      role?.toLowerCase() == 'gerant' || role?.toLowerCase() == 'manager';
  bool get isPompiste =>
      role?.toLowerCase() == 'pompiste' ||
      role?.toLowerCase() == 'attendant';
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

  int getLoyaltyPoints(String companyId) =>
      loyaltyPoints[companyId.toUpperCase().trim()] ?? 0;

  int get currentCompanyPoints => getLoyaltyPoints(selectedCompagnie);
  int get totalLoyaltyPoints =>
      loyaltyPoints.values.fold(0, (s, p) => s + p);

  String get formattedPhone =>
      (countryCode?.isNotEmpty ?? false) ? '+$countryCode$phone' : phone;

  // ── COPY WITH ────────────────────────────────────────────────────────────
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
  }) =>
      UserModel(
        id: id,
        stringId: stringId,
        username: username,
        phone: phone ?? this.phone,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        selectedCompagnie:
            (selectedCompagnie ?? this.selectedCompagnie).toUpperCase(),
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