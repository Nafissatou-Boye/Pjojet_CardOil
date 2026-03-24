import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bill_reminder_model.dart';

class BillReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── STREAM RAPPELS UTILISATEUR ───────────────────────────────────────────
  Stream<List<BillReminderModel>> getRemindersStream(String compagnie) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('bill_reminders')
        .where('userId', isEqualTo: uid)
        .where('compagnie', isEqualTo: compagnie)
        .where('status', isEqualTo: 'pending')
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BillReminderModel.fromFirestore(doc))
            .toList());
  }

  // ─── AJOUTER UN RAPPEL ────────────────────────────────────────────────────
  Future<bool> addReminder({
    required String compagnie,
    required String type,
    required double amount,
    required DateTime dueDate,
    bool recurring = false,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      await _firestore.collection('bill_reminders').add({
        'userId': uid,
        'compagnie': compagnie,
        'type': type,
        'amount': amount,
        'dueDate': Timestamp.fromDate(dueDate),
        'status': 'pending',
        'recurring': recurring,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── MARQUER COMME PAYÉ ───────────────────────────────────────────────────
  Future<bool> markAsPaid(String reminderId) async {
    try {
      await _firestore
          .collection('bill_reminders')
          .doc(reminderId)
          .update({'status': 'paid'});
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── SUPPRIMER UN RAPPEL ──────────────────────────────────────────────────
  Future<bool> deleteReminder(String reminderId) async {
    try {
      await _firestore
          .collection('bill_reminders')
          .doc(reminderId)
          .delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
