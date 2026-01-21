import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:quantum_dashboard/models/notification_model.dart' as models;
import 'package:quantum_dashboard/services/notification_service.dart';
import 'package:quantum_dashboard/services/local_notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final LocalNotificationService _localNotification =
      LocalNotificationService();

  List<models.Notification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  Timer? _pollingTimer;

  List<models.Notification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Helper method to safely notify listeners
  void _safeNotifyListeners() {
    Future.microtask(() {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  // Initialize local notifications
  Future<void> initializeLocalNotifications() async {
    await _localNotification.initialize();
    await _localNotification.requestPermissions();
  }

  // Load notifications (updated to detect new ones and show local notifications)
  Future<void> loadNotifications({
    bool unreadOnly = false,
    String? type,
    int? limit,
  }) async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      // Store previous notification IDs to detect new ones
      final previousIds = _notifications.map((n) => n.id).toSet();

      _notifications = await _notificationService.getNotifications(
        unreadOnly: unreadOnly,
        type: type,
        limit: limit,
      );

      _updateUnreadCount();

      // Detect new unread notifications and show local notifications
      final newNotifications = _notifications
          .where((n) => !previousIds.contains(n.id) && !n.isRead)
          .toList();

      if (newNotifications.isNotEmpty) {
        await _showLocalNotifications(newNotifications);
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Show local notifications for new notifications
  Future<void> _showLocalNotifications(
    List<models.Notification> notifications,
  ) async {
    for (final notification in notifications) {
      try {
        await _localNotification.showNotification(
          id: notification.id.hashCode,
          title: notification.title,
          body: notification.message,
          payload: jsonEncode({
            'notificationId': notification.id,
            'type': notification.type,
            'relatedId': notification.relatedId,
          }),
        );
        debugPrint('Local notification shown: ${notification.title}');
      } catch (e) {
        debugPrint('Error showing local notification: $e');
      }
    }
  }

  // Load unread count
  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await _notificationService.getUnreadCount();
      _safeNotifyListeners();
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  // Update unread count from current notifications
  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  // Start polling for new notifications
  void startPolling({Duration interval = const Duration(seconds: 30)}) {
    // Stop existing timer if any
    stopPolling();

    // Initialize local notifications if not already done
    initializeLocalNotifications();

    // Load immediately
    loadNotifications();
    loadUnreadCount();

    // Start periodic polling
    _pollingTimer = Timer.periodic(interval, (timer) {
      loadNotifications();
      loadUnreadCount();
    });
  }

  // Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        _updateUnreadCount();
        _safeNotifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();

      // Update local state
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
          .toList();
      _unreadCount = 0;
      _safeNotifyListeners();
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);

      // Remove from local state
      _notifications.removeWhere((n) => n.id == notificationId);
      _updateUnreadCount();
      _safeNotifyListeners();
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  // Create notification (for admin)
  Future<void> createNotification({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String type,
    required String title,
    required String message,
    String? relatedId,
  }) async {
    try {
      await _notificationService.createNotification(
        recipientId: recipientId,
        senderId: senderId,
        senderName: senderName,
        type: type,
        title: title,
        message: message,
        relatedId: relatedId,
      );

      // Reload notifications to get the new one
      await loadNotifications();
      await loadUnreadCount();
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
