import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../config/constants.dart';
import '../models/complaint.dart';
import '../models/timeline_event.dart';
import '../models/comment.dart';
import '../services/api_service.dart';
import '../services/mock_repository.dart';

class ComplaintProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Complaint> _complaints = [];
  bool _isLoading = false;
  bool _isFetching = false;
  String? _error;

  List<Complaint> get complaints => _complaints;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ComplaintProvider() {
    if (ApiConfig.useMockMode) {
      _loadMockComplaints();
    }
  }

  void _loadMockComplaints() {
    _complaints = MockRepository().complaints;
  }

  Future<void> fetchComplaints({bool silent = false}) async {
    if (_isFetching || (silent && _isLoading)) return;
    _isFetching = true;
    if (!silent) _isLoading = true;
    _error = null;
    if (!silent) notifyListeners();

    try {
      if (ApiConfig.useMockMode) {
        await Future.delayed(const Duration(milliseconds: 600));
        _complaints = List.from(MockRepository().complaints);
      } else {
        final response = await _apiService.get(
          ApiConfig.complaintsEndpoint,
          requireAuth: false,
        );
        final List<dynamic> data = jsonDecode(response.body);
        _complaints = data.map((json) => Complaint.fromJson(json)).toList();
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isFetching = false;
      if (!silent) _isLoading = false;
      notifyListeners();
    }
  }

  String _imageMimeType(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
      return 'image/webp';
    }
    throw Exception('Please choose a JPEG, PNG, or WebP image.');
  }

  Future<String> _imageAsDataUri(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    if (bytes.length > 8 * 1024 * 1024) {
      throw Exception('The selected image is larger than 8 MB.');
    }
    final mimeType = _imageMimeType(bytes);
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  void _upsertLiveComplaint(Complaint complaint, {bool prepend = false}) {
    final index = _complaints.indexWhere((item) => item.id == complaint.id);
    if (index >= 0) {
      _complaints[index] = complaint;
    } else if (prepend) {
      _complaints.insert(0, complaint);
    } else {
      _complaints.add(complaint);
    }
  }

  Future<bool> submitComplaint({
    required String title,
    required String description,
    required String category, // Holds departmentId (e.g., 'ROADS_HIGHWAYS')
    required double latitude,
    required double longitude,
    required String imagePath,
    String? userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final deptInfo = AppConstants.departments.firstWhere(
        (d) => d.id == category,
        orElse: () => AppConstants.departments.first,
      );

      if (ApiConfig.useMockMode) {
        await Future.delayed(const Duration(seconds: 1));
        final newComplaintId =
            'mock_c_${DateTime.now().millisecondsSinceEpoch}';

        String priority = 'MEDIUM';
        String dept = deptInfo.backendDepartment;
        String reasoning =
            'CivicAgent Reason: Routed automatically to ${deptInfo.name} based on AI text analysis.';

        if (category == 'ROADS_HIGHWAYS' ||
            category == 'WATER_SUPPLY' ||
            category == 'SANITATION_WASTE') {
          priority = 'HIGH';
        } else if (category == 'ELECTRICITY_POWER') {
          priority = 'MEDIUM';
        }

        final newComplaint = Complaint(
          id: newComplaintId,
          userId: userId ?? 'user_citizen',
          title: title,
          description: description,
          category: deptInfo.backendCategory,
          status: 'SUBMITTED',
          priority: priority,
          assignedDepartment: dept,
          latitude: latitude,
          longitude: longitude,
          imageUrl: imagePath.isNotEmpty
              ? imagePath
              : 'https://images.unsplash.com/photo-1599740831119-07284763f831?q=80&w=600',
          createdAt: DateTime.now(),
          slaDeadline: DateTime.now().add(const Duration(days: 2)),
          agentReasoning: reasoning,
          timeline: [
            TimelineEvent(
              id: '${newComplaintId}_e1',
              status: 'SUBMITTED',
              title: 'Complaint Submitted',
              description: 'Grievance registered successfully by Citizen.',
              timestamp: DateTime.now(),
              actor: 'CITIZEN',
            ),
            TimelineEvent(
              id: '${newComplaintId}_e2',
              status: 'SUBMITTED',
              title: 'AI Analysis Completed',
              description: '$reasoning Assigned to $dept.',
              timestamp: DateTime.now().add(const Duration(seconds: 2)),
              actor: 'CIVIC_AGENT',
            ),
          ],
          comments: [],
        );

        MockRepository().complaints.insert(0, newComplaint);
        _complaints = List.from(MockRepository().complaints);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final photoData = await _imageAsDataUri(imagePath);
        final payload = {
          'title': title,
          'description': description,
          'category': deptInfo.backendCategory,
          'location': {
            'lat': latitude,
            'lng': longitude,
            'address': 'Submitted via CivicPulse Mobile App',
          },
          'photoData': photoData,
          'userId': userId ?? 'user_anonymous',
        };

        final response = await _apiService.post(
          ApiConfig.complaintsEndpoint,
          payload,
          requireAuth: false,
        );

        final newComplaint = Complaint.fromJson(jsonDecode(response.body));
        _upsertLiveComplaint(newComplaint, prepend: true);

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> postComment(
    String complaintId,
    String userName,
    String text,
  ) async {
    final comment = Comment(
      id: 'mock_com_${DateTime.now().millisecondsSinceEpoch}',
      userName: userName,
      text: text,
      timestamp: DateTime.now(),
    );

    MockRepository().addComment(complaintId, comment);
    _complaints = List.from(MockRepository().complaints);
    notifyListeners();
  }

  Future<bool> resolveComplaintByAdmin(
    String complaintId,
    String adminName,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (ApiConfig.useMockMode) {
        await Future.delayed(const Duration(milliseconds: 800));
        MockRepository().resolveComplaint(complaintId, adminName);
        _complaints = List.from(MockRepository().complaints);
        return true;
      } else {
        final response = await _apiService.patch(
          '${ApiConfig.complaintsEndpoint}/$complaintId/resolve',
          {'description': 'Resolved by official $adminName'},
          requireAuth: false,
        );
        if (response.statusCode == 200) {
          final updatedComplaint = Complaint.fromJson(
            jsonDecode(response.body),
          );
          _upsertLiveComplaint(updatedComplaint);
          return true;
        }
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyResolution(String complaintId, bool isFixed) async {
    final index = _complaints.indexWhere((c) => c.id == complaintId);
    if (index == -1) return;

    final old = _complaints[index];
    _isLoading = true;
    notifyListeners();

    try {
      if (ApiConfig.useMockMode) {
        if (isFixed) {
          final updated = Complaint(
            id: old.id,
            userId: old.userId,
            title: old.title,
            description: old.description,
            category: old.category,
            status: 'VERIFIED',
            priority: old.priority,
            assignedDepartment: old.assignedDepartment,
            latitude: old.latitude,
            longitude: old.longitude,
            imageUrl: old.imageUrl,
            createdAt: old.createdAt,
            slaDeadline: old.slaDeadline,
            agentReasoning: old.agentReasoning,
            timeline: [
              ...old.timeline,
              TimelineEvent(
                id: 'e_verify_${DateTime.now().millisecondsSinceEpoch}',
                status: 'VERIFIED',
                title: 'Resolution Verified',
                description:
                    'Citizen verified that the issue has been FIXED. Complaint is closed.',
                timestamp: DateTime.now(),
                actor: 'CITIZEN',
              ),
            ],
            comments: old.comments,
          );

          final repoIndex = MockRepository().complaints.indexWhere(
            (c) => c.id == complaintId,
          );
          if (repoIndex != -1) {
            MockRepository().complaints[repoIndex] = updated;
          }
          _complaints = List.from(MockRepository().complaints);
        } else {
          String newPriority = old.priority;
          if (old.priority == 'LOW') {
            newPriority = 'MEDIUM';
          } else if (old.priority == 'MEDIUM') {
            newPriority = 'HIGH';
          }

          final updated = Complaint(
            id: old.id,
            userId: old.userId,
            title: old.title,
            description: old.description,
            category: old.category,
            status: 'REOPENED',
            priority: newPriority,
            assignedDepartment: old.assignedDepartment,
            latitude: old.latitude,
            longitude: old.longitude,
            imageUrl: old.imageUrl,
            createdAt: old.createdAt,
            slaDeadline: DateTime.now().add(const Duration(hours: 12)),
            agentReasoning:
                '${old.agentReasoning}\n[Escalated] Citizen reported resolution failure. Re-opened and escalated priority to $newPriority.',
            timeline: [
              ...old.timeline,
              TimelineEvent(
                id: 'e_reopen_${DateTime.now().millisecondsSinceEpoch}',
                status: 'REOPENED',
                title: 'Complaint Reopened',
                description:
                    'Citizen reported: STILL EXISTS. Complaint reopened and escalated.',
                timestamp: DateTime.now(),
                actor: 'CITIZEN',
              ),
            ],
            comments: old.comments,
          );

          final repoIndex = MockRepository().complaints.indexWhere(
            (c) => c.id == complaintId,
          );
          if (repoIndex != -1) {
            MockRepository().complaints[repoIndex] = updated;
          }
          _complaints = List.from(MockRepository().complaints);
        }
      } else {
        final resultValue = isFixed ? 'fixed' : 'still_exists';
        final response = await _apiService.patch(
          ApiConfig.getVerifyEndpoint(complaintId),
          {'result': resultValue},
          requireAuth: false,
        );

        final updatedComplaint = Complaint.fromJson(jsonDecode(response.body));
        _upsertLiveComplaint(updatedComplaint);
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
