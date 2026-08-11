import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/constants.dart';
import '../../../core/services/location_service.dart';
import '../../citizen_official_app/screens/complaint/map_picker_screen.dart';

class LocationPickerWidget extends StatefulWidget {
  const LocationPickerWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final LatLng? value;
  final ValueChanged<LatLng> onChanged;

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  final LocationService _locationService = LocationService();
  bool _isLocating = false;

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      widget.onChanged(LatLng(position.latitude, position.longitude));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current location captured.'),
          backgroundColor: AppColors.severityLow,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final canOpenSettings = error is LocationFailure &&
          error.settingsTarget != LocationSettingsTarget.none;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.severityHigh,
          action: canOpenSettings
              ? SnackBarAction(
                  label: 'SETTINGS',
                  textColor: Colors.white,
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

  Future<void> _selectOnMap() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute<LatLng>(
        builder: (_) => MapPickerScreen(
          initialLocation: widget.value ?? const LatLng(8.2000, 77.3833),
        ),
      ),
    );
    if (result != null) widget.onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    if (value != null) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.padding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_pin,
              color: AppColors.severityHigh,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Confirmed location',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${value.latitude.toStringAsFixed(6)}, ${value.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Change location on map',
              onPressed: _selectOnMap,
              icon: const Icon(
                Icons.edit_location_alt_outlined,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isLocating ? null : _useCurrentLocation,
            icon: _isLocating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(_isLocating ? 'Locating...' : 'Use GPS'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _selectOnMap,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Select on map'),
          ),
        ),
      ],
    );
  }
}
