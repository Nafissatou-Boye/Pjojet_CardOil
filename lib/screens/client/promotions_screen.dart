// lib/screens/client/all_promotions_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/promotion_service.dart';
import '../../models/promotion_model.dart';
import 'promotion_detail_screen.dart';

class AllPromotionsScreen extends StatefulWidget {
  final int companyId;

  const AllPromotionsScreen({super.key, required this.companyId});

  @override
  State<AllPromotionsScreen> createState() => _AllPromotionsScreenState();
}

class _AllPromotionsScreenState extends State<AllPromotionsScreen> {
  final _promotionService = PromotionService();
  late Future<List<PromotionModel>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _promotionService.getAllPromotions(widget.companyId);
  }

  Future<void> _refresh() async {
    setState(() => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotions'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<PromotionModel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return _ErrorState(onRetry: _refresh);
          }

          final promotions = snap.data ?? [];

          if (promotions.isEmpty) {
            return _EmptyState(onRefresh: _refresh);
          }

          final activePromos = promotions.where((p) => p.isActive).toList();
          final expiredPromos = promotions.where((p) => !p.isActive).toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            color: const Color(0xFF2563EB),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activePromos.isNotEmpty) ...[
                    _SectionTitle(label: 'Promotions actives', count: activePromos.length),
                    const SizedBox(height: 12),
                    ...activePromos.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _PromotionCard(
                          promo: p,
                          isActive: true,
                          onTap: () => _openDetail(p.id),
                        ),
                      ),
                    ),
                  ],
                  if (expiredPromos.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionTitle(label: 'Promotions expirées', count: expiredPromos.length),
                    const SizedBox(height: 12),
                    ...expiredPromos.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _PromotionCard(
                          promo: p,
                          isActive: false,
                          onTap: null,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openDetail(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PromotionDetailScreen(promotionId: id),
      ),
    );
  }
}

// ── Widgets internes ─────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  final int count;

  const _SectionTitle({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('$count',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB))),
      ),
    ]);
  }
}

class _PromotionCard extends StatelessWidget {
  final PromotionModel promo;
  final bool isActive;
  final VoidCallback? onTap;

  const _PromotionCard({
    required this.promo,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = isActive ? _gradientColors() : [Colors.grey.shade300, Colors.grey.shade400];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Stack(children: [
          // Badge type
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(promo.typeLabel,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colors[0])),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Icône
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(_icon(), color: Colors.white, size: 28),
              ),

              const SizedBox(height: 16),

              // Nom
              Text(promo.name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),

              const SizedBox(height: 8),

              // Description
              if (promo.description != null)
                Text(promo.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.white70)),

              const SizedBox(height: 16),

              // Date de fin
              Row(children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  "Jusqu'au ${DateFormat('dd/MM/yyyy').format(promo.endDate)}",
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ]),

              // Points si pertinent
              if (promo.pointsMultiplier > 1) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.star, size: 14, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text('x${promo.pointsMultiplier.toStringAsFixed(1)} points',
                      style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ]),
              ],

              const SizedBox(height: 16),

              // Bouton
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: colors[0],
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isActive ? 'Voir les détails' : 'Expirée',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  List<Color> _gradientColors() {
    switch (promo.type) {
      case PromotionType.gift:
        return [const Color(0xFF10B981), const Color(0xFF34D399)];
      case PromotionType.scratch:
        return [const Color(0xFFDC2626), const Color(0xFFEF4444)];
      case PromotionType.points:
      default:
        return [const Color(0xFF2563EB), const Color(0xFF60A5FA)];
    }
  }

  IconData _icon() {
    switch (promo.type) {
      case PromotionType.gift:
        return Icons.card_giftcard;
      case PromotionType.scratch:
        return Icons.emoji_events;
      case PromotionType.points:
      default:
        return Icons.star;
    }
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.card_giftcard_outlined, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Aucune promotion disponible',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        Text('Les promotions apparaîtront ici',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Actualiser'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
        ),
      ]),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
        const SizedBox(height: 16),
        const Text('Erreur de chargement',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.red)),
        const SizedBox(height: 8),
        const Text('Vérifiez votre connexion et réessayez',
            style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Réessayer'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
        ),
      ]),
    );
  }
}