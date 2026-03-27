import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/issue_model.dart';

class IssueTimeline extends StatelessWidget {
  final IssueModel issue;

  const IssueTimeline({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: Text(
            'Issue Timeline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              letterSpacing: -0.5,
            ),
          ),
        ),
        _buildTimelineItem(
          status: 'Reported',
          timestamp: issue.createdAt,
          isCompleted: true, // Always completed
          isLast: false,
          icon: Icons.assignment_late_rounded,
        ),
        _buildTimelineItem(
          status: 'Assigned',
          timestamp: issue.assignedAt,
          isCompleted: issue.assignedAt != null || 
                       issue.status == statusInProgress || 
                       issue.status == statusResolved,
          isLast: false,
          icon: Icons.person_add_alt_1_rounded,
        ),
        _buildTimelineItem(
          status: 'In Progress',
          timestamp: issue.startedAt,
          isCompleted: issue.startedAt != null || 
                       issue.status == statusResolved,
          isLast: false,
          icon: Icons.pending_actions_rounded,
        ),
        _buildTimelineItem(
          status: 'Resolved',
          timestamp: issue.resolvedAt,
          isCompleted: issue.status == statusResolved,
          isLast: true,
          icon: Icons.check_circle_rounded,
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String status,
    required DateTime? timestamp,
    required bool isCompleted,
    required bool isLast,
    required IconData icon,
  }) {
    final Color activeColor = isCompleted ? const Color(0xFF6C63FF) : const Color(0xFFE5E7EB);
    final Color textColor = isCompleted ? const Color(0xFF111827) : const Color(0xFF9CA3AF);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Dot and Connector Line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: activeColor,
                      width: 2.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isCompleted ? Icons.check_rounded : icon,
                      size: 16,
                      color: activeColor,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.5,
                      color: activeColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Step Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isCompleted ? FontWeight.w800 : FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (timestamp != null)
                    Text(
                      DateFormat('MMM dd, hh:mm a').format(timestamp),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    const Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
