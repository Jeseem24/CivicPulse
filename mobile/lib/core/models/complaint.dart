import 'timeline_event.dart';
import 'comment.dart';
import '../config/constants.dart';

class Complaint {
  final String id;
  final String userId; // Owner of the report
  final String title;
  final String description;
  final String category;
  final String status; // 'SUBMITTED', 'ASSIGNED', 'IN_PROGRESS', 'AWAITING_VERIFICATION', 'VERIFIED', 'REOPENED'
  final String priority; // 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
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

    // Extract location coordinates
    double lat = 0.0;
    double lng = 0.0;
    if (json['location'] is Map) {
      lat = (json['location']['lat'] as num?)?.toDouble() ?? 0.0;
      lng = (json['location']['lng'] as num?)?.toDouble() ?? 0.0;
    } else {
      lat = (json['latitude'] as num?)?.toDouble() ?? (json['lat'] as num?)?.toDouble() ?? 0.0;
      lng = (json['longitude'] as num?)?.toDouble() ?? (json['lng'] as num?)?.toDouble() ?? 0.0;
    }

    // Extract priority string
    String pStr = 'MEDIUM';
    if (json['priority'] is num) {
      int pNum = (json['priority'] as num).toInt();
      pStr = pNum >= 85 ? 'CRITICAL' : pNum >= 65 ? 'HIGH' : pNum >= 40 ? 'MEDIUM' : 'LOW';
    } else if (json['priority'] is String) {
      pStr = (json['priority'] as String).toUpperCase();
    }

    // Extract SLA deadline
    DateTime sla = DateTime.now().add(const Duration(days: 2));
    if (json['aiAnalysis'] is Map && json['aiAnalysis']['slaDeadline'] != null) {
      sla = DateTime.tryParse(json['aiAnalysis']['slaDeadline']) ?? sla;
    } else if (json['sla_deadline'] != null) {
      sla = DateTime.tryParse(json['sla_deadline']) ?? sla;
    } else if (json['slaDeadline'] != null) {
      sla = DateTime.tryParse(json['slaDeadline']) ?? sla;
    }

    // Extract reasoning
    String reasoning = '';
    if (json['aiAnalysis'] is Map && json['aiAnalysis']['reason'] != null) {
      reasoning = json['aiAnalysis']['reason'];
    } else {
      reasoning = json['agent_reasoning'] ?? json['agentReasoning'] ?? '';
    }

    return Complaint(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? 'user_anonymous',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Public Infrastructure',
      status: (json['status'] ?? 'SUBMITTED').toString().toUpperCase(),
      priority: pStr,
      assignedDepartment: json['department'] ?? json['assigned_department'] ?? json['assignedDepartment'] ?? 'Roads Dept',
      latitude: lat,
      longitude: lng,
      imageUrl: json['photoUrl'] ?? json['photo_url'] ?? json['image_url'] ?? json['imageUrl'] ?? '',
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt']) ?? DateTime.now())
          : json['created_at'] != null 
          ? (DateTime.tryParse(json['created_at']) ?? DateTime.now()) 
          : DateTime.now(),
      slaDeadline: sla,
      agentReasoning: reasoning,
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
