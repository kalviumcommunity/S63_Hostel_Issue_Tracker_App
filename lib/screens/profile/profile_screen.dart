import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/issue_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final issueProvider = context.watch<IssueProvider>();
    final user = auth.userModel;
    final isAdmin = user?.role == 'admin';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF3F4F6), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              user?.name ?? 'User',
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isAdmin
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isAdmin
                      ? const Color(0xFFFECACA)
                      : const Color(0xFFC7D2FE),
                ),
              ),
              child: Text(
                isAdmin ? '🛠️  ADMIN' : '🎓  STUDENT',
                style: TextStyle(
                  color: isAdmin
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF4F46E5),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Info Cards
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF3F4F6)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF111827).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  if (!isAdmin) ...[
                    _InfoRow(
                        icon: Icons.meeting_room_outlined,
                        label: 'Room Number',
                        value: user?.roomNumber ?? '-'),
                    const Divider(color: Color(0xFFF3F4F6), height: 1),
                    _InfoRow(
                        icon: Icons.business_outlined,
                        label: 'Hostel Block',
                        value: user?.hostelBlock ?? '-'),
                    const Divider(color: Color(0xFFF3F4F6), height: 1),
                  ],
                  _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Account Email',
                      value: user?.email ?? '-'),
                ],
              ),
            ),

            // Stats (for students)
            if (!isAdmin) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF111827).withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    _StatMini(
                        label: 'Pending',
                        count: issueProvider.pendingIssues.length,
                        color: const Color(0xFFEF4444)),
                    _Divider(),
                    _StatMini(
                        label: 'In Progress',
                        count: issueProvider.inProgressIssues.length,
                        color: const Color(0xFFF59E0B)),
                    _Divider(),
                    _StatMini(
                        label: 'Resolved',
                        count: issueProvider.resolvedIssues.length,
                        color: const Color(0xFF10B981)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 48),

            // Sign out
            OutlinedButton.icon(
              onPressed: () async {
                context.read<IssueProvider>().clearIssues();
                await auth.logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
              label: const Text('Sign Out',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
                backgroundColor: const Color(0xFFFEF2F2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6B7280), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatMini(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
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
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: const Color(0xFFF3F4F6));
  }
}
