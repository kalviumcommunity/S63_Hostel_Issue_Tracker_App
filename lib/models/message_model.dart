import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final bool isAdmin;
  final DateTime timestamp;
  final DateTime clientTimestamp;

  MessageModel({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.isAdmin,
    required this.timestamp,
    required this.clientTimestamp,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedTime;
    if (map['timestamp'] is Timestamp) {
      parsedTime = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      parsedTime = DateTime.parse(map['timestamp']);
    } else {
      parsedTime = DateTime.timestamp(); // Use server-ish time if unknown
    }

    DateTime clientTime;
    if (map['clientTimestamp'] != null) {
      clientTime = DateTime.tryParse(map['clientTimestamp']) ?? parsedTime;
    } else {
      clientTime = parsedTime;
    }

    return MessageModel(
      id: docId,
      text: map['text'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Unknown',
      isAdmin: map['isAdmin'] ?? false,
      timestamp: parsedTime,
      clientTimestamp: clientTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'isAdmin': isAdmin,
      'timestamp': timestamp.toIso8601String(),
      'clientTimestamp': clientTimestamp.toIso8601String(),
    };
  }
}
