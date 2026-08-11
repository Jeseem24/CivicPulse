import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/constants.dart';
import '../models/decision_log_entry.dart';

class DecisionLogPanel extends StatelessWidget {
  const DecisionLogPanel({super.key, required this.entries});

  final List<DecisionLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.78,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.psychology_alt_outlined, color: AppColors.accent),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'CivicAgent decision log',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Explainable mock decisions derived from the shared complaint dataset.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: entries.isEmpty
                  ? const Center(
                      child: Text(
                        'No CivicAgent decisions yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.complaintId,
                                      style: const TextStyle(
                                        color: AppColors.primaryLight,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    DateFormat(
                                      'MMM d, h:mm a',
                                    ).format(entry.timestamp),
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _Tag(
                                    label: entry.action,
                                    color: AppColors.accent,
                                  ),
                                  _Tag(
                                    label: entry.category,
                                    color: AppColors.primary,
                                  ),
                                  _Tag(
                                    label: entry.priority,
                                    color: _priorityColor(entry.priority),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                entry.reason,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _priorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return AppColors.severityHigh;
      case 'MEDIUM':
        return AppColors.severityMedium;
      default:
        return AppColors.severityLow;
    }
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label.replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
