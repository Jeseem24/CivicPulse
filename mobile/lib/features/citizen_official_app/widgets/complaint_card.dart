import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'package:intl/intl.dart';
import '../../../core/config/constants.dart';
import '../../../core/models/complaint.dart';
import '../screens/complaint/complaint_detail_screen.dart';

class ComplaintCard extends StatelessWidget {
  final Complaint complaint;

  const ComplaintCard({super.key, required this.complaint});

  Widget _buildImage(String url) {
    if (url.isEmpty) {
      return Container(
        height: 140,
        color: AppColors.surface,
        child: const Center(
          child: Icon(
            Icons.image_outlined,
            size: 40,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    if (url.startsWith('http') || url.startsWith('blob:')) {
      return Image.network(
        url,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 140,
            color: AppColors.surface,
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 40,
                color: AppColors.textMuted,
              ),
            ),
          );
        },
      );
    } else {
      if (kIsWeb) {
        return Container(
          height: 140,
          color: AppColors.surface,
          child: const Center(
            child: Icon(
              Icons.image_outlined,
              size: 40,
              color: AppColors.textMuted,
            ),
          ),
        );
      } else {
        return Image.file(
          io.File(url),
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 140,
              color: AppColors.surface,
              child: const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 40,
                  color: AppColors.textMuted,
                ),
              ),
            );
          },
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(complaint.status);
    final priorityColor = _getPriorityColor(complaint.priority);
    final formattedDate = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(complaint.createdAt);

    // Calculate SLA remaining text
    final now = DateTime.now();
    final isOverdue = now.isAfter(complaint.slaDeadline);
    final duration = complaint.slaDeadline.difference(now);

    String slaText = '';
    if (complaint.status == 'VERIFIED') {
      slaText = 'Resolved';
    } else if (isOverdue) {
      slaText = 'SLA Overdue';
    } else {
      final hours = duration.inHours;
      final mins = duration.inMinutes % 60;
      slaText = 'SLA: ${hours}h ${mins}m left';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComplaintDetailScreen(complaint: complaint),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(complaint.imageUrl),
            Padding(
              padding: const EdgeInsets.all(AppConstants.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        complaint.departmentName.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    complaint.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    complaint.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
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
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  complaint.status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
                              '${complaint.priority} PRIORITY',
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
                        slaText,
                        style: TextStyle(
                          color: complaint.status == 'VERIFIED'
                              ? AppColors.textMuted
                              : isOverdue
                              ? AppColors.severityHigh
                              : AppColors.severityMedium,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
