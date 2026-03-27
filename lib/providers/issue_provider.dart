import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/issue_model.dart';

class IssueProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<IssueModel> _issues = [];
  bool _isLoading = false;
  String? _error;

  List<IssueModel> get issues => _issues;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered getters
  List<IssueModel> get pendingIssues =>
      _issues.where((i) => i.status == statusPending).toList();
  List<IssueModel> get inProgressIssues =>
      _issues.where((i) => i.status == statusInProgress).toList();
  List<IssueModel> get resolvedIssues =>
      _issues.where((i) => i.status == statusResolved).toList();

  // Real-time listener
  void listenToAllIssues() {
    _firestore
        .collection('issues')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _issues = snapshot.docs
          .map((doc) =>
              IssueModel.fromMap(doc.data(), doc.id))
          .toList();
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      notifyListeners();
    });
  }

  // Real-time listener for a specific student
  void listenToMyIssues(String userId) {
    _firestore
        .collection('issues')
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _issues = snapshot.docs
          .map((doc) =>
              IssueModel.fromMap(doc.data(), doc.id))
          .toList();
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      notifyListeners();
    });
  }

  // Upload image to Firebase Storage, returns download URL
  Future<String?> uploadImage(File imageFile, String userId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('issueImages/$userId/$fileName');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // Create a new issue in Firestore
  Future<bool> createIssue(IssueModel issue) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('issues').add(issue.toMap());
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Admin: update issue status + optional comment
  Future<bool> updateIssue({
    required String issueId,
    required String newStatus,
    String? adminComment,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (adminComment != null && adminComment.isNotEmpty) {
        updates['adminComment'] = adminComment;
      }

      await _firestore.collection('issues').doc(issueId).update(updates);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete an issue
  Future<bool> deleteIssue(String issueId) async {
    try {
      await _firestore.collection('issues').doc(issueId).delete();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  IssueModel? getById(String id) {
    try {
      return _issues.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }
}
