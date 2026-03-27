import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/issue_model.dart';
import 'package:intl/intl.dart';
import '../services/sla_service.dart';
import 'countdown_timer.dart';

class IssueCard extends StatelessWidget {
  final IssueModel issue;
  final bool isAdmin;
  const IssueCard({super.key, required this.issue, this.isAdmin = false});

  Color get _statusColor {
    switch (issue.status) {
      case statusInProgress: return const Color(0xFFF59E0B); // Amber
      case statusResolved: return const Color(0xFF10B981); // Emerald
      default: return const Color(0xFFEF4444); // Red
    }
  }

  Color get _statusBgColor {
    switch (issue.status) {
      case statusInProgress: return const Color(0xFFFEF3C7);
      case statusResolved: return const Color(0xFFD1FAE5);
      default: return const Color(0xFFFEE2E2);
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
    bool isDelayed = SLAService.isDelayed(issue.deadline, issue.status);

    return GestureDetector(
      onTap: () => context.push('/issue/${issue.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDelayed ? const Color(0xFFFEF2F2) : Colors.white, // Red tint if delayed
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDelayed ? const Color(0xFFEF4444).withValues(alpha: 0.5) : const Color(0xFFF3F4F6),
            width: isDelayed ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDelayed 
                  ? const Color(0xFFEF4444).withValues(alpha: 0.1) 
                  : const Color(0xFF111827).withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _statusBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_categoryIcon, color: _statusColor, size: 24),
            ),
            const SizedBox(width: 16),

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
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Badge(label: _statusLabel, color: _statusColor, bgColor: _statusBgColor),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    issue.description,
                    style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
          
                  // Location and Date
                  Row(children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        issue.location,
                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Text(
                      _shortDate(issue.createdAt),
                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ]),
                  
                  const SizedBox(height: 8),
                  
                  // SLA Timer and Priority Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SLACountdownTimer(issue: issue, compact: true),
                      _PriorityBadge(priority: issue.priority),
                    ],
                  ),
                  
                  // Admin: show reporter name
                  if (isAdmin) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.person_rounded, size: 14, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Text(issue.createdByName,
                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w500)),
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

  String _shortDate(DateTime dt) {
    return DateFormat('d MMM yyyy').format(dt);
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  const _Badge({required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color pColor;
    if (priority == SLAService.priorityHigh) {
      pColor = const Color(0xFFEF4444);
    } else if (priority == SLAService.priorityMedium) {
      pColor = const Color(0xFFF59E0B);
    } else {
      pColor = const Color(0xFF10B981);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flag_rounded, color: pColor, size: 14),
        const SizedBox(width: 4),
        Text(
          priority,
          style: TextStyle(
            color: pColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

