// lib/screens/client/promotion_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/promotion_service.dart';
import '../../models/promotion_model.dart';

class PromotionDetailScreen extends StatelessWidget {
  final String promotionId;

  const PromotionDetailScreen({
    super.key,
    required this.promotionId,
  });

  @override
  Widget build(BuildContext context) {
    final promotionService = PromotionService();

    return StreamBuilder<PromotionModel?>(
      stream: promotionService.getPromotionStream(promotionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Promotion'),
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Text('Promotion introuvable'),
            ),
          );
        }

        final promo = snapshot.data!;
        final gradientColors = _getGradientColors(promo.type);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Header avec image/gradient
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: gradientColors[0],
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    promo.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: promo.image != null
                        ? Image.network(
                            promo.image!,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Icon(
                              _getIcon(promo.type),
                              size: 100,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                  ),
                ),
              ),

              // Contenu
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge type + statut
                      Row(
                        children: [
                          _buildBadge(
                            _getTypeLabel(promo.type),
                            gradientColors[0],
                          ),
                          const SizedBox(width: 8),
                          if (promo.isActive)
                            _buildBadge('ACTIF', const Color(0xFF10B981))
                          else
                            _buildBadge('EXPIRÉ', Colors.grey),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Description complète
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        promo.description,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Dates
                      _buildInfoSection(
                        'Période de validité',
                        Icons.calendar_today,
                        'Du ${DateFormat('dd MMMM yyyy', 'fr_FR').format(promo.startDate)}\n'
                        'Au ${DateFormat('dd MMMM yyyy', 'fr_FR').format(promo.endDate)}',
                      ),

                      const SizedBox(height: 24),

                      // Conditions
                      if (promo.conditions.isNotEmpty)
                        _buildInfoSection(
                          'Conditions',
                          Icons.info_outline,
                          promo.conditions,
                        ),

                      const SizedBox(height: 32),

                      // Bouton d'action
                      if (promo.isActive)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => _handleAction(context, promo),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: gradientColors[0],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              promo.actionButton,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, PromotionModel promo) async {
    final promotionService = PromotionService();
    
    // Vérifier si déjà participé
    final hasParticipated = await promotionService.hasParticipated(promo.id);
    
    if (hasParticipated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous avez déjà participé à cette promotion'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Participer
    final success = await promotionService.participatePromotion(promo.id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Participation enregistrée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la participation'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Color> _getGradientColors(String type) {
    switch (type) {
      case 'cashback':
        return [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
      case 'jackpot':
        return [const Color(0xFFDC2626), const Color(0xFFEF4444)];
      case 'reward':
        return [const Color(0xFF10B981), const Color(0xFF34D399)];
      case 'cagnotte':
        return [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)];
      default:
        return [const Color(0xFF3B82F6), const Color(0xFF60A5FA)];
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'cashback':
        return Icons.percent;
      case 'jackpot':
        return Icons.emoji_events;
      case 'reward':
        return Icons.card_giftcard;
      case 'cagnotte':
        return Icons.savings;
      default:
        return Icons.local_offer;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'cashback':
        return 'CASHBACK';
      case 'jackpot':
        return 'JACKPOT';
      case 'reward':
        return 'CADEAU';
      case 'cagnotte':
        return 'CAGNOTTE';
      default:
        return type.toUpperCase();
    }
  }
}
