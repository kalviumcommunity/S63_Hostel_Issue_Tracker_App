import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Real-time stream of messages under a specific issue
  Stream<List<MessageModel>> getMessagesStream(String issueId) {
    return _firestore
        .collection('issues')
        .doc(issueId)
        .collection('messages')
        .orderBy('timestamp', descending: true) // newest at top of list, which is bottom of reverse-ListView
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

      // FIRE AND FORGET: Add the message but don't wait for server confirmation to continue
      // Firestore will handle this optimistically in the local cache/stream
      _firestore
          .collection('issues')
          .doc(issueId)
          .collection('messages')
          .add(newMessage.toMap());

      // BACKGROUND UPDATE: Refresh parent issue timestamp without blocking the UI
      _firestore.collection('issues').doc(issueId).update({
        'updatedAt': DateTime.now().toIso8601String(),
      }).catchError((e) => debugPrint('Secondary update failed: $e'));

      return true; // We return true immediately as Firestore has cached the write locally
    } catch (e) {
      debugPrint('Chat error: $e');
      return false;
    }
  }
}

