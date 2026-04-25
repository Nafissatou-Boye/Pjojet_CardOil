class CorporateAccountModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  // ✅ matriculePlaque au lieu de matricule (plus parlant)
  final String matriculePlaque;
  final String enterpriseId;
  final String enterpriseName;
  final String accountType;    // 'capped' | 'cumulative'
  final double monthlyLimit;   // dotation
  final double currentMonthUsage;
  final double balance;        // soldeDisponible
  final String? department;
  final String? position;
  // ✅ Infos véhicule
  final String? marqueModele;
  final String? carburant;
  final String? boiteVitesse;
  final int? kilometrage;
  final bool isActive;

  CorporateAccountModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber = '',
    required this.matriculePlaque,
    required this.enterpriseId,
    required this.enterpriseName,
    required this.accountType,
    required this.monthlyLimit,
    required this.currentMonthUsage,
    required this.balance,
    this.department,
    this.position,
    this.marqueModele,
    this.carburant,
    this.boiteVitesse,
    this.kilometrage,
    required this.isActive,
  });

  bool get isCapped => !accountType.toLowerCase().contains('cumulat');
  double get remainingBalance => monthlyLimit > 0 ? monthlyLimit - currentMonthUsage : balance;
  double get usagePercentage =>
      monthlyLimit > 0 ? (currentMonthUsage / monthlyLimit * 100).clamp(0, 100) : 0;
  bool get hasReachedLimit => isCapped && currentMonthUsage >= monthlyLimit;
  bool get hasVehicle => matriculePlaque.isNotEmpty;
  // ✅ Compatibilité : employeeNumber = matriculePlaque (pour le QR et l'API)
  String get employeeNumber => matriculePlaque.isNotEmpty ? matriculePlaque : id;

  String get usageLevel {
    if (usagePercentage >= 90) return 'red';
    if (usagePercentage >= 70) return 'yellow';
    return 'green';
  }

  // ✅ Factory depuis la combinaison compte + user
  factory CorporateAccountModel.fromCombined({
    required Map<String, dynamic> compteJson,
    required Map<String, dynamic> userJson,
  }) {
    // ── Extraire vehicleMaintenance ──────────────────────────────────────
    final vm = userJson['vehicleMaintenance'] as Map<String, dynamic>? ?? {};
    final porteur = vm['porteursClient'] as Map<String, dynamic>? ?? {};
    final vehicule = vm['vehiculeInfo'] as Map<String, dynamic>? ?? {};
    final entreprise = vm['entreprise'] as Map<String, dynamic>? ?? {};

    // ── Nom complet ──────────────────────────────────────────────────────
    // ✅ Fix "null" dans le nom : filtrer les null explicites
    final prenom = (userJson['firstname']?.toString() ?? '').trim();
    final nom = (porteur['nom']?.toString() ?? '').trim();
    // Éviter "BOYE Nafissatou null" si nom est la string "null"
    final nomClean = (nom == 'null' || nom.isEmpty) ? '' : nom;
    final prenomClean = (prenom == 'null' || prenom.isEmpty) ? '' : prenom;
    // Nettoyer les "null" résiduels avec regex
    final rawName = [prenomClean, nomClean].where((s) => s.isNotEmpty).join(' ')
        .ifEmpty(userJson['username']?.toString() ?? 'Employé');
    final fullName = rawName.replaceAll(RegExp(r'\bnull\b'), '').trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .ifEmpty(userJson['username']?.toString() ?? 'Employé');

    // ── Type de compte : cumul=true → cumulatif, cumul=false → plafonné ─
    final cumul = porteur['cumul'] as bool? ?? true;
    final accountType = cumul ? 'cumulative' : 'capped';

    // ── Dotation (plafond mensuel) ───────────────────────────────────────
    final dotation = (porteur['dotation'] ?? 0).toDouble();

    return CorporateAccountModel(
      id: compteJson['id']?.toString() ?? userJson['id']?.toString() ?? '',
      fullName: fullName,
      email: userJson['email']?.toString() ?? porteur['email']?.toString() ?? '',
      phoneNumber: userJson['phoneNumber']?.toString() ?? porteur['telephone']?.toString() ?? '',
      // ✅ Immatriculation du véhicule
      matriculePlaque: vehicule['matriculePlaque']?.toString() ?? '',
      enterpriseId: entreprise['id']?.toString() ?? userJson['compagnie']?.toString() ?? '',
      enterpriseName: entreprise['name']?.toString()
          ?? userJson['compagnieName']?.toString()
          ?? 'Entreprise',
      accountType: accountType,
      monthlyLimit: dotation,
      currentMonthUsage: (compteJson['depensesMois'] ?? compteJson['currentMonthUsage'] ?? 0).toDouble(),
     balance: (compteJson['soldeReel']
    ?? compteJson['solde_reel']
    ?? compteJson['soldeDisponible']
    ?? compteJson['balance']
    ?? 0).toDouble(),
      marqueModele: vehicule['marqueModele']?.toString(),
      carburant: vehicule['carburant']?.toString(),
      boiteVitesse: vehicule['boiteVitesse']?.toString(),
      kilometrage: (vehicule['kilometrage'] as num?)?.toInt(),
      isActive: compteJson['etat']?.toString() == 'ACTIVE'
          || (compteJson['isActive'] as bool? ?? true),
    );
  }

  factory CorporateAccountModel.fromJson(Map<String, dynamic> json) {
    return CorporateAccountModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      matriculePlaque: json['matriculePlaque']?.toString() ?? '',
      enterpriseId: json['enterpriseId']?.toString() ?? '',
      enterpriseName: json['enterpriseName']?.toString() ?? '',
      accountType: json['accountType']?.toString() ?? 'cumulative',
      monthlyLimit: (json['monthlyLimit'] ?? 0).toDouble(),
      currentMonthUsage: (json['currentMonthUsage'] ?? 0).toDouble(),
      balance: (json['balance'] ?? 0).toDouble(),
      department: json['department']?.toString(),
      position: json['position']?.toString(),
      marqueModele: json['marqueModele']?.toString(),
      carburant: json['carburant']?.toString(),
      boiteVitesse: json['boiteVitesse']?.toString(),
      kilometrage: json['kilometrage'] as int?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'fullName': fullName, 'email': email,
    'phoneNumber': phoneNumber,
    'matriculePlaque': matriculePlaque,
    'enterpriseId': enterpriseId, 'enterpriseName': enterpriseName,
    'accountType': accountType, 'monthlyLimit': monthlyLimit,
    'currentMonthUsage': currentMonthUsage, 'balance': balance,
    'isActive': isActive,
    if (department != null) 'department': department,
    if (position != null) 'position': position,
    if (marqueModele != null) 'marqueModele': marqueModele,
    if (carburant != null) 'carburant': carburant,
    if (boiteVitesse != null) 'boiteVitesse': boiteVitesse,
    if (kilometrage != null) 'kilometrage': kilometrage,
  };
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id, required this.title, required this.message,
    required this.type, required this.isRead, required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['titre']?.toString() ?? '',
      message: json['message']?.toString() ?? json['contenu']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      isRead: json['isRead'] as bool? ?? json['lu'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

// Extension helper
extension StringHelper on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
