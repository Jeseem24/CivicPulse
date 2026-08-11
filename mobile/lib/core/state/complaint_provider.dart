import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../config/constants.dart';
import '../models/complaint.dart';
import '../models/timeline_event.dart';
import '../services/api_service.dart';

class ComplaintProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Complaint> _complaints = [];
  bool _isLoading = false;
  String? _error;

  List<Complaint> get complaints => _complaints;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ComplaintProvider() {
    _loadMockComplaints();
  }

  void _loadMockComplaints() {
    _complaints = [
      Complaint(
        id: 'c1',
        title: 'Huge Pothole near Central Market',
        description: 'A deep pothole is blocking traffic near the entrance of Central Market. It has caused multiple two-wheeler accidents in the past few days.',
        category: 'Roads',
        status: 'IN_PROGRESS',
        priority: 'HIGH',
        assignedDepartment: 'Roads Dept',
        latitude: 12.971598,
        longitude: 77.594562,
        imageUrl: 'https://images.unsplash.com/photo-1515162305285-0293e4767cc2?q=80&w=600',
        createdAt: DateTime.now().subtract(const Duration(hours: 36)),
        slaDeadline: DateTime.now().add(const Duration(hours: 12)),
        agentReasoning: 'CivicAgent Reason: Pothole located in a high-density market zone. Classified as HIGH priority to mitigate public safety hazards and vehicle damage.',
        timeline: [
          TimelineEvent(
            id: 'e1_1',
            status: 'SUBMITTED',
            title: 'Complaint Submitted',
            description: 'Grievance registered successfully by Citizen.',
            timestamp: DateTime.now().subtract(const Duration(hours: 36)),
            actor: 'CITIZEN',
          ),
          TimelineEvent(
            id: 'e1_2',
            status: 'SUBMITTED',
            title: 'AI Analysis Completed',
            description: 'CivicAgent analyzed report. Department: Roads & Highways, Priority: HIGH. Assigned to Roads & Highways Department.',
            timestamp: DateTime.now().subtract(const Duration(hours: 35, minutes: 45)),
            actor: 'CIVIC_AGENT',
          ),
          TimelineEvent(
            id: 'e1_3',
            status: 'IN_PROGRESS',
            title: 'Work In Progress',
            description: 'Assigned officer Accepted the grievance. Team dispatched to inspect and repair the road.',
            timestamp: DateTime.now().subtract(const Duration(hours: 24)),
            actor: 'OFFICER',
          ),
        ],
      ),
      Complaint(
        id: 'c2',
        title: 'Broken Streetlight on 5th Cross Street',
        description: 'The street lamp opposite House #42 is broken and flickering. The street is pitch black after 7 PM, making it unsafe for walking.',
        category: 'Electricity',
        status: 'RESOLVED',
        priority: 'MEDIUM',
        assignedDepartment: 'Electricity Dept',
        latitude: 12.9698,
        longitude: 77.5912,
        imageUrl: 'https://images.unsplash.com/photo-1509024644558-2f56ce76c490?q=80&w=600',
        createdAt: DateTime.now().subtract(const Duration(hours: 48)),
        slaDeadline: DateTime.now().subtract(const Duration(hours: 24)),
        agentReasoning: 'CivicAgent Reason: Streetlight failure classified as MEDIUM priority. Standard SLA is 24 hours.',
        timeline: [
          TimelineEvent(
            id: 'e2_1',
            status: 'SUBMITTED',
            title: 'Complaint Submitted',
            description: 'Grievance registered successfully by Citizen.',
            timestamp: DateTime.now().subtract(const Duration(hours: 48)),
            actor: 'CITIZEN',
          ),
          TimelineEvent(
            id: 'e2_2',
            status: 'SUBMITTED',
            title: 'AI Routing Complete',
            description: 'CivicAgent categorized issue under Electricity. Assigned priority: MEDIUM.',
            timestamp: DateTime.now().subtract(const Duration(hours: 47, minutes: 50)),
            actor: 'CIVIC_AGENT',
          ),
          TimelineEvent(
            id: 'e2_3',
            status: 'IN_PROGRESS',
            title: 'Work Initiated',
            description: 'Maintenance team accepted. Replacement bulb ordered.',
            timestamp: DateTime.now().subtract(const Duration(hours: 30)),
            actor: 'OFFICER',
          ),
          TimelineEvent(
            id: 'e2_4',
            status: 'RESOLVED',
            title: 'Complaint Resolved',
            description: 'Officer uploaded resolution proof. Streetlight bulb has been replaced and verified working.',
            timestamp: DateTime.now().subtract(const Duration(hours: 6)),
            actor: 'OFFICER',
          ),
        ],
      ),
      Complaint(
        id: 'c3',
        title: 'Overflowing Sewage Drain near Park',
        description: 'The open drain near the public children\'s park is overflowing with sewage water. Terrible smell is spreading and it is a health hazard.',
        category: 'Sanitation',
        status: 'SUBMITTED',
        priority: 'HIGH',
        assignedDepartment: 'Sanitation Dept',
        latitude: 12.9754,
        longitude: 77.5998,
        imageUrl: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?q=80&w=600',
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        slaDeadline: DateTime.now().add(const Duration(hours: 23, minutes: 15)),
        agentReasoning: 'CivicAgent Reason: Sanitation and drainage overflow near a public park involves high disease vectors. Priority set to HIGH. Instant department assignment routed.',
        timeline: [
          TimelineEvent(
            id: 'e3_1',
            status: 'SUBMITTED',
            title: 'Complaint Submitted',
            description: 'Grievance registered successfully by Citizen.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
            actor: 'CITIZEN',
          ),
          TimelineEvent(
            id: 'e3_2',
            status: 'SUBMITTED',
            title: 'CivicAgent Routing',
            description: 'AI detected high health risk factor. Categorized as Sanitation. Priority: HIGH. Allocated 24h SLA.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 44)),
            actor: 'CIVIC_AGENT',
          ),
        ],
      )
    ];
  }

  Future<void> fetchComplaints() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (ApiConfig.useMockMode) {
        await Future.delayed(const Duration(milliseconds: 600));
      } else {
        final response = await _apiService.get(ApiConfig.complaintsEndpoint);
        final List<dynamic> data = jsonDecode(response.body);
        _complaints = data.map((json) => Complaint.fromJson(json)).toList();
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitComplaint({
    required String title,
    required String description,
    required String category, // Holds departmentId (e.g., 'ROADS_HIGHWAYS')
    required double latitude,
    required double longitude,
    required String imagePath,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final deptInfo = AppConstants.departments.firstWhere(
        (d) => d.id == category,
        orElse: () => AppConstants.departments.first,
      );

      if (ApiConfig.useMockMode) {
        await Future.delayed(const Duration(seconds: 1));
        final newComplaintId = 'mock_c_${DateTime.now().millisecondsSinceEpoch}';
        
        String priority = 'MEDIUM';
        String dept = deptInfo.backendDepartment;
        String reasoning = 'CivicAgent Reason: Routed automatically to ${deptInfo.name} based on AI text analysis.';
        
        if (category == 'ROADS_HIGHWAYS' || category == 'WATER_SUPPLY' || category == 'SANITATION_WASTE') {
          priority = 'HIGH';
        } else if (category == 'ELECTRICITY_POWER') {
          priority = 'MEDIUM';
        }

        final newComplaint = Complaint(
          id: newComplaintId,
          title: title,
          description: description,
          category: deptInfo.backendCategory,
          status: 'SUBMITTED',
          priority: priority,
          assignedDepartment: dept,
          latitude: latitude,
          longitude: longitude,
          imageUrl: imagePath.isNotEmpty ? imagePath : 'https://images.unsplash.com/photo-1599740831119-07284763f831?q=80&w=600',
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
        );

        _complaints.insert(0, newComplaint);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final fields = {
          'title': title,
          'description': description,
          'category': deptInfo.backendCategory,
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        };

        final response = await _apiService.postMultipart(
          endpoint: ApiConfig.complaintsEndpoint,
          fields: fields,
          filePath: imagePath,
          fileKey: 'photo',
        );

        final newComplaint = Complaint.fromJson(jsonDecode(response.body));
        _complaints.insert(0, newComplaint);
        
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
                description: 'Citizen verified that the issue has been FIXED. Complaint is closed.',
                timestamp: DateTime.now(),
                actor: 'CITIZEN',
              ),
            ],
          );
          _complaints[index] = updated;
        } else {
          String newPriority = old.priority;
          if (old.priority == 'LOW') {
            newPriority = 'MEDIUM';
          } else if (old.priority == 'MEDIUM') {
            newPriority = 'HIGH';
          }

          final updated = Complaint(
            id: old.id,
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
            agentReasoning: '${old.agentReasoning}\n[Escalated] Citizen reported resolution failure. Re-opened and escalated priority to $newPriority.',
            timeline: [
              ...old.timeline,
              TimelineEvent(
                id: 'e_reopen_${DateTime.now().millisecondsSinceEpoch}',
                status: 'REOPENED',
                title: 'Complaint Reopened',
                description: 'Citizen reported: STILL EXISTS. Complaint reopened and escalated.',
                timestamp: DateTime.now(),
                actor: 'CITIZEN',
              ),
            ],
          );
          _complaints[index] = updated;
        }
      } else {
        final statusValue = isFixed ? 'FIXED' : 'STILL_EXISTS';
        final response = await _apiService.post(
          ApiConfig.getVerifyEndpoint(complaintId),
          {'status': statusValue},
        );
        
        final updatedComplaint = Complaint.fromJson(jsonDecode(response.body));
        _complaints[index] = updatedComplaint;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
