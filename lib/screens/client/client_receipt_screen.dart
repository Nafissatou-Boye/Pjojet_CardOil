import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../langue/app_localizations.dart';

class ClientReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const ClientReceiptScreen({super.key, required this.data});

  String _fmt(double v) => NumberFormat('#,###', 'fr_FR').format(v);
  String _fmtDate(DateTime d, AppLocalizations t) =>
      DateFormat("d MMM yyyy 'à' HH:mm", 'fr_FR').format(d);
  String _maskCard(String card) =>
      card.length < 4 ? card : '${'*' * (card.length - 4)}${card.substring(card.length - 4)}';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final stationName = data['stationName']?.toString() ?? t.station;
    final compagnie = data['compagnie']?.toString() ?? stationName;
    final stationLocation = data['stationLocation']?.toString() ?? 'Dakar, Sénégal';
    final reference = data['transactionId']?.toString() ?? '—';
    final clientName = data['clientName']?.toString() ?? '—';
    final card = data['qrCode']?.toString() ?? '';
    final product = data['product']?.toString() ?? '';
    final points = (data['loyaltyPoints'] as num?)?.toInt() ?? 0;
    final DateTime date =
        data['createdAt'] is DateTime ? data['createdAt'] : DateTime.now();

    return Directionality(
      textDirection: t.textDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F0F0),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Color(0xFFFF6D35), Color(0xFFFF3D00)]),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        Icons.arrow_back_ios_new,
                                        color: Colors.white,
                                        size: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.local_gas_station_rounded,
                                    color: Colors.white,
                                    size: 34),
                              ),
                              const SizedBox(height: 14),
                              Text(compagnie,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white)),
                              const SizedBox(height: 4),
                              Text(stationName,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.88))),
                              Text(stationLocation,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.72))),
                            ],
                          ),
                        ),
                      ),
                    ),

                  
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(24)),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 24,
                                offset: const Offset(0, 8))
                          ],
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 32),
                            Text(t.clientReceiptTitle,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A1A))),
                            const SizedBox(height: 28),

                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 28),
                              child: Column(
                                children: [
                                  _Row(t.date, _fmtDate(date, t)),
                                  _Row(t.reference,
                                      reference.length > 14
                                          ? reference.substring(0, 14)
                                          : reference),
                                  _Row(t.client, clientName),
                                  if (card.isNotEmpty)
  _Row('Carte:', _maskCard(card)),
                                ],
                              ),
                            ),

                            // Séparateur pointillé
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20),
                              child: Row(
                                children: List.generate(
                                    35,
                                    (i) => Expanded(
                                          child: Container(
                                              height: 1.5,
                                              color: i.isEven
                                                  ? Colors.grey.shade300
                                                  : Colors.transparent),
                                        )),
                              ),
                            ),

                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 28),
                              child: Column(
                                children: [
                                  if (product.isNotEmpty)
                                    _Row(t.product, product),
                                  if (points > 0)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 14),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(t.loyaltyPointsReceiptLabel,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF9CA3AF))),
                                          Row(children: [
                                            const Icon(Icons.star_rounded,
                                                color: Color(0xFFF59E0B),
                                                size: 20),
                                            const SizedBox(width: 4),
                                            Text('$points',
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        Color(0xFFF59E0B))),
                                          ]),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Box montant
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 28),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3F0),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: const Color(0xFFFF4500)
                                          .withOpacity(0.2)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(t.amountPaid,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1A1A1A))),
                                    Text('${_fmt(amount)} XOF',
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFFFF4500))),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),
                            Text(t.thankYou,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF9CA3AF),
                                    fontStyle: FontStyle.italic)),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          
            Container(
              color: const Color(0xFFF0F0F0),
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  // TODO: PDF download
                },
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFF6D35), Color(0xFFFF3D00)]),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFFF4500).withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.download_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(t.downloadReceipt,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF9CA3AF))),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A))),
            ),
          ],
        ),
      );
}