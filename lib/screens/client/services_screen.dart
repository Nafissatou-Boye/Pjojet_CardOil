// lib/screens/client/services_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/service_service.dart';
import '../../services/auth_service.dart';
import '../../models/service_model.dart';

class ServicesScreen extends StatefulWidget {
  final int companyId;
  final int? highlightServiceId;

  const ServicesScreen({super.key, required this.companyId, this.highlightServiceId});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _serviceService = ServiceService();
  Map<CategoryModel, List<ServiceModel>> _grouped = {};
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
      final token = await Provider.of<AuthService>(context, listen: false).getToken();
      final grouped = await _serviceService.getServicesGroupedByCategory(
        widget.companyId, activeOnly: true, token: token,
      );
      if (!mounted) return;
      setState(() { _grouped = grouped; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Impossible de charger les services.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Nos Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 15)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.miscellaneous_services_outlined, size: 48, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun service disponible',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Les services de votre station\napparaîtront ici',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }

    final total = _grouped.values.fold<int>(0, (s, l) => s + l.length);
    final catCount = _grouped.keys.length;

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF2563EB),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // ── Résumé ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined, color: Color(0xFF2563EB), size: 20),
                const SizedBox(width: 10),
                Text(
                  '$total service${total > 1 ? 's' : ''} · $catCount catégorie${catCount > 1 ? 's' : ''}',
                  style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Sections par catégorie ──
          ..._grouped.entries.map((e) => _CategorySection(
            category: e.key,
            services: e.value,
            highlightServiceId: widget.highlightServiceId,
          )),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// _CategorySection
// ════════════════════════════════════════════════════════════════

class _CategorySection extends StatelessWidget {
  final CategoryModel category;
  final List<ServiceModel> services;
  final int? highlightServiceId;

  const _CategorySection({required this.category, required this.services, this.highlightServiceId});

  Color _catColor() {
    final hex = category.colorHex;
    if (hex == null || hex.isEmpty) return const Color(0xFF2563EB);
    try { return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16)); }
    catch (_) { return const Color(0xFF2563EB); }
  }

  IconData _catIcon() {
    switch (category.type.toUpperCase()) {
      case 'ENERGIE_CARBURANT': return Icons.local_gas_station;
      case 'LAVAGE':            return Icons.local_car_wash;
      case 'MAINTENANCE':       return Icons.build_outlined;
      case 'RESTAURATION':      return Icons.restaurant_outlined;
      case 'BOUTIQUE':          return Icons.shopping_bag_outlined;
      default:                  return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _catColor();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête catégorie
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_catIcon(), size: 14, color: color),
                  const SizedBox(width: 6),
                  Text(category.name,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Divider(color: Colors.grey.shade200, height: 1)),
            const SizedBox(width: 8),
            Text('${services.length}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),

        // Grille services
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.9,
          ),
          itemCount: services.length,
          itemBuilder: (ctx, i) => _ServiceCard(
            service: services[i],
            isHighlighted: services[i].id == highlightServiceId,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// _ServiceCard
// ════════════════════════════════════════════════════════════════

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final bool isHighlighted;
  const _ServiceCard({required this.service, this.isHighlighted = false});

  Color _hexColor(String hex) {
    try { return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16)); }
    catch (_) { return const Color(0xFF2563EB); }
  }

  IconData _iconForCode(String code) {
    final c = code.toLowerCase();
    if (c.contains('wash') || c.contains('lavage'))           return Icons.local_car_wash;
    if (c.contains('fuel') || c.contains('carburant'))        return Icons.local_gas_station;
    if (c.contains('maintenance') || c.contains('entretien')) return Icons.build;
    if (c.contains('shop') || c.contains('boutique'))         return Icons.shopping_bag;
    if (c.contains('food') || c.contains('restaurant') || c.contains('vente')) return Icons.restaurant;
    if (c.contains('park'))                                   return Icons.local_parking;
    if (c.contains('air') || c.contains('gonflage'))          return Icons.tire_repair;
    return Icons.miscellaneous_services;
  }

  @override
  Widget build(BuildContext context) {
    final color = _hexColor(service.effectiveColorHex);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted
            ? Border.all(color: color, width: 2)
            : Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: isHighlighted ? color.withOpacity(0.15) : Colors.black.withOpacity(0.04),
            blurRadius: isHighlighted ? 12 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetail(context, color),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: service.iconUrl != null && service.iconUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            service.iconUrl!, fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                Center(child: Icon(_iconForCode(service.code), color: color, size: 26)),
                          ),
                        )
                      : Center(child: Icon(_iconForCode(service.code), color: color, size: 26)),
                ),
                const SizedBox(height: 10),

                // Nom
                Text(
                  service.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937), height: 1.3,
                  ),
                ),

                // Badge points
                if (service.loyaltyPointsOnUse > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${service.loyaltyPointsOnUse} pts',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceDetailSheet(service: service, color: color),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// _ServiceDetailSheet
// ════════════════════════════════════════════════════════════════

class _ServiceDetailSheet extends StatelessWidget {
  final ServiceModel service;
  final Color color;
  const _ServiceDetailSheet({required this.service, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Icon(Icons.miscellaneous_services, size: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                    if (service.categoryName != null) ...[
                      const SizedBox(height: 4),
                      Text(service.categoryName!,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Description
          if (service.description != null && service.description!.isNotEmpty) ...[
            Text(service.description!,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5)),
            const SizedBox(height: 16),
          ],

          // Chips infos
          Wrap(
            spacing: 10, runSpacing: 10,
            children: [
              if (service.loyaltyPointsOnUse > 0)
                _chip(Icons.stars_rounded, '+${service.loyaltyPointsOnUse} pts fidélité', const Color(0xFFF59E0B)),
              if (service.mandatory)
                _chip(Icons.verified, 'Service inclus', const Color(0xFF10B981)),
              if (service.allowedInteractionTypes.isNotEmpty)
                _chip(Icons.nfc, service.allowedInteractionTypes.join(' · '), const Color(0xFF6366F1)),
            ],
          ),
          const SizedBox(height: 24),

          // Bouton fermer
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}