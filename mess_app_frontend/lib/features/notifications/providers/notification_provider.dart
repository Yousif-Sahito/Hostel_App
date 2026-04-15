import 'package:flutter/material.dart';

import '../models/notification_item.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  int unreadCount = 0;
  List<NotificationItem> notifications = [];

  Future<void> fetchNotifications() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      notifications = await NotificationService.getMyNotifications();
      unreadCount = notifications.where((item) => !item.isRead).length;

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      unreadCount = await NotificationService.getUnreadCount();
      notifyListeners();
    } catch (_) {
      // Ignore unread-count failures to avoid noisy UX.
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await NotificationService.markAsRead(id);
      final index = notifications.indexWhere((item) => item.id == id);
      if (index >= 0 && !notifications[index].isRead) {
        notifications[index] = NotificationItem(
          id: notifications[index].id,
          userId: notifications[index].userId,
          title: notifications[index].title,
          body: notifications[index].body,
          type: notifications[index].type,
          data: notifications[index].data,
          isRead: true,
          readAt: DateTime.now().toIso8601String(),
          createdAt: notifications[index].createdAt,
        );
        unreadCount = unreadCount > 0 ? unreadCount - 1 : 0;
        notifyListeners();
      }
    } catch (_) {
      // Leave state unchanged on failure.
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead();
      notifications = notifications
          .map(
            (item) => NotificationItem(
              id: item.id,
              userId: item.userId,
              title: item.title,
              body: item.body,
              type: item.type,
              data: item.data,
              isRead: true,
              readAt: DateTime.now().toIso8601String(),
              createdAt: item.createdAt,
            ),
          )
          .toList();
      unreadCount = 0;
      notifyListeners();
    } catch (_) {
      // Leave state unchanged on failure.
    }
  }
}
