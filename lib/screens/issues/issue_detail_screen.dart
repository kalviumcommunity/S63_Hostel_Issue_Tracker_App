import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/issue_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/issue_provider.dart';

class IssueDetailScreen extends StatelessWidget {
  final String issueId;
  const IssueDetailScreen({super.key, required this.issueId});

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high': return const Color(0xFFFF6B6B);
      case 'low': return const Color(0xFF4CAF94);
      default: return const Color(0xFFFFB347);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open': return const Color(0xFFFF6B6B);
      case 'in_progress': return const Color(0xFFFFB347);
      case 'resolved': return const Color(0xFF4CAF94);
      default: return const Color(0xFF9E9EBF);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open': return 'Open';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      default: return 'Closed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final issueProvider = context.watch<IssueProvider>();
    final auth = context.watch<AuthProvider>();
    final issue = issueProvider.getIssueById(issueId);

    if (issue == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Issue not found', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final isAdmin = auth.userModel?.role == 'admin';

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
            // Status + Priority Badges
            Row(
              children: [
                _badge(_statusLabel(issue.status), _statusColor(issue.status)),
                const SizedBox(width: 8),
                _badge(
                  '${issue.priority[0].toUpperCase()}${issue.priority.substring(1)} Priority',
                  _priorityColor(issue.priority),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              issue.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.category_outlined,
                    size: 16, color: Color(0xFF9E9EBF)),
                const SizedBox(width: 6),
                Text(issue.category,
                    style: const TextStyle(
                        color: Color(0xFF9E9EBF), fontSize: 13)),
                const SizedBox(width: 16),
                const Icon(Icons.apartment_rounded,
                    size: 16, color: Color(0xFF9E9EBF)),
                const SizedBox(width: 6),
                Text('${issue.hostelBlock} · Room ${issue.roomNumber}',
                    style: const TextStyle(
                        color: Color(0xFF9E9EBF), fontSize: 13)),
              ],
            ),
            const SizedBox(height: 20),

            _sectionTitle('Description'),
            Text(
              issue.description,
              style: const TextStyle(
                  color: Color(0xFFCCCCDD), fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 20),

            _sectionTitle('Reported By'),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      issue.reporterName.isNotEmpty
                          ? issue.reporterName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(issue.reporterName,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                    Text(
                      issue.createdAt.toString().substring(0, 16),
                      style: const TextStyle(
                          color: Color(0xFF9E9EBF), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),

            if (issue.resolutionNote != null) ...[
              const SizedBox(height: 20),
              _sectionTitle('Resolution Note'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF94).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF4CAF94).withOpacity(0.3)),
                ),
                child: Text(
                  issue.resolutionNote!,
                  style: const TextStyle(color: Color(0xFF4CAF94)),
                ),
              ),
            ],

            // Admin Status Controls
            if (isAdmin && issue.status != 'closed') ...[
              const SizedBox(height: 28),
              _sectionTitle('Update Status'),
              ..._buildStatusButtons(context, issue, issueProvider),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStatusButtons(
      BuildContext context, IssueModel issue, IssueProvider provider) {
    final transitions = <Map<String, dynamic>>[
      if (issue.status == 'open')
        {'label': 'Mark In Progress', 'status': 'in_progress', 'color': const Color(0xFFFFB347)},
      if (issue.status == 'in_progress')
        {'label': 'Mark Resolved', 'status': 'resolved', 'color': const Color(0xFF4CAF94)},
      if (issue.status != 'closed')
        {'label': 'Close Issue', 'status': 'closed', 'color': const Color(0xFF9E9EBF)},
    ];

    return transitions.map((t) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: OutlinedButton(
          onPressed: () async {
            await provider.updateIssueStatus(
              issueId: issue.id,
              newStatus: t['status'] as String,
            );
            if (context.mounted) context.pop();
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: BorderSide(color: t['color'] as Color),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            t['label'] as String,
            style: TextStyle(
                color: t['color'] as Color, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }).toList();
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}
