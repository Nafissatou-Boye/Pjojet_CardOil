// lib/models/corporate_employee_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String accountType; // 👈 AJOUTÉ : 'capped' | 'cumulative'

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
    this.accountType = 'capped', // 👈 défaut : plafonné
  });

  factory CorporateEmployeeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CorporateEmployeeModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      enterpriseId: data['enterpriseId'] ?? '',
      enterpriseName: data['enterpriseName'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      employeeNumber: data['employeeNumber'] ?? '',
      monthlyLimit: (data['monthlyLimit'] ?? 0).toDouble(),
      currentMonthUsage: (data['currentMonthUsage'] ?? 0).toDouble(),
      isActive: data['isActive'] ?? true,
      profileLocked: data['profileLocked'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      department: data['department'],
      position: data['position'],
      accountType: data['accountType'] ?? 'capped', // 👈 AJOUTÉ
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
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
      'createdAt': Timestamp.fromDate(createdAt),
      'department': department,
      'position': position,
      'accountType': accountType, // 👈 AJOUTÉ
    };
  }

  // ── Getters communs ──
  bool get isCapped => accountType == 'capped';
  bool get isCumulative => accountType == 'cumulative';

  // ── Getters Plafonné (capped) ──
  double get remainingBalance => monthlyLimit - currentMonthUsage;
  bool get hasReachedLimit => currentMonthUsage >= monthlyLimit;
  double get usagePercentage =>
      monthlyLimit > 0
          ? (currentMonthUsage / monthlyLimit * 100).clamp(0, 100)
          : 0;

  // Couleur de la barre selon consommation
  // 🟢 0–40% | 🟡 40–80% | 🔴 80–100%
  String get usageLevel {
    if (usagePercentage < 40) return 'green';
    if (usagePercentage < 80) return 'yellow';
    return 'red';
  }

  // ── Getters Cumulatif (cumulative) ──
  // Pour le cumulatif, monthlyLimit = solde total disponible
  // currentMonthUsage = dépenses du mois
  double get cumulativeBalance => monthlyLimit; // solde total
  double get cumulativeUsed => currentMonthUsage;

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
    String? accountType, // 👈 AJOUTÉ
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
      currentMonthUsage: currentMonthUsage ?? this.currentMonthUsage,
      isActive: isActive ?? this.isActive,
      profileLocked: profileLocked ?? this.profileLocked,
      createdAt: createdAt ?? this.createdAt,
      department: department ?? this.department,
      position: position ?? this.position,
      accountType: accountType ?? this.accountType, // 👈 AJOUTÉ
    );
  }
}