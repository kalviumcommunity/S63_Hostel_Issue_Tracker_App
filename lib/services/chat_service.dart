import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Real-time stream of messages under a specific issue
  Stream<List<MessageModel>> getMessagesStream(String issueId) {
    return _firestore
        .collection('issues')
        .doc(issueId)
        .collection('messages')
        .orderBy('timestamp', descending: true) // new messages at the top/bottom depending on UI
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Send a new message
  Future<bool> sendMessage({
    required String issueId,
    required String text,
    required String senderId,
    required String senderName,
    required bool isAdmin,
  }) async {
    if (text.trim().isEmpty) return false;

    try {
      final newMessage = MessageModel(
        id: '',
        text: text.trim(),
        senderId: senderId,
        senderName: senderName,
        isAdmin: isAdmin,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('issues')
          .doc(issueId)
          .collection('messages')
          .add(newMessage.toMap());

      // Optionally update the issue's updatedAt timestamp
      await _firestore.collection('issues').doc(issueId).update({
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}
