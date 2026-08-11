import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/config/constants.dart';
import '../../../../../core/state/auth_provider.dart';
import '../../../../../core/state/complaint_provider.dart';
import '../../../../../core/models/complaint.dart';
import '../../complaint/complaint_detail_screen.dart';
import '../home_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  // Haversine formula to compute distance in km
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) *
        (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    
    final currentUser = authProvider.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    // Current citizen coordinate fallbacks
    const double currentLat = 12.9716;
    const double currentLng = 77.5946;

    // Filter community reports:
    // 1. Exclude the current user's own reports
    // 2. Limit to a nearby radius (e.g. 5.0 km)
    final nearbyComplaints = complaintProvider.complaints.where((c) {
      final isOwnReport = c.userId == currentUser.id;
      if (isOwnReport) return false;

      final dist = _calculateDistance(currentLat, currentLng, c.latitude, c.longitude);
      return dist <= 5.0; // 5 km radius
    }).toList();

    // Sort by proximity
    nearbyComplaints.sort((a, b) {
      final distA = _calculateDistance(currentLat, currentLng, a.latitude, a.longitude);
      final distB = _calculateDistance(currentLat, currentLng, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => complaintProvider.fetchComplaints(),
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User greeting and top-right profile preview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hello,',
                        style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                      ),
                      Text(
                        '${currentUser.name} 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      final parentState = context.findAncestorStateOfType<HomeScreenState>();
                      parentState?.setIndex(3); // Switch to Profile tab
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: const Icon(Icons.person, color: AppColors.primary, size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Nearby reports header
              const Text(
                'Nearby Community Reports',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Issues reported by citizens within a 5 km radius',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),

              if (nearbyComplaints.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.location_off_outlined, color: AppColors.textMuted, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'No nearby reports found',
                        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your neighborhood is clean!',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: nearbyComplaints.length,
                  itemBuilder: (context, index) {
                    final complaint = nearbyComplaints[index];
                    final distance = _calculateDistance(
                      currentLat,
                      currentLng,
                      complaint.latitude,
                      complaint.longitude,
                    );
                    return _buildNearbyCard(context, complaint, distance);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyCard(BuildContext context, Complaint complaint, double distance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              builder: (context) => ComplaintDetailScreen(
                complaint: complaint,
                mockDistance: distance, // Pass distance for display in detail screen
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Image.network(
                    complaint.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.border,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 48),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primary, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${distance.toStringAsFixed(1)} km away',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(complaint.status).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      complaint.status,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complaint.departmentName.toUpperCase(),
                    style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    complaint.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    complaint.description,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Divider(height: 20, color: AppColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reported: ${complaint.createdAt.day}/${complaint.createdAt.month}/${complaint.createdAt.year}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${complaint.comments.length}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
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
