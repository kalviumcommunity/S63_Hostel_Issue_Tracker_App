import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/staff_model.dart';
import '../models/issue_model.dart';

class StaffSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Call this once to populate your Firestore with staff members
  static Future<void> seedStaff() async {
    final staffCollection = _firestore.collection('staff');
    
    // Check if empty
    final existing = await staffCollection.limit(1).get();
    if (existing.docs.isNotEmpty) {
      print('Staff already seeded.');
      return;
    }

    final staff = [
      StaffModel(id: '', name: 'John Electric', role: 'Chief Electrician', category: 'Electricity', isAvailable: true),
      StaffModel(id: '', name: 'Mike Volt', role: 'Junior Electrician', category: 'Electricity', isAvailable: true),
      StaffModel(id: '', name: 'Sam Plumb', role: 'Master Plumber', category: 'Water Problem', isAvailable: true),
      StaffModel(id: '', name: 'Chef Mario', role: 'Mess Manager', category: 'Mess Food', isAvailable: true),
      StaffModel(id: '', name: 'Robert Clean', role: 'Housekeeping Lead', category: 'Cleanliness', isAvailable: true),
    ];

    final batch = _firestore.batch();
    for (var s in staff) {
      batch.set(staffCollection.doc(), s.toMap());
    }
    
    await batch.commit();
    print('Staff seeded successfully!');
  }
}
