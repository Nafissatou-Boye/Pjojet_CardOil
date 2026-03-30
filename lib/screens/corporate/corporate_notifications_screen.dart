// lib/screens/notifications/corporate_notifications_screen.dart
//
// ✅ Zéro Firebase — utilise NotificationService (REST API).
// Le stream se rafraîchit toutes les 30 s grâce au polling dans le service.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class CorporateNotificationsScreen extends StatefulWidget {
  final String userId; // conservé pour compatibilité d'interface
  final String? token; // JWT nécessaire pour l'API

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



  Future<void> _markRead(String id) =>
      _service.markAsRead(id, token: widget.token);

  Future<void> _markAllRead() =>
      _service.markAllAsRead(token: widget.token);

  Future<void> _delete(String id) =>
      _service.deleteNotification(id, token: widget.token);

  

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
            onPressed: () async {
              await _markAllRead();
              // Force le rebuild en reconstruisant le widget
              if (mounted) setState(() {});
            },
            child: const Text(
              'Tout lire',
              style: TextStyle(
                  color: Color(0xFF2196F3), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _service.getAllNotificationsStream(token: widget.token),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2196F3)),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmpty();
          }

          return RefreshIndicator(
            color: const Color(0xFF2196F3),
            onRefresh: () async {
              // Le stream se rafraîchit seul, on attend juste un tick
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
                    if (!notif.isRead) {
                      await _markRead(notif.id);
                    }
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

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
             decoration: BoxDecoration(
  color: const Color(0xFF2196F3).withAlpha((0.1 * 255).round()), // 0.1 → alpha ≈ 26
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
}

// ─── Carte de notification ──────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotifCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;
    final type = notification.type;

    final Color iconBg = type == NotificationType.transaction
        ? const Color(0xFFD1FAE5)
        : type == NotificationType.alert
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFFEF3C7);

    final Color iconColor = type == NotificationType.transaction
        ? const Color(0xFF059669)
        : type == NotificationType.alert
            ? const Color(0xFFDC2626)
            : const Color(0xFFD97706);

    final IconData icon = type == NotificationType.transaction
        ? Icons.payments_rounded
        : type == NotificationType.alert
            ? Icons.warning_rounded
            : Icons.info_rounded;

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
            : iconColor.withAlpha((0.25 * 255).round()), // anciennement withOpacity(0.25)
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha((0.04 * 255).round()), // anciennement withOpacity(0.04)
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
  
          child: Row(
            children: [
              // Icône
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isRead ? FontWeight.w600 : FontWeight.w800,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.message,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: iconColor,
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