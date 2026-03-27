import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/issue_provider.dart';
import 'student_dashboard.dart';
import 'admin_dashboard.dart';

/// HomeScreen checks the user's role and shows either the
/// StudentDashboard or the AdminDashboard.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final auth = context.read<AuthProvider>();
      final issueProvider = context.read<IssueProvider>();

      if (auth.userModel?.role == 'admin') {
        // Admin sees all issues in real time
        issueProvider.listenToAllIssues();
      } else {
        // Student sees only their own issues
        issueProvider.listenToMyIssues(auth.userModel?.uid ?? '');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.userModel?.role == 'admin';
    return isAdmin ? const AdminDashboard() : const StudentDashboard();
  }
}
