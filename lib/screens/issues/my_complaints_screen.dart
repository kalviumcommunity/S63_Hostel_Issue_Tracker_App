import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/issue_model.dart';
import '../../providers/issue_provider.dart';
import '../../widgets/issue_card.dart';

/// Student's own complaints with status tabs
class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IssueProvider>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              'My Complaints',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Track the status of your reported issues',
              style: TextStyle(color: Color(0xFF9E9EBF), fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: const Color(0xFF6C63FF),
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF9E9EBF),
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hourglass_empty, size: 14),
                      const SizedBox(width: 4),
                      Text('Pending (${provider.pendingIssues.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.construction, size: 14),
                      const SizedBox(width: 4),
                      Text('Active (${provider.inProgressIssues.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 14),
                      const SizedBox(width: 4),
                      Text('Done (${provider.resolvedIssues.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _IssueList(issues: provider.pendingIssues, emptyMsg: 'No pending issues 🎉'),
                _IssueList(issues: provider.inProgressIssues, emptyMsg: 'Nothing in progress'),
                _IssueList(issues: provider.resolvedIssues, emptyMsg: 'No resolved issues yet'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueList extends StatelessWidget {
  final List<IssueModel> issues;
  final String emptyMsg;

  const _IssueList({required this.issues, required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 60, color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 12),
            Text(
              emptyMsg,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3), fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: issues.length,
      itemBuilder: (context, i) => IssueCard(issue: issues[i]),
    );
  }
}
