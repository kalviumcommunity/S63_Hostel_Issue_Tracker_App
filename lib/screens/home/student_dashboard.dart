import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/issue_provider.dart';
import '../../widgets/issue_card.dart';
import '../../widgets/stats_row.dart';
import '../issues/my_complaints_screen.dart';
import '../profile/profile_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _MyIssuesTab(),
      const MyComplaintsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_currentTab],
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/create-issue'),
              backgroundColor: const Color(0xFF6C63FF),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Report Issue',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        backgroundColor: const Color(0xFF1A1A2E),
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: const Color(0xFF6C6685),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'My Issues',
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

// ─── Home Tab ─────────────────────────────────────────────────────────────────
class _MyIssuesTab extends StatelessWidget {
  const _MyIssuesTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<IssueProvider>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${auth.userModel?.name.split(' ').first ?? 'Student'} 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${auth.userModel?.hostelBlock} · Room ${auth.userModel?.roomNumber}',
                      style: const TextStyle(
                          color: Color(0xFF9E9EBF), fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
                _Avatar(name: auth.userModel?.name ?? 'U'),
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

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Recent Reports',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Issue List
          Expanded(
            child: provider.issues.isEmpty
                ? const _EmptyState(
                    message: 'No issues reported yet.\nTap + to report one.')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: provider.issues.length,
                    itemBuilder: (context, index) =>
                        IssueCard(issue: provider.issues[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 72, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3), fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
