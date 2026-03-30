class CountryModel {
  final int id;
  final String nomPays;
  final String indicatif;
  final String devise;
  final String drapeau;
  final String icone;

  CountryModel({
    required this.id,
    required this.nomPays,
    required this.indicatif,
    required this.devise,
    required this.drapeau,
    required this.icone,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id: json['id'] ?? 0,
      nomPays: json['nomPays'] ?? '',
      indicatif: json['indicatif'] ?? '',
      devise: json['devise'] ?? '',
      drapeau: json['drapeau'] ?? '',
      icone: json['icone'] ?? '',
    );
  }
}