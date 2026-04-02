import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/issue_provider.dart';
import 'student_dashboard.dart';
import 'admin_dashboard.dart';
import 'staff_dashboard.dart';

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
    // We handle listener logic in build or via post-frame triggered by rebuilds
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('--- [HomeScreen] BUILD CALLED ---');
    final auth = context.watch<AuthProvider>();
    final user = auth.userModel;

    // Side-effect: Ensure listeners are active for the current user
    if (user != null && user.uid != _currentUserId) {
      _currentUserId = user.uid;
      final role = user.role;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final issueProvider = context.read<IssueProvider>();
        debugPrint('--- [HomeScreen] CALLING LISTENERS for $role (${user.uid}) ---');
        if (role == 'admin') {
          issueProvider.listenToAllIssues();
        } else if (role == 'staff') {
          issueProvider.listenToMyAssignedIssues(user.uid);
        } else {
          issueProvider.listenToMyIssues(user.uid);
        }
      });
    }

    // Show loading if user is authenticated but profile isn't loaded yet
    if (auth.isLoggedIn && user == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Syncing your profile...', style: TextStyle(color: Color(0xFF6B7280))),
            ],
          ),
        ),
      );
    }

    final role = auth.userModel?.role;
    if (role == 'admin') return const AdminDashboard();
    if (role == 'staff') return const StaffDashboard();
    return const StudentDashboard();
  }
}
