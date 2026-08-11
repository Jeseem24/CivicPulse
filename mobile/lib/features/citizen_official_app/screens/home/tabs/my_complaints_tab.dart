import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/config/constants.dart';
import '../../../../../core/state/complaint_provider.dart';
import '../../../../../core/state/auth_provider.dart';
import '../../../../../core/models/user.dart';
import '../../../widgets/complaint_grid_card.dart';

class MyComplaintsTab extends StatefulWidget {
  const MyComplaintsTab({super.key});

  @override
  State<MyComplaintsTab> createState() => _MyComplaintsTabState();
}

class _MyComplaintsTabState extends State<MyComplaintsTab> {
  String _selectedFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final allComplaints = complaintProvider.complaints;

    final filteredComplaints = allComplaints.where((complaint) {
      // Admin department restriction
      if (currentUser?.role == 'ADMIN') {
        if (complaint.departmentId != currentUser?.departmentId) {
          return false;
        }
      }

      // Citizen personal complaints restriction
      if (currentUser?.role == 'USER') {
        if (complaint.userId != currentUser?.id) {
          return false;
        }
      }

      if (_selectedFilter == 'ALL') return true;
      if (_selectedFilter == 'PENDING') {
        return complaint.status == 'SUBMITTED' ||
            complaint.status == 'ASSIGNED' ||
            complaint.status == 'IN_PROGRESS' ||
            complaint.status == 'REOPENED';
      }
      if (_selectedFilter == 'RESOLVED') {
        return complaint.status == 'RESOLVED' ||
            complaint.status == 'AWAITING_VERIFICATION' ||
            complaint.status == 'VERIFIED';
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => complaintProvider.fetchComplaints(),
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentUser?.role == 'ADMIN') ...[
                      _buildAdminHeaderCard(
                        context,
                        currentUser!,
                        filteredComplaints.length,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        _buildFilterChip('ALL', 'All Reports'),
                        const SizedBox(width: 8),
                        _buildFilterChip('PENDING', 'Active'),
                        const SizedBox(width: 8),
                        _buildFilterChip('RESOLVED', 'Resolved'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (filteredComplaints.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 64,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No complaints found',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap the + button to report a new issue.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.padding,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return ComplaintGridCard(
                      complaint: filteredComplaints[index],
                    );
                  }, childCount: filteredComplaints.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      disabledColor: AppColors.surface,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.border,
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildAdminHeaderCard(BuildContext context, User admin, int count) {
    final deptName = AppConstants.departments
        .firstWhere(
          (d) => d.id == admin.departmentId,
          orElse: () => AppConstants.departments.first,
        )
        .name;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome, Admin',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      admin.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),
          const Text(
            'DEPARTMENT ASSIGNMENT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            deptName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Department Grievances',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.background,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
