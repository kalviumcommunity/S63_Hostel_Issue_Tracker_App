import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/issue_model.dart';

class IssueCard extends StatelessWidget {
  final IssueModel issue;
  final bool isAdmin;
  const IssueCard({super.key, required this.issue, this.isAdmin = false});

  Color get _statusColor {
    switch (issue.status) {
      case statusInProgress: return const Color(0xFFFFB347);
      case statusResolved: return const Color(0xFF4CAF94);
      default: return const Color(0xFFFF6B6B);
    }
  }

  String get _statusLabel {
    switch (issue.status) {
      case statusPending: return 'Pending';
      case statusInProgress: return 'In Progress';
      case statusResolved: return 'Resolved';
      default: return issue.status;
    }
  }

  IconData get _categoryIcon {
    switch (issue.category) {
      case 'Mess Food': return Icons.restaurant_outlined;
      case 'Water Problem': return Icons.water_drop_outlined;
      case 'Electricity': return Icons.bolt_outlined;
      case 'Room Maintenance': return Icons.build_outlined;
      case 'Cleanliness': return Icons.clean_hands_outlined;
      case 'Internet / WiFi': return Icons.wifi_outlined;
      case 'Security': return Icons.security_outlined;
      default: return Icons.report_problem_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/issue/${issue.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A3E)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_categoryIcon, color: _statusColor, size: 22),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          issue.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Badge(label: _statusLabel, color: _statusColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    issue.description,
                    style: const TextStyle(
                        color: Color(0xFF9E9EBF),
                        fontSize: 12,
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: Color(0xFF6C6685)),
                    const SizedBox(width: 3),
                    Text(issue.location,
                        style: const TextStyle(
                            color: Color(0xFF6C6685), fontSize: 11)),
                    const Spacer(),
                    const Icon(Icons.access_time,
                        size: 12, color: Color(0xFF6C6685)),
                    const SizedBox(width: 3),
                    Text(
                      _shortDate(issue.createdAt),
                      style: const TextStyle(
                          color: Color(0xFF6C6685), fontSize: 11),
                    ),
                  ]),
                  // Admin: show reporter name
                  if (isAdmin) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.person_outline,
                          size: 12, color: Color(0xFF6C6685)),
                      const SizedBox(width: 3),
                      Text(issue.createdByName,
                          style: const TextStyle(
                              color: Color(0xFF6C6685), fontSize: 11)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
