// lib/screens/corporate/corporate_qr_screen.dart
// ✅ CORRECTIONS :
//   1. onDetect → nouvelle API BarcodeCapture (mobile_scanner >= 3.x)
//   2. client_transactions inclut 'status': 'completed' pour l'historique
//   3. BOTTOM OVERFLOW fix dans le dialog

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../../models/corporate_employee_model.dart';

enum CorporateQRMode { myCard, scanner }

class CorporateQRScreen extends StatefulWidget {
  final String userId;
  const CorporateQRScreen({super.key, required this.userId});

  @override
  State<CorporateQRScreen> createState() => _CorporateQRScreenState();
}

class _CorporateQRScreenState extends State<CorporateQRScreen>
    with SingleTickerProviderStateMixin {
  CorporateQRMode _mode = CorporateQRMode.myCard;
  MobileScannerController? _scannerCtrl;
  bool _scanned = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scannerCtrl?.dispose();
    super.dispose();
  }

  void _switchToScanner() {
    setState(() {
      _mode = CorporateQRMode.scanner;
      _scanned = false;
      _scannerCtrl = MobileScannerController(
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    });
  }

  void _switchToCard() {
    _scannerCtrl?.dispose();
    setState(() {
      _mode = CorporateQRMode.myCard;
      _scannerCtrl = null;
      _scanned = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E40AF),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('corporate_employees')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
          final employee = CorporateEmployeeModel.fromFirestore(snap.data!);
          return Column(
            children: [
              _buildHeader(employee),
              Expanded(
                child: _mode == CorporateQRMode.myCard
                    ? _buildCardView(employee)
                    : _buildScannerView(employee),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(CorporateEmployeeModel employee) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFF1E40AF), Color(0xFF2563EB)]),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ma Carte Corporate',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    Text(employee.enterpriseName,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.75))),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _mode == CorporateQRMode.myCard
                    ? _switchToScanner
                    : _switchToCard,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Icon(
                          _mode == CorporateQRMode.myCard
                              ? Icons.qr_code_scanner
                              : Icons.qr_code_2_rounded,
                          color: Colors.white,
                          size: 18),
                      const SizedBox(width: 6),
                      Text(
                          _mode == CorporateQRMode.myCard
                              ? 'Scanner'
                              : 'Ma carte',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardView(CorporateEmployeeModel employee) {
    final remaining = employee.isCapped
        ? employee.monthlyLimit - employee.currentMonthUsage
        : employee.cumulativeBalance;
    String fmt(double v) => v
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]} ');

    final qrData = jsonEncode({
      'type': 'CLIENT',
      'uid': widget.userId,
      'enterpriseId': employee.enterpriseId,
      'enterpriseName': employee.enterpriseName,
      'employeeNumber': employee.employeeNumber,
      'fullName': employee.fullName,
      'accountType': employee.isCapped ? 'capped' : 'cumulative',
      'monthlyLimit': employee.monthlyLimit,
      'currentUsage': employee.currentMonthUsage,
      // ✅ compagnie pour compatibilité pompiste particulier
      'compagnie': employee.enterpriseName,
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 12))
              ],
            ),
            child: Column(
              children: [
                Text(employee.fullName,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E40AF))),
                const SizedBox(height: 4),
                Text(employee.enterpriseName,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF6B7280))),
                const SizedBox(height: 20),
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFF2563EB).withOpacity(0.2),
                            width: 2),
                        borderRadius: BorderRadius.circular(16)),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF1E40AF)),
                      dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF1F2937)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: const Color(0xFFEEF4FF),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(employee.employeeNumber,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                          letterSpacing: 1)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 1.5)),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          employee.isCapped
                              ? 'Solde disponible ce mois'
                              : 'Solde cumulé',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('${fmt(remaining)} FCFA',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: employee.hasReachedLimit
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                      employee.hasReachedLimit ? 'Plafond atteint' : 'Actif',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: _switchToScanner,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 1.5)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text('Scanner le QR de la station',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView(CorporateEmployeeModel employee) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28)),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  const Text('Scanner la station',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E40AF))),
                  const SizedBox(height: 6),
                  Text('Scannez le QR code du pompiste',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            // ✅ FIX : nouvelle API onDetect (BarcodeCapture)
                            MobileScanner(
  controller: _scannerCtrl!,
  onDetect: (barcode, args) {
    if (_scanned) return;

    final String? code = barcode.rawValue;
    if (code == null) return;

    setState(() => _scanned = true);

    HapticFeedback.heavyImpact();

    _handleScannedQR(code, employee);
  },
),
                            Positioned(
                              bottom: 14,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                      color:
                                          Colors.black.withOpacity(0.55),
                                      borderRadius:
                                          BorderRadius.circular(20)),
                                  child: const Text(
                                      'Pointez vers le QR du pompiste',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _switchToCard,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.4))),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Afficher ma carte',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleScannedQR(
      String rawValue, CorporateEmployeeModel employee) async {
    try {
      final data = jsonDecode(rawValue) as Map<String, dynamic>;
      if (data['type'] != 'STATION') {
        _showError('Ce QR n\'est pas un code de station');
        setState(() => _scanned = false);
        return;
      }
      _scannerCtrl?.stop();
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CorporatePaymentDialog(
          employee: employee,
          employeeDocId: widget.userId,
          stationId: data['stationId'] ?? '',
          stationName: data['stationName'] ?? 'Station',
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          product: data['product']?.toString() ?? '',
          transactionId: data['transactionId']?.toString() ?? '',
          pompisteName: data['pompisteName']?.toString() ?? '',
          pompisteId: data['pompisteId']?.toString() ?? '', // ✅ NOUVEAU
        ),
      );
      if (confirmed == true && mounted) {
        Navigator.pop(context);
      } else {
        setState(() => _scanned = false);
        _scannerCtrl?.start();
      }
    } catch (_) {
      _showError('QR invalide');
      setState(() => _scanned = false);
    }
  }

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12))));
}

// ══════════════════════════════════════════════════
// DIALOG PAIEMENT CORPORATE — ✅ CORRIGÉ COMPLET
// ══════════════════════════════════════════════════

class CorporatePaymentDialog extends StatefulWidget {
  final CorporateEmployeeModel employee;
  final String employeeDocId;
  final String stationId, stationName, product, transactionId, pompisteName;
  final String pompisteId; // ✅ NOUVEAU
  final double amount;

  const CorporatePaymentDialog({
    super.key,
    required this.employee,
    required this.employeeDocId,
    required this.stationId,
    required this.stationName,
    required this.amount,
    required this.product,
    required this.transactionId,
    required this.pompisteName,
    required this.pompisteId, // ✅
  });

  @override
  State<CorporatePaymentDialog> createState() =>
      _CorporatePaymentDialogState();
}

class _CorporatePaymentDialogState extends State<CorporatePaymentDialog> {
  bool _isProcessing = false;

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ');

  bool get _canPay {
    if (widget.employee.hasReachedLimit) return false;
    if (widget.employee.isCapped) {
      return widget.employee.currentMonthUsage + widget.amount <=
          widget.employee.monthlyLimit;
    }
    return widget.employee.cumulativeBalance >= widget.amount;
  }

  double get _remaining => widget.employee.isCapped
      ? widget.employee.monthlyLimit - widget.employee.currentMonthUsage
      : widget.employee.cumulativeBalance;

  Future<void> _processPayment() async {
    if (!_canPay) return;
    setState(() => _isProcessing = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // 1. ✅ Débiter corporate_employees (currentMonthUsage)
      batch.update(
        firestore
            .collection('corporate_employees')
            .doc(widget.employeeDocId),
        {
          'currentMonthUsage': FieldValue.increment(widget.amount),
          // Si compte cumulatif, débiter aussi le solde
          if (!widget.employee.isCapped)
            'cumulativeBalance': FieldValue.increment(-widget.amount),
        },
      );

      // 2. ✅ Compléter station_transaction (visible gérant/pompiste)
      if (widget.transactionId.isNotEmpty) {
        batch.update(
          firestore
              .collection('station_transactions')
              .doc(widget.transactionId),
          {
            'status': 'completed',
            'clientId': widget.employeeDocId,
            'clientName': widget.employee.fullName,
            'clientType': 'corporate',
            'enterpriseId': widget.employee.enterpriseId,
            'enterpriseName': widget.employee.enterpriseName,
            'paymentMethod': 'qr_corporate',
            'completedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      // 3. ✅ Créer client_transaction (visible historique client corporate)
      batch.set(firestore.collection('client_transactions').doc(), {
        'clientId': widget.employeeDocId,
        'clientName': widget.employee.fullName,
        'clientType': 'corporate',
        'enterpriseId': widget.employee.enterpriseId,
        'enterpriseName': widget.employee.enterpriseName,
        'stationId': widget.stationId,
        'stationName': widget.stationName,
        'pompisteName': widget.pompisteName,
        'pompisteId': widget.pompisteId, // ✅
        'transactionId': widget.transactionId,
        'transactionRef': widget.transactionId,
        'amount': widget.amount,
        'product': widget.product,
        'type': 'PAYMENT',
        'serviceType': widget.product,
        'status': 'completed', // ✅ FIX : manquait avant
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      // ✅ FIX OVERFLOW : SingleChildScrollView + insetPadding
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (_canPay
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFEF4444))
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                    _canPay
                        ? Icons.payments_rounded
                        : Icons.block_rounded,
                    color: _canPay
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFEF4444),
                    size: 30),
              ),
              const SizedBox(height: 16),
              const Text('Confirmer le paiement',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937))),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FF),
                    borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    _dRow(Icons.local_gas_station_outlined,
                        widget.stationName),
                    if (widget.pompisteName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _dRow(Icons.person_outline, widget.pompisteName)
                    ],
                    if (widget.product.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _dRow(Icons.local_gas_station_outlined, widget.product)
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text('${_fmt(widget.amount)} FCFA',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: _canPay
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFEF4444),
                      letterSpacing: -1)),
              const SizedBox(height: 4),
              Text(
                  _canPay
                      ? 'débité sur votre compte entreprise'
                      : 'Solde insuffisant ou plafond atteint',
                  style: TextStyle(
                      fontSize: 13,
                      color: _canPay
                          ? Colors.grey.shade500
                          : const Color(0xFFEF4444))),

              if (_canPay) ...[
                const SizedBox(height: 6),
                Text(
                    'Solde après : ${_fmt(_remaining - widget.amount)} FCFA',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing
                          ? null
                          : () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text('Annuler',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (_isProcessing || !_canPay)
                          ? null
                          : _processPayment,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Confirmer',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dRow(IconData icon, String text) => Row(children: [
        Icon(icon, color: const Color(0xFF1565C0), size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF0D1B2A)))),
      ]);
}