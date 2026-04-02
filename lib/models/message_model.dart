import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final bool isAdmin;
  final DateTime timestamp;

  MessageModel({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.isAdmin,
    required this.timestamp,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return MessageModel(
      id: docId,
      text: map['text'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Unknown',
      isAdmin: map['isAdmin'] ?? false,
      timestamp: _parseDateTime(map['timestamp']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'isAdmin': isAdmin,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
