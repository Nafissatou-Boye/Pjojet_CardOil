import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../langue/app_localizations.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _service = TransactionService();
  List<TransactionModel>? _transactions;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getTransactions();
      if (mounted) setState(() { _transactions = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

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
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
              tooltip: 'Actualiser',
            ),
          ],
        ),
        body: _buildBody(t),
      ),
    );
  }

  Widget _buildBody(AppLocalizations t) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    }

    if (_error != null) {
      return _buildError(_error!, t);
    }

    final txs = _transactions ?? [];
    if (txs.isEmpty) return _buildEmptyState(t);

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF2563EB),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: txs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _buildCard(txs[i], t),
      ),
    );
  }

  Widget _buildCard(TransactionModel tx, AppLocalizations t) {
    final isPayment = tx.type.toUpperCase() == 'PAYMENT' ||
        tx.type.toUpperCase() == 'VENTE';
    final isCompleted = tx.status == 'completed' || tx.status == 'success' ||
        tx.status == 'COMPLETED' || tx.status == 'SUCCESS';

    final color = isPayment ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final icon = isPayment ? Icons.payments_rounded : Icons.account_balance_wallet_rounded;

    final amountStr = tx.amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        // Icône
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 14),

        // Infos
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPayment ? t.paymentLabel : t.rechargeLabel,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 3),
            if (tx.compagnie.isNotEmpty)
              Text(tx.compagnie,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            if (tx.method.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(children: [
                Icon(Icons.credit_card_outlined, size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(tx.method.toUpperCase(),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ]),
            ],
            const SizedBox(height: 3),
            Row(children: [
              Icon(Icons.access_time_rounded, size: 11, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd/MM/yyyy à HH:mm').format(tx.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ]),
            if (tx.cashbackEarned > 0) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.star_rounded, size: 13, color: Colors.amber.shade600),
                const SizedBox(width: 4),
                Text(
                  t.cashbackLine(tx.cashbackEarned),
                  style: TextStyle(fontSize: 11, color: Colors.amber.shade700, fontWeight: FontWeight.w600),
                ),
              ]),
            ],
          ],
        )),

        const SizedBox(width: 10),

        // Montant + statut
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '${isPayment ? "-" : "+"}$amountStr',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          const Text('FCFA', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFFBBF24),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildEmptyState(AppLocalizations t) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
          child: Icon(Icons.receipt_long_outlined, size: 44, color: Colors.grey.shade300),
        ),
        const SizedBox(height: 20),
        Text(t.noTransactionYet,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
        const SizedBox(height: 8),
        Text(t.noTransactionSub,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.5)),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
          label: const Text('Actualiser', style: TextStyle(color: Color(0xFF2563EB))),
        ),
      ],
    ));
  }

  Widget _buildError(String error, AppLocalizations t) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(t.loadingError,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
        const SizedBox(height: 8),
        Text(error, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Réessayer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    ));
  }
}