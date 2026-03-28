import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/issue_model.dart';

class IssueRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int pageSize = 10;

  // Cache settings: Firestore mobile SDK enables 100MB offline persistence by default.
  // We can explicitly set it if needed, but here we focus on query efficiency.

  /// Fetches a paginated list of issues for Admin/Analytics.
  /// Uses [lastDocument] as the cursor for the next page.
  Future<QuerySnapshot<Map<String, dynamic>>> getIssuesPaginated({
    DocumentSnapshot? lastDocument,
    String? filterStatus,
    String? filterCategory,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('issues')
        .orderBy('createdAt', descending: true)
        .limit(pageSize);

    if (filterStatus != null) {
      query = query.where('status', isEqualTo: filterStatus);
    }
    
    if (filterCategory != null) {
      query = query.where('category', isEqualTo: filterCategory);
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    // Source.serverAndCache ensures we use local data if available, 
    // reducing billed reads.
    return await query.get(const GetOptions(source: Source.serverAndCache));
  }

  /// Specialized fetch for Student/Staff with owner/assignee filtering.
  Future<QuerySnapshot<Map<String, dynamic>>> getMyIssuesPaginated({
    required String userId,
    required bool isStaff,
    DocumentSnapshot? lastDocument,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection('issues');

    if (isStaff) {
      query = query.where('assignedStaffId', isEqualTo: userId);
    } else {
      query = query.where('createdBy', isEqualTo: userId);
    }

    query = query.orderBy('createdAt', descending: true).limit(pageSize);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return await query.get();
  }

  /// Toggle Offline Persistence (Settings)
  Future<void> toggleOfflinePersistence(bool enabled) async {
    await _firestore.terminate();
    await _firestore.clearPersistence();
    // Default settings with the specific persistence choice
    // On modern Flutter, we handle this through FirebaseOptions but can be toggled via settings:
    _firestore.settings = Settings(
      persistenceEnabled: enabled,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
}
