import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/issue_model.dart';
import '../repositories/issue_repository.dart';
import '../services/assignment_service.dart';
import '../services/duplicate_detection_service.dart';

class IssueProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DuplicateDetectionService _duplicateService = DuplicateDetectionService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final IssueRepository _repository = IssueRepository();

  List<IssueModel> _issues = [];
  List<IssueModel> _paginatedIssues = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  String? _error;
  StreamSubscription? _subscription; // tracks active Firestore listener
  DateTime _lastCheckedTime = DateTime.now(); // for notification badge reset

  List<IssueModel> get issues => _issues;
  List<IssueModel> get paginatedIssues => _paginatedIssues;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  // Filtered getters
  List<IssueModel> get pendingIssues =>
      _issues.where((i) {
        final s = i.status.toLowerCase();
        return s == statusPending || s == statusAssigned || s == 'open';
      }).toList();
  List<IssueModel> get inProgressIssues =>
      _issues.where((i) => i.status == statusInProgress).toList();
  List<IssueModel> get resolvedIssues =>
      _issues.where((i) => i.status == statusResolved).toList();

  // New issues count (for red badge)
  int get newIssuesCount => 
      pendingIssues.where((i) => i.createdAt.isAfter(_lastCheckedTime)).length;

  void markNotificationsRead() {
    _lastCheckedTime = DateTime.now();
    notifyListeners();
  }

  // Cancel old listener and clear issues (called on logout or user switch)
  void clearIssues() {
    _subscription?.cancel();
    _subscription = null;
    _issues = [];
    notifyListeners();
  }

  // Real-time listener for admin — sees ALL issues
  void listenToAllIssues() {
    _subscription?.cancel(); // cancel previous listener first
    _issues = [];            // clear old user's data immediately
    notifyListeners();

    _subscription = _firestore
        .collection('issues')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      debugPrint('--- [ADMIN] Received ${snapshot.docs.length} issues from Firestore ---');
      _issues = snapshot.docs
          .map((doc) => IssueModel.fromMap(doc.data(), doc.id))
          .toList();
      notifyListeners();
    }, onError: (e) {
      debugPrint('--- [ADMIN] Error: $e ---');
      _error = e.toString();
      notifyListeners();
    });
  }

  // Real-time listener for a specific student — sees only THEIR issues
  void listenToMyIssues(String userId) {
    _subscription?.cancel(); // cancel previous listener first
    _issues = [];            // clear old user's data immediately
    notifyListeners();

    _subscription = _firestore
        .collection('issues')
        .where('createdBy', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      debugPrint('--- [STUDENT] Received ${snapshot.docs.length} issues for user $userId ---');
      _issues = snapshot.docs
          .map((doc) => IssueModel.fromMap(doc.data(), doc.id))
          .toList();
      _issues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    }, onError: (e) {
      debugPrint('--- [STUDENT] Error: $e ---');
      _error = e.toString();
      notifyListeners();
    });
  }

  // Real-time listener for a specific staff member — sees only issues ASSIGNED to them
  void listenToMyAssignedIssues(String staffId) {
    _subscription?.cancel();
    _issues = [];
    notifyListeners();

    _subscription = _firestore
        .collection('issues')
        .where('assignedStaffId', isEqualTo: staffId)
        .snapshots()
        .listen((snapshot) {
      _issues = snapshot.docs
          .map((doc) => IssueModel.fromMap(doc.data(), doc.id))
          .toList();
      _issues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      notifyListeners();
    });
  }

  // --- PAGINATION & INFINITE SCROLL ---

  Future<void> fetchFirstPage({String? filterStatus, String? filterCategory}) async {
    _isLoading = true;
    _paginatedIssues = [];
    _lastDocument = null;
    _hasMore = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _repository.getIssuesPaginated(
        filterStatus: filterStatus,
        filterCategory: filterCategory,
      );

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _paginatedIssues = snapshot.docs
            .map((doc) => IssueModel.fromMap(doc.data(), doc.id))
            .toList();
      } else {
        _hasMore = false;
      }
    } catch (e) {
      _error = 'Pagination failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreIssues({String? filterStatus, String? filterCategory}) async {
    if (_isFetchingMore || !_hasMore) return;

    _isFetchingMore = true;
    notifyListeners();

    try {
      final snapshot = await _repository.getIssuesPaginated(
        lastDocument: _lastDocument,
        filterStatus: filterStatus,
        filterCategory: filterCategory,
      );

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        final newItems = snapshot.docs
            .map((doc) => IssueModel.fromMap(doc.data(), doc.id))
            .toList();
        
        final existingIds = _paginatedIssues.map((i) => i.id).toSet();
        for (var item in newItems) {
          if (!existingIds.contains(item.id)) {
            _paginatedIssues.add(item);
          }
        }
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('Error fetching more: $e');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
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
  // --- ADVANCED FEATURES ---

  /// Checks if a similar issue exists based on category and title similarity
  Future<List<IssueModel>> checkPotentialDuplicates({
    required String title,
    required String category,
    required String location,
  }) async {
    _isLoading = true;
    notifyListeners();

    final duplicates = await _duplicateService.checkRecentDuplicates(
      title: title,
      category: category,
      location: location,
    );

    _isLoading = false;
    notifyListeners();
    return duplicates;
  }

  Future<bool> createIssue(IssueModel issue) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final docRef = await _firestore.collection('issues').add(issue.toMap());
      
      // Auto-assign immediately after creation
      // We pass the new doc ID and the category
      await AssignmentService.autoAssignIssue(docRef.id, issue.category);

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
      final now = DateTime.now().toIso8601String();
      final updates = <String, dynamic>{
        'status': newStatus,
        'updatedAt': now,
      };

      if (newStatus == statusAssigned) {
        updates['assignedAt'] = now;
      } else if (newStatus == statusInProgress) {
        updates['startedAt'] = now;
      } else if (newStatus == statusResolved) {
        updates['resolvedAt'] = now;
      }

      if (adminComment != null && adminComment.isNotEmpty) {
        updates['adminComment'] = adminComment;
      }

      // If resolving, decrement the staff count
      if (newStatus == statusResolved) {
        final issueSnap = await _firestore.collection('issues').doc(issueId).get();
        final staffId = issueSnap.data()?['assignedStaffId'];
        if (staffId != null) {
          await AssignmentService.markResolved(staffId);
        }
      }

      await _firestore.collection('issues').doc(issueId).update(updates);

      final nowDateTime = DateTime.parse(now);
      
      // Helper for local update logic
      IssueModel updateLocal(IssueModel old) {
        return old.copyWith(
          status: newStatus,
          adminComment: adminComment,
          updatedAt: nowDateTime,
          assignedAt: newStatus == statusAssigned ? nowDateTime : old.assignedAt,
          startedAt: newStatus == statusInProgress ? nowDateTime : old.startedAt,
          resolvedAt: newStatus == statusResolved ? nowDateTime : old.resolvedAt,
        );
      }

      // --- NEW: Update Local State for Instant UI Refresh ---
      final issueIndex = _issues.indexWhere((i) => i.id == issueId);
      if (issueIndex != -1) {
        _issues[issueIndex] = updateLocal(_issues[issueIndex]);
      }

      final paginatedIndex = _paginatedIssues.indexWhere((i) => i.id == issueId);
      if (paginatedIndex != -1) {
        _paginatedIssues[paginatedIndex] = updateLocal(_paginatedIssues[paginatedIndex]);
      }

      notifyListeners();
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
