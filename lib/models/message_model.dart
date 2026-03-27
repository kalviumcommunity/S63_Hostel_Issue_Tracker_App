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
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'isAdmin': isAdmin,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
