// lib/services/client_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client_model.dart';

class ClientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream de tous les clients
  Stream<List<ClientModel>> getClientsStream() {
    return _firestore.collection('clients')
        .orderBy('fullName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClientModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}