import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';

class NotificationService {
  static const String _base = 'https://api.cardoil.io';
  static const Duration _timeout = Duration(seconds: 10);
  static const Duration _pollInterval = Duration(seconds: 30);

  
  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };


  Future<void> initialize() async {
     }


  Future<List<NotificationModel>> _fetchNotifications({
    String? token,
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    try {
     
      final path = unreadOnly
          ? '$_base/api/notifications/unread'
          : '$_base/api/notifications';

      final uri = Uri.parse(path).replace(
        queryParameters: {
          'limit': '$limit',
        },
      );

      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body is List
            ? body
            : (body['content'] ?? body['data'] ?? body['notifications'] ?? [])
                as List;
        return list
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('NotificationService._fetchNotifications error: $e');
    }
    return [];
  }

 Stream<List<NotificationModel>> getAllNotificationsStream({
    String? token,
  }) async* {
    yield await _fetchNotifications(token: token);
    yield* Stream.periodic(_pollInterval).asyncMap(
      (_) => _fetchNotifications(token: token),
    );
  }

 
  Stream<List<NotificationModel>> getUnreadNotificationsStream({
    String? token,
  }) async* {
    yield await _fetchNotifications(token: token, unreadOnly: true);
    yield* Stream.periodic(_pollInterval).asyncMap(
      (_) => _fetchNotifications(token: token, unreadOnly: true),
    );
  }

  Stream<int> getUnreadCountStream({String? token}) async* {
    yield await getUnreadCount(token: token);
    yield* Stream.periodic(_pollInterval)
        .asyncMap((_) => getUnreadCount(token: token));
  }

  Stream<int> unreadCount(String userId, {String? token}) =>
      getUnreadCountStream(token: token);

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
        if (data is Map) return (data['count'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}

    // Fallback : compte via la liste si l'endpoint count échoue
    final list = await _fetchNotifications(token: token, unreadOnly: true);
    return list.length;
  }

  Future<void> markAsRead(String notificationId, {String? token}) async {
    try {
      await http
          .put(
            Uri.parse('$_base/api/notifications/$notificationId/read'),
            headers: _headers(token),
          )
          .timeout(_timeout);
    } catch (e) {
      print('NotificationService.markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead({String? token}) async {
    try {
      final unread =
          await _fetchNotifications(token: token, unreadOnly: true);
      final futures =
          unread.map((n) => markAsRead(n.id, token: token));
      await Future.wait(futures);
    } catch (e) {
      print('NotificationService.markAllAsRead error: $e');
    }
  }

  Future<void> deleteNotification(String notificationId,
      {String? token}) async {
    try {
      await http
          .delete(
            Uri.parse('$_base/api/notifications/$notificationId'),
            headers: _headers(token),
          )
          .timeout(_timeout);
    } catch (e) {
      print('NotificationService.deleteNotification error: $e');
    }
  }

  Future<List<NotificationModel>> getNotificationsPaginated({
    String? token,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final uri =
          Uri.parse('$_base/api/notifications/paginated').replace(
        queryParameters: {
          'page': '$page',
          'size': '$size',
        },
      );
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(_timeout);

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
      print('NotificationService.getNotificationsPaginated error: $e');
    }
    return [];
  }

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
            Uri.parse('$_base/api/notifications'),
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
          .timeout(_timeout);
    } catch (e) {
      print('NotificationService.createNotification error: $e');
    }
  }
}