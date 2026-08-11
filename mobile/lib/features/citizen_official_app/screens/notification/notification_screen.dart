import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/state/complaint_provider.dart';
import '../../../../core/state/notification_provider.dart';
import '../../../../core/models/complaint.dart';
import '../complaint/complaint_detail_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final complaintProvider = Provider.of<ComplaintProvider>(context);

    final currentUser = authProvider.currentUser;
    if (currentUser == null) return const Scaffold(body: Center(child: Text('Please log in')));

    // Filter notifications for current user
    final userNotifications = notificationProvider.notifications
        .where((n) => n.userId == currentUser.id)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (userNotifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: () {
                notificationProvider.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    backgroundColor: AppColors.severityLow,
                  ),
                );
              },
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: userNotifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You will be notified when your reported issues get resolved.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppConstants.padding),
              itemCount: userNotifications.length,
              itemBuilder: (context, index) {
                final notification = userNotifications[index];
                final formattedTime =
                    '${notification.createdAt.day}/${notification.createdAt.month} at ${notification.createdAt.hour.toString().padLeft(2, '0')}:${notification.createdAt.minute.toString().padLeft(2, '0')}';

                return Card(
                  color: notification.isRead ? AppColors.surface.withOpacity(0.5) : AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    side: BorderSide(
                      color: notification.isRead ? AppColors.border.withOpacity(0.5) : AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: notification.isRead
                          ? AppColors.border
                          : AppColors.primary.withOpacity(0.1),
                      child: Icon(
                        notification.type == 'REPORT_RESOLVED'
                            ? Icons.check_circle_outline
                            : Icons.info_outline,
                        color: notification.isRead ? AppColors.textSecondary : AppColors.primary,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                              color: notification.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            height: 8,
                            width: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: notification.isRead ? AppColors.textMuted : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formattedTime,
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Mark as read
                      notificationProvider.markAsRead(notification.id);

                      // Find corresponding complaint and navigate to detail
                      final complaint = complaintProvider.complaints.firstWhere(
                        (c) => c.id == notification.reportId,
                        orElse: () => Complaint(
                          id: notification.reportId,
                          userId: currentUser.id,
                          title: 'Grievance Detail',
                          description: 'Detail of report',
                          category: 'Roads',
                          status: 'RESOLVED',
                          priority: 'MEDIUM',
                          assignedDepartment: 'Roads Dept',
                          latitude: 12.9716,
                          longitude: 77.5946,
                          imageUrl: '',
                          createdAt: DateTime.now(),
                          slaDeadline: DateTime.now(),
                          agentReasoning: '',
                          timeline: [],
                          comments: [],
                        ),
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ComplaintDetailScreen(complaint: complaint),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
