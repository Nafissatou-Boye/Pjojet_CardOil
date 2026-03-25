import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../langue/app_localizations.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final notificationService = NotificationService();

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
                await notificationService.markAllAsRead();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(t.allMarkedRead),
                    backgroundColor: const Color(0xFF10B981),
                  ));
                }
              },
              child: Text(t.markAllRead,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        body: StreamBuilder<List<NotificationModel>>(
          stream: notificationService.getAllNotificationsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState(t);
            }
            final notifications = snapshot.data!;
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildNotificationCard(
                  context, notifications[index], notificationService, t),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(t.noNotification,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(t.noNotificationSub,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notif,
    NotificationService service,
    AppLocalizations t,
  ) {
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) async {
        await service.deleteNotification(notif.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t.notificationDeleted),
            backgroundColor: Colors.red,
          ));
        }
      },
      child: InkWell(
        onTap: () async {
          if (!notif.isRead) await service.markAsRead(notif.id);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notif.isRead ? Colors.white : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notif.isRead
                  ? Colors.grey.shade200
                  : const Color(0xFF2563EB).withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                    color: Color(0xFF2563EB), shape: BoxShape.circle),
                child: Center(child: _getNotificationIcon(notif.type)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notif.title,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: notif.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            color: const Color(0xFF1F2937))),
                    const SizedBox(height: 6),
                    Text(notif.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.grey.shade700)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatDate(notif.createdAt, t),
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500)),
                  if (!notif.isRead) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                          color: Color(0xFF2563EB), shape: BoxShape.circle),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getNotificationIcon(NotificationType type) {
    IconData icon;
    switch (type) {
      case NotificationType.transaction:
        icon = Icons.receipt_long;
        break;
      case NotificationType.promotion:
        icon = Icons.card_giftcard;
        break;
      case NotificationType.reminder:
        icon = Icons.notifications_active;
        break;
      default:
        icon = Icons.info_outline;
    }
    return Icon(icon, color: Colors.white, size: 28);
  }

  String _formatDate(DateTime date, AppLocalizations t) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return DateFormat('HH:mm').format(date);
    if (diff.inDays == 1) return t.yesterday;
    if (diff.inDays < 7) return '${diff.inDays}j';
    return DateFormat('dd/MM/yy').format(date);
  }
}