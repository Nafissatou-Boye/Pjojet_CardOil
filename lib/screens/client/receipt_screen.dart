// lib/screens/client/receipt_screen.dart
//
// ✅ getReceiptByTransaction() est maintenant Stream<ReceiptModel?>(transactionId)
//    — pas de token ni de named param requis depuis l'écran.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/transaction_service.dart';
import '../../models/receipt_model.dart';

class ReceiptScreen extends StatelessWidget {
  final String transactionId;

  const ReceiptScreen({
    super.key,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    final transactionService = TransactionService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reçu de paiement'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReceipt(context),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadReceipt(context),
          ),
        ],
      ),
      body: StreamBuilder<ReceiptModel?>(
        // ✅ Signature corrigée : positional param, pas de token requis ici
        stream: transactionService.getReceiptByTransaction(transactionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Reçu introuvable'));
          }

          final receipt = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // ── Header check vert ─────────────────────────
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Paiement réussi',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Card reçu ─────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildRow('Numéro de reçu', receipt.receiptNumber,
                          bold: true),
                      const Divider(height: 32),
                      _buildRow(
                        'Date',
                        DateFormat('dd/MM/yyyy à HH:mm')
                            .format(receipt.date),
                      ),
                      const SizedBox(height: 16),
                      _buildRow('Compagnie',
                          receipt.compagnie.toUpperCase()),
                      const SizedBox(height: 16),
                      _buildRow(
                          'Méthode de paiement', receipt.paymentMethod),
                      const Divider(height: 32),
                      _buildRow(
                        'Montant',
                        '${receipt.amount.toStringAsFixed(0)} FCFA',
                        valueColor: const Color(0xFF2563EB),
                        bold: true,
                        large: true,
                      ),
                      if (receipt.cashback > 0) ...[
                        const SizedBox(height: 16),
                        _buildRow(
                          'Cashback gagné',
                          '+${receipt.cashback.toStringAsFixed(0)} FCFA',
                          valueColor: const Color(0xFF10B981),
                          bold: true,
                        ),
                      ],
                      const Divider(height: 32),
                      _buildRow('Transaction ID', receipt.transactionId,
                          small: true),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Boutons ──────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _downloadReceipt(context),
                        icon: const Icon(Icons.download),
                        label: const Text('Télécharger'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(
                              color: Color(0xFF2563EB), width: 2),
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shareReceipt(context),
                        icon: const Icon(Icons.share),
                        label: const Text('Partager'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
    bool large = false,
    bool small = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: small ? 11 : 14, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: large ? 24 : (small ? 11 : 14),
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? const Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }

  void _downloadReceipt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Téléchargement du reçu...'),
        backgroundColor: Color(0xFF2563EB),
      ),
    );
  }

  void _shareReceipt(BuildContext context) {
    Share.share(
      'Reçu Card Oil\nMontant: XXX FCFA\nDate: XXX',
      subject: 'Reçu de paiement',
    );
  }
}