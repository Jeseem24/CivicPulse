import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../../core/config/constants.dart';
import '../../../../../core/models/complaint.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../core/state/auth_provider.dart';
import '../../../../../core/state/complaint_provider.dart';
import '../../../../map_intelligence/models/decision_log_entry.dart';
import '../../../../map_intelligence/models/department_metrics.dart';
import '../../../../map_intelligence/services/mock_map_intelligence_repository.dart';
import '../../../../map_intelligence/widgets/decision_log_panel.dart';
import '../../../../map_intelligence/widgets/trust_score_panel.dart';
import '../../complaint/complaint_detail_screen.dart';

class CivicMapTab extends StatefulWidget {
  const CivicMapTab({super.key});

  @override
  State<CivicMapTab> createState() => _CivicMapTabState();
}

class _CivicMapTabState extends State<CivicMapTab> {
  static const LatLng _defaultCenter = LatLng(12.9716, 77.5946);

  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final MockMapIntelligenceRepository _intelligenceRepository =
      const MockMapIntelligenceRepository();

  late final List<DepartmentMetrics> _departments;
  late List<DecisionLogEntry> _decisionLog;
  Complaint? _activeComplaint;
  LatLng? _deviceLocation;
  bool _isRefreshing = false;
  bool _isLocating = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _departments = _intelligenceRepository.getDepartments();
    _decisionLog = _intelligenceRepository.getDecisionLog();
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUBMITTED':
      case 'ASSIGNED':
        return const Color(0xFFFACC15);
      case 'IN_PROGRESS':
      case 'AWAITING_VERIFICATION':
        return AppColors.statusInProgress;
      case 'RESOLVED':
      case 'VERIFIED':
      case 'CLOSED':
        return AppColors.statusResolved;
      case 'REOPENED':
        return AppColors.statusReopened;
      default:
        return AppColors.primary;
    }
  }

  double _markerSize(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return 48;
      case 'LOW':
        return 36;
      default:
        return 42;
    }
  }

  bool _hasValidLocation(Complaint complaint) {
    return complaint.latitude >= -90 &&
        complaint.latitude <= 90 &&
        complaint.longitude >= -180 &&
        complaint.longitude <= 180 &&
        !(complaint.latitude == 0 && complaint.longitude == 0);
  }

  Future<void> _locateDevice() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;

      final location = LatLng(position.latitude, position.longitude);
      setState(() => _deviceLocation = location);
      if (_mapReady) _mapController.move(location, 16);
    } catch (error) {
      if (!mounted) return;
      final canOpenSettings = error is LocationFailure &&
          error.settingsTarget != LocationSettingsTarget.none;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            action: canOpenSettings
                ? SnackBarAction(
                    label: 'SETTINGS',
                    onPressed: () {
                      _locationService.openSettingsFor(error);
                    },
                  )
                : null,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _refreshMockData() async {
    setState(() => _isRefreshing = true);
    await context.read<ComplaintProvider>().fetchComplaints();
    if (!mounted) return;
    setState(() {
      _decisionLog = _intelligenceRepository.getDecisionLog();
      _activeComplaint = null;
      _isRefreshing = false;
    });
  }

  void _showTrustScores() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrustScorePanel(departments: _departments),
    );
  }

  void _showDecisionLog() {
    setState(() => _decisionLog = _intelligenceRepository.getDecisionLog());
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DecisionLogPanel(entries: _decisionLog),
    );
  }

  @override
  Widget build(BuildContext context) {
    final complaintProvider = context.watch<ComplaintProvider>();
    final currentUser = context.watch<AuthProvider>().currentUser;
    final complaints = complaintProvider.complaints.where((complaint) {
      if (!_hasValidLocation(complaint)) return false;
      if (currentUser?.role == 'ADMIN') {
        return complaint.departmentId == currentUser?.departmentId;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 13,
              onMapReady: () {
                _mapReady = true;
                _locateDevice();
              },
              onTap: (_, __) => setState(() => _activeComplaint = null),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.smartcivic.civic_app',
              ),
              MarkerLayer(
                markers: [
                  ...complaints.map((complaint) {
                    final color = _statusColor(complaint.status);
                    final size = _markerSize(complaint.priority);
                    return Marker(
                      point: LatLng(complaint.latitude, complaint.longitude),
                      width: size,
                      height: size,
                      child: Semantics(
                        label: '${complaint.title}, ${complaint.status}',
                        button: true,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _activeComplaint = complaint);
                            _mapController.move(
                              LatLng(
                                complaint.latitude,
                                complaint.longitude,
                              ),
                              14.5,
                            );
                          },
                          child: Icon(
                            Icons.location_on,
                            color: color,
                            size: size,
                            shadows: const [
                              Shadow(
                                blurRadius: 7,
                                color: Colors.black54,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  if (_deviceLocation != null)
                    Marker(
                      point: _deviceLocation!,
                      width: 38,
                      height: 38,
                      child: const _DeviceLocationMarker(),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 70,
            child: _MapLegend(complaintCount: complaints.length),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                _MapActionButton(
                  tooltip: 'Department trust scores',
                  icon: Icons.verified_user_outlined,
                  onPressed: _showTrustScores,
                ),
                const SizedBox(height: 10),
                _MapActionButton(
                  tooltip: 'CivicAgent decision log',
                  icon: Icons.psychology_alt_outlined,
                  onPressed: _showDecisionLog,
                ),
                const SizedBox(height: 10),
                _MapActionButton(
                  tooltip: 'Refresh mock data',
                  icon: _isRefreshing ? Icons.hourglass_top : Icons.refresh,
                  onPressed: _isRefreshing ? null : _refreshMockData,
                ),
                const SizedBox(height: 10),
                _MapActionButton(
                  tooltip: 'Use my phone location',
                  icon: _isLocating
                      ? Icons.location_searching
                      : Icons.my_location,
                  onPressed: _isLocating ? null : _locateDevice,
                ),
              ],
            ),
          ),
          if (_activeComplaint != null)
            Positioned(
              bottom: AppConstants.padding,
              left: AppConstants.padding,
              right: AppConstants.padding,
              child: _ComplaintMapCard(
                complaint: _activeComplaint!,
                statusColor: _statusColor(_activeComplaint!.status),
                onView: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ComplaintDetailScreen(complaint: _activeComplaint!),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DeviceLocationMarker extends StatelessWidget {
  const _DeviceLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Your current phone location',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 8),
          ],
        ),
        child: const Icon(Icons.person, color: AppColors.primary, size: 22),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.complaintCount});

  final int complaintCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.background.withValues(alpha: 0.92),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.layers_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '$complaintCount mapped complaints',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const Text(
                  'MOCK',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _LegendItem(label: 'New', color: Color(0xFFFACC15)),
                _LegendItem(
                  label: 'In progress',
                  color: AppColors.statusInProgress,
                ),
                _LegendItem(label: 'Resolved', color: AppColors.statusResolved),
                _LegendItem(label: 'Reopened', color: AppColors.statusReopened),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background.withValues(alpha: 0.94),
      shape: const CircleBorder(),
      elevation: 4,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: AppColors.primary,
        icon: Icon(icon),
      ),
    );
  }
}

class _ComplaintMapCard extends StatelessWidget {
  const _ComplaintMapCard({
    required this.complaint,
    required this.statusColor,
    required this.onView,
  });

  final Complaint complaint;
  final Color statusColor;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      elevation: 8,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.75),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Row(
          children: [
            Icon(Icons.location_on, color: statusColor, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    complaint.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${complaint.category} • ${complaint.departmentName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    children: [
                      _StatusChip(label: complaint.status, color: statusColor),
                      _StatusChip(
                        label: '${complaint.priority} priority',
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(onPressed: onView, child: const Text('View')),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
