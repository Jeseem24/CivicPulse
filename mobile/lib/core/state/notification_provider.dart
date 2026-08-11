import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/mock_repository.dart';

class NotificationProvider with ChangeNotifier {
  List<UserNotification> _notifications = [];

  List<UserNotification> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _loadNotifications();
  }

  void _loadNotifications() {
    _notifications = MockRepository().notifications;
  }

  void refreshNotifications() {
    _notifications = List.from(MockRepository().notifications);
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = MockRepository().notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final old = MockRepository().notifications[index];
      MockRepository().notifications[index] = old.copyWith(isRead: true);
      refreshNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < MockRepository().notifications.length; i++) {
      final old = MockRepository().notifications[i];
      if (!old.isRead) {
        MockRepository().notifications[i] = old.copyWith(isRead: true);
      }
    }
    refreshNotifications();
  }
}
