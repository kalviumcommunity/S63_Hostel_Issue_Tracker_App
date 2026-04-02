import 'package:flutter/material.dart';

/// Horizontal row showing Pending / In Progress / Resolved counts
class StatsRow extends StatelessWidget {
  final int pending;
  final int inProgress;
  final int resolved;

  const StatsRow({
    super.key,
    required this.pending,
    required this.inProgress,
    required this.resolved,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Pending',
            count: pending,
            iconColor: const Color(0xFFEF4444),
            bgColor: const Color(0xFFFEE2E2),
            icon: Icons.hourglass_empty_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'In Progress',
            count: inProgress,
            iconColor: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7),
            icon: Icons.construction_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Resolved',
            count: resolved,
            iconColor: const Color(0xFF10B981),
            bgColor: const Color(0xFFD1FAE5),
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color iconColor;
  final Color bgColor;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.count,
    required this.iconColor,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
