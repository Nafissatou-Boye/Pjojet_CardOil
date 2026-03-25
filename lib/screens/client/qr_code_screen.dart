// lib/screens/client/qr_code_screen.dart
//
// ✅ PaymentDialog utilise TransactionService.createVente()
//    POST /api/transactions/vente/{username}/{clientId}/{amount}/{productId}
//    Body : { "id": stationId, "companyName": "string" }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/transaction_service.dart';
import '../../models/models.dart';
import '../../langue/app_localizations.dart';
import 'client_receipt_screen.dart';

enum QRMode { scanner, myCard }

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

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
    if (_currentMode == QRMode.scanner) {
      _scannerController = MobileScannerController();
    }
    _prefetchUser();
  }

  Future<void> _prefetchUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.loadUserProfile();
    if (result['success'] == true && mounted) {
      setState(() => _cachedUser = result['user'] as UserModel);
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
          title: Text(_currentMode == QRMode.myCard
              ? t.myQrCode
              : t.scanQrTitle),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(_currentMode == QRMode.myCard
                  ? Icons.qr_code_scanner
                  : Icons.qr_code),
              onPressed: _switchMode,
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
    if (_cachedUser == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final user = _cachedUser!;

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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: jsonEncode({
                        'uid': user.uid,
                        'type': 'CLIENT',
                        'compagnie': user.selectedCompagnie,
                        'qrCode': user.qrCode,
                      }),
                      version: QrVersions.auto,
                      size: 250,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(user.qrCode,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text(user.fullName,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${t.balance}: ${user.balance.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _switchMode,
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(t.scanQrStation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              children: [
                Text(t.scanQrTitle,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Text(t.scanQrSub,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  void _handleScannedQR(String qrData, AppLocalizations t) async {
    try {
      final data = jsonDecode(qrData) as Map<String, dynamic>;

      if (data['type'] != 'STATION') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t.notStationQr),
            backgroundColor: Colors.orange,
          ));
        }
        setState(() => _scanned = false);
        return;
      }

      _scannerController?.stop();

      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PaymentDialog(
          // ── Path params ─────────────────────────────────────
          pompisteUsername: data['pompisteUsername']?.toString() ?? '',
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          productId: data['productId']?.toString() ?? '',
          // ── Body ────────────────────────────────────────────
          stationId: (data['stationId'] as num?)?.toInt() ?? 0,
          companyName: data['companyName']?.toString() ?? '',
          // ── Affichage ────────────────────────────────────────
          stationName: data['stationName']?.toString() ?? t.station,
          pompisteName: data['pompisteName']?.toString() ?? '',
          cachedUser: _cachedUser,
        ),
      );

      if (confirmed == true) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t.paymentSuccessMsg),
            backgroundColor: Colors.green,
          ));
        }
      } else {
        setState(() => _scanned = false);
        _scannerController?.start();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t.invalidQr),
          backgroundColor: Colors.red,
        ));
      }
      setState(() => _scanned = false);
      _scannerController?.start();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENT DIALOG
// POST /api/transactions/vente/{username}/{clientId}/{amount}/{productId}
// Body : { "id": stationId, "companyName": "..." }
// ─────────────────────────────────────────────────────────────────────────────

class PaymentDialog extends StatefulWidget {
  // ── Path params ──────────────────────────────────────────────
  final String pompisteUsername;   // {username}
  final double amount;             // {amount}  — affiché + envoyé
  final String productId;          // {productId}
  // ── Body ────────────────────────────────────────────────────
  final int stationId;             // body.id
  final String companyName;        // body.companyName
  // ── Affichage seul ──────────────────────────────────────────
  final String stationName;
  final String pompisteName;
  final UserModel? cachedUser;

  const PaymentDialog({
    super.key,
    required this.pompisteUsername,
    required this.amount,
    required this.productId,
    required this.stationId,
    required this.companyName,
    required this.stationName,
    required this.pompisteName,
    this.cachedUser,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  bool _isProcessing = false;

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    final t = AppLocalizations.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final txService = TransactionService();

    // ── Récupère le user ────────────────────────────────────
    UserModel? user = widget.cachedUser;
    if (user == null) {
      final result = await authService.loadUserProfile();
      if (result['success'] == true) user = result['user'] as UserModel;
    }
    if (user == null) { Navigator.pop(context, false); return; }

    final token = await authService.getToken();
    if (token == null) { Navigator.pop(context, false); return; }

    // ── Appel createVente ───────────────────────────────────
    final result = await txService.createVente(
      //token: token,
      username: widget.pompisteUsername,
      clientId: int.tryParse(user.uid) ?? 0,
      amount: widget.amount.toStringAsFixed(0),
      productId: widget.productId,
      stationId: widget.stationId,
      companyName: widget.companyName,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pop(context, true);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClientReceiptScreen(data: {
            'transactionId': result['data']?.toString() ?? '',
            'amount': widget.amount,
            'clientName': user!.fullName,
            'qrCode': user.qrCode,
            'product': widget.productId,
            'stationName': widget.stationName,
            'compagnie': widget.companyName,
            'loyaltyPoints': (widget.amount / 100).round(),
            'createdAt': DateTime.now(),
          }),
        ),
      );
    } else {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['error'] ?? t.unknownError),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(t.confirmPaymentTitle,
          style: const TextStyle(fontWeight: FontWeight.w800)),
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
              children: [
                Row(children: [
                  const Icon(Icons.local_gas_station_outlined,
                      color: Color(0xFF1565C0), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(widget.stationName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0D1B2A)))),
                ]),
                if (widget.pompisteName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.person_outline,
                        color: Color(0xFF1565C0), size: 16),
                    const SizedBox(width: 8),
                    Text(widget.pompisteName,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                  ]),
                ],
                if (widget.companyName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.business_outlined,
                        color: Color(0xFF1565C0), size: 16),
                    const SizedBox(width: 8),
                    Text(widget.companyName,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                  ]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('${_fmt(widget.amount)} FCFA',
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2563EB),
                  letterSpacing: -1)),
          const SizedBox(height: 4),
          Text(t.debitedFrom,
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
      actions: [
        TextButton(
          onPressed:
              _isProcessing ? null : () => Navigator.pop(context, false),
          child: Text(t.annuler,
              style: const TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(Colors.white)))
              : Text(t.confirmer,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}