import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// Service Firestore général — utilisé pour
/// les opérations multi-collection et le profil.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── STREAM USER COURANT ───────────────────────────────────────────────────
  Stream<UserModel?> get userStream {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // ─── METTRE À JOUR PROFIL ─────────────────────────────────────────────────
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (fullName != null) updates['fullName'] = fullName;
      if (phone != null) updates['phone'] = phone;

      await _firestore.collection('users').doc(uid).update(updates);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── SOLDE TEMPS RÉEL ─────────────────────────────────────────────────────
  Stream<double> getBalanceStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => (doc.data()?['balance'] ?? 0).toDouble());
  }

  // ─── QR CODE UTILISATEUR ──────────────────────────────────────────────────
  Future<String?> getUserQrCode() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;

      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['qrCode'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ─── VÉRIFIER STATION ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getStation(String stationId) async {
    try {
      final doc =
          await _firestore.collection('stations').doc(stationId).get();
      return doc.exists ? doc.data() : null;
    } catch (_) {
      return null;
    }
  }

  // ─── RECHARGER SOLDE (admin / gérant) ─────────────────────────────────────
  Future<bool> rechargeWallet(String userId, double amount) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'balance': FieldValue.increment(amount),
      });

      await _firestore.collection('transactions').add({
        'userId': userId,
        'type': 'RECHARGE',
        'amount': amount,
        'cashbackEarned': 0,
        'method': 'MANUAL',
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (_) {
      return false;
    }
  }
}
