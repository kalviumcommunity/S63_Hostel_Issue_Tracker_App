import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/issue_provider.dart';
import '../../models/issue_model.dart';
import '../../widgets/issue_card.dart';
import '../profile/profile_screen.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _StaffIssuesTab(),
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
            icon: Icon(Icons.engineering_outlined),
            selectedIcon: Icon(Icons.engineering_rounded, color: Color(0xFF6C63FF)),
            label: 'My Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF6C63FF)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _StaffIssuesTab extends StatelessWidget {
  const _StaffIssuesTab();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final issueProvider = context.watch<IssueProvider>();

    // Filter issues assigned to this specific staff member
    final myTasks = issueProvider.issues.where((i) => i.assignedStaffId == user?.uid).toList();
    final pendingTasks = myTasks.where((i) => i.status == statusAssigned).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Maintenance Taskboard',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  '${user?.staffCategory} Specialist • ${myTasks.length} total tasks',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 16),
                ),
                const SizedBox(height: 24),
                
                // Workload Overview
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _WorkloadItem(count: pendingTasks.length, label: 'Pending'),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _WorkloadItem(
                        count: myTasks.where((i) => i.status == statusInProgress).length,
                        label: 'Active',
                      ),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _WorkloadItem(
                        count: myTasks.where((i) => i.status == statusResolved).length,
                        label: 'Resolved',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: myTasks.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt_rounded, size: 70, color: Color(0xFFE5E7EB)),
                        SizedBox(height: 16),
                        Text('All caught up!', 
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: myTasks.length,
                    itemBuilder: (context, index) {
                      return IssueCard(issue: myTasks[index], isAdmin: false);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _WorkloadItem extends StatelessWidget {
  final int count;
  final String label;
  const _WorkloadItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
