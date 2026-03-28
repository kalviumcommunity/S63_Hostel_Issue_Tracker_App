import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/issues/create_issue_screen.dart';
import '../screens/issues/issue_detail_screen.dart';
import '../screens/issues/issue_chat_screen.dart';

class HostelIssueTrackerApp extends StatelessWidget {
  const HostelIssueTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Make status bar transparent for modern look
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp.router(
      title: 'Hostel Issue Tracker',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: _router,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter', // Requires google_fonts but we can let Flutter fallback to highly readable sans-serif
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C63FF),
        brightness: Brightness.light,
        surface: const Color(0xFFF9FAFB),
        primary: const Color(0xFF6C63FF),
        secondary: const Color(0xFF3ECFCF),
      ),
      scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFF3F4F6), width: 1.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF111827),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFF111827),
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0xFF6C63FF).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          minimumSize: const Size(double.infinity, 56),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 20,
        selectedItemColor: Color(0xFF6C63FF),
        unselectedItemColor: Color(0xFF9CA3AF),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }

  CustomTransitionPage _fadeScaleTransition(Widget child, LocalKey key) {
    return CustomTransitionPage(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  GoRouter get _router => GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/', 
            pageBuilder: (context, state) => _fadeScaleTransition(const SplashScreen(), state.pageKey),
          ),
          GoRoute(
            path: '/login', 
            pageBuilder: (context, state) => _fadeScaleTransition(const LoginScreen(), state.pageKey),
          ),
          GoRoute(
            path: '/register', 
            pageBuilder: (context, state) => _fadeScaleTransition(const RegisterScreen(), state.pageKey),
          ),
          GoRoute(
            path: '/home', 
            pageBuilder: (context, state) => _fadeScaleTransition(const HomeScreen(), state.pageKey),
          ),
          GoRoute(
            path: '/create-issue',
            pageBuilder: (context, state) => _fadeScaleTransition(const CreateIssueScreen(), state.pageKey),
          ),
          GoRoute(
            path: '/issue/:id',
            pageBuilder: (context, state) => _fadeScaleTransition(
                IssueDetailScreen(issueId: state.pathParameters['id']!), state.pageKey),
          ),
          GoRoute(
            path: '/issue/:id/chat',
            pageBuilder: (context, state) => _fadeScaleTransition(
                IssueChatScreen(issueId: state.pathParameters['id']!), state.pageKey),
          ),
        ],
      );
}

