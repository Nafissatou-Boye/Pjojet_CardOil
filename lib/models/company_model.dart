// lib/models/company_model.dart

class CompanyModel {
  final String id;
  final String name;
  final String logo;
  final String color;
  final List<String> services;
  final double cashbackRate;
  final String status;

  CompanyModel({
    required this.id,
    required this.name,
    required this.logo,
    required this.color,
    required this.services,
    required this.cashbackRate,
    required this.status,
  });

  // ── Depuis la réponse API REST (/api/companies/{id}) ──────────
  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id']?.toString() ?? '',
      // tolère plusieurs noms de champ selon le backend
      name: (json['name'] ??
              json['nomCompagnie'] ??
              json['libelle'] ??
              json['companyName'] ??
              '')
          .toString(),
      logo: json['logo']?.toString() ?? '',
      color: json['color']?.toString() ?? '#2563EB',
      services: json['services'] != null
          ? List<String>.from(json['services'] as List)
          : [],
      cashbackRate: (json['cashbackRate'] ?? 0).toDouble(),
      status: json['status']?.toString() ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'logo': logo,
        'color': color,
        'services': services,
        'cashbackRate': cashbackRate,
        'status': status,
      };
}

/// ─────────────────────────────────────────────────────────────
/// PAYS MODEL  —  GET /api/pays
/// ─────────────────────────────────────────────────────────────
class PaysModel {
  final int id;
  final String nomPays;
  final String indicatif;
  final String devise;
  final String drapeau;
  final String icone;

  PaysModel({
    required this.id,
    required this.nomPays,
    required this.indicatif,
    required this.devise,
    required this.drapeau,
    required this.icone,
  });

  factory PaysModel.fromJson(Map<String, dynamic> json) {
    return PaysModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nomPays: json['nomPays']?.toString() ?? '',
      indicatif: json['indicatif']?.toString() ?? '',
      devise: json['devise']?.toString() ?? '',
      drapeau: json['drapeau']?.toString() ?? '',
      icone: json['icone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nomPays': nomPays,
        'indicatif': indicatif,
        'devise': devise,
        'drapeau': drapeau,
        'icone': icone,
      };
}