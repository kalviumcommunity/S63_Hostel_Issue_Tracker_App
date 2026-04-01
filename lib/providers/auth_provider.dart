import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _firebaseUser != null;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      await _fetchUserData(user.uid);
      await NotificationService().updateFCMToken();
    } else {
      _userModel = null;
    }
    notifyListeners();
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromMap(doc.data()!);
        debugPrint('--- Profile Loaded for: ${_userModel?.name} (${_userModel?.role}) ---');
      } else {
        _error = 'User profile data missing in Firestore.';
        debugPrint('--- Error: Firestore document $uid not found! ---');
      }
    } catch (e) {
      _error = 'Database connection failed: $e';
      debugPrint('--- Firestore Fetch Error: $e ---');
    }
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String roomNumber,
    required String hostelBlock,
    String role = 'student',
    String? staffCategory,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
        uid: credential.user!.uid,
        name: name,
        email: email,
        roomNumber: roomNumber,
        hostelBlock: hostelBlock,
        role: role,
        staffCategory: staffCategory,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(user.toMap());

      // IF STAFF, ALSO SYNC TO STAFF COLLECTION FOR ASSIGNMENT
      if (role == 'staff') {
        await _firestore.collection('staff').doc(credential.user!.uid).set({
          'name': name,
          'role': 'Maintenance Specialist',
          'category': staffCategory,
          'isAvailable': true,
          'activeIssuesCount': 0,
        });
      }

      _userModel = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('--- Registration [Auth] Error [${e.code}]: ${e.message} ---');
      _error = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('--- Registration [Unexpected] Error: $e ---');
      _error = 'Registration failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('--- Login Error [${e.code}]: ${e.message} ---');
      _error = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('--- Unexpected Login Error: $e ---');
      _error = 'Login failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await NotificationService().deleteToken();
    await _auth.signOut();
    _userModel = null;
    notifyListeners();
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'No user found or incorrect password.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'channel-error':
        return 'Network error or empty fields.';
      case 'network-request-failed':
        return 'Check your internet connection.';
      default:
        return 'Auth error ($code). Please try again.';
    }
  }
}
