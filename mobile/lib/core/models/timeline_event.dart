class TimelineEvent {
  final String id;
  final String status;      // e.g., 'SUBMITTED', 'IN_PROGRESS', 'RESOLVED', 'VERIFIED', 'REOPENED'
  final String title;
  final String description; // Action details/reasoning
  final DateTime timestamp;
  final String? actor;      // 'CITIZEN', 'CIVIC_AGENT', 'OFFICER'

  TimelineEvent({
    required this.id,
    required this.status,
    required this.title,
    required this.description,
    required this.timestamp,
    this.actor,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'] ?? '',
      status: json['status'] ?? 'SUBMITTED',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      actor: json['actor'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'actor': actor,
    };
  }
}
