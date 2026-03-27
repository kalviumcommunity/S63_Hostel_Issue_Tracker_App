import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/issue_model.dart';

class IssueCard extends StatelessWidget {
  final IssueModel issue;
  const IssueCard({super.key, required this.issue});

  Color get _priorityColor {
    switch (issue.priority) {
      case 'high': return const Color(0xFFFF6B6B);
      case 'low': return const Color(0xFF4CAF94);
      default: return const Color(0xFFFFB347);
    }
  }

  Color get _statusColor {
    switch (issue.status) {
      case 'open': return const Color(0xFFFF6B6B);
      case 'in_progress': return const Color(0xFFFFB347);
      case 'resolved': return const Color(0xFF4CAF94);
      default: return const Color(0xFF9E9EBF);
    }
  }

  String get _statusLabel {
    switch (issue.status) {
      case 'open': return 'Open';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      default: return 'Closed';
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _priorityColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        issue.category,
                        style: const TextStyle(
                          color: Color(0xFF9E9EBF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              issue.description,
              style: const TextStyle(
                color: Color(0xFF9E9EBF),
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.apartment_rounded,
                    size: 13, color: Color(0xFF6C6685)),
                const SizedBox(width: 4),
                Text(
                  '${issue.hostelBlock} · Room ${issue.roomNumber}',
                  style: const TextStyle(
                      color: Color(0xFF6C6685), fontSize: 11),
                ),
                const Spacer(),
                const Icon(Icons.access_time,
                    size: 13, color: Color(0xFF6C6685)),
                const SizedBox(width: 4),
                Text(
                  issue.createdAt.toString().substring(0, 10),
                  style: const TextStyle(
                      color: Color(0xFF6C6685), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
