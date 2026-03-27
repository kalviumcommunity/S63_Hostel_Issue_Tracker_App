import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/issue_provider.dart';
import 'student_dashboard.dart';
import 'admin_dashboard.dart';

/// HomeScreen checks the user's role and starts the correct
/// Firestore listener. It re-initializes if the userId changes
/// (e.g. a different user logs in without restarting the app).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _currentUserId; // tracks which user's listener is active

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = context.read<AuthProvider>();
    final issueProvider = context.read<IssueProvider>();
    final newUserId = auth.userModel?.uid;

    // Only start a new listener if the user has actually changed
    if (newUserId != null && newUserId != _currentUserId) {
      _currentUserId = newUserId;

      if (auth.userModel?.role == 'admin') {
        issueProvider.listenToAllIssues(); // admin sees everyone's issues
      } else {
        issueProvider.listenToMyIssues(newUserId); // student sees only theirs
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
