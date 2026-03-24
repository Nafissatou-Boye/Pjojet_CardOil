// lib/models/promotion_model.dart

class PromotionModel {
  final String id;
  final String compagnie;
  final String title;
  final String description;
  final String? image;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String conditions;
  final String actionButton;
  final DateTime createdAt;

  PromotionModel({
    required this.id,
    required this.compagnie,
    required this.title,
    required this.description,
    this.image,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.conditions,
    required this.actionButton,
    required this.createdAt,
  });

  // ─── JSON → MODEL ─────────────────────────────
  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id']?.toString() ?? '',
      compagnie: json['compagnie'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      image: json['image'],
      type: json['type'] ?? 'offer',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate']) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate']) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] ?? 'active',
      conditions: json['conditions'] ?? '',
      actionButton: json['actionButton'] ?? 'Participer',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // ─── MODEL → JSON (pour POST API) ─────────────
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'compagnie': compagnie,
      'title': title,
      'description': description,
      'image': image,
      'type': type,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'conditions': conditions,
      'actionButton': actionButton,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // ─── PROMOTION ACTIVE ─────────────────────────
  bool get isActive {
    final now = DateTime.now();
    return status == 'active' &&
        now.isAfter(startDate) &&
        now.isBefore(endDate);
  }
}