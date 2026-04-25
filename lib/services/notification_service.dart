// lib/services/notification_service.dart
//
// ✅ Zéro Firebase — service simplifié selon la réalité de la BDD CARDOIL.
//
// Seules les opérations réellement utiles sont conservées :
//   - Lister toutes les notifications du client connecté
//   - Lister les non lues
//   - Compter les non lues (badge)
//   - Marquer une notification comme lue
//   - Marquer toutes comme lues
//   - Supprimer une notification
//   - Enregistrer le token push Expo (pour les futures notifications PUSH)

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';

class NotificationService {
  static const String _base = 'https://api.cardoil.io';
  static const Duration _timeout = Duration(seconds: 10);
  static const Duration _pollInterval = Duration(seconds: 30);

  // ─── Headers ───────────────────────────────────────────────────────────────

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ─── Fetch interne ─────────────────────────────────────────────────────────

  Future<List<NotificationModel>> _fetch({
    required String? token,
    bool unreadOnly = false,
  }) async {
    try {
      final url = unreadOnly
          ? '$_base/api/notifications/unread'
          : '$_base/api/notifications';

      final response = await http
          .get(Uri.parse(url), headers: _headers(token))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body is List
            ? body
            : (body['content'] ?? body['data'] ?? []) as List;
        return list
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (response.statusCode == 401) {
        throw NotificationAuthException();
      }
    } catch (e) {
      if (e is NotificationAuthException) rethrow;
      _log('_fetch', e);
    }
    return [];
  }

  // ─── Streams (polling 30 s) ────────────────────────────────────────────────

  /// Toutes les notifications du client, rafraîchies toutes les 30 s.
  Stream<List<NotificationModel>> notificationsStream({String? token}) async* {
    yield await _fetch(token: token);
    yield* Stream.periodic(_pollInterval)
        .asyncMap((_) => _fetch(token: token));
  }

  /// Notifications non lues uniquement, rafraîchies toutes les 30 s.
  Stream<List<NotificationModel>> unreadStream({String? token}) async* {
    yield await _fetch(token: token, unreadOnly: true);
    yield* Stream.periodic(_pollInterval)
        .asyncMap((_) => _fetch(token: token, unreadOnly: true));
  }

  /// Compteur de non lues — utile pour le badge dans la barre de navigation.
  Stream<int> unreadCountStream({String? token}) async* {
    yield await getUnreadCount(token: token);
    yield* Stream.periodic(_pollInterval)
        .asyncMap((_) => getUnreadCount(token: token));
  }

  // ─── Lectures ponctuelles ──────────────────────────────────────────────────

  /// Nombre de notifications non lues.
  /// Tente d'abord l'endpoint dédié, puis compte via la liste en fallback.
  Future<int> getUnreadCount({String? token}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_base/api/notifications/unread/count'),
            headers: _headers(token),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is int) return data;
        if (data is num) return data.toInt();
        if (data is Map) return (data['count'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      _log('getUnreadCount', e);
    }
    // Fallback
    final list = await _fetch(token: token, unreadOnly: true);
    return list.length;
  }

  /// Liste paginée — utile si le client a beaucoup de notifications.
  Future<List<NotificationModel>> getNotificationsPaginated({
    String? token,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final uri =
          Uri.parse('$_base/api/notifications/paginated').replace(
        queryParameters: {'page': '$page', 'size': '$size'},
      );
      final response =
          await http.get(uri, headers: _headers(token)).timeout(_timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body is List
            ? body
            : (body['content'] ?? body['data'] ?? []) as List;
        return list
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _log('getNotificationsPaginated', e);
    }
    return [];
  }

  // ─── Mutations ─────────────────────────────────────────────────────────────

  /// Marque une notification comme lue — PUT /api/notifications/{id}/read
  Future<bool> markAsRead(String id, {String? token}) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_base/api/notifications/$id/read'),
            headers: _headers(token),
          )
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      _log('markAsRead', e);
      return false;
    }
  }

  /// Marque toutes les notifications non lues comme lues (appels parallèles).
  Future<void> markAllAsRead({String? token}) async {
    try {
      final unread = await _fetch(token: token, unreadOnly: true);
      await Future.wait(unread.map((n) => markAsRead(n.id, token: token)));
    } catch (e) {
      _log('markAllAsRead', e);
    }
  }

  /// Supprime une notification — DELETE /api/notifications/{id}
  Future<bool> deleteNotification(String id, {String? token}) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_base/api/notifications/$id'),
            headers: _headers(token),
          )
          .timeout(_timeout);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _log('deleteNotification', e);
      return false;
    }
  }

  // ─── Push token ────────────────────────────────────────────────────────────

  /// Enregistre le token Expo push — POST /api/notifications/register-token
  /// À appeler au login si vous activez les notifications PUSH dans le futur.
  Future<bool> registerPushToken({
    required String expoPushToken,
    required String platform, // 'ios' ou 'android'
    String? token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_base/api/notifications/register-token'),
            headers: _headers(token),
            body: jsonEncode({
              'token': expoPushToken,
              'platform': platform,
            }),
          )
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      _log('registerPushToken', e);
      return false;
    }
  }

  // ─── Utilitaire ────────────────────────────────────────────────────────────

  void _log(String method, Object error) {
    // ignore: avoid_print
    print('NotificationService.$method error: $error');
  }
}

class NotificationAuthException implements Exception {
  @override
  String toString() => 'NotificationAuthException: token invalide ou expiré';
}