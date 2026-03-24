// corporate_notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


class CorporateNotificationsScreen extends StatelessWidget {
  final String userId;

  const CorporateNotificationsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _markAllRead(userId),
            child: const Text('Tout lire',
                style: TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmpty();
          }
          final docs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _NotifCard(
                id: docs[i].id,
                data: data,
                onTap: () => _markRead(docs[i].id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markRead(String id) async =>
      FirebaseFirestore.instance.collection('notifications').doc(id).update({'isRead': true});

  Future<void> _markAllRead(String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snap.docs) batch.update(doc.reference, {'isRead': true});
    await batch.commit();
  }

  Widget _buildEmpty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.notifications_none_rounded,
                size: 40, color: Color(0xFF2196F3)),
          ),
          const SizedBox(height: 16),
          const Text('Aucune notification',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Text('Les événements apparaîtront ici',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ]),
      );
}

class _NotifCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  const _NotifCard({required this.id, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isRead = data['isRead'] == true;
    final type = data['type']?.toString() ?? 'info';
    final title = data['title']?.toString() ?? 'Notification';
    final message = data['message']?.toString() ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    final Color iconBg = type == 'recharge' ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7);
    final Color iconColor = type == 'recharge' ? const Color(0xFF059669) : const Color(0xFFD97706);
    final IconData icon = type == 'recharge' ? Icons.payments_rounded : Icons.info_rounded;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isRead ? Colors.grey.shade100 : iconColor.withOpacity(0.25), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: isRead ? FontWeight.w600 : FontWeight.w800, color: const Color(0xFF1F2937))),
                const SizedBox(height: 3),
                Text(message, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Text(DateFormat('HH:mm', 'fr_FR').format(createdAt), style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}