// lib/screens/corporate/corporate_history_screen.dart
// ✅ FIX : FutureBuilder + getTransactions() au lieu de StreamBuilder brisé

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../services/corporate_service.dart';
import '../../services/transaction_service.dart';
import '../../models/transaction_model.dart';

class CorporateHistoryScreen extends StatefulWidget {
  final String userId;
  const CorporateHistoryScreen({super.key, required this.userId});

  @override
  State<CorporateHistoryScreen> createState() => _CorporateHistoryScreenState();
}

class _CorporateHistoryScreenState extends State<CorporateHistoryScreen> {
  String _filterType = 'tous';
  DateTimeRange? _dateRange;
  List<StationTransactionModel>? _transactions;
  bool _loading = true;
  String? _error;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        TransactionService().getTransactions(forceRefresh: forceRefresh),
        CorporateService().getUnreadCount(),
      ]);
      if (!mounted) return;
      setState(() {
        _transactions = results[0] as List<StationTransactionModel>;
        _unreadCount = results[1] as int;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _fmt(double v) => NumberFormat('#,###', 'fr_FR').format(v);
  String _fmtDate(DateTime d) =>
      DateFormat('dd MMM yyyy HH:mm', 'fr_FR').format(d);

  List<StationTransactionModel> get _filtered {
    var list = List<StationTransactionModel>.from(_transactions ?? []);

   if (_filterType == 'PAYMENT') {
  list = list.where((tx) =>
     tx.transactionType == TransactionType.payment
  ).toList();
} else if (_filterType == 'CREDIT') {
  list = list.where((tx) =>
      tx.transactionType == TransactionType.recharge
  ).toList();
}
    if (_dateRange != null) {
      list = list.where((tx) =>
          !tx.createdAt.isBefore(
              _dateRange!.start.subtract(const Duration(days: 1))) &&
          !tx.createdAt
              .isAfter(_dateRange!.end.add(const Duration(days: 1)))).toList();
    }

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(children: [
        _buildHeader(context),
        _buildFilters(),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6)]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Row(children: [
            const Text('Historique',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const Spacer(),
            // Badge notifications
            Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 40, height: 40,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.notifications_rounded,
                    color: Colors.white, size: 20)),
              if (_unreadCount > 0)
                Positioned(
                  top: -4, right: 6,
                  child: Container(
                    width: 18, height: 18,
                    decoration: const BoxDecoration(
                        color: Color(0xFFEF4444), shape: BoxShape.circle),
                    child: Center(
                        child: Text(
                      _unreadCount > 9 ? '9+' : '$_unreadCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    )))),
            ]),
            // Filtre date
            GestureDetector(
              onTap: () => _pickDateRange(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _dateRange == null
                        ? 'Toutes dates'
                        : '${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)}',
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                  if (_dateRange != null) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                        onTap: () => setState(() => _dateRange = null),
                        child: const Icon(Icons.close, color: Colors.white, size: 14))
                  ],
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filters = [
      ('tous', 'Tous'),
      ('PAYMENT', 'Paiements'),
      ('CREDIT', 'Crédits'),
    ];
    return Container(
      color: const Color(0xFFF5F7FA),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: filters.map((f) {
          final sel = _filterType == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _filterType = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF2563EB) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 6)
                  ],
                ),
                child: Text(f.$2,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : const Color(0xFF6B7280))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    }

    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(_error!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Réessayer'),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white),
        ),
      ]));
    }

    final docs = _filtered;
    if (docs.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration:
              BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
          child:
              Icon(Icons.receipt_long_outlined, size: 38, color: Colors.grey.shade300)),
        const SizedBox(height: 16),
        const Text('Aucune transaction',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 15)),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => _load(forceRefresh: true),
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
          label: const Text('Actualiser',
              style: TextStyle(color: Color(0xFF2563EB))),
        ),
      ]));
    }

    return RefreshIndicator(
      onRefresh: () => _load(forceRefresh: true),
      color: const Color(0xFF2563EB),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        itemCount: docs.length,
        itemBuilder: (ctx, i) => _buildCard(ctx, docs[i]),
      ),
    );
  }

Widget _buildCard(BuildContext context, StationTransactionModel tx) {
  final isDebit = tx.isDebit;
  final isDone = tx.status == TransactionStatus.success;

  return GestureDetector(
    onTap: () => _showDetail(context, tx),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // ICON
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isDebit
                  ? const Color(0xFFEF4444).withOpacity(0.1)
                  : const Color(0xFF22C55E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDebit
                  ? Icons.local_gas_station_rounded
                  : Icons.account_balance_wallet_rounded,
              color: isDebit
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF22C55E),
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          // INFOS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.productLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 3),

                Text(
                  tx.stationName.isNotEmpty ? tx.stationName : '—',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  _fmtDate(tx.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB0B7C3),
                  ),
                ),
              ],
            ),
          ),

          // MONTANT + STATUS
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tx.sign}${_fmt(tx.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: isDebit
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF22C55E),
                ),
              ),
              const Text(
                'FCFA',
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 4),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF22C55E).withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isDone ? 'OK' : 'En attente',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDone
                        ? const Color(0xFF22C55E)
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 6),
          const Icon(Icons.chevron_right,
              color: Color(0xFFD1D5DB), size: 20),
        ],
      ),
    ),
  );
}
 void _showDetail(BuildContext context, StationTransactionModel tx) {
  final isDebit = tx.isDebit;
  final isDone = tx.status == TransactionStatus.success;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDebit
                  ? const Color(0xFFEF4444).withOpacity(0.1)
                  : const Color(0xFF22C55E).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDebit ? Icons.arrow_upward : Icons.arrow_downward,
              color: isDebit
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF22C55E),
              size: 30,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            '${tx.sign}${_fmt(tx.amount)} FCFA',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isDebit
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF22C55E),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            isDebit ? 'Paiement' : 'Recharge',
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          _det('Produit', tx.productLabel),
          _det('Station', tx.stationName),
          _det('Date', _fmtDate(tx.createdAt)),
          _det('Type', isDebit ? 'Paiement' : 'Recharge'),
          _det('Statut', isDone ? 'Succès' : 'En attente'),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Fermer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _det(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
      Text(value,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1F2937))),
    ]));

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB))),
        child: child!));
    if (picked != null) setState(() => _dateRange = picked);
  }
}