import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/issue_model.dart';

class DuplicateDetectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Checks for issues that have been reported in the last [days] 
  /// with a similar title and category.
  Future<List<IssueModel>> checkRecentDuplicates({
    required String title,
    required String category,
    required String location,
    int days = 5,
  }) async {
    try {
      final now = DateTime.now();
      final threshold = now.subtract(Duration(days: days));

      // Fetch internal/pending issues in the same category within the time window
      // Optimization: Filter by category to reduce the search space significantly
      final snapshot = await _firestore
          .collection('issues')
          .where('category', isEqualTo: category)
          .where('createdAt', isGreaterThan: threshold.toIso8601String())
          .get();

      final existingIssues = snapshot.docs
          .map((doc) => IssueModel.fromMap(doc.data(), doc.id))
          .toList();

      List<IssueModel> potentialDuplicates = [];

      for (var existing in existingIssues) {
        if (_isSimilar(title, existing.title) || 
            (existing.location == location && _isSimilar(title, existing.title))) {
          potentialDuplicates.add(existing);
        }
      }

      return potentialDuplicates;
    } catch (e) {
      print('Duplicate detection error: $e');
      return [];
    }
  }

  /// Simple string similarity check based on word overlap
  bool _isSimilar(String text1, String text2) {
    final t1 = text1.toLowerCase().trim();
    final t2 = text2.toLowerCase().trim();

    if (t1 == t2) return true;

    final words1 = t1.split(RegExp(r'\s+')).where((w) => w.length > 3).toSet();
    final words2 = t2.split(RegExp(r'\s+')).where((w) => w.length > 3).toSet();

    if (words1.isEmpty || words2.isEmpty) return false;

    final intersection = words1.intersection(words2);
    final union = words1.union(words2);
    
    // Jaccard similarity coefficient (simplified)
    final similarity = intersection.length / union.length;

    // Threshold: 30% word overlap is usually enough for titles like "Fan not working" 
    // vs "Bedroom fan is not working"
    return similarity >= 0.3;
  }
}
