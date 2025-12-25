import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quantum_dashboard/models/notification_model.dart' as models;
import 'package:quantum_dashboard/services/api_service.dart';

class NotificationService extends ApiService {
  // Get notifications with optional filters
  Future<List<models.Notification>> getNotifications({
    bool? unreadOnly,
    String? type,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    if (unreadOnly == true) {
      queryParams['unreadOnly'] = 'true';
    }
    if (type != null) {
      queryParams['type'] = type;
    }
    if (limit != null) {
      queryParams['limit'] = limit.toString();
    }

    final queryString = queryParams.isEmpty
        ? ''
        : '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

    final url = '${ApiService.baseUrl}/api/notifications$queryString';
    final headers = await getHeaders();

    final response = await http.get(Uri.parse(url), headers: headers);
    final data = handleResponse(response);

    if (data is List) {
      return data.map((json) => models.Notification.fromJson(json)).toList();
    }
    return [];
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    final url = '${ApiService.baseUrl}/api/notifications/unread-count';
    final headers = await getHeaders();

    final response = await http.get(Uri.parse(url), headers: headers);
    final data = handleResponse(response);

    return data['unreadCount'] ?? 0;
  }

  // Get single notification
  Future<models.Notification> getNotification(String notificationId) async {
    final url = '${ApiService.baseUrl}/api/notifications/$notificationId';
    final headers = await getHeaders();

    final response = await http.get(Uri.parse(url), headers: headers);
    final data = handleResponse(response);

    return models.Notification.fromJson(data);
  }

  // Mark notification as read
  Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    final url = '${ApiService.baseUrl}/api/notifications/$notificationId/read';
    final headers = await getHeaders();

    final response = await http.put(Uri.parse(url), headers: headers);
    return handleResponse(response);
  }

  // Mark all notifications as read
  Future<Map<String, dynamic>> markAllAsRead() async {
    final url = '${ApiService.baseUrl}/api/notifications/read-all';
    final headers = await getHeaders();

    final response = await http.put(Uri.parse(url), headers: headers);
    return handleResponse(response);
  }

  // Delete notification
  Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    final url = '${ApiService.baseUrl}/api/notifications/$notificationId';
    final headers = await getHeaders();

    final response = await http.delete(Uri.parse(url), headers: headers);
    return handleResponse(response);
  }

  // Create notification (for admin)
  Future<Map<String, dynamic>> createNotification({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String type,
    required String title,
    required String message,
    String? relatedId,
  }) async {
    final url = '${ApiService.baseUrl}/api/notifications';
    final headers = await getHeaders();

    final body = json.encode({
      'recipientId': recipientId,
      'senderId': senderId,
      'senderName': senderName,
      'type': type,
      'title': title,
      'message': message,
      if (relatedId != null) 'relatedId': relatedId,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    return handleResponse(response);
  }
}
