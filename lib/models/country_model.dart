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

  // ✅ Liste locale de pays (exemple)
 static List<CountryModel> get localList => [
  CountryModel(
    id: 1,
    nomPays: "Sénégal",
    indicatif: "+221",
    devise: "XOF",
    drapeau: "🇸🇳",
    icone: "SN",
  ),
  CountryModel(
    id: 2,
    nomPays: "Côte d'Ivoire",
    indicatif: "+225",
    devise: "XOF",
    drapeau: "🇨🇮",
    icone: "CI",
  ),
  CountryModel(
    id: 3,
    nomPays: "Mauritanie",
    indicatif: "+222",
    devise: "MRU",
    drapeau: "🇲🇷",
    icone: "MR",
  ),
  CountryModel(
    id: 4,
    nomPays: "Mali",
    indicatif: "+223",
    devise: "XOF",
    drapeau: "🇲🇱",
    icone: "ML",
  ),
  CountryModel(
    id: 5,
    nomPays: "Burkina Faso",
    indicatif: "+226",
    devise: "XOF",
    drapeau: "🇧🇫",
    icone: "BF",
  ),
  CountryModel(
    id: 6,
    nomPays: "Niger",
    indicatif: "+227",
    devise: "XOF",
    drapeau: "🇳🇪",
    icone: "NE",
  ),
  CountryModel(
    id: 7,
    nomPays: "Guinée",
    indicatif: "+224",
    devise: "GNF",
    drapeau: "🇬🇳",
    icone: "GN",
  ),
  CountryModel(
    id: 8,
    nomPays: "Guinée-Bissau",
    indicatif: "+245",
    devise: "XOF",
    drapeau: "🇬🇼",
    icone: "GW",
  ),
  CountryModel(
    id: 9,
    nomPays: "Bénin",
    indicatif: "+229",
    devise: "XOF",
    drapeau: "🇧🇯",
    icone: "BJ",
  ),
  CountryModel(
    id: 10,
    nomPays: "Togo",
    indicatif: "+228",
    devise: "XOF",
    drapeau: "🇹🇬",
    icone: "TG",
  ),
  CountryModel(
    id: 11,
    nomPays: "Ghana",
    indicatif: "+233",
    devise: "GHS",
    drapeau: "🇬🇭",
    icone: "GH",
  ),
  CountryModel(
    id: 12,
    nomPays: "Nigeria",
    indicatif: "+234",
    devise: "NGN",
    drapeau: "🇳🇬",
    icone: "NG",
  ),
  CountryModel(
    id: 13,
    nomPays: "Libéria",
    indicatif: "+231",
    devise: "LRD",
    drapeau: "🇱🇷",
    icone: "LR",
  ),
  CountryModel(
    id: 14,
    nomPays: "Sierra Leone",
    indicatif: "+232",
    devise: "SLL",
    drapeau: "🇸🇱",
    icone: "SL",
  ),
  CountryModel(
    id: 15,
    nomPays: "Gambie",
    indicatif: "+220",
    devise: "GMD",
    drapeau: "🇬🇲",
    icone: "GM",
  ),
  CountryModel(
    id: 16,
    nomPays: "Cap-Vert",
    indicatif: "+238",
    devise: "CVE",
    drapeau: "🇨🇻",
    icone: "CV",
  ),
];

  // ✅ Pays par défaut
  static CountryModel get defaultCountry => localList.first;

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    final nom = json['nomPays']?.toString() ??
        json['nom_pays']?.toString() ??
        '';
    final indicatif = json['indicatif']?.toString() ?? '';
    final devise = json['devise']?.toString() ?? '';
    final icone = json['icone']?.toString() ?? '';

    final rawDrapeau = json['drapeau']?.toString() ?? '';
    final drapeau =
        _toEmoji(rawDrapeau) ?? _toEmoji(icone) ?? rawDrapeau;

    return CountryModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nomPays: nom,
      indicatif: indicatif,
      devise: devise,
      drapeau: drapeau,
      icone: icone,
    );
  }

  static String? _toEmoji(String code) {
    if (code.length != 2) return null;
    final upper = code.toUpperCase();
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(upper)) return null;

    final first = upper.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final second = upper.codeUnitAt(1) - 0x41 + 0x1F1E6;

    return String.fromCharCode(first) +
        String.fromCharCode(second);
  }
}