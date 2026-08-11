import 'package:flutter/material.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/models/complaint.dart';
import '../screens/complaint/complaint_detail_screen.dart';

class ComplaintGridCard extends StatelessWidget {
  final Complaint complaint;

  const ComplaintGridCard({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    final formattedDate = '${complaint.createdAt.day}/${complaint.createdAt.month}/${complaint.createdAt.year}';
    final statusColor = _getStatusColor(complaint.status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
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
            // Image header
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    complaint.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.border,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textMuted,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        complaint.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info body
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complaint.departmentName.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    complaint.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        return AppColors.primary;
    }
  }
}
