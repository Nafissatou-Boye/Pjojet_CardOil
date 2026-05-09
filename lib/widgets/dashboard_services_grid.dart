// lib/widgets/dashboard_services_grid.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/service_service.dart';
import '../services/auth_service.dart';
import '../models/service_model.dart';
import '../screens/client/services_screen.dart';

class DashboardServicesGrid extends StatefulWidget {
  final int companyId;
  const DashboardServicesGrid({super.key, required this.companyId});

  @override
  State<DashboardServicesGrid> createState() => _DashboardServicesGridState();
}

class _DashboardServicesGridState extends State<DashboardServicesGrid> {
  final _serviceService = ServiceService();
  List<ServiceModel> _services = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.companyId == 0) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final token = await Provider.of<AuthService>(context, listen: false).getToken();
    final list = await _serviceService.getActiveServices(widget.companyId, token: token);
    if (!mounted) return;
    setState(() {
      _services = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Titre + "Voir tout" ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Services',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
            ),
            if (!_loading && _services.length > 8)
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ServicesScreen(companyId: widget.companyId),
                )),
                child: const Text(
                  'Voir tout',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (_loading)
          _buildSkeleton()
        else if (_services.isEmpty)
          _buildEmptyState()
        else
          _buildGrid(),
      ],
    );
  }

  // ── Skeleton 4 tuiles grises ──
  Widget _buildSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 10, childAspectRatio: 0.82,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
          ),
          const SizedBox(height: 6),
          Container(
            height: 10, width: 44,
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
          ),
        ],
      ),
    );
  }

  // ── État vide propre ──
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.miscellaneous_services_outlined, color: Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'Aucun service disponible',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ── Grille ──
  Widget _buildGrid() {
    final displayed = _services.take(8).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 10, childAspectRatio: 0.82,
      ),
      itemCount: displayed.length,
      itemBuilder: (ctx, i) => _ServiceTile(service: displayed[i], companyId: widget.companyId),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// _ServiceTile
// ════════════════════════════════════════════════════════════════

class _ServiceTile extends StatelessWidget {
  final ServiceModel service;
  final int companyId;
  const _ServiceTile({required this.service, required this.companyId});

  Color _hexColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFF2563EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _hexColor(service.effectiveColorHex);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ServicesScreen(companyId: companyId, highlightServiceId: service.id),
      )),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.25), width: 1),
            ),
            child: service.iconUrl != null && service.iconUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      service.iconUrl!,
                      width: 32, height: 32, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _FallbackIcon(color: color, service: service),
                    ),
                  )
                : _FallbackIcon(color: color, service: service),
          ),
          const SizedBox(height: 6),
          Text(
            service.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151), height: 1.2),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// _FallbackIcon
// ════════════════════════════════════════════════════════════════

class _FallbackIcon extends StatelessWidget {
  final Color color;
  final ServiceModel service;
  const _FallbackIcon({required this.color, required this.service});

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
    return Center(child: Icon(_iconForCode(service.code), color: color, size: 26));
  }
}