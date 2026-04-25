import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/transaction_service.dart';
import '../../services/corporate_service.dart';
import '../../services/card_service.dart';
import '../../models/corporate_employee_model.dart';

class CorporateQRScreen extends StatefulWidget {
  const CorporateQRScreen({super.key});

  @override
  State<CorporateQRScreen> createState() => _CorporateQRScreenState();
}

class _CorporateQRScreenState extends State<CorporateQRScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CorporateAccountModel? _account;
  String? _cardReference; // référence carte pour le paiement
  bool _isLoading = true;
  bool _isScanning = false;
  bool _scanned = false;
  MobileScannerController? _scannerCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerCtrl?.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 1) {
      setState(() {
        _scanned = false;
        _scannerCtrl = MobileScannerController();
        _isScanning = true;
      });
    } else {
      _scannerCtrl?.dispose();
      _scannerCtrl = null;
      if (mounted) setState(() => _isScanning = false);
    }
  }

// Dans _loadData() — ajouter log
Future<void> _loadData() async {
  final results = await Future.wait([
    CorporateService().getMyAccount(),
    CardService().getMyCard(),
  ]);

  if (!mounted) return;

  final accountResult = results[0];
  final cardResult = results[1];

  setState(() {
    _account = accountResult['account'] as CorporateAccountModel?;

    if (cardResult['success'] == true && cardResult['card'] != null) {
      final card = cardResult['card'] as CardModel;
      _cardReference = card.reference;
      debugPrint('💳 CardReference chargée: $_cardReference');
    } else {
      debugPrint('⚠️ Pas de carte trouvée: ${cardResult}');
      // _cardReference reste null → le paiement utilisera account.id
      // qui peut être invalide → afficher message à l'utilisateur
    }

    _isLoading = false;
  });
}

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Paiement QR', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.credit_card), text: 'Ma Carte'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scanner'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildMyCard(), _buildScanner()],
            ),
    );
  }

  Widget _buildMyCard() {
    if (_account == null) {
    return const Center(child: Text('Impossible de charger le compte'));
  }

  
  if (_cardReference == null) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card_off, size: 64, color: Colors.orange.shade300),
            const SizedBox(height: 16),
            const Text(
              'Carte non disponible',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre carte de paiement n\'a pas pu être chargée. '
              'Contactez votre administrateur.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () { setState(() => _isLoading = true); _loadData(); },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

    final account = _account!;

    
    final cleanName = account.fullName
        .replaceAll(RegExp(r'\bnull\b'), '').trim()
        .replaceAll(RegExp(r'\s+'), ' ');

final qrData = jsonEncode({
  'type':          'EMPLOYE',
  'userId':        _account!.id,     // ✅ même valeur — sera lu par le pompiste
  'fullName':      _account!.fullName.replaceAll(RegExp(r'\bnull\b'), '').trim(),
  'compagnie':     _account!.enterpriseId,
  'company':       _account!.enterpriseName,
  'cardReference': _cardReference!,
  'qrCode':        _cardReference!,
  'balance':       _account!.balance,
  'isCorporate':   true,
});

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Carte bleue
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))]),
          child: Column(children: [
            // Header nom / entreprise
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.business, color: Colors.white, size: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cleanName.isNotEmpty ? cleanName : account.fullName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
                Text(account.enterpriseName,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ])),
            ]),
            const SizedBox(height: 20),

            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: QrImageView(data: qrData, size: 200, backgroundColor: Colors.white)),
            const SizedBox(height: 16),

            // Solde
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text('${_fmt(account.balance)} FCFA',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 20, fontWeight: FontWeight.w900)),
              ])),

           
            if (account.hasVehicle) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.directions_car, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text(account.matriculePlaque,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 2)),
                ])),
            ],
          ]),
        ),

        const SizedBox(height: 16),

        // Info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
          child: Row(children: [
            const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
            const SizedBox(width: 12),
            const Expanded(child: Text(
              'Montrez ce QR au pompiste, ou scannez le QR de la station pour payer directement.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4))),
          ]),
        ),
        const SizedBox(height: 16),

        // Bouton scanner
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: () => _tabController.animateTo(1),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scanner',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0)),
        ),
      ]),
    );
  }

  // ── Scanner ────────────────────────────────────────────────────────────────
  Widget _buildScanner() {
    if (!_isScanning || _scannerCtrl == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    }

    return Stack(children: [
      MobileScanner(
        controller: _scannerCtrl!,
        onDetect: (barcode, args) {
          if (_scanned) return;
          final code = barcode.rawValue;
          if (code == null) return;
          setState(() => _scanned = true);
          _handleStationQR(code);
        },
      ),
      Positioned(top: 0, left: 0, right: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.7), Colors.transparent])),
          child: const SafeArea(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Scanner la station',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 4),
              Text('Pointez vers le QR affiché à la station service',
                  style: TextStyle(fontSize: 14, color: Colors.white70)),
            ])))),
      Center(child: Container(
        width: 260, height: 260,
        decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 3),
            borderRadius: BorderRadius.circular(20)),
        child: Stack(children: [
          Positioned(top: -2, left: -2, child: _corner()),
          Positioned(top: -2, right: -2, child: Transform.rotate(angle: 1.57, child: _corner())),
          Positioned(bottom: -2, left: -2, child: Transform.rotate(angle: -1.57, child: _corner())),
          Positioned(bottom: -2, right: -2, child: Transform.rotate(angle: 3.14, child: _corner())),
        ]))),
      Positioned(bottom: 40, left: 0, right: 0,
        child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20)),
          child: const Text('QR de la station service',
              style: TextStyle(color: Colors.white, fontSize: 14))))),
    ]);
  }

  Widget _corner() => Container(
    width: 30, height: 30,
    decoration: const BoxDecoration(
      border: Border(
          top: BorderSide(color: Color(0xFF2563EB), width: 4),
          left: BorderSide(color: Color(0xFF2563EB), width: 4)),
      borderRadius: BorderRadius.only(topLeft: Radius.circular(8))));

  void _handleStationQR(String raw) async {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final type = data['type']?.toString() ?? '';

      if (type != 'STATION') {
        _showError(
          type == 'CLIENT' || type == 'CORPORATE_CLIENT'
              ? 'C\'est votre carte — montrez-la au pompiste. Scannez le QR de la station.'
              : 'Ce QR n\'est pas celui d\'une station service');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) { setState(() => _scanned = false); _scannerCtrl?.start(); }
        return;
      }

      HapticFeedback.heavyImpact();
      _scannerCtrl?.stop();
      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _PaymentConfirmDialog(
          account: _account!,
          cardReference: _cardReference,
          stationData: data,
          onSuccess: _loadData,
        ),
      );

      if (!mounted) return;
      if (confirmed == true) {
        _tabController.animateTo(0);
        setState(() { _scanned = false; _isScanning = false; });
        _scannerCtrl?.dispose();
        _scannerCtrl = null;
      } else {
        setState(() => _scanned = false);
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) _scannerCtrl?.start();
      }
    } catch (e) {
      _showError('QR invalide ou illisible');
      setState(() => _scanned = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16)));
  }
  
}

class _PaymentConfirmDialog extends StatefulWidget {
  final CorporateAccountModel account;
  final String? cardReference;
  final Map<String, dynamic> stationData;
  final VoidCallback onSuccess;

  const _PaymentConfirmDialog({
    required this.account,
    required this.cardReference,
    required this.stationData,
    required this.onSuccess,
  });

  @override
  State<_PaymentConfirmDialog> createState() => _PaymentConfirmDialogState();
}

class _PaymentConfirmDialogState extends State<_PaymentConfirmDialog> {
  bool _isProcessing = false;

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

Future<void> _pay() async {
  setState(() => _isProcessing = true);

  try {
    final data = widget.stationData;
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final productId = (data['productId'] as num?)?.toInt()
        ?? _productNameToId(data['product']?.toString() ?? '');
    final stationIdRaw = data['stationId'];
    final stationId = stationIdRaw is int
        ? stationIdRaw
        : int.tryParse(stationIdRaw?.toString() ?? '0') ?? 0;
    final cardRef = widget.cardReference ?? '';
    final pompisteUsername = data['pompisteId']?.toString() ?? '';

    debugPrint('💳 Corporate _pay:');
    debugPrint('   cardRef: "$cardRef"');
    debugPrint('   pompisteUsername: "$pompisteUsername"');
    debugPrint('   amount: $amount | productId: $productId | stationId: $stationId');

    if (cardRef.isEmpty) {
      setState(() => _isProcessing = false);
      _showSnack('Carte introuvable. Contactez votre administrateur.', Colors.red);
      return;
    }

    if (stationId == 0) {
      setState(() => _isProcessing = false);
      _showSnack('QR station invalide.', Colors.orange);
      return;
    }

    // ✅ Récupérer userId depuis la carte (API /api/cartes/ref/{ref})
    String clientUserId = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final cardRes = await http.get(
        Uri.parse('https://api.cardoil.io/api/cartes/ref/$cardRef'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('💳 GET cartes/ref/$cardRef → ${cardRes.statusCode}: ${cardRes.body}');

      if (cardRes.statusCode == 200) {
        final cardJson = jsonDecode(cardRes.body) as Map<String, dynamic>;
        final rawUserId = cardJson['userId'] ?? cardJson['user_id'];
        clientUserId = rawUserId?.toString() ?? '';
        debugPrint('✅ clientUserId depuis carte: $clientUserId');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur récupération userId: $e');
    }

    final txService = TransactionService();
    final result = await txService.makeClientPayment(
      cardReference:    cardRef,
      amount:           amount,
      productId:        productId,
      stationId:        stationId,
      pompisteUsername: pompisteUsername,
      clientUserId:     clientUserId,  // ✅ userId réel depuis l'API carte
      stationName:      data['stationName']?.toString(),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      widget.onSuccess();
      Navigator.of(context, rootNavigator: true).pop(true);
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E), shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 48)),
                const SizedBox(height: 20),
                const Text('Transaction réussie !',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937))),
                const SizedBox(height: 8),
                Text(
                  'Votre paiement de ${_fmt(amount)} FCFA\na été effectué avec succès.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280), height: 1.5)),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0),
                    child: const Text('Fermer',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                            color: Colors.white)))),
              ]),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isProcessing = false);
    final errorRaw = result['error']?.toString().toLowerCase() ?? '';
    String displayError;
    if (errorRaw.contains('solde') || errorRaw.contains('insufficient')) {
      displayError = 'Solde insuffisant';
    } else if (errorRaw.contains('initiateur') || errorRaw.contains('introuvable')) {
      displayError = 'Pompiste non reconnu. Demandez un nouveau QR.';
    } else {
      displayError = result['error']?.toString() ?? 'Erreur inconnue';
    }
    _showSnack('❌ $displayError', Colors.red);

  } catch (e) {
    setState(() => _isProcessing = false);
    if (!mounted) return;
    _showSnack('Erreur technique: $e', Colors.red);
  }
}

void _showSnack(String msg, Color color) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: color,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 5),
    margin: const EdgeInsets.all(16),
  ));
}
  // Mapper nom produit → ID selon la DB (table products)
  int _productNameToId(String name) {
    switch (name.toLowerCase()) {
      case 'gasoil': return 1;
      case 'super':  return 2;
      case 'diesel': return 3;
      case 'essence': return 4;
      default: return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.stationData;
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final stationName = data['stationName']?.toString() ?? 'Station';
    final productName = data['productName']?.toString()
        ?? data['product']?.toString() ?? 'Carburant';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Confirmer le paiement',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        // Info station
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF), borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.local_gas_station, color: Color(0xFF2563EB), size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(stationName,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937)))),
            ]),
            if (productName.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.local_offer_outlined, color: Color(0xFF6B7280), size: 16),
                const SizedBox(width: 8),
                Text(productName,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              ]),
            ],
            if (widget.cardReference != null) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.credit_card, color: Color(0xFF6B7280), size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.cardReference!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    overflow: TextOverflow.ellipsis)),
              ]),
            ],
          ]),
        ),
        const SizedBox(height: 20),
        Text('${_fmt(amount)} FCFA',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900,
                color: Color(0xFF2563EB), letterSpacing: -1)),
        const SizedBox(height: 4),
        Text('Débité de votre compte',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        if (amount > 0) ...[
          const SizedBox(height: 8),
          Text('Solde après : ${_fmt(widget.account.balance - amount)} FCFA',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: Color(0xFF22C55E))),
        ],
      ]),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context, false),
          child: const Text('Annuler', style: TextStyle(color: Colors.red))),
        ElevatedButton(
          onPressed: _isProcessing ? null : _pay,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: _isProcessing
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Payer',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
      ],
    );
  }
}