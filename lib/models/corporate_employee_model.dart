// lib/models/corporate_employee_model.dart

class CorporateEmployeeModel {
  final String id;
  final String userId;
  final String enterpriseId;
  final String enterpriseName;
  final String fullName;
  final String email;
  final String employeeNumber;
  final double monthlyLimit;
  final double currentMonthUsage;
  final bool isActive;
  final bool profileLocked;
  final DateTime createdAt;
  final String? department;
  final String? position;
  final String accountType; // 'capped' | 'cumulative'

  CorporateEmployeeModel({
    required this.id,
    required this.userId,
    required this.enterpriseId,
    required this.enterpriseName,
    required this.fullName,
    required this.email,
    required this.employeeNumber,
    required this.monthlyLimit,
    this.currentMonthUsage = 0,
    this.isActive = true,
    this.profileLocked = true,
    required this.createdAt,
    this.department,
    this.position,
    this.accountType = 'capped',
  });

  // ═══════════════════════════════════════════════════════════
  // ✅ FROM API (remplace Firestore)
  // ═══════════════════════════════════════════════════════════
  factory CorporateEmployeeModel.fromJson(Map<String, dynamic> json) {
    return CorporateEmployeeModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      enterpriseId: json['enterpriseId']?.toString() ??
          json['compagnie']?.toString() ?? '',
      enterpriseName: json['enterpriseName']?.toString() ??
          json['compagnieName']?.toString() ?? '',
      fullName: json['fullName']?.toString() ??
          json['firstname']?.toString() ??
          json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      employeeNumber: json['employeeNumber']?.toString() ??
          json['matricule']?.toString() ?? '',
      monthlyLimit: (json['monthlyLimit'] ??
              json['plafond'] ??
              json['balance'] ??
              json['solde'] ??
              0)
          .toDouble(),
      currentMonthUsage: (json['currentMonthUsage'] ??
              json['depensesMois'] ??
              0)
          .toDouble(),
      isActive: json['isActive'] ?? json['actif'] ?? true,
      profileLocked: json['profileLocked'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      department: json['department']?.toString() ??
          json['departement']?.toString(),
      position:
          json['position']?.toString() ?? json['poste']?.toString(),
      accountType:
          json['accountType']?.toString() ??
          json['typeCompte']?.toString() ??
          'capped',
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ TO API
  // ═══════════════════════════════════════════════════════════
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'enterpriseId': enterpriseId,
      'enterpriseName': enterpriseName,
      'fullName': fullName,
      'email': email,
      'employeeNumber': employeeNumber,
      'monthlyLimit': monthlyLimit,
      'currentMonthUsage': currentMonthUsage,
      'isActive': isActive,
      'profileLocked': profileLocked,
      'createdAt': createdAt.toIso8601String(),
      'department': department,
      'position': position,
      'accountType': accountType,
    };
  }

  // ═══════════════════════════════════════════════════════════
  // 🎯 LOGIQUE MÉTIER (inchangée)
  // ═══════════════════════════════════════════════════════════

  bool get isCapped =>
      accountType == 'capped' || accountType == 'CAPPED';

  bool get isCumulative =>
      accountType == 'cumulative' || accountType == 'CUMULATIVE';

  // ── Plafonné ──
  double get remainingBalance => monthlyLimit - currentMonthUsage;

  bool get hasReachedLimit => currentMonthUsage >= monthlyLimit;

  double get usagePercentage => monthlyLimit > 0
      ? (currentMonthUsage / monthlyLimit * 100).clamp(0, 100)
      : 0;

  String get usageLevel {
    if (usagePercentage < 40) return 'green';
    if (usagePercentage < 80) return 'yellow';
    return 'red';
  }

  // ── Cumulatif ──
  double get cumulativeBalance => monthlyLimit;
  double get cumulativeUsed => currentMonthUsage;

  // ═══════════════════════════════════════════════════════════
  // 🔁 COPY WITH
  // ═══════════════════════════════════════════════════════════
  CorporateEmployeeModel copyWith({
    String? userId,
    String? enterpriseId,
    String? enterpriseName,
    String? fullName,
    String? email,
    String? employeeNumber,
    double? monthlyLimit,
    double? currentMonthUsage,
    bool? isActive,
    bool? profileLocked,
    DateTime? createdAt,
    String? department,
    String? position,
    String? accountType,
  }) {
    return CorporateEmployeeModel(
      id: id,
      userId: userId ?? this.userId,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      enterpriseName: enterpriseName ?? this.enterpriseName,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currentMonthUsage:
          currentMonthUsage ?? this.currentMonthUsage,
      isActive: isActive ?? this.isActive,
      profileLocked: profileLocked ?? this.profileLocked,
      createdAt: createdAt ?? this.createdAt,
      department: department ?? this.department,
      position: position ?? this.position,
      accountType: accountType ?? this.accountType,
    );
  }
}