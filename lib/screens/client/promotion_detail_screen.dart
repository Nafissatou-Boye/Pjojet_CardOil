// lib/screens/client/promotion_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/promotion_service.dart';
import '../../models/promotion_model.dart';

class PromotionDetailScreen extends StatefulWidget {
  final int promotionId;

  const PromotionDetailScreen({super.key, required this.promotionId});

  @override
  State<PromotionDetailScreen> createState() => _PromotionDetailScreenState();
}

class _PromotionDetailScreenState extends State<PromotionDetailScreen> {
  final _promotionService = PromotionService();
  late Future<PromotionModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = _promotionService.getPromotion(widget.promotionId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PromotionModel?>(
      future: _future,
      builder: (context, snap) {
        // ── Chargement ──
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // ── Erreur / introuvable ──
        if (snap.hasError || snap.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Promotion'),
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                const Text('Promotion introuvable',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Retour'),
                ),
              ]),
            ),
          );
        }

        final promo = snap.data!;
        final colors = _gradientColors(promo.type);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ── Header ──
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: colors[0],
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    promo.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 10)],
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(_icon(promo.type),
                          size: 100, color: Colors.white.withOpacity(0.3)),
                    ),
                  ),
                ),
              ),

              // ── Contenu ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges
                      Row(children: [
                        _Badge(label: promo.typeLabel, color: colors[0]),
                        const SizedBox(width: 8),
                        if (promo.isActive)
                          const _Badge(label: 'ACTIF', color: Color(0xFF10B981))
                        else
                          _Badge(label: 'EXPIRÉ', color: Colors.grey.shade400),
                      ]),

                      const SizedBox(height: 24),

                      // Description
                      const Text('Description',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937))),
                      const SizedBox(height: 12),
                      Text(
                        promo.description ?? 'Aucune description disponible.',
                        style: TextStyle(
                            fontSize: 16, height: 1.5, color: Colors.grey.shade700),
                      ),

                      const SizedBox(height: 32),

                      // Période
                      _InfoSection(
                        title: 'Période de validité',
                        icon: Icons.calendar_today,
                        content:
                            'Du ${DateFormat('dd MMMM yyyy', 'fr_FR').format(promo.startDate)}\n'
                            'Au ${DateFormat('dd MMMM yyyy', 'fr_FR').format(promo.endDate)}',
                      ),

                      const SizedBox(height: 16),

                      // Points / multiplicateur
                      if (promo.pointsMultiplier > 1 || promo.pointsRequired > 0)
                        _InfoSection(
                          title: 'Points',
                          icon: Icons.star,
                          content: [
                            if (promo.pointsMultiplier > 1)
                              'Multiplicateur : x${promo.pointsMultiplier.toStringAsFixed(1)}',
                            if (promo.pointsRequired > 0)
                              'Points requis : ${promo.pointsRequired}',
                          ].join('\n'),
                        ),

                      if (promo.pointsMultiplier > 1 || promo.pointsRequired > 0)
                        const SizedBox(height: 16),

                      // Montant minimum
                      if (promo.minPurchaseAmount > 0)
                        _InfoSection(
                          title: 'Conditions',
                          icon: Icons.info_outline,
                          content:
                              'Achat minimum : ${promo.minPurchaseAmount.toStringAsFixed(0)} FCFA',
                        ),

                      const SizedBox(height: 32),

                      // Bouton d'action
                      if (promo.isActive)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => _showParticipationConfirm(context, promo),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors[0],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Participer',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showParticipationConfirm(BuildContext context, PromotionModel promo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la participation'),
        content: Text('Participer à "${promo.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnack(context, 'Participation enregistrée !', Colors.green);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _gradientColors(promo.type)[0]),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  List<Color> _gradientColors(PromotionType type) {
    switch (type) {
      case PromotionType.gift:
        return [const Color(0xFF10B981), const Color(0xFF34D399)];
      case PromotionType.scratch:
        return [const Color(0xFFDC2626), const Color(0xFFEF4444)];
      case PromotionType.points:
      default:
        return [const Color(0xFF2563EB), const Color(0xFF60A5FA)];
    }
  }

  IconData _icon(PromotionType type) {
    switch (type) {
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

// ── Widgets internes ─────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String content;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 20, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
        ]),
        const SizedBox(height: 12),
        Text(content,
            style: TextStyle(
                fontSize: 14, height: 1.5, color: Colors.grey.shade700)),
      ]),
    );
  }
}