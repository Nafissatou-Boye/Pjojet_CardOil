// lib/screens/corporate/corporate_history_screen.dart
// ✅ CORRECTIONS :
//   1. Spinner infini → hasError affiché, connectionState.waiting ≠ hasData
//   2. initializeDateFormatting pour éviter LocaleDataException
//   3. Badge non-lues dans le header
//   4. Tri côté client (pas d'orderBy → pas d'index requis)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅
import '../../services/notification_service.dart';

class CorporateHistoryScreen extends StatefulWidget {
  final String userId;
  const CorporateHistoryScreen({super.key, required this.userId});

  @override
  State<CorporateHistoryScreen> createState() =>
      _CorporateHistoryScreenState();
}

class _CorporateHistoryScreenState extends State<CorporateHistoryScreen> {
  String _filterType = 'tous';
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null); // ✅ Fix LocaleDataException
  }

  String _fmt(double v) => NumberFormat('#,###', 'fr_FR').format(v);
  String _fmtDate(DateTime d) =>
      DateFormat('dd MMM yyyy • HH:mm', 'fr_FR').format(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(context),
          _buildFilters(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Row(
            children: [
              const Text('Historique',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const Spacer(),

              // ✅ Badge notifications non lues
              StreamBuilder<int>(
                stream: NotificationService().unreadCount(widget.userId),
                builder: (context, snap) {
                  final count = snap.data ?? 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.notifications_rounded,
                            color: Colors.white, size: 20),
                      ),
                      if (count > 0)
                        Positioned(
                          top: -4,
                          right: 6,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle),
                            child: Center(
                              child: Text(
                                count > 9 ? '9+' : '$count',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              // Filtre date
              GestureDetector(
                onTap: () => _pickDateRange(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _dateRange == null
                            ? 'Toutes dates'
                            : '${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                      ),
                      if (_dateRange != null) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _dateRange = null),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 14),
                        ),
                      ],
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

  // ── Filtres ──────────────────────────────────────────────────────────────
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
          final isSelected = _filterType == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _filterType = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6)
                  ],
                ),
                child: Text(f.$2,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF6B7280))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Liste ────────────────────────────────────────────────────────────────
  Widget _buildList() {
    // ✅ Pas d'orderBy → pas d'index composite requis
    Query query = FirebaseFirestore.instance
        .collection('client_transactions')
        .where('clientId', isEqualTo: widget.userId);

    if (_filterType != 'tous') {
      query = query.where('type', isEqualTo: _filterType);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {

        // ✅ FIX SPINNER INFINI : distinguer waiting vs hasData vs erreur
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final err = snapshot.error.toString();
          final isIndex = err.contains('index') || err.contains('Index') ||
              err.contains('failed-precondition');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isIndex
                        ? Icons.warning_amber_rounded
                        : Icons.error_outline,
                    size: 56,
                    color: isIndex
                        ? Colors.orange.shade300
                        : Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isIndex
                        ? 'Index Firestore manquant'
                        : 'Erreur de chargement',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isIndex
                        ? 'Firebase Console → Firestore → Index\n'
                            'Collection: client_transactions\n'
                            'Champs: clientId ↑ + createdAt ↓'
                        : err,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.5),
                  ),
                ],
              ),
            ),
          );
        }

        // ✅ Tri côté client pour éviter l'index Firestore
        var docs = [...(snapshot.data?.docs ?? [])];
        docs.sort((a, b) {
          final aT =
              ((a.data() as Map)['createdAt'] as Timestamp?)?.toDate();
          final bT =
              ((b.data() as Map)['createdAt'] as Timestamp?)?.toDate();
          if (aT == null && bT == null) return 0;
          if (aT == null) return 1;
          if (bT == null) return -1;
          return bT.compareTo(aT);
        });

        // Filtre date côté client
        if (_dateRange != null) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final d = (data['createdAt'] as Timestamp?)?.toDate();
            if (d == null) return false;
            return !d
                    .isBefore(_dateRange!.start
                        .subtract(const Duration(days: 1))) &&
                !d.isAfter(
                    _dateRange!.end.add(const Duration(days: 1)));
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle),
                  child: Icon(Icons.receipt_long_outlined,
                      size: 38, color: Colors.grey.shade300),
                ),
                const SizedBox(height: 16),
                const Text('Aucune transaction trouvée',
                    style: TextStyle(
                        color: Color(0xFF9CA3AF), fontSize: 15)),
                const SizedBox(height: 6),
                Text(
                    _filterType != 'tous'
                        ? 'Modifiez les filtres pour voir plus de résultats'
                        : 'Vos transactions apparaîtront ici',
                    style: const TextStyle(
                        color: Color(0xFFB0B7C3), fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _buildCard(context, data);
          },
        );
      },
    );
  }

  // ── Carte transaction ────────────────────────────────────────────────────
  Widget _buildCard(BuildContext context, Map<String, dynamic> data) {
    final amount = (data['amount'] ?? 0).toDouble();
    final type = data['type']?.toString() ?? 'PAYMENT';
    final isDebit = type == 'PAYMENT' || type == 'debit';
    final date = (data['createdAt'] as Timestamp?)?.toDate();
    final station = data['stationName']?.toString() ??
        data['station']?.toString() ??
        '—';
    final service =
        data['serviceType']?.toString() ?? data['product']?.toString() ?? '';
    final status =
        data['status']?.toString() ?? 'completed';
    final isDone = status == 'completed' || status == 'success';

    return GestureDetector(
      onTap: () => _showDetail(context, data),
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
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Icône
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

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDebit
                        ? 'Paiement${service.isNotEmpty ? ' · $service' : ''}'
                        : 'Crédit reçu',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 3),
                  Text(station,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9CA3AF))),
                  if (date != null) ...[
                    const SizedBox(height: 2),
                    Text(_fmtDate(date),
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFB0B7C3))),
                  ],
                ],
              ),
            ),

            // Montant + statut
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isDebit ? "-" : "+"}${_fmt(amount)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: isDebit
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF22C55E)),
                ),
                const Text('FCFA',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF))),
                const SizedBox(height: 4),
                // ✅ Badge statut
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
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
                            : Colors.orange),
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

  // ── Détail modal ─────────────────────────────────────────────────────────
  void _showDetail(BuildContext context, Map<String, dynamic> data) {
    final amount = (data['amount'] ?? 0).toDouble();
    final type = data['type']?.toString() ?? 'PAYMENT';
    final isDebit = type == 'PAYMENT' || type == 'debit';
    final date = (data['createdAt'] as Timestamp?)?.toDate();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
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
              '${isDebit ? "-" : "+"}${_fmt(amount)} FCFA',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDebit
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF22C55E)),
            ),
            const SizedBox(height: 4),
            Text(isDebit ? 'Paiement' : 'Crédit reçu',
                style: const TextStyle(
                    color: Color(0xFF9CA3AF), fontSize: 14)),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            if (data['stationName'] != null)
              _detRow('Station', data['stationName']),
            if (data['serviceType'] != null)
              _detRow('Service', data['serviceType']),
            if (data['product'] != null)
              _detRow('Produit', data['product']),
            if (data['pompisteName'] != null)
              _detRow('Pompiste', data['pompisteName']),
            if (date != null) _detRow('Date', _fmtDate(date)),
            if (data['transactionRef'] != null)
              _detRow('Référence',
                  data['transactionRef'].toString().substring(0, 12)),
            _detRow(
                'Statut',
                (data['status'] == 'completed' ||
                        data['status'] == 'success')
                    ? '✅ Validé'
                    : '⏳ En attente'),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Fermer',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF9CA3AF), fontSize: 14)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1F2937))),
          ],
        ),
      );

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
                primary: Color(0xFF2563EB))),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateRange = picked);
  }
}