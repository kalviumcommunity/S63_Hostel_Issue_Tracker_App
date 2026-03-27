import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/issue_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/issue_provider.dart';
import '../../widgets/issue_card.dart';
import '../../widgets/stats_row.dart';
import '../profile/profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentTab == 0
          ? const _AllIssuesTab()
          : const ProfileScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        backgroundColor: const Color(0xFF1A1A2E),
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: const Color(0xFF6C6685),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'All Issues',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── All Issues Tab (Admin) ────────────────────────────────────────────────────
class _AllIssuesTab extends StatefulWidget {
  const _AllIssuesTab();

  @override
  State<_AllIssuesTab> createState() => _AllIssuesTabState();
}

class _AllIssuesTabState extends State<_AllIssuesTab> {
  String _filter = 'all'; // all | pending | in_progress | resolved

  List<IssueModel> _getFiltered(IssueProvider p) {
    switch (_filter) {
      case 'pending':
        return p.pendingIssues;
      case 'in_progress':
        return p.inProgressIssues;
      case 'resolved':
        return p.resolvedIssues;
      default:
        return p.issues;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<IssueProvider>();
    final filtered = _getFiltered(provider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Panel 🛠️',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      auth.userModel?.name ?? 'Admin',
                      style: const TextStyle(
                          color: Color(0xFF9E9EBF), fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
                _AdminBadge(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: StatsRow(
              pending: provider.pendingIssues.length,
              inProgress: provider.inProgressIssues.length,
              resolved: provider.resolvedIssues.length,
            ),
          ),

          const SizedBox(height: 16),

          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    count: provider.issues.length,
                    isSelected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  _FilterChip(
                    label: 'Pending',
                    count: provider.pendingIssues.length,
                    isSelected: _filter == 'pending',
                    color: const Color(0xFFFF6B6B),
                    onTap: () => setState(() => _filter = 'pending'),
                  ),
                  _FilterChip(
                    label: 'In Progress',
                    count: provider.inProgressIssues.length,
                    isSelected: _filter == 'in_progress',
                    color: const Color(0xFFFFB347),
                    onTap: () => setState(() => _filter = 'in_progress'),
                  ),
                  _FilterChip(
                    label: 'Resolved',
                    count: provider.resolvedIssues.length,
                    isSelected: _filter == 'resolved',
                    color: const Color(0xFF4CAF94),
                    onTap: () => setState(() => _filter = 'resolved'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Issue list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No issues in this category',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) =>
                        IssueCard(issue: filtered[i], isAdmin: true),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AdminBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'ADMIN',
        style: TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800,
            letterSpacing: 1.2),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    this.color = const Color(0xFF6C63FF),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF2A2A3E),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          '$label  $count',
          style: TextStyle(
            color: isSelected ? color : const Color(0xFF9E9EBF),
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
