import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/config/constants.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;

  const MapPickerScreen({
    super.key,
    this.initialLocation = const LatLng(12.9716, 77.5946),
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _currentCenter;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Locate Civic Issue'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation,
              initialZoom: 15.0,
              onPositionChanged: (position, hasGesture) {
                if (position.center != null) {
                  setState(() {
                    _currentCenter = position.center!;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.smartcivic.civic_app',
              ),
            ],
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 38), 
              child: Icon(
                Icons.location_on,
                color: AppColors.severityHigh,
                size: 48,
                shadows: const [
                  Shadow(
                    blurRadius: 4,
                    color: Colors.black45,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: AppConstants.padding * 2,
            left: AppConstants.padding,
            right: AppConstants.padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  color: AppColors.background.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Lat: ${_currentCenter.latitude.toStringAsFixed(6)}, Lng: ${_currentCenter.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _currentCenter);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                    ),
                    child: const Text(
                      'Confirm Location',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
