// lib/screens/notifications/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../langue/app_localizations.dart';

class NotificationsScreen extends StatelessWidget {
  final String? token;
  const NotificationsScreen({super.key, this.token});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final service = NotificationService();

    return Directionality(
      textDirection: t.textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.notificationsTitle),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            TextButton(
              onPressed: () async {
                await service.markAllAsRead(token: token);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(t.allMarkedRead),
                    backgroundColor: const Color(0xFF10B981),
                  ));
                }
              },
              child: Text(
                t.markAllRead,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        body: StreamBuilder<List<NotificationModel>>(
          stream: service.notificationsStream(token: token),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return _buildError();
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmpty(t);
            }
            return RefreshIndicator(
              color: const Color(0xFF2563EB),
              onRefresh: () async =>
                  await Future.delayed(const Duration(milliseconds: 600)),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final notif = snapshot.data![i];
                  return _NotificationCard(
                    notification: notif,
                    onTap: () async {
                      if (!notif.isRead) {
                        await service.markAsRead(notif.id, token: token);
                      }
                    },
                    onDelete: () async {
                      await service.deleteNotification(notif.id, token: token);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(t.notificationDeleted),
                          backgroundColor: Colors.red,
                        ));
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations t) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(t.noNotification,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text(t.noNotificationSub,
                style:
                    TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Impossible de charger les notifications.\nVérifiez votre connexion.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      );
}

// ─── Carte ────────────────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final meta = notification.parsedMetadata;
    final isRead = notification.isRead;

    // ── Couleur et icône selon paiement ou recharge ──────────────────────
    final isRecharge = meta?.isRecharge ?? false;
    final color = isRecharge
        ? const Color(0xFF059669) // vert  → recharge
        : const Color(0xFFDC2626); // rouge → paiement
    final iconData = isRecharge
        ? Icons.account_balance_wallet_rounded // portefeuille → recharge
        : Icons.local_gas_station_rounded;     // pompe → paiement carburant

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
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
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
                  ? Colors.grey.shade200
                  : color.withAlpha(51),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône colorée selon le type
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre + type
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        // Badge paiement / recharge
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
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Chips metadata
                    if (meta != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (meta.amount != null)
                            _Chip(
                              icon: Icons.payments_rounded,
                              label:
                                  '${meta.sign}${NumberFormat('#,##0.00', 'fr_FR').format(meta.amount)} FCFA',
                              color: color,
                            ),
                        if (!isRecharge && meta.productName != null)
  _Chip(
    icon: Icons.local_gas_station_rounded,
    label: meta.productName!,
    color: color,
  ),
                          if (meta.productName != null)
                            _Chip(
                              icon: isRecharge
                                  ? Icons.battery_charging_full_rounded
                                  : Icons.local_gas_station_rounded,
                              label: meta.productName!,
                              color: color,
                            ),
                          if (meta.pointsEarned != null &&
                              meta.pointsEarned! > 0)
                            _Chip(
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
              // Point non-lu
              if (!isRead)
                Container(
                  width: 9,
                  height: 9,
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

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return DateFormat('HH:mm').format(dt);
    if (diff.inDays < 7) return DateFormat('EEE HH:mm', 'fr_FR').format(dt);
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(dt);
  }
}

// ─── Chip ─────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({
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
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}