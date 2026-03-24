// lib/screens/client/history_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../langue/app_localizations.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Directionality(
      textDirection: t.textDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(t.historyTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: uid == null
            ? Center(child: Text(t.notConnected))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('client_transactions')
                    .where('clientId', isEqualTo: uid)
                    .orderBy('createdAt', descending: true)
                    .limit(50)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _buildError(snapshot.error.toString(), t);
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) return _buildEmptyState(t);

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return _buildTransactionCard(context, data, t);
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildTransactionCard(
      BuildContext context, Map<String, dynamic> data, AppLocalizations t) {
    final type = data['type']?.toString() ?? 'PAYMENT';
    final isPayment = type == 'PAYMENT';
    final amount = (data['amount'] ?? 0.0) as double;
    final status = data['status']?.toString() ?? 'completed';
    final isCompleted = status == 'completed' || status == 'success';

    final stationName = data['stationName']?.toString() ??
        data['compagnie']?.toString() ??
        data['enterpriseName']?.toString() ??
        '—';

    final product = data['product']?.toString() ??
        data['serviceType']?.toString() ??
        '';

    final cashback =
        (data['cashbackEarned'] ?? data['cashback'] ?? 0.0) as double;

    final createdAt = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();

    final clientType = data['clientType']?.toString() ?? 'individual';
    final isCorporate = clientType == 'corporate';

    final color =
        isPayment ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final icon = isCorporate
        ? Icons.business_center_rounded
        : isPayment
            ? Icons.payments_rounded
            : Icons.account_balance_wallet_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isPayment ? t.paymentLabel : t.rechargeLabel,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937)),
                    ),
                    if (isCorporate) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(t.corporateLabel,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB))),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(stationName,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500)),
                if (product.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.local_gas_station_outlined,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(product.toUpperCase(),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 11, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(DateFormat('dd/MM/yyyy à HH:mm').format(createdAt),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400)),
                  ],
                ),
                if (cashback > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 13, color: Colors.amber.shade600),
                      const SizedBox(width: 4),
                      Text(
                        t.cashbackLine(cashback),
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPayment ? "-" : "+"}${_fmt(amount)}',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w900, color: color),
              ),
              const SizedBox(height: 2),
              const Text('FCFA',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFFBBF24).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCompleted ? t.successLabel : t.pendingLabel,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isCompleted
                          ? const Color(0xFF10B981)
                          : const Color(0xFFFBBF24)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
                color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.receipt_long_outlined,
                size: 44, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 20),
          Text(t.noTransactionYet,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Text(t.noTransactionSub,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade500, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildError(String error, AppLocalizations t) {
    final isIndexError = error.contains('index') || error.contains('Index');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 56, color: Colors.orange.shade300),
            const SizedBox(height: 16),
            Text(isIndexError ? t.indexMissing : t.loadingError,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            Text(isIndexError ? t.createIndexHint : error,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
}