// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String phone;
  final String fullName;
  final String selectedCompagnie;
  final String qrCode;
  final double balance;
  final String status;
  final bool phoneVerified;
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.uid,
    required this.phone,
    required this.fullName,
    required this.selectedCompagnie,
    required this.qrCode,
    required this.balance,
    required this.status,
    this.phoneVerified = false,
    required this.createdAt,
    this.lastLogin,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      phone: data['phone'] ?? '',
      fullName: data['fullName'] ?? '',
      selectedCompagnie: data['selectedCompagnie'] ?? 'total',
      qrCode: data['qrCode'] ?? '',
      balance: (data['balance'] ?? 0).toDouble(),
      status: data['status'] ?? 'ACTIVE',
      phoneVerified: data['phoneVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'fullName': fullName,
      'selectedCompagnie': selectedCompagnie,
      'qrCode': qrCode,
      'balance': balance,
      'status': status,
      'phoneVerified': phoneVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }
}
