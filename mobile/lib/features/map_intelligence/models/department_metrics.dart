class DepartmentMetrics {
  const DepartmentMetrics({
    required this.id,
    required this.name,
    required this.trustScore,
    required this.totalComplaints,
    required this.resolvedCount,
    required this.reopenCount,
  });

  final String id;
  final String name;
  final int trustScore;
  final int totalComplaints;
  final int resolvedCount;
  final int reopenCount;
}
