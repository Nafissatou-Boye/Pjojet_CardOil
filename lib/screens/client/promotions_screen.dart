// lib/screens/client/all_promotions_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/promotion_service.dart';
import '../../models/promotion_model.dart';
import 'promotion_detail_screen.dart';

class AllPromotionsScreen extends StatelessWidget {
  const AllPromotionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final promotionService = PromotionService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotions'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: authService.getCurrentUserStream(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData || userSnapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = userSnapshot.data!;

          return StreamBuilder<List<PromotionModel>>(
            stream: promotionService.getAllPromotionsStream(user.selectedCompagnie),
            builder: (context, promoSnapshot) {
              if (promoSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!promoSnapshot.hasData || promoSnapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              final promotions = promoSnapshot.data!;
              final activePromos = promotions.where((p) => p.isActive).toList();
              final expiredPromos = promotions.where((p) => !p.isActive).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (activePromos.isNotEmpty) ...[
                      _buildSectionTitle('Promotions actives', activePromos.length),
                      const SizedBox(height: 12),
                      ...activePromos.map((promo) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildPromotionCard(context, promo, isActive: true),
                      )),
                    ],

                    if (expiredPromos.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('Promotions expirées', expiredPromos.length),
                      const SizedBox(height: 12),
                      ...expiredPromos.map((promo) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildPromotionCard(context, promo, isActive: false),
                      )),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune promotion disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les promotions apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionCard(BuildContext context, PromotionModel promo, {required bool isActive}) {
    final gradientColors = _getGradientColors(promo.type);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PromotionDetailScreen(promotionId: promo.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive ? gradientColors : [Colors.grey.shade300, Colors.grey.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
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
                child: Text(
                  _getTypeLabel(promo.type),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: gradientColors[0],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIcon(promo.type),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Titre
                  Text(
                    promo.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    promo.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Dates
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Jusqu\'au ${DateFormat('dd/MM/yyyy').format(promo.endDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bouton
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isActive ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PromotionDetailScreen(promotionId: promo.id),
                          ),
                        );
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: gradientColors[0],
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isActive ? 'Voir les détails' : 'Expirée',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 18),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
