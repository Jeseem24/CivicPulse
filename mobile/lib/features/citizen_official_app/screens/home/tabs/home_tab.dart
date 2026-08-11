import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/config/constants.dart';
import '../../../../../core/state/auth_provider.dart';
import '../../../../../core/state/complaint_provider.dart';
import '../../../../../core/state/settings_provider.dart';
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
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    final currentUser = authProvider.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    // Current citizen coordinate fallbacks
    const double currentLat = 12.9716;
    const double currentLng = 77.5946;

    final radiusKm = settingsProvider.radiusKm;

    // Filter community reports:
    // 1. Exclude the current user's own reports
    // 2. Limit to the user-configured radius
    final nearbyComplaints = complaintProvider.complaints.where((c) {
      final isOwnReport = c.userId == currentUser.id;
      if (isOwnReport) return false;

      final dist = _calculateDistance(currentLat, currentLng, c.latitude, c.longitude);
      return dist <= radiusKm;
    }).toList();

    // Sort by proximity
    nearbyComplaints.sort((a, b) {
      final distA = _calculateDistance(currentLat, currentLng, a.latitude, a.longitude);
      final distB = _calculateDistance(currentLat, currentLng, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });

    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => complaintProvider.fetchComplaints(),
        color: theme.colorScheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppConstants.padding),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User greeting and top-right profile preview
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello,',
                                style: TextStyle(fontSize: 16, color: theme.textTheme.bodySmall?.color),
                              ),
                              Text(
                                '${currentUser.name} 👋',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            final parentState = context.findAncestorStateOfType<HomeScreenState>();
                            parentState?.setIndex(3); // Switch to Profile tab
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  child: Icon(Icons.person, color: theme.colorScheme.primary, size: 16),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right, color: theme.textTheme.bodySmall?.color, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Nearby reports header
                    Text(
                      'Nearby Community Reports',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Issues reported by citizens within ${radiusKm.toStringAsFixed(0)} km radius',
                      style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            if (nearbyComplaints.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.location_off_outlined, color: theme.textTheme.bodySmall?.color, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No nearby reports found',
                          style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try increasing your radius in Settings',
                          style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.padding),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final complaint = nearbyComplaints[index];
                      final distance = _calculateDistance(
                        currentLat,
                        currentLng,
                        complaint.latitude,
                        complaint.longitude,
                      );
                      return _buildNearbyGridCard(context, complaint, distance);
                    },
                    childCount: nearbyComplaints.length,
                  ),
                ),
              ),

            // Bottom spacing
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyGridCard(BuildContext context, Complaint complaint, double distance) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComplaintDetailScreen(
                complaint: complaint,
                mockDistance: distance,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    complaint.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: theme.dividerColor,
                        child: Center(
                          child: Icon(Icons.broken_image_outlined, color: theme.textTheme.bodySmall?.color, size: 32),
                        ),
                      );
                    },
                  ),
                  // Distance badge (top-right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, color: theme.colorScheme.primary, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            '${distance.toStringAsFixed(1)} km',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Status badge (top-left)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getStatusColor(complaint.status).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        complaint.status,
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
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
                    style: TextStyle(
                      color: theme.colorScheme.primary,
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
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${complaint.createdAt.day}/${complaint.createdAt.month}/${complaint.createdAt.year}',
                        style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 9),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 11, color: theme.textTheme.bodySmall?.color),
                          const SizedBox(width: 2),
                          Text(
                            '${complaint.comments.length}',
                            style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color),
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
