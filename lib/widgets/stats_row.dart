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
            color: const Color(0xFFFF6B6B),
            icon: Icons.hourglass_empty_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'In Progress',
            count: inProgress,
            color: const Color(0xFFFFB347),
            icon: Icons.construction_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Resolved',
            count: resolved,
            color: const Color(0xFF4CAF94),
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
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9E9EBF),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
