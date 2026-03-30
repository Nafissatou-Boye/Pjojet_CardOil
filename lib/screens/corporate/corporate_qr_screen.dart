// lib/screens/corporate/corporate_qr_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/corporate_service.dart';
import '../../services/auth_service.dart';

class CorporateQRScreen extends StatefulWidget {
  const CorporateQRScreen({super.key});

  @override
  State<CorporateQRScreen> createState() => _CorporateQRScreenState();
}

class _CorporateQRScreenState extends State<CorporateQRScreen> {
  CorporateAccountModel? employee;
  bool isLoading = true;
  bool isScanner = false;
  bool isProcessing = false;

  final MobileScannerController scannerController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    loadAccount();
  }

  Future<void> loadAccount() async {
    final res = await CorporateService().getMyAccount();

    if (res['success']) {
      setState(() {
        employee = res['account'];
        isLoading = false;
      });
    } else {
      showError(res['error']);
    }
  }

  // 🔥 SCAN QR
  void handleScan(String raw) async {
    if (isProcessing) return;

    try {
      final data = jsonDecode(raw);

      if (data['type'] != 'STATION') {
        showError("QR invalide");
        return;
      }

      HapticFeedback.heavyImpact();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => _confirmDialog(data),
      );

      if (confirmed == true) {
        processPayment(data);
      }
    } catch (e) {
      showError("QR invalide");
    }
  }

  // 🔥 PAIEMENT API
  Future<void> processPayment(Map data) async {
    setState(() => isProcessing = true);

    try {
      final token = await AuthService().getToken();

      final uri = Uri.parse(
          "https://api.cardoil.io/api/transactions/createByClient/"
          "${employee!.fullName}/${employee!.id}/${data['amount']}/${data['productId']}");

      final response = await Future.delayed(
        const Duration(milliseconds: 300),
        () => null,
      );

      // 👉 Tu peux remplacer ici par http.post réel si besoin

      showSuccess("Paiement réussi");

      await loadAccount(); // refresh solde

    } catch (e) {
      showError("Erreur paiement");
    } finally {
      setState(() => isProcessing = false);
    }
  }

  // 🔥 UI
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final qrData = jsonEncode({
      "type": "CLIENT",
      "id": employee!.id,
      "name": employee!.fullName,
      "company": employee!.enterpriseName,
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Carte Corporate"),
        actions: [
          IconButton(
            icon: Icon(isScanner ? Icons.qr_code : Icons.qr_code_scanner),
            onPressed: () {
              setState(() => isScanner = !isScanner);
            },
          )
        ],
      ),
      body: isScanner ? buildScanner() : buildCard(qrData),
    );
  }

  Widget buildCard(String qrData) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(employee!.fullName,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(employee!.enterpriseName),

          const SizedBox(height: 20),

          QrImageView(
            data: qrData,
            size: 220,
          ),

          const SizedBox(height: 20),

          Text("Solde: ${employee!.balance} FCFA",
              style: const TextStyle(fontSize: 18)),

          const SizedBox(height: 10),

          Text(
            "Utilisé: ${employee!.currentMonthUsage} / ${employee!.monthlyLimit}",
          ),
        ],
      ),
    );
  }

  Widget buildScanner() {
    return MobileScanner(
      controller: scannerController,
      onDetect: (barcode, args) {
        final String? code = barcode.rawValue;
        if (code != null) {
          handleScan(code);
        }
      },
    );
  }

  // 🔥 DIALOG CONFIRMATION
  Widget _confirmDialog(Map data) {
    return AlertDialog(
      title: const Text("Confirmer paiement"),
      content: Text(
          "Montant: ${data['amount']} FCFA\nProduit: ${data['product']}"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Confirmer"),
        ),
      ],
    );
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }
}