import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/issue_model.dart';

class IssueProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<IssueModel> _issues = [];
  bool _isLoading = false;
  String? _error;

  List<IssueModel> get issues => _issues;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<IssueModel> get openIssues =>
      _issues.where((i) => i.status == 'open').toList();

  List<IssueModel> get inProgressIssues =>
      _issues.where((i) => i.status == 'in_progress').toList();

  List<IssueModel> get resolvedIssues =>
      _issues.where((i) => i.status == 'resolved' || i.status == 'closed').toList();

  Future<void> fetchIssues({String? userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Query query = _firestore
          .collection('issues')
          .orderBy('createdAt', descending: true);

      if (userId != null) {
        query = query.where('reportedBy', isEqualTo: userId);
      }

      final snapshot = await query.get();
      _issues = snapshot.docs
          .map((doc) => IssueModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createIssue(IssueModel issue) async {
    try {
      final docRef = await _firestore
          .collection('issues')
          .add(issue.toMap());

      final newIssue = IssueModel.fromMap(issue.toMap(), docRef.id);
      _issues.insert(0, newIssue);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateIssueStatus({
    required String issueId,
    required String newStatus,
    String? resolutionNote,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (resolutionNote != null) {
        updates['resolutionNote'] = resolutionNote;
      }

      await _firestore.collection('issues').doc(issueId).update(updates);

      final index = _issues.indexWhere((i) => i.id == issueId);
      if (index != -1) {
        _issues[index] = _issues[index].copyWith(
          status: newStatus,
          resolutionNote: resolutionNote,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteIssue(String issueId) async {
    try {
      await _firestore.collection('issues').doc(issueId).delete();
      _issues.removeWhere((i) => i.id == issueId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  IssueModel? getIssueById(String id) {
    try {
      return _issues.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }
}
