// lib/models/client_model.dart
class ClientModel {
  final String id;
  final String fullName;

  ClientModel({required this.id, required this.fullName});

  factory ClientModel.fromMap(Map<String, dynamic> map, String id) {
    return ClientModel(
      id: id,
      fullName: map['fullName'] ?? '',
    );
  }
}