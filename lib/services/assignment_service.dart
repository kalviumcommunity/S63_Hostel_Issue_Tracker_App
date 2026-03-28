import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/issue_model.dart';
import '../models/staff_model.dart';

class AssignmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Automatically assigns an issue to the most available staff in the matching category.
  static Future<void> autoAssignIssue(String issueId, String category) async {
    try {
      // 1. Find all available staff for this category
      final staffSnapshot = await _firestore
          .collection('staff')
          .where('category', isEqualTo: category)
          .where('isAvailable', isEqualTo: true)
          .get();

      if (staffSnapshot.docs.isEmpty) {
        print('No available staff for category: $category');
        return;
      }

      // 2. Load Balancing: Pick the staff with the minimum active issues
      List<StaffModel> staffList = staffSnapshot.docs
          .map((doc) => StaffModel.fromMap(doc.data(), doc.id))
          .toList();

      staffList.sort((a, b) => a.activeIssuesCount.compareTo(b.activeIssuesCount));
      final selectedStaff = staffList.first;

      // 3. Atomically update the issue and the staff count
      final batch = _firestore.batch();

      final issueRef = _firestore.collection('issues').doc(issueId);
      final staffRef = _firestore.collection('staff').doc(selectedStaff.id);

      batch.update(issueRef, {
        'status': statusAssigned,
        'assignedStaffId': selectedStaff.id,
        'assignedStaffName': selectedStaff.name,
        'assignedAt': DateTime.now().toIso8601String(),
      });

      batch.update(staffRef, {
        'activeIssuesCount': FieldValue.increment(1),
      });

      await batch.commit();
      print('Auto-assigned issue $issueId to ${selectedStaff.name}');
    } catch (e) {
      print('Error in auto-assignment: $e');
    }
  }

  /// Manual override for admins
  static Future<bool> manualAssign(String issueId, StaffModel staff) async {
    try {
      final batch = _firestore.batch();
      final issueRef = _firestore.collection('issues').doc(issueId);
      final newStaffRef = _firestore.collection('staff').doc(staff.id);

      // Get current issue to check if it was already assigned
      final issueSnap = await issueRef.get();
      final oldStaffId = issueSnap.data()?['assignedStaffId'];

      if (oldStaffId != null) {
        final oldStaffRef = _firestore.collection('staff').doc(oldStaffId);
        batch.update(oldStaffRef, {'activeIssuesCount': FieldValue.increment(-1)});
      }

      batch.update(issueRef, {
        'status': statusAssigned,
        'assignedStaffId': staff.id,
        'assignedStaffName': staff.name,
        'assignedAt': DateTime.now().toIso8601String(),
      });

      batch.update(newStaffRef, {'activeIssuesCount': FieldValue.increment(1)});

      await batch.commit();
      return true;
    } catch (e) {
      print('Manual assignment error: $e');
      return false;
    }
  }

  /// Special helper for resolving (to decrement staff count)
  static Future<void> markResolved(String staffId) async {
    try {
      await _firestore.collection('staff').doc(staffId).update({
        'activeIssuesCount': FieldValue.increment(-1),
      });
    } catch (e) {
      print('Decrement count error: $e');
    }
  }

  /// Fetch all staff (for admin manual assignment selection)
  static Future<List<StaffModel>> getAvailableStaff() async {
    final snapshot = await _firestore.collection('staff').get();
    return snapshot.docs
        .map((doc) => StaffModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
