import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/issue_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/issue_provider.dart';
import '../../services/sla_service.dart';
import '../../services/assignment_service.dart';
import '../../models/staff_model.dart';
import '../../widgets/countdown_timer.dart';
import '../../widgets/issue_timeline.dart';

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

  Future<void> _updateStatus(String newStatus) async {
    final issueProvider = context.read<IssueProvider>();
    setState(() => _isUpdating = true);

    final success = await issueProvider.updateIssue(
      issueId: widget.issueId,
      newStatus: newStatus,
      adminComment: _commentController.text.trim(),
    );

    if (mounted) {
      setState(() => _isUpdating = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated successfully'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(issueProvider.error ?? 'Failed to update'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _showReassignDialog(String issueId) async {
    final staff = await AssignmentService.getAvailableStaff();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Assign Staff Member',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: staff.length,
                  itemBuilder: (context, index) {
                    final s = staff[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                        child: Text(s.name[0]),
                      ),
                      title: Text(s.name),
                      subtitle: Text('${s.role} • ${s.activeIssuesCount} active issues'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        Navigator.pop(context);
                        setState(() => _isUpdating = true);
                        final success = await AssignmentService.manualAssign(issueId, s);
                        if (!context.mounted) return;
                        if (mounted) setState(() => _isUpdating = false);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Staff assigned successfully')),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    if (status == statusInProgress) return const Color(0xFFF59E0B);
    if (status == statusResolved) return const Color(0xFF10B981);
    return const Color(0xFFEF4444);
  }

  Color _getStatusBgColor(String status) {
    if (status == statusInProgress) return const Color(0xFFFEF3C7);
    if (status == statusResolved) return const Color(0xFFD1FAE5);
    return const Color(0xFFFEE2E2);
  }

  String _getStatusLabel(String status) {
    if (status == statusPending) return 'Pending';
    if (status == statusAssigned) return 'Assigned';
    if (status == statusInProgress) return 'In Progress';
    if (status == statusResolved) return 'Resolved';
    return status;
  }

  @override
  Widget build(BuildContext context) {
    final issueProvider = context.watch<IssueProvider>();
    final issue = issueProvider.getById(widget.issueId);
    final user = context.watch<AuthProvider>().userModel;
    final isAdmin = user?.role == 'admin';

    if (issue == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827)),
            onPressed: () {
              if (context.canPop()) context.pop();
            },
          ),
        ),
        body: const Center(
            child: Text('Issue not found or deleted.',
                style: TextStyle(color: Color(0xFF6B7280)))),
      );
    }

    final isAssignedStaff = user?.uid == issue.assignedStaffId;
    final isResolved = issue.status == statusResolved;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Issue Details', style: TextStyle(color: Color(0xFF111827))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827)),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF3F4F6), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusBgColor(issue.status),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    issue.status == statusResolved
                        ? Icons.check_circle_rounded
                        : Icons.info_rounded,
                    color: _getStatusColor(issue.status),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusLabel(issue.status).toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(issue.status),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SLA Countdown and Priority
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SLACountdownTimer(issue: issue),
                
                // Detailed Priority Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: issue.priority == SLAService.priorityHigh 
                        ? const Color(0xFFFEF2F2)
                        : issue.priority == SLAService.priorityMedium 
                            ? const Color(0xFFFFFBEB)
                            : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: issue.priority == SLAService.priorityHigh 
                        ? const Color(0xFFEF4444).withOpacity(0.3)
                        : issue.priority == SLAService.priorityMedium 
                            ? const Color(0xFFF59E0B).withOpacity(0.3)
                            : const Color(0xFF10B981).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag_rounded,
                        size: 16,
                        color: issue.priority == SLAService.priorityHigh 
                        ? const Color(0xFFEF4444)
                        : issue.priority == SLAService.priorityMedium 
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${issue.priority} Priority',
                        style: TextStyle(
                          color: issue.priority == SLAService.priorityHigh 
                          ? const Color(0xFFEF4444)
                          : issue.priority == SLAService.priorityMedium 
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF10B981),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              issue.title,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),

            // Metadata Chips
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_outlined,
                          color: Color(0xFF6B7280), size: 16),
                      const SizedBox(width: 6),
                      Text(issue.category,
                          style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: Color(0xFF6B7280), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(issue.location,
                              style: const TextStyle(
                                  color: Color(0xFF4B5563),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // --- Timeline Section ---
            IssueTimeline(issue: issue),
            const SizedBox(height: 32),

            // Description
            const Text('Description',
                style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF3F4F6)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF111827).withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              ),
              child: Text(
                issue.description,
                style: const TextStyle(
                    color: Color(0xFF4B5563), fontSize: 16, height: 1.6),
              ),
            ),
            const SizedBox(height: 32),

            // Image
            if (issue.imageUrl != null) ...[
              const Text('Photo Evidence',
                  style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Image.network(
                    issue.imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF6C63FF)));
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image_rounded,
                            size: 40, color: Color(0xFF9CA3AF)),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],

            const SizedBox(height: 32),

            // Assigned Staff Section
            const Text('Assigned Personnel',
                style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF3ECFCF).withOpacity(0.1),
                    child: const Icon(Icons.person_pin_rounded, color: Color(0xFF3ECFCF)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.assignedStaffName ?? 'Assigning automatically...',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        if (issue.assignedStaffName != null)
                          const Text(
                            'Maintenance Specialist',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                      ],
                    ),
                  ),
                  if (isAdmin)
                    TextButton.icon(
                      onPressed: () => _showReassignDialog(issue.id),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Change'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Reporter Details
            const Text('Reported By',
                style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                  child: Text(
                    issue.createdByName.isNotEmpty ? issue.createdByName[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.w800,
                        fontSize: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(issue.createdByName,
                        style: const TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                        DateFormat('MMM dd, yyyy - hh:mm a')
                            .format(issue.createdAt),
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 13)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Chat Button (Prominent)
            ElevatedButton.icon(
              onPressed: () => context.push('/issue/${issue.id}/chat'),
              icon: const Icon(Icons.forum_rounded),
              label: const Text('Open Issue Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827), // Dark accent for contrast
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF111827).withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            // Admin Comment Display (if exists)
            if (issue.adminComment != null &&
                issue.adminComment!.isNotEmpty) ...[
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.admin_panel_settings_rounded,
                            color: Color(0xFF6C63FF), size: 20),
                        const SizedBox(width: 8),
                        const Text('Admin Response',
                            style: TextStyle(
                                color: Color(0xFF6C63FF),
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                        const Spacer(),
                        if (issue.updatedAt != null)
                          Text(
                            DateFormat('MMM dd').format(issue.updatedAt!),
                            style: const TextStyle(
                                color: Color(0xFF9CA3AF), fontSize: 12),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      issue.adminComment!,
                      style: const TextStyle(
                          color: Color(0xFF111827), fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],

            // -----------------------------------------------------------------
            // ACTIONS SECTION (ADMİN & STAFF)
            // -----------------------------------------------------------------
            if ((isAdmin || isAssignedStaff) && !isResolved) ...[
              const SizedBox(height: 40),
              const Divider(color: Color(0xFFE5E7EB)),
              const SizedBox(height: 24),
              Text(isAdmin ? 'Admin Actions' : 'Staff Actions',
                  style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5)),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                maxLines: 3,
                style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  labelText: isAdmin 
                    ? 'Add a response or update for the student'
                    : 'Add a note about the fix (Optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              if (_isUpdating)
                const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (isAdmin && issue.status == statusPending)
                      _buildAdminButton(
                        label: 'Assign',
                        color: const Color(0xFF6C63FF),
                        onTap: () => _updateStatus(statusAssigned),
                      ),
                    if (issue.status == statusPending || issue.status == statusAssigned)
                      _buildAdminButton(
                        label: 'Start Progress',
                        color: const Color(0xFFF59E0B),
                        onTap: () => _updateStatus(statusInProgress),
                      ),
                    _buildAdminButton(
                      label: 'Resolve',
                      color: const Color(0xFF10B981),
                      onTap: () => _updateStatus(statusResolved),
                      isPrimary: true,
                    ),
                  ],
                ),
              const SizedBox(height: 48),
            ] else if (isResolved) ...[
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.verified_rounded, size: 48, color: Color(0xFF10B981)),
                    SizedBox(height: 12),
                    Text('This issue is resolved.',
                        style: TextStyle(
                            color: Color(0xFF065F46),
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdminButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    if (isPrimary) {
      return ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: color.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          minimumSize: const Size(140, 56),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      );
    }
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size(140, 56),
        backgroundColor: Colors.white,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
