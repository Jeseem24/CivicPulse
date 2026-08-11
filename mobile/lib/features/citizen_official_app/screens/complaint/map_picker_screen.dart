import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/services/location_service.dart';

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
  final LocationService _locationService = LocationService();
  LatLng? _deviceLocation;
  bool _isLocating = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialLocation;
  }

  bool get _startsAtFallback =>
      widget.initialLocation.latitude == 12.9716 &&
      widget.initialLocation.longitude == 77.5946;

  Future<void> _locateDevice() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;

      final location = LatLng(position.latitude, position.longitude);
      setState(() {
        _deviceLocation = location;
        _currentCenter = location;
      });
      if (_mapReady) _mapController.move(location, 17);
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
              onMapReady: () {
                _mapReady = true;
                if (_startsAtFallback) _locateDevice();
              },
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
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.smartcivic.civic_app',
              ),
              if (_deviceLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _deviceLocation!,
                      width: 26,
                      height: 26,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: AppConstants.padding,
            right: AppConstants.padding,
            child: FloatingActionButton.small(
              heroTag: 'map-picker-device-location',
              tooltip: 'Use my phone location',
              onPressed: _isLocating ? null : _locateDevice,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              child: _isLocating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
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
                  color: AppColors.background.withValues(alpha: 0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
