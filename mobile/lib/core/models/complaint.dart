import 'timeline_event.dart';
import 'comment.dart';
import '../config/constants.dart';

class Complaint {
  final String id;
  final String userId; // Owner of the report
  final String title;
  final String description;
  final String category;
  final String status; // 'SUBMITTED', 'IN_PROGRESS', 'RESOLVED', 'VERIFIED', 'REOPENED'
  final String priority; // 'LOW', 'MEDIUM', 'HIGH'
  final String assignedDepartment;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime slaDeadline;
  final String agentReasoning;
  final List<TimelineEvent> timeline;
  final List<Comment> comments;

  // Add a clean mapping layer for UI presentation
  DepartmentInfo get departmentInfo {
    return AppConstants.departments.firstWhere(
      (d) => d.backendCategory.toLowerCase() == category.toLowerCase() ||
             d.name.toLowerCase() == category.toLowerCase() ||
             d.id.toLowerCase() == category.toLowerCase(),
      orElse: () => AppConstants.departments.last, // Fallback to Environment & Forests
    );
  }

  String get departmentId => departmentInfo.id;
  String get departmentName => departmentInfo.name;

  Complaint({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.assignedDepartment,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.createdAt,
    required this.slaDeadline,
    required this.agentReasoning,
    required this.timeline,
    required this.comments,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    var timelineListRaw = json['timeline'] as List? ?? [];
    List<TimelineEvent> timelineList = timelineListRaw.map((e) => TimelineEvent.fromJson(e)).toList();

    var commentsListRaw = json['comments'] as List? ?? [];
    List<Comment> commentsList = commentsListRaw.map((e) => Comment.fromJson(e)).toList();

    return Complaint(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? 'user_anonymous',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Other Civic Issues',
      status: json['status'] ?? 'SUBMITTED',
      priority: json['priority'] ?? 'MEDIUM',
      assignedDepartment: json['assigned_department'] ?? 'Unassigned',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      slaDeadline: json['sla_deadline'] != null 
          ? DateTime.parse(json['sla_deadline']) 
          : DateTime.now().add(const Duration(days: 3)), // default fallback SLA
      agentReasoning: json['agent_reasoning'] ?? '',
      timeline: timelineList,
      comments: commentsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'priority': priority,
      'assigned_department': assignedDepartment,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'sla_deadline': slaDeadline.toIso8601String(),
      'agent_reasoning': agentReasoning,
      'timeline': timeline.map((e) => e.toJson()).toList(),
      'comments': comments.map((e) => e.toJson()).toList(),
    };
  }
}
