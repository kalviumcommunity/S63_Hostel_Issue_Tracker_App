import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/issue_provider.dart';
import '../../widgets/issue_card.dart';
import '../../widgets/stats_row.dart';
import '../profile/profile_screen.dart';
import '../issues/my_complaints_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),
          MyComplaintsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (v) => setState(() => _currentIndex = v),
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: const Color(0xFF6C63FF).withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF6C63FF)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_rounded),
            selectedIcon: Icon(Icons.list_alt_rounded, color: Color(0xFF6C63FF)),
            label: 'My Issues',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF6C63FF)),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/create-issue'),
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Report Issue', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final issueProvider = context.watch<IssueProvider>();

    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFF6C63FF),
        backgroundColor: Colors.white,
        onRefresh: () async {
          if (user != null) {
            issueProvider.listenToMyIssues(user.uid);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Good Morning,',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.name.split(' ')[0] ?? 'Student',
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 32),

              // Overview Section Title
              const Text(
                'Overview',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),

              // Stats Row
              StatsRow(
                pending: issueProvider.pendingIssues.length,
                inProgress: issueProvider.inProgressIssues.length,
                resolved: issueProvider.resolvedIssues.length,
              ),

              const SizedBox(height: 36),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Issues',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${issueProvider.issues.length} Total',
                    style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (issueProvider.issues.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 60, color: Color(0xFFD1FAE5)),
                      SizedBox(height: 16),
                      Text('All clear!',
                          style: TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: 6),
                      Text('No issues reported yet.',
                          style: TextStyle(color: Color(0xFF6B7280))),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: issueProvider.issues.length > 5
                      ? 5
                      : issueProvider.issues.length,
                  itemBuilder: (context, index) {
                    final issue = issueProvider.issues[index];
                    return IssueCard(issue: issue);
                  },
                ),
              const SizedBox(height: 80), // Fab space
            ],
          ),
        ),
      ),
    );
  }
}
