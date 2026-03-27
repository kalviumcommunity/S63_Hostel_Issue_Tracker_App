import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/issue_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/issue_provider.dart';

class IssueDetailScreen extends StatefulWidget {
  final String issueId;
  const IssueDetailScreen({super.key, required this.issueId});

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  final _commentController = TextEditingController();
  bool _isUpdating = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case statusInProgress: return const Color(0xFFFFB347);
      case statusResolved: return const Color(0xFF4CAF94);
      default: return const Color(0xFFFF6B6B);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case statusPending: return '🔴  Pending';
      case statusInProgress: return '🟡  In Progress';
      case statusResolved: return '🟢  Resolved';
      default: return status;
    }
  }

  Future<void> _updateStatus(
      IssueProvider provider, String issueId, String newStatus) async {
    setState(() => _isUpdating = true);
    await provider.updateIssue(
      issueId: issueId,
      newStatus: newStatus,
      adminComment: _commentController.text.trim().isNotEmpty
          ? _commentController.text.trim()
          : null,
    );
    setState(() => _isUpdating = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to: ${_statusLabel(newStatus)}'),
          backgroundColor: _statusColor(newStatus),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IssueProvider>();
    final auth = context.watch<AuthProvider>();
    final issue = provider.getById(widget.issueId);
    final isAdmin = auth.userModel?.role == 'admin';

    if (issue == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Issue not found',
              style: TextStyle(color: Color(0xFF9E9EBF))),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Details',
            style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor(issue.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _statusColor(issue.status).withValues(alpha: 0.4)),
              ),
              child: Text(
                _statusLabel(issue.status),
                style: TextStyle(
                    color: _statusColor(issue.status),
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),

            const SizedBox(height: 14),

            // Title
            Text(
              issue.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),

            // Category + location
            Row(children: [
              const Icon(Icons.category_outlined,
                  size: 14, color: Color(0xFF9E9EBF)),
              const SizedBox(width: 4),
              Text(issue.category,
                  style: const TextStyle(
                      color: Color(0xFF9E9EBF), fontSize: 13)),
              const SizedBox(width: 12),
              const Icon(Icons.location_on_outlined,
                  size: 14, color: Color(0xFF9E9EBF)),
              const SizedBox(width: 4),
              Text(issue.location,
                  style: const TextStyle(
                      color: Color(0xFF9E9EBF), fontSize: 13)),
            ]),

            const SizedBox(height: 20),

            // Description
            _sectionTitle('Description'),
            Text(
              issue.description,
              style: const TextStyle(
                  color: Color(0xFFCCCCDD), fontSize: 15, height: 1.6),
            ),

            const SizedBox(height: 20),

            // Photo
            if (issue.imageUrl != null) ...[
              _sectionTitle('Photo Evidence'),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: issue.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 200,
                    color: const Color(0xFF1A1A2E),
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF6C63FF)),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 200,
                    color: const Color(0xFF1A1A2E),
                    child: const Icon(Icons.broken_image_outlined,
                        color: Color(0xFF9E9EBF)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Reported by
            _sectionTitle('Reported By'),
            _InfoRow(
              icon: Icons.person_outline,
              value: issue.createdByName,
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.access_time,
              value: _formatDate(issue.createdAt),
            ),

            // Admin comment
            if (issue.adminComment != null &&
                issue.adminComment!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionTitle('Admin Comment'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF4CAF94).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF4CAF94)
                          .withValues(alpha: 0.3)),
                ),
                child: Text(
                  issue.adminComment!,
                  style: const TextStyle(
                      color: Color(0xFF4CAF94), height: 1.5),
                ),
              ),
            ],

            // ── Admin controls ──────────────────────────────────────
            if (isAdmin && issue.status != statusResolved) ...[
              const SizedBox(height: 28),
              _sectionTitle('Update Status'),
              TextFormField(
                controller: _commentController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Add a comment for the student (optional)',
                  prefixIcon: Icon(Icons.comment_outlined,
                      color: Color(0xFF6C63FF)),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              if (issue.status == statusPending)
                _StatusButton(
                  label: 'Mark as In Progress',
                  color: const Color(0xFFFFB347),
                  icon: Icons.construction,
                  isLoading: _isUpdating,
                  onTap: () => _updateStatus(
                      provider, issue.id, statusInProgress),
                ),
              if (issue.status == statusInProgress)
                _StatusButton(
                  label: 'Mark as Resolved',
                  color: const Color(0xFF4CAF94),
                  icon: Icons.check_circle_outline,
                  isLoading: _isUpdating,
                  onTap: () =>
                      _updateStatus(provider, issue.id, statusResolved),
                ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
      );

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  const _InfoRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9E9EBF)),
        const SizedBox(width: 8),
        Text(value,
            style:
                const TextStyle(color: Color(0xFFCCCCDD), fontSize: 14)),
      ],
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onTap,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon, color: color),
      label: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        side: BorderSide(color: color),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
