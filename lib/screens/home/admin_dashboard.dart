import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/issue_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/issue_provider.dart';
import '../../widgets/issue_card.dart';
import '../profile/profile_screen.dart';
import 'admin_analytics_tab.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _AdminAllIssuesTab(),
          AdminAnalyticsTab(),
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF6C63FF)),
            label: 'All Issues',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded, color: Color(0xFF6C63FF)),
            label: 'Analytics',
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

class _AdminAllIssuesTab extends StatefulWidget {
  const _AdminAllIssuesTab();

  @override
  State<_AdminAllIssuesTab> createState() => _AdminAllIssuesTabState();
}

class _AdminAllIssuesTabState extends State<_AdminAllIssuesTab> {
  String _filter = 'All'; 
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<IssueProvider>();
      provider.fetchFirstPage();   // For 'All' tab (performance)
      provider.listenToAllIssues(); // For 'Filtered' tabs & Analytics (Real-time)
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_filter == 'All') {
        context.read<IssueProvider>().fetchMoreIssues();
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final issueProvider = context.watch<IssueProvider>();

    List<IssueModel> filteredIssues = [];
    bool isPaginated = _filter == 'All';

    if (_filter == 'All') {
      filteredIssues = issueProvider.paginatedIssues;
    } else if (_filter == 'Pending') {
      filteredIssues = issueProvider.pendingIssues;
    } else if (_filter == 'In Progress') {
      filteredIssues = issueProvider.inProgressIssues;
    } else if (_filter == 'Resolved') {
      filteredIssues = issueProvider.resolvedIssues;
    }

    return SafeArea(
      child: Stack(
        children: [
          // Content
          RefreshIndicator(
            color: const Color(0xFF6C63FF),
            backgroundColor: Colors.white,
            onRefresh: () async {
              if (isPaginated) {
                await issueProvider.fetchFirstPage();
              } else {
                issueProvider.listenToAllIssues();
              }
            },
            child: issueProvider.error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 100, left: 32, right: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 60, color: Color(0xFFEF4444)),
                          const SizedBox(height: 16),
                          const Text('Connection Link Broken', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF111827))),
                          const SizedBox(height: 8),
                          Text(issueProvider.error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B7280))),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => issueProvider.listenToAllIssues(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Re-Sync Dashboard'),
                          )
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(left: 24, right: 24, top: 180, bottom: 20),
              physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              child: filteredIssues.isEmpty
                  ? Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 40),
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFF3F4F6)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.assignment_turned_in_rounded,
                              size: 70, color: Color(0xFF9CA3AF)),
                          const SizedBox(height: 16),
                          Text('No $_filter Issues',
                              style: const TextStyle(
                                  color: Color(0xFF111827),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5)),
                          const SizedBox(height: 6),
                          const Text('Everything looks clean.',
                              style: TextStyle(color: Color(0xFF6B7280))),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredIssues.length,
                          itemBuilder: (context, index) {
                            return IssueCard(
                              issue: filteredIssues[index],
                              isAdmin: true,
                            );
                          },
                        ),
                        if (isPaginated && issueProvider.isFetchingMore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        if (isPaginated && !issueProvider.hasMore && filteredIssues.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text('You have reached the end', 
                                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontStyle: FontStyle.italic)),
                            ),
                          ),
                      ],
                    ),
            ),
          ),

          // Top Header (Fixed at top)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF111827).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin Panel',
                            style: TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.name ?? 'Admin',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                        onTap: () {
                          setState(() => _filter = 'Pending');
                          issueProvider.markNotificationsRead();
                        },
                          borderRadius: BorderRadius.circular(12),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.campaign_rounded, size: 16, color: Color(0xFFEF4444)),
                                const SizedBox(width: 6),
                                Text(
                                  '${issueProvider.newIssuesCount} New',
                                  style: const TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _FilterChip(
                            label: 'All',
                            count: issueProvider.issues.length,
                            isSelected: _filter == 'All',
                            onTap: () => setState(() => _filter = 'All')),
                        _FilterChip(
                            label: 'Pending',
                            count: issueProvider.pendingIssues.length,
                            isSelected: _filter == 'Pending',
                            onTap: () => setState(() => _filter = 'Pending')),
                        _FilterChip(
                            label: 'In Progress',
                            count: issueProvider.inProgressIssues.length,
                            isSelected: _filter == 'In Progress',
                            onTap: () => setState(() => _filter = 'In Progress')),
                        _FilterChip(
                            label: 'Resolved',
                            count: issueProvider.resolvedIssues.length,
                            isSelected: _filter == 'Resolved',
                            onTap: () => setState(() => _filter = 'Resolved')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFFE5E7EB),
              width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
