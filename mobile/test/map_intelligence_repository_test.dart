import 'package:flutter_test/flutter_test.dart';

import 'package:civic_app/core/services/mock_repository.dart';
import 'package:civic_app/features/map_intelligence/services/mock_map_intelligence_repository.dart';

void main() {
  const repository = MockMapIntelligenceRepository();

  test('mock department trust scores stay within display bounds', () {
    final departments = repository.getDepartments();

    expect(departments, hasLength(5));
    expect(
      departments.every(
        (department) =>
            department.trustScore >= 0 && department.trustScore <= 100,
      ),
      isTrue,
    );
  });

  test('decision log reuses the shared mock complaint dataset', () {
    final complaintIds = MockRepository().complaints
        .map((item) => item.id)
        .toSet();
    final decisions = repository.getDecisionLog();

    expect(decisions, isNotEmpty);
    expect(
      decisions.every((entry) => complaintIds.contains(entry.complaintId)),
      isTrue,
    );
    expect(decisions.every((entry) => entry.reason.isNotEmpty), isTrue);
  });
}
