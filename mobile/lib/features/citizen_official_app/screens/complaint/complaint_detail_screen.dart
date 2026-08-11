import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/models/complaint.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../../core/state/complaint_provider.dart';
import '../../../../core/state/notification_provider.dart';
import '../../widgets/timeline_widget.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final Complaint complaint;
  final double? mockDistance;

  const ComplaintDetailScreen({
    super.key,
    required this.complaint,
    this.mockDistance,
  });

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  Timer? _timer;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'SUBMITTED':
        return AppColors.statusSubmitted;
      case 'IN_PROGRESS':
        return AppColors.statusInProgress;
      case 'RESOLVED':
      case 'AWAITING_VERIFICATION':
        return AppColors.statusResolved;
      case 'VERIFIED':
        return AppColors.statusVerified;
      case 'REOPENED':
        return AppColors.statusReopened;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'HIGH':
        return AppColors.severityHigh;
      case 'MEDIUM':
        return AppColors.severityMedium;
      case 'LOW':
        return AppColors.severityLow;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getSLAText(Complaint complaint) {
    if (complaint.status == 'VERIFIED') {
      return 'Resolved & Closed';
    }

    final now = DateTime.now();
    final duration = complaint.slaDeadline.difference(now);

    if (duration.isNegative) {
      return 'SLA Overdue (Escalated)';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    return '${hours}h ${minutes}m ${seconds}s left';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final complaintProvider = Provider.of<ComplaintProvider>(context);

    // Refresh complaint model from provider state to catch live updates (comments, resolutions, etc.)
    final complaintIndex = complaintProvider.complaints.indexWhere(
      (c) => c.id == widget.complaint.id,
    );
    final complaint = complaintIndex == -1
        ? widget.complaint
        : complaintProvider.complaints[complaintIndex];

    final statusColor = _getStatusColor(complaint.status);
    final priorityColor = _getPriorityColor(complaint.priority);

    final currentUser = authProvider.currentUser;
    final isLocalAdmin = currentUser?.role == 'ADMIN';
    final isMatchingAdminDept =
        isLocalAdmin && (currentUser?.departmentId == complaint.departmentId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Complaint Tracking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (complaint.imageUrl.isNotEmpty)
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: complaint.imageUrl.startsWith('http')
                    ? Image.network(
                        complaint.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.surface,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 50,
                                color: AppColors.textMuted,
                              ),
                            ),
                          );
                        },
                      )
                    : Image.file(
                        File(complaint.imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.surface,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 50,
                                color: AppColors.textMuted,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  complaint.departmentName.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Created: ${complaint.createdAt.day}/${complaint.createdAt.month}/${complaint.createdAt.year}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              complaint.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          complaint.status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          complaint.priority,
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _getSLAText(complaint),
                    style: TextStyle(
                      color: complaint.status == 'VERIFIED'
                          ? AppColors.textMuted
                          : complaint.slaDeadline
                                .difference(DateTime.now())
                                .isNegative
                          ? AppColors.severityHigh
                          : AppColors.severityMedium,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Description & Metadata
            const Text(
              'Grievance Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complaint.description,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reported By: ${complaint.userId == currentUser?.id ? "You (Citizen)" : "Community Member"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (widget.mockDistance != null)
                        Text(
                          'Location: ${widget.mockDistance!.toStringAsFixed(1)} km away',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Official Resolution Flow
            if (isMatchingAdminDept &&
                complaint.status != 'RESOLVED' &&
                complaint.status != 'AWAITING_VERIFICATION' &&
                complaint.status != 'VERIFIED') ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusResolved,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'ISSUE CLEARED',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: () async {
                    final adminName = currentUser?.name ?? 'Official';
                    final success = await complaintProvider
                        .resolveComplaintByAdmin(complaint.id, adminName);
                    if (success && mounted) {
                      // Trigger notifications updates in Provider
                      Provider.of<NotificationProvider>(
                        context,
                        listen: false,
                      ).refreshNotifications();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Issue marked as CLEARED. User has been notified.',
                          ),
                          backgroundColor: AppColors.severityLow,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // AI analysis card
            Container(
              padding: const EdgeInsets.all(AppConstants.padding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withOpacity(0.08),
                    AppColors.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.psychology,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'CivicAgent AI Analysis',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildAIField(
                    'Assigned Department',
                    complaint.assignedDepartment,
                  ),
                  const SizedBox(height: 8),
                  _buildAIField('Priority Scoring Level', complaint.priority),
                  const SizedBox(height: 8),
                  _buildAIField('Reasoning Logs', complaint.agentReasoning),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Resolution verification loop (Citizen view)
            if (!isLocalAdmin &&
                (complaint.status == 'RESOLVED' ||
                    complaint.status == 'AWAITING_VERIFICATION')) ...[
              Card(
                color: AppColors.surface,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Resolution Verification Loop',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'The department has resolved this grievance. Has this issue actually been fixed to your satisfaction?',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.severityLow,
                                foregroundColor: AppColors.background,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () {
                                complaintProvider.verifyResolution(
                                  complaint.id,
                                  true,
                                );
                              },
                              icon: const Icon(Icons.check),
                              label: const Text(
                                'FIXED',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.severityHigh,
                                foregroundColor: AppColors.textPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () {
                                complaintProvider.verifyResolution(
                                  complaint.id,
                                  false,
                                );
                              },
                              icon: const Icon(Icons.warning_amber_rounded),
                              label: const Text(
                                'STILL EXISTS',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Comments/Reviews section
            const Text(
              'Comments & Discussions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (complaint.comments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No comments yet. Write a comment to join the discussion.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: complaint.comments.length,
                itemBuilder: (context, index) {
                  final comment = complaint.comments[index];
                  final formattedCommentTime =
                      '${comment.timestamp.hour.toString().padLeft(2, '0')}:${comment.timestamp.minute.toString().padLeft(2, '0')}';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              comment.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              formattedCommentTime,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          comment.text,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // Add comment input (Only for Citizens or matching departments)
            if (currentUser?.role == 'USER') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        hintStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      if (_commentController.text.trim().isNotEmpty) {
                        complaintProvider.postComment(
                          complaint.id,
                          currentUser?.name ?? 'Citizen',
                          _commentController.text.trim(),
                        );
                        _commentController.clear();
                      }
                    },
                    child: const Text(
                      'Post',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),

            // Timeline lifecycle
            const Text(
              'Complaint Lifecycle Audit Trail',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TimelineWidget(events: complaint.timeline),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildAIField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
