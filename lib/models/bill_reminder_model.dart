// lib/models/bill_reminder_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BillReminderModel {
  final String id;
  final String userId;
  final String compagnie;
  final String type;
  final double amount;
  final DateTime dueDate;
  final String status;
  final bool recurring;

  BillReminderModel({
    required this.id,
    required this.userId,
    required this.compagnie,
    required this.type,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.recurring,
  });

  factory BillReminderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return BillReminderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      compagnie: data['compagnie'] ?? '',
      type: data['type'] ?? 'electricity',
      amount: (data['amount'] ?? 0).toDouble(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      recurring: data['recurring'] ?? false,
    );
  }

  bool get isOverdue => DateTime.now().isAfter(dueDate) && status == 'pending';
  
  String get typeLabel {
    switch (type) {
      case 'electricity': return 'Électricité';
      case 'water': return 'Eau';
      case 'internet': return 'Internet';
      default: return type;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'compagnie': compagnie,
      'type': type,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'recurring': recurring,
    };
  }
}
