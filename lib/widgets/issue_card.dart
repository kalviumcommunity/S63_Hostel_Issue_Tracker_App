import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/issue_model.dart';
import 'package:intl/intl.dart';
import '../services/sla_service.dart';
import 'countdown_timer.dart';

class IssueCard extends StatefulWidget {
  final IssueModel issue;
  final bool isAdmin;
  const IssueCard({super.key, required this.issue, this.isAdmin = false});

  @override
  State<IssueCard> createState() => _IssueCardState();
}

class _IssueCardState extends State<IssueCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.issue.status) {
      case statusAssigned: return const Color(0xFF6C63FF); 
      case statusInProgress: return const Color(0xFFF59E0B); 
      case statusResolved: return const Color(0xFF10B981); 
      default: return const Color(0xFFEF4444); 
    }
  }

  Color get _statusBgColor {
    switch (widget.issue.status) {
      case statusAssigned: return const Color(0xFF6C63FF).withValues(alpha: 0.1);
      case statusInProgress: return const Color(0xFFFEF3C7);
      case statusResolved: return const Color(0xFFD1FAE5);
      default: return const Color(0xFFFEE2E2);
    }
  }

  String get _statusLabel {
    switch (widget.issue.status) {
      case statusPending: return 'Pending';
      case statusAssigned: return 'Assigned';
      case statusInProgress: return 'In Progress';
      case statusResolved: return 'Resolved';
      default: return widget.issue.status;
    }
  }

  IconData get _categoryIcon {
    switch (widget.issue.category) {
      case 'Mess Food': return Icons.restaurant_rounded;
      case 'Water Problem': return Icons.water_drop_rounded;
      case 'Electricity': return Icons.bolt_rounded;
      case 'Room Maintenance': return Icons.build_rounded;
      case 'Cleanliness': return Icons.clean_hands_rounded;
      case 'Internet / WiFi': return Icons.wifi_rounded;
      case 'Security': return Icons.security_rounded;
      default: return Icons.report_problem_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDelayed = SLAService.isDelayed(widget.issue.deadline, widget.issue.status);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: () => context.push('/issue/${widget.issue.id}'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDelayed ? const Color(0xFFFFF1F1) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDelayed 
                  ? const Color(0xFFEF4444).withValues(alpha: 0.3) 
                  : const Color(0xFFF3F4F6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDelayed 
                    ? const Color(0xFFEF4444).withValues(alpha: 0.05) 
                    : const Color(0xFF111827).withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _statusBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_categoryIcon, color: _statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.issue.title,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          DateFormat('d MMM · HH:mm').format(widget.issue.createdAt),
                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  _Badge(label: _statusLabel, color: _statusColor, bgColor: _statusBgColor),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.issue.description,
                style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 14,
                    height: 1.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  // Reporter/Staff Avatars
                  if (widget.issue.assignedStaffName != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.engineering_rounded, size: 14, color: Color(0xFF6C63FF)),
                          const SizedBox(width: 6),
                          Text(
                            widget.issue.assignedStaffName!,
                            style: const TextStyle(
                              color: Color(0xFF6C63FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                  _PriorityIndicator(priority: widget.issue.priority),
                ],
              ),
              if (widget.issue.status != statusResolved) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 12),
                SLACountdownTimer(issue: widget.issue, compact: true),
              ]
            ],
          ),
        ),
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
    );
  }
}

class _PriorityIndicator extends StatelessWidget {
  final String priority;
  const _PriorityIndicator({required this.priority});

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: pColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: pColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            priority,
            style: TextStyle(color: pColor, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

