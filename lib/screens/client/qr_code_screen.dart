import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/card_service.dart';
import '../../services/transaction_service.dart';
import '../../models/models.dart';
import '../../langue/app_localizations.dart';
import 'client_receipt_screen.dart';

enum QRMode { myCard, scanner }

class QRCodeScreen extends StatefulWidget {
  final QRMode initialMode;
  const QRCodeScreen({super.key, this.initialMode = QRMode.myCard});

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  late QRMode _currentMode;
  MobileScannerController? _scannerController;
  bool _scanned = false;
  UserModel? _cachedUser;
  CardModel? _cachedCard;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
    if (_currentMode == QRMode.scanner) {
      _scannerController = MobileScannerController();
    }
    _prefetchData();
  }

  Future<void> _prefetchData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final cardService = CardService();

    final results = await Future.wait([
      authService.loadUserProfile(),
      cardService.getMyCard(),
    ]);

    if (!mounted) return;

    final userResult = results[0];
    final cardResult = results[1];

    if (userResult['success'] == true) {
      setState(() {
        _cachedUser = userResult['user'] as UserModel;
        if (cardResult['success'] == true) {
          _cachedCard = cardResult['card'] as CardModel;
        }
      });
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _scanned = false;
      if (_currentMode == QRMode.myCard) {
        _currentMode = QRMode.scanner;
        _scannerController = MobileScannerController();
      } else {
        _scannerController?.dispose();
        _scannerController = null;
        _currentMode = QRMode.myCard;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Directionality(
      textDirection: t.textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _currentMode == QRMode.myCard ? t.myQrCode : t.scanQrTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                _currentMode == QRMode.myCard
                    ? Icons.qr_code_scanner
                    : Icons.qr_code,
              ),
              onPressed: _switchMode,
              tooltip: _currentMode == QRMode.myCard
                  ? 'Scanner'
                  : 'Mon QR',
            ),
          ],
        ),
        body: _currentMode == QRMode.myCard
            ? _buildMyCardView(t)
            : _buildScannerView(t),
      ),
    );
  }


 Widget _buildMyCardView(AppLocalizations t) {
  // ✅ Attendre AUSSI la carte, pas seulement l'utilisateur
  if (_cachedUser == null || _cachedCard == null) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF2563EB)),
          const SizedBox(height: 16),
          Text(
            _cachedUser == null ? 'Chargement profil...' : 'Chargement carte...',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  final user = _cachedUser!;
  final card = _cachedCard!; // ← garanti non-null ici

  // ✅ QR avec toutes les données garanties
  final qrData = jsonEncode({
    'type': 'CLIENT',
    'userId': user.id,           // int DB garanti
    'cardReference': card.reference, // string garanti non-null
    'fullName': user.fullName,
  });

  debugPrint('✅ QR généré: userId=${user.id}, cardRef=${card.reference}');

    print('🔍 QR Data générée:');
    print('  - Type: CLIENT');
    print('  - CardRef: ${card?.reference ?? user.qrCode}');
    print('  - QRCode: ${user.qrCode}');

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Mon QR Code',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
               
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 250,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF2563EB),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              card?.reference ?? user.qrCode,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            if (card != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Carte #${card.id}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(card?.balance ?? user.balance).toStringAsFixed(0)} FCFA',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (card != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.stars,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${card.loyaltyPoints} pts',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _switchMode,
                  icon: const Icon(Icons.qr_code_scanner, size: 24),
                  label: const Text(
                    'Scanner',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VUE: SCANNER (IDENTIQUE)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildScannerView(AppLocalizations t) {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (barcode, args) {
            if (_scanned) return;
            final String? code = barcode.rawValue;
            if (code == null) return;

            setState(() => _scanned = true);
            _handleScannedQR(code, t);
          },
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.scanQrTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.scanQrSub,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
        Center(
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: _switchMode,
              icon: const Icon(Icons.qr_code),
              label: const Text('Mon QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

void _handleScannedQR(String qrData, AppLocalizations t) async {
  try {
    print('🔍 QR scanné: $qrData');

    final data = jsonDecode(qrData) as Map<String, dynamic>;

    if (data['type'] != 'STATION') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.notStationQr),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() => _scanned = false);
      _scannerController?.start();
      return;
    }

    _scannerController?.stop();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentConfirmDialog(
        stationData: data,
        cachedUser: _cachedUser,
        cachedCard: _cachedCard,
      ),
    );

    // ✅ FUSION AJOUTÉE ICI
    if (confirmed == true) {
      if (!mounted) return;

      // 🔄 Rafraîchir les données utilisateur + carte
      await _prefetchData();

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.paymentSuccessMsg),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => _scanned = false);
      _scannerController?.start();
    }
  } catch (e) {
    print('❌ Erreur QR: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.invalidQr),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => _scanned = false);
    _scannerController?.start();
  }
}
}

// ══════════════════════════════════════════════════════════════════════════
// ✅ DIALOG CONFIRMATION avec makeClientPayment()
class PaymentConfirmDialog extends StatefulWidget {
  final Map<String, dynamic> stationData;
  final UserModel? cachedUser;
  final CardModel? cachedCard;

  const PaymentConfirmDialog({
    super.key,
    required this.stationData,
    this.cachedUser,
    this.cachedCard,
  });

  @override
  State<PaymentConfirmDialog> createState() => _PaymentConfirmDialogState();
}

class _PaymentConfirmDialogState extends State<PaymentConfirmDialog> {
  bool _isProcessing = false;

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]} ',
      );

      void _showSnack(String msg, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
    ),
  );
}

Future<void> _processPayment() async {
  if (_isProcessing) return; // ← GARDE anti-double-appui
  setState(() => _isProcessing = true);

  final t = AppLocalizations.of(context);
  final txService = TransactionService();

  UserModel? user = widget.cachedUser;
  if (user == null) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final res = await authService.loadUserProfile();
    if (res['success'] == true) {
      user = res['user'] as UserModel;
    }
  }

  if (user == null) {
    setState(() => _isProcessing = false);
    _showSnack('Impossible de charger le profil', Colors.red);
    return;
  }

  final data = widget.stationData;
  final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
  final productId = int.tryParse(data['productId']?.toString() ?? '') ?? 0;
  final stationId = (data['stationId'] as num?)?.toInt()
      ?? int.tryParse(data['stationId']?.toString() ?? '0') ?? 0;
  final cardRef = widget.cachedCard?.reference;
  final pompisteUsername = data['pompisteId']?.toString() ?? '';
  final clientUserId = user.id?.toString() ?? '';

  // Validations
  if (productId == 0) { _showSnack('Produit invalide', Colors.orange); setState(() => _isProcessing = false); return; }
  if (cardRef == null || cardRef.isEmpty) { _showSnack('Carte introuvable', Colors.red); setState(() => _isProcessing = false); return; }
  if (stationId == 0) { _showSnack('Station invalide', Colors.orange); setState(() => _isProcessing = false); return; }

  debugPrint('💳 pompisteUsername: $pompisteUsername');
  debugPrint('💳 clientUserId: $clientUserId');

  final result = await txService.makeClientPayment(
    cardReference: cardRef,
    amount: amount,
    productId: productId,
    stationId: stationId,
    pompisteUsername: pompisteUsername,
    clientUserId: clientUserId,
    stationName: data['stationName']?.toString(),
  );

  if (!mounted) return;

  if (result['success'] == true) {
    debugPrint('✅ Paiement réussi: ${result['transactionId']}');

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
            'Votre paiement de ${_fmt(amount)} FCFA a été\neffectué avec succès.',
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
  } else {
    setState(() => _isProcessing = false); // ← réactiver seulement en cas d'échec

    final error = result['error']?.toString().toLowerCase() ?? '';
    String message;
    if (error.contains('solde') || error.contains('insufficient') || error.contains('balance')) {
      message = '❌ Solde insuffisant';
    } else {
      message = '❌ ${result['error'] ?? t.unknownError}';
    }
    debugPrint('❌ Paiement échoué: $message');
    _showSnack(message, Colors.red);
  }
}
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final data = widget.stationData;

    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final stationName = data['stationName']?.toString() ?? 'Station';
    final pompisteName = data['pompisteName']?.toString() ?? '';
    final companyName = data['companyName']?.toString() ?? '';
    final productName = data['productName']?.toString() ?? '';

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        t.confirmPaymentTitle,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_gas_station_outlined,
                      color: Color(0xFF1565C0),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stationName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D1B2A),
                        ),
                      ),
                    ),
                  ],
                ),
                if (pompisteName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          color: Color(0xFF1565C0), size: 16),
                      const SizedBox(width: 8),
                      Text(pompisteName,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ],
                if (companyName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.business_outlined,
                          color: Color(0xFF1565C0), size: 16),
                      const SizedBox(width: 8),
                      Text(companyName,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ],
                if (productName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.local_offer_outlined,
                          color: Color(0xFF1565C0), size: 16),
                      const SizedBox(width: 8),
                      Text(productName,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${_fmt(amount)} FCFA',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2563EB),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.debitedFrom,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context, false),
          child: Text(
            t.annuler,
            style: const TextStyle(color: Colors.red),
          ),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  t.confirmer,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ],
    );
  }
}