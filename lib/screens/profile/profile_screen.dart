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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Avatar
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 14),

            Text(
              user?.name ?? 'User',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
            ),
            Text(
              user?.email ?? '',
              style: const TextStyle(
                  color: Color(0xFF9E9EBF), fontSize: 13),
            ),
            const SizedBox(height: 8),

            // Role badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isAdmin
                    ? const Color(0xFFFF6B6B).withValues(alpha: 0.15)
                    : const Color(0xFF6C63FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isAdmin
                      ? const Color(0xFFFF6B6B).withValues(alpha: 0.4)
                      : const Color(0xFF6C63FF).withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                isAdmin ? '🛠️  ADMIN' : '🎓  STUDENT',
                style: TextStyle(
                  color: isAdmin
                      ? const Color(0xFFFF6B6B)
                      : const Color(0xFF6C63FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Info
            if (!isAdmin) ...[
              _InfoCard(
                  icon: Icons.meeting_room_outlined,
                  label: 'Room Number',
                  value: user?.roomNumber ?? '-'),
              _InfoCard(
                  icon: Icons.business_outlined,
                  label: 'Hostel Block',
                  value: user?.hostelBlock ?? '-'),
            ],
            _InfoCard(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user?.email ?? '-'),

            // Stats (for students)
            if (!isAdmin) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2A2A3E)),
                ),
                child: Row(
                  children: [
                    _StatMini(
                        label: 'Pending',
                        count: issueProvider.pendingIssues.length,
                        color: const Color(0xFFFF6B6B)),
                    _Divider(),
                    _StatMini(
                        label: 'In Progress',
                        count: issueProvider.inProgressIssues.length,
                        color: const Color(0xFFFFB347)),
                    _Divider(),
                    _StatMini(
                        label: 'Resolved',
                        count: issueProvider.resolvedIssues.length,
                        color: const Color(0xFF4CAF94)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Sign out
            OutlinedButton.icon(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout, color: Color(0xFFFF6B6B)),
              label: const Text('Sign Out',
                  style: TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Color(0xFFFF6B6B)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A3E)),
      ),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF6C63FF), size: 20),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF9E9EBF), fontSize: 11)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ]),
      ]),
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
      child: Column(children: [
        Text(count.toString(),
            style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF9E9EBF), fontSize: 11)),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 40, color: const Color(0xFF2A2A3E));
  }
}
