import '../../../core/services/mock_repository.dart';
import '../models/decision_log_entry.dart';
import '../models/department_metrics.dart';

class MockMapIntelligenceRepository {
  const MockMapIntelligenceRepository();

  List<DepartmentMetrics> getDepartments() {
    return const [
      DepartmentMetrics(
        id: 'dept-roads',
        name: 'Roads Dept',
        trustScore: 88,
        totalComplaints: 34,
        resolvedCount: 27,
        reopenCount: 2,
      ),
      DepartmentMetrics(
        id: 'dept-sanitation',
        name: 'Sanitation Dept',
        trustScore: 72,
        totalComplaints: 29,
        resolvedCount: 19,
        reopenCount: 4,
      ),
      DepartmentMetrics(
        id: 'dept-water',
        name: 'Water Dept',
        trustScore: 81,
        totalComplaints: 22,
        resolvedCount: 18,
        reopenCount: 2,
      ),
      DepartmentMetrics(
        id: 'dept-electricity',
        name: 'Electricity Dept',
        trustScore: 64,
        totalComplaints: 18,
        resolvedCount: 12,
        reopenCount: 5,
      ),
      DepartmentMetrics(
        id: 'dept-infrastructure',
        name: 'Public Infrastructure Dept',
        trustScore: 93,
        totalComplaints: 16,
        resolvedCount: 14,
        reopenCount: 1,
      ),
    ];
  }

  List<DecisionLogEntry> getDecisionLog() {
    final complaints = MockRepository().complaints;
    final entries = complaints.map((complaint) {
      final civicAgentEvents = complaint.timeline.where(
        (event) => event.actor == 'CIVIC_AGENT',
      );
      final timestamp = civicAgentEvents.isEmpty
          ? complaint.createdAt
          : civicAgentEvents.last.timestamp;
      final reason = complaint.agentReasoning
          .replaceFirst('CivicAgent Reason:', '')
          .trim();

      return DecisionLogEntry(
        timestamp: timestamp,
        complaintId: complaint.id,
        action: 'AI_ANALYSIS',
        reason: reason,
        category: complaint.category,
        priority: complaint.priority,
      );
    }).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return entries;
  }
}
