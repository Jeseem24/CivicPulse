import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/state/complaint_provider.dart';
import '../../../../core/services/camera_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/ai_prediction_service.dart';
import '../../widgets/custom_button.dart';
import 'map_picker_screen.dart';

class ReportComplaintScreen extends StatefulWidget {
  const ReportComplaintScreen({super.key});

  @override
  State<ReportComplaintScreen> createState() => _ReportComplaintScreenState();
}

class _ReportComplaintScreenState extends State<ReportComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descFocusNode = FocusNode();
  
  String? _selectedCategory; // Holds the predicted/selected department ID
  String? _imagePath;
  LatLng? _selectedLocation;
  
  bool _isLocating = false;
  bool _isPredicting = false;
  String? _predictionError;
  double? _confidence;

  final CameraService _cameraService = CameraService();
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _titleFocusNode.addListener(_onFocusChange);
    _descFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _titleFocusNode.removeListener(_onFocusChange);
    _descFocusNode.removeListener(_onFocusChange);
    _titleFocusNode.dispose();
    _descFocusNode.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_titleFocusNode.hasFocus && !_descFocusNode.hasFocus) {
      if (_titleController.text.trim().isNotEmpty &&
          _descriptionController.text.trim().isNotEmpty &&
          _selectedCategory == null &&
          !_isPredicting &&
          _predictionError == null) {
        _runAiPrediction();
      }
    }
  }

  Future<void> _runAiPrediction() async {
    final title = _titleController.text.trim();
    final desc = _descriptionController.text.trim();
    if (title.isEmpty || desc.isEmpty) return;

    setState(() {
      _isPredicting = true;
      _predictionError = null;
      _selectedCategory = null;
      _confidence = null;
    });

    try {
      final result = await AiPredictionService.predictDepartment(title, desc);
      setState(() {
        _selectedCategory = result['departmentId'];
        _confidence = result['confidence'];
        _isPredicting = false;
      });
    } catch (e) {
      setState(() {
        _predictionError = e.toString();
        _isPredicting = false;
      });
    }
  }

  Future<void> _pickImage(bool fromCamera) async {
    final path = fromCamera
        ? await _cameraService.pickImageFromCamera()
        : await _cameraService.pickImageFromGallery();
    
    if (path != null) {
      setState(() {
        _imagePath = path;
      });
    }
  }

  Future<void> _fetchGPS() async {
    setState(() {
      _isLocating = true;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS coordinates successfully captured!'),
            backgroundColor: AppColors.severityLow,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get GPS: ${e.toString()}'),
            backgroundColor: AppColors.severityHigh,
          ),
        );
      }
    } finally {
      setState(() {
        _isLocating = false;
      });
    }
  }

  Future<void> _openMapPicker() async {
    final startLoc = _selectedLocation ?? const LatLng(12.9716, 77.5946);
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(initialLocation: startLoc),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isPredicting) {
      _showErrorSnackBar('AI prediction is still running. Please wait.');
      return;
    }
    if (_selectedCategory == null) {
      _showErrorSnackBar('Department selection is required. Please fill title/description to run AI prediction.');
      return;
    }
    if (_imagePath == null) {
      _showErrorSnackBar('Please upload/take a photo of the issue.');
      return;
    }
    if (_selectedLocation == null) {
      _showErrorSnackBar('Please attach coordinates or select location.');
      return;
    }

    final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);
    final success = await complaintProvider.submitComplaint(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory!,
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
      imagePath: _imagePath!,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint submitted successfully. AI analysis initiated!'),
          backgroundColor: AppColors.severityLow,
        ),
      );
      Navigator.pop(context);
    } else {
      _showErrorSnackBar(complaintProvider.error ?? 'Submission failed.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.severityHigh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final complaintProvider = Provider.of<ComplaintProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('File Complaint'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Title',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                decoration: const InputDecoration(
                  hintText: 'e.g., Streetlight broken for 3 days',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                focusNode: _descFocusNode,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe the issue. Include landmarks if possible. Backend AI will analyze this description text.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe the issue';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Grievance Department Routing',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildPredictionWidget(),
              const SizedBox(height: 24),
              const Text(
                'Photo Evidence',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: 12),
              if (_imagePath != null)
                Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        border: Border.all(color: AppColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _imagePath!.startsWith('http')
                          ? Image.network(_imagePath!, fit: BoxFit.cover)
                          : Image.file(File(_imagePath!), fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _imagePath = null;
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.6),
                          child: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                          ),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        onPressed: () => _pickImage(true),
                        icon: const Icon(Icons.camera_alt, color: AppColors.primary),
                        label: const Text('Take Photo', style: TextStyle(color: AppColors.textPrimary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                          ),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        onPressed: () => _pickImage(false),
                        icon: const Icon(Icons.photo_library, color: AppColors.primary),
                        label: const Text('From Gallery', style: TextStyle(color: AppColors.textPrimary)),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              const Text(
                'Location Coordinates',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: 12),
              if (_selectedLocation != null)
                Container(
                  padding: const EdgeInsets.all(AppConstants.padding),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_pin, color: AppColors.severityHigh, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Confirmed Location Coordinates', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(
                              'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_location_alt_outlined, color: AppColors.primary),
                        onPressed: _openMapPicker,
                      )
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                          ),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        onPressed: _isLocating ? null : _fetchGPS,
                        icon: _isLocating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primary)),
                              )
                            : const Icon(Icons.my_location, color: AppColors.primary),
                        label: Text(_isLocating ? 'Locating...' : 'Get Current GPS', style: const TextStyle(color: AppColors.textPrimary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                          ),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        onPressed: _openMapPicker,
                        icon: const Icon(Icons.map_outlined, color: AppColors.primary),
                        label: const Text('Select on Map', style: TextStyle(color: AppColors.textPrimary)),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 40),
              CustomButton(
                text: 'Submit Grievance',
                onPressed: _submit,
                isLoading: complaintProvider.isLoading,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionWidget() {
    if (_isPredicting) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
            ),
            SizedBox(height: 12),
            Text(
              'Analyzing complaint...',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Detecting responsible department...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_predictionError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: AppColors.severityHigh.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.severityHigh, size: 36),
            const SizedBox(height: 8),
            Text(
              'AI prediction failed: $_predictionError',
              style: const TextStyle(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _runAiPrediction,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _predictionError = null;
                      _selectedCategory = AppConstants.departments.first.id;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: const Text('Manual Select', style: TextStyle(color: AppColors.textPrimary)),
                ),
              ],
            )
          ],
        ),
      );
    }

    if (_selectedCategory != null) {
      final selectedDept = AppConstants.departments.firstWhere(
        (d) => d.id == _selectedCategory,
        orElse: () => AppConstants.departments.first,
      );

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: AppColors.primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AI PREDICTED DEPARTMENT',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1),
                ),
                if (_confidence != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.severityLow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Confidence: ${(_confidence! * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 11, color: AppColors.severityLow, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.severityLow),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedDept.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.border),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Modify Department (Optional)',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: AppConstants.departments.map((dept) {
                return DropdownMenuItem<String>(
                  value: dept.id,
                  child: Text(dept.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  _confidence = null; // Clear confidence if manually adjusted
                });
              },
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.psychology_outlined, color: AppColors.textMuted, size: 40),
          const SizedBox(height: 8),
          const Text(
            'Auto Department Prediction',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'AI will analyze your description to assign the correct government department.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: (_titleController.text.trim().isNotEmpty && _descriptionController.text.trim().isNotEmpty)
                ? _runAiPrediction
                : null,
            icon: const Icon(Icons.online_prediction, size: 16),
            label: const Text('Predict Department'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              disabledBackgroundColor: AppColors.surface,
              disabledForegroundColor: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
