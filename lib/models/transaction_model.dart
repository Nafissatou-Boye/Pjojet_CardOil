// lib/models/station_transaction_model.dart

enum TransactionStatus { pending, success, failed, cancelled }
enum PaymentMethod { qr_code, nfc, cash }
enum ProductType { gasoil, msuper, diesel, essence }
enum TransactionType {
  recharge,
  payment,
}


class StationTransactionModel {
  final String id;
  final double amount;
  final ProductType product;
  final String stationId;
  final String stationName;
  final String pompisteId;
  final String pompisteName;
  final String? clientId;
  final String? clientName;
  final String rawStatus;
  final TransactionStatus status;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? qrData;
  final String? cancelReason;
  final String? cancelledBy;

  StationTransactionModel({
    required this.id,
    required this.amount,
    required this.product,
    required this.stationId,
    required this.stationName,
    required this.pompisteId,
    required this.pompisteName,
    this.clientId,
    this.clientName,
    required this.rawStatus,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.completedAt,
    this.qrData,
    this.cancelReason,
    this.cancelledBy,
  });

  factory StationTransactionModel.fromJson(Map<String, dynamic> data) {

  // ✅ Date
  final dateRaw = data['date'] ?? data['createdAt'];

  // ✅ Produit
  final productStr = (data['productName'] as String? ??
          data['product'] as String? ??
          '')
      .toLowerCase();

  ProductType product;
  if (productStr.contains('super')) {
    product = ProductType.msuper;
  } else if (productStr.contains('diesel')) {
    product = ProductType.diesel;
  } else if (productStr.contains('essence')) {
    product = ProductType.essence;
  } else {
    product = ProductType.gasoil;
  }

  // ✅ Type (vente vs recharge)
  final role = (data['operatorRole'] as String? ?? '').toUpperCase();
  final typeStr = (data['type'] as String? ?? '').toUpperCase();
  final productName = (data['productName'] as String? ?? '');

  // GERANT sans produit = recharge, POMPISTE avec produit = vente
  final rawStatus = typeStr.isNotEmpty
      ? typeStr
      : (role.contains('GERANT') && productName.isEmpty)
          ? 'RECHARGE'
          : 'CLIENT_VENTE';

  // ✅ Statut réel
  final statusStr = (data['status'] as String? ?? '').toLowerCase();

  return StationTransactionModel(
    id: data['id']?.toString() ?? '',
    amount: (data['amount'] ?? 0.0).toDouble(),
    product: product,
    stationId: data['operatorStationId']?.toString() ??
        data['stationId']?.toString() ??
        '',
    stationName: data['stationName'] as String? ??
        data['operatorStationName'] as String? ??
        '',
    pompisteId: data['operatorUsername'] as String? ??
        data['pompisteId']?.toString() ??
        '',
    pompisteName: data['operatorUsername'] as String? ??
        data['pompisteName'] as String? ??
        '',
    clientId: data['user']?.toString() ?? data['clientId']?.toString(),
    clientName: data['user'] as String? ?? data['clientName'] as String?,
    rawStatus: rawStatus,
    status: _parseStatus(statusStr),
    paymentMethod: PaymentMethod.qr_code,
    createdAt: _parseDate(dateRaw),
    completedAt: null,
    qrData: null,
    cancelReason: null,
    cancelledBy: null,
  );
}

  // ✅ UTILISÉ MAINTENANT → plus de warning
  static TransactionStatus _parseStatus(String s) {
    switch (s) {
      case 'success':
      case 'completed':
        return TransactionStatus.success;
      case 'pending':
        return TransactionStatus.pending;
      case 'failed':
        return TransactionStatus.failed;
      case 'cancelled':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.success; // fallback logique
    }
  }

// Dans votre TransactionModel ou StationTransactionModel
TransactionType get transactionType {
  final t = rawStatus.toUpperCase();
  // ✅ Tous les mots-clés de recharge/crédit
  if (t.contains('RECHARGE') || 
      t.contains('CREDIT')   || 
      t.contains('DEPOT')    ||
      t.contains('TOPUP')) {
    return TransactionType.recharge;
  }
  return TransactionType.payment;
}

  // ✅ Simplification UI
  bool get isDebit => transactionType == TransactionType.payment;
  bool get isCredit => transactionType == TransactionType.recharge;
  String get sign => isDebit ? '-' : '+';

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'product': product.toString().split('.').last,
        'stationId': stationId,
        'stationName': stationName,
        'pompisteId': pompisteId,
        'pompisteName': pompisteName,
        'clientId': clientId,
        'clientName': clientName,
        'status': rawStatus,
        'paymentMethod': paymentMethod.toString().split('.').last,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  Map<String, dynamic> toJson() => toMap();

  String get productLabel {
    switch (product) {
      case ProductType.gasoil:
        return 'Gasoil';
      case ProductType.msuper:
        return 'Super';
      case ProductType.diesel:
        return 'Diesel';
      case ProductType.essence:
        return 'Essence';
    }
  }

  // Compatibilité
  String get type => rawStatus;
}
// ═══════════════════════════════════════════════════════════════════════════
// CARTE
// ═══════════════════════════════════════════════════════════════════════════

class CarteModel {
  final int id;
  final String reference;
  final String statut;
  final bool isActive;
  final bool cumul;
  final int? compteId;
  final int? compteDotationId;
  final int userId;
  /// solde = solde brut total de la carte (ex: 1 578 100 FCFA)
  final double solde;
  /// soldeReel = compte.solde_disponible — montant réellement dépensable
  /// C'est CE champ que le backend utilise pour autoriser un paiement.
  /// Exemple DB: compte.solde_disponible = 100 FCFA
  final double soldeReel;

  CarteModel({
    required this.id,
    required this.reference,
    required this.statut,
    required this.isActive,
    required this.cumul,
    this.compteId,
    this.compteDotationId,
    required this.userId,
    required this.solde,
    required this.soldeReel,
  });

  factory CarteModel.fromJson(Map<String, dynamic> json) => CarteModel(
        id: json['id'] ?? 0,
        reference: json['reference'] ?? '',
        statut: json['statut'] ?? '',
        isActive: json['isActive'] ?? false,
        cumul: json['cumul'] ?? false,
        compteId: json['compteId'],
        compteDotationId: json['compteDotationId'],
        userId: json['userId'] ?? 0,
        solde: (json['solde'] ?? 0).toDouble(),
        soldeReel: (json['soldeReel'] ?? 0).toDouble(),
      );


double get soldeDisponible => soldeReel;
double get balance => soldeReel;
}



class DailyStats {
  final double totalAmount;
  final int totalCount;
  final int successCount;

  const DailyStats({
    this.totalAmount = 0,
    this.totalCount = 0,
    this.successCount = 0,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// PRIX JOURNALIERS — définis ici pour éviter le conflit d'import ambiguous
// ═══════════════════════════════════════════════════════════════════════════

class ProductInfo {
  final int id;
  final String code;
  final String name;
  final String productType;

  ProductInfo({
    required this.id,
    required this.code,
    required this.name,
    required this.productType,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) => ProductInfo(
        id: json['id'] ?? 0,
        code: json['code'] ?? '',
        name: json['name'] ?? '',
        productType: json['productType'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'code': code, 'name': name, 'productType': productType,
      };
}

class StationInfo {
  final int id;
  final String name;
  final String address;
  final String phone;

  StationInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
  });

  factory StationInfo.fromJson(Map<String, dynamic> json) => StationInfo(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        phone: json['phone'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'address': address, 'phone': phone,
      };
}

class DailyPriceModel {
  final int id;
  final double amount;
  final String date;
  final ProductInfo product;
  final StationInfo station;

  DailyPriceModel({
    required this.id,
    required this.amount,
    required this.date,
    required this.product,
    required this.station,
  });

  factory DailyPriceModel.fromJson(Map<String, dynamic> json) => DailyPriceModel(
        id: json['id'] ?? 0,
        amount: (json['amount'] ?? 0).toDouble(),
        date: json['date'] ?? '',
        product: ProductInfo.fromJson(
            (json['product'] as Map<String, dynamic>?) ?? {}),
        station: StationInfo.fromJson(
            (json['station'] as Map<String, dynamic>?) ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'date': date,
        'product': product.toJson(),
        'station': station.toJson(),
      };
}