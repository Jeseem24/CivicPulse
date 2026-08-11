class DecisionLogEntry {
  const DecisionLogEntry({
    required this.timestamp,
    required this.complaintId,
    required this.action,
    required this.reason,
    required this.category,
    required this.priority,
  });

  final DateTime timestamp;
  final String complaintId;
  final String action;
  final String reason;
  final String category;
  final String priority;
}
