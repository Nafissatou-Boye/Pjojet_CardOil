// lib/services/notification_service.dart
//
// Migration Firebase → API REST
// Toutes les méthodes de l'original sont conservées avec les mêmes signatures.
// Les streams sont émulés via async* yield pour la compatibilité des widgets.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';

class NotificationService {
  static const String _baseUrl = 'https://api.cardoil.io';

  // ─── INITIALIZE ───────────────────────────────────────────────
  Future<void> initialize() async {
    // Plus de Firebase Messaging — à étendre si besoin (FCM via backend)
  }

  // ─── HELPERS INTERNES ─────────────────────────────────────────

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<List<NotificationModel>> _fetchNotifications({
    String? token,
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/notifications').replace(
        queryParameters: {
          if (unreadOnly) 'isRead': 'false',
          'limit': '$limit',
        },
      );
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body is List
            ? body
            : (body['content'] ?? body['data'] ?? []) as List;
        return list
            .map((e) =>
                NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('NotificationService._fetchNotifications error: $e');
    }
    return [];
  }

  // ─── STREAM NOTIFICATIONS NON LUES ───────────────────────────
  // Conserve la même signature que l'original Firebase
  Stream<List<NotificationModel>> getUnreadNotificationsStream({
    String? token,
  }) async* {
    yield await _fetchNotifications(token: token, unreadOnly: true);
  }

  // ─── STREAM TOUTES LES NOTIFICATIONS ─────────────────────────
  Stream<List<NotificationModel>> getAllNotificationsStream({
    String? token,
  }) async* {
    yield await _fetchNotifications(token: token, limit: 50);
  }

  // ─── COUNT NOTIFICATIONS NON LUES (badge) ────────────────────
  // Même signature que l'original : Stream<int> getUnreadCountStream()
  Stream<int> getUnreadCountStream({String? token}) async* {
    yield await getUnreadCount(token: token);
  }

  // Future version (utilisée dans client_dashboard)
  Future<int> getUnreadCount({String? token}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/notifications/unread-count'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is int) return data;
        if (data is Map) return (data['count'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}

    // Fallback : compte via la liste si l'endpoint count n'existe pas
    final list =
        await _fetchNotifications(token: token, unreadOnly: true);
    return list.length;
  }

  // ─── COMPATIBILITÉ : unreadCount(userId) ─────────────────────
  // Conserve la signature originale utilisée dans certains écrans
  Stream<int> unreadCount(String userId, {String? token}) async* {
    yield await getUnreadCount(token: token);
  }

  // ─── MARQUER COMME LUE ───────────────────────────────────────
  Future<void> markAsRead(String notificationId, {String? token}) async {
    try {
      await http
          .patch(
            Uri.parse(
                '$_baseUrl/api/notifications/$notificationId/read'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('NotificationService.markAsRead error: $e');
    }
  }

  // ─── MARQUER TOUTES COMME LUES ───────────────────────────────
  Future<void> markAllAsRead({String? token}) async {
    try {
      await http
          .patch(
            Uri.parse('$_baseUrl/api/notifications/read-all'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('NotificationService.markAllAsRead error: $e');
    }
  }

  // ─── CRÉER UNE NOTIFICATION ──────────────────────────────────
  // (usage admin/back-office)
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
    String? token,
  }) async {
    try {
      await http
          .post(
            Uri.parse('$_baseUrl/api/notifications'),
            headers: _headers(token),
            body: jsonEncode({
              'userId': userId,
              'title': title,
              'message': message,
              'type': type.toString().split('.').last,
              'isRead': false,
              if (data != null) 'data': data,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('NotificationService.createNotification error: $e');
    }
  }

  // ─── SUPPRIMER UNE NOTIFICATION ──────────────────────────────
  Future<void> deleteNotification(String notificationId,
      {String? token}) async {
    try {
      await http
          .delete(
            Uri.parse('$_baseUrl/api/notifications/$notificationId'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('NotificationService.deleteNotification error: $e');
    }
  }
}