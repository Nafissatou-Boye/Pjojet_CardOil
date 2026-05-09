// lib/screens/notifications/corporate_notifications_screen.dart
//
// ✅ Zéro Firebase — adapté au nouveau modèle simplifié CARDOIL.
// Destiné aux clients employés (style corporate : fond gris, AppBar blanche).
// Toutes les notifications sont de type TRANSACTION / IN_APP.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class CorporateNotificationsScreen extends StatefulWidget {
  final String userId;
  final String? token;

  const CorporateNotificationsScreen({
    super.key,
    required this.userId,
    this.token,
  });

  @override
  State<CorporateNotificationsScreen> createState() =>
      _CorporateNotificationsScreenState();
}

class _CorporateNotificationsScreenState
    extends State<CorporateNotificationsScreen> {
  final NotificationService _service = NotificationService();

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> _markRead(String id) async {
    await _service.markAsRead(id, token: widget.token);
    if (mounted) setState(() {});
  }

  Future<void> _markAllRead() async {
    await _service.markAllAsRead(token: widget.token);
    if (mounted) setState(() {});
  }

  Future<void> _delete(String id) async {
    await _service.deleteNotification(id, token: widget.token);
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text(
              'Tout lire',
              style: TextStyle(
                  color: Color(0xFF2196F3), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _service.notificationsStream(token: widget.token),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2196F3)),
            );
          }

          if (snapshot.hasError) {
            return _buildError();
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmpty();
          }

          return RefreshIndicator(
            color: const Color(0xFF2196F3),
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final notif = notifications[i];
                return _NotifCard(
                  notification: notif,
                  onTap: () async {
                    if (!notif.isRead) await _markRead(notif.id);
                  },
                  onDelete: () => _delete(notif.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ─── États ─────────────────────────────────────────────────────────────────

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 40,
                color: Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune notification',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 8),
            Text(
              'Les événements apparaîtront ici',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Impossible de charger les notifications.\nVérifiez votre connexion.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, color: Colors.grey.shade600, height: 1.5),
              ),
            ],
          ),
        ),
      );
}

// ─── Carte de notification ─────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotifCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

   String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return DateFormat('HH:mm').format(dt);
    if (diff.inDays < 7) return DateFormat('EEE HH:mm', 'fr_FR').format(dt);
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(dt);
  }

  @override
Widget build(BuildContext context) {
  final isRead = notification.isRead;
  final meta = notification.parsedMetadata;

  // ── Couleur et icône selon le type ──────────────────────────────────
  final isRecharge = meta?.isRecharge ?? false;
  final color = isRecharge
      ? const Color(0xFF059669)   // vert  → recharge
      : const Color(0xFFDC2626);  // rouge → paiement carburant
  final bgColor = isRecharge
      ? const Color(0xFFD1FAE5)   // fond vert clair
      : const Color(0xFFFEE2E2);  // fond rouge clair
  final iconData = isRecharge
      ? Icons.account_balance_wallet_rounded
      : Icons.local_gas_station_rounded;

  return Dismissible(
    key: Key(notification.id),
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
    ),
    onDismissed: (_) => onDelete(),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? Colors.grey.shade100
                : color.withAlpha(64),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icône colorée selon le type ──────────────────────────
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            // ── Contenu ──────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre + badge type
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isRead ? FontWeight.w600 : FontWeight.w800,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      // Badge Paiement / Recharge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          meta?.typeLabel ?? 'Transaction',
                          style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.message,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // ── Chips metadata ───────────────────────────────
                  if (meta != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (meta.amount != null)
                          _MetaChip(
                            icon: Icons.payments_rounded,
                            label:
                                '${meta.sign}${NumberFormat('#,##0.00', 'fr_FR').format(meta.amount)} FCFA',
                            color: color,
                          ),
                        if (meta.stationName != null)
                          _MetaChip(
                            icon: Icons.location_on_rounded,
                            label: meta.stationName!,
                            color: const Color(0xFF2196F3),
                          ),
                       if (!isRecharge && meta.productName != null)
  _MetaChip(
     icon: Icons.local_gas_station_rounded,
    label: meta.productName!,
    color: color,
  ),
                        if (meta.pointsEarned != null &&
                            meta.pointsEarned! > 0)
                          _MetaChip(
                            icon: Icons.stars_rounded,
                            label: '+${meta.pointsEarned} pts',
                            color: const Color(0xFFD97706),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(notification.createdAt),
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            // ── Point non-lu ─────────────────────────────────────────
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 8, top: 4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
}

// ─── Chip metadata ────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}