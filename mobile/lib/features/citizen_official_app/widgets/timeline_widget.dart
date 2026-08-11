import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/config/constants.dart';
import '../../../core/models/timeline_event.dart';

class TimelineWidget extends StatelessWidget {
  final List<TimelineEvent> events;

  const TimelineWidget({super.key, required this.events});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'SUBMITTED':
        return AppColors.statusSubmitted;
      case 'IN_PROGRESS':
        return AppColors.statusInProgress;
      case 'RESOLVED':
        return AppColors.statusResolved;
      case 'VERIFIED':
        return AppColors.statusVerified;
      case 'REOPENED':
        return AppColors.statusReopened;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'SUBMITTED':
        return Icons.post_add;
      case 'IN_PROGRESS':
        return Icons.construction;
      case 'RESOLVED':
        return Icons.done_all;
      case 'VERIFIED':
        return Icons.verified_user;
      case 'REOPENED':
        return Icons.replay_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedEvents = List<TimelineEvent>.from(events)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedEvents.length,
      itemBuilder: (context, index) {
        final event = sortedEvents[index];
        final isLast = index == sortedEvents.length - 1;
        final color = _getStatusColor(event.status);
        final icon = _getStatusIcon(event.status);
        final formattedTime = DateFormat('dd MMM yyyy, hh:mm a').format(event.timestamp);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppColors.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (event.actor != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                event.actor!,
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedTime,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
