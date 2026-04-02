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
        .snapshots(includeMetadataChanges: true) // Get instant local updates
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
      
      // Memory Sort: Descending (Newest first) for reversed list (bottom-up)
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return messages;
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
      final messageRef = _firestore
          .collection('issues')
          .doc(issueId)
          .collection('messages')
          .doc();

      final timestamp = FieldValue.serverTimestamp();

      // Batch update: Add message and update issue activity time simultaneously
      final batch = _firestore.batch();
      
      batch.set(messageRef, {
        'text': text.trim(),
        'senderId': senderId,
        'senderName': senderName,
        'isAdmin': isAdmin,
        'timestamp': timestamp,
      });

      batch.update(_firestore.collection('issues').doc(issueId), {
        'updatedAt': timestamp,
      });

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Chat error: $e');
      return false;
    }
  }
}

