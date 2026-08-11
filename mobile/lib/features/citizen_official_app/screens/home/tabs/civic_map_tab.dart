import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../../core/config/constants.dart';
import '../../../../../core/state/complaint_provider.dart';
import '../../../../../core/state/auth_provider.dart';
import '../../../../../core/models/complaint.dart';
import '../../complaint/complaint_detail_screen.dart';

class CivicMapTab extends StatefulWidget {
  const CivicMapTab({super.key});

  @override
  State<CivicMapTab> createState() => _CivicMapTabState();
}

class _CivicMapTabState extends State<CivicMapTab> {
  final MapController _mapController = MapController();
  Complaint? _activeComplaint;

  Color _getSeverityColor(String priority) {
    switch (priority) {
      case 'HIGH':
        return AppColors.severityHigh;
      case 'MEDIUM':
        return AppColors.severityMedium;
      case 'LOW':
        return AppColors.severityLow;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    
    final complaints = complaintProvider.complaints.where((c) {
      if (currentUser?.role == 'ADMIN') {
        return c.departmentId == currentUser?.departmentId;
      }
      return true;
    }).toList();
    
    // Default fallback center coordinates (Bangalore Center)
    const LatLng defaultCenter = LatLng(12.9716, 77.5946);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: defaultCenter,
              initialZoom: 13.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _activeComplaint = null; // Close card on tapping empty map
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.smartcivic.civic_app',
              ),
              MarkerLayer(
                markers: complaints.map((complaint) {
                  final color = _getSeverityColor(complaint.priority);
                  return Marker(
                    point: LatLng(complaint.latitude, complaint.longitude),
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _activeComplaint = complaint;
                        });
                        _mapController.move(
                          LatLng(complaint.latitude, complaint.longitude),
                          14.5,
                        );
                      },
                      child: Icon(
                        Icons.location_on,
                        color: color,
                        size: 40,
                        shadows: const [
                          Shadow(
                            blurRadius: 6,
                            color: Colors.black45,
                            offset: Offset(0, 3),
                          )
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          if (_activeComplaint != null)
            Positioned(
              bottom: AppConstants.padding,
              left: AppConstants.padding,
              right: AppConstants.padding,
              child: Card(
                color: AppColors.surface,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  side: const BorderSide(color: AppColors.border, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.padding),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getSeverityColor(_activeComplaint!.priority),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _activeComplaint!.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Department: ${_activeComplaint!.departmentName}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Status: ${_activeComplaint!.status}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _activeComplaint!.status == 'RESOLVED' || _activeComplaint!.status == 'VERIFIED'
                                    ? AppColors.statusResolved
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ComplaintDetailScreen(complaint: _activeComplaint!),
                            ),
                          );
                        },
                        child: const Text('View', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
