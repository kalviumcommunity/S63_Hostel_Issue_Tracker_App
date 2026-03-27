import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sla_service.dart';
import '../models/issue_model.dart';

class SLACountdownTimer extends StatefulWidget {
  final IssueModel issue;
  final bool compact; // For the card vs detail screen

  const SLACountdownTimer({super.key, required this.issue, this.compact = false});

  @override
  State<SLACountdownTimer> createState() => _SLACountdownTimerState();
}

class _SLACountdownTimerState extends State<SLACountdownTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.issue.status == statusResolved) {
      return widget.compact ? const SizedBox() : _buildBadge(
        const Color(0xFF10B981), 
        const Color(0xFFD1FAE5),
        Icons.verified_rounded, 
        'Resolved on time' // simplified
      );
    }

    final isDelayed = SLAService.isDelayed(widget.issue.deadline, widget.issue.status);
    final textStr = SLAService.getRemainingTimeStr(widget.issue.deadline);

    if (isDelayed) {
      return _buildBadge(
        const Color(0xFFEF4444),
        const Color(0xFFFEE2E2),
        Icons.warning_rounded,
        widget.compact ? 'Delayed' : textStr,
        isDelayed: true
      );
    } else {
      return _buildBadge(
        const Color(0xFF6B7280),
        const Color(0xFFF3F4F6),
        Icons.timer_outlined,
        textStr,
      );
    }
  }

  Widget _buildBadge(Color color, Color bgColor, IconData icon, String text, {bool isDelayed = false}) {
    if (widget.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isDelayed ? FontWeight.w800 : FontWeight.w600,
            ),
          )
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: isDelayed ? Border.all(color: color.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  color: color,
                  fontWeight: isDelayed ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
