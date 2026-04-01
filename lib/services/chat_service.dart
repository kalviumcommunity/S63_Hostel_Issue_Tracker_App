import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _cachedProjectId;

  // --- OAUTH2 TOKEN GENERATION (MODERN WAY) ---
  Future<String?> _getAccessToken() async {
    try {
      // 1. Load the service account json from assets
      final String jsonString = await rootBundle.loadString('assets/service_account.json');
      final Map<String, dynamic> accountData = jsonDecode(jsonString);
      
      // Cache project ID dynamically from the JSON
      _cachedProjectId = accountData['project_id'];

      // 2. Define the scope for FCM
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      // 3. Create a client with the credentials
      final client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(accountData),
        scopes,
      );

      // 4. Return the access token
      return client.credentials.accessToken.data;
    } catch (e) {
      debugPrint('--- [AUTH-ERR] Failed to parse service_account.json: $e ---');
      return null;
    }
  }

  Stream<List<MessageModel>> getMessagesStream(String issueId) {
    debugPrint('--- [CHAT] Opening Stream for Issue: $issueId ---');
    return _db
        .collection('issues')
        .doc(issueId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
              .toList();
          
          // CRITICAL: Stable sort for local updates
          // Newer messages at index 0 (for reverse ListView)
          messages.sort((a, b) {
            // First try server timestamp
            int cmp = b.timestamp.compareTo(a.timestamp);
            if (cmp != 0) return cmp;
            // Fallback to high-precision client timestamp for local stability
            return b.clientTimestamp.compareTo(a.clientTimestamp);
          });
          
          return messages;
        });
  }

  Future<void> sendMessage({
    required String issueId,
    required String text,
    required String senderId,
    required String senderName,
    required bool isAdmin,
  }) async {
    try {
      debugPrint('--- [CHAT] Attempting to send message to Issue: $issueId ---');
      
      final now = DateTime.now();
      final messageData = {
        'text': text,
        'senderId': senderId,
        'senderName': senderName,
        'isAdmin': isAdmin,
        'timestamp': FieldValue.serverTimestamp(),
        'clientTimestamp': now.toIso8601String(), // For stable local/secondary sort
      };

      // 1. CRITICAL: Save to Firestore first (Don't let notification errors block this)
      await _db.collection('issues').doc(issueId).collection('messages').add(messageData);
      debugPrint('--- [CHAT-SUCCESS] Message written to Firestore sub-collection ---');

      // 2. Update the main issue's modified timestamp
      await _db.collection('issues').doc(issueId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      }).catchError((e) => debugPrint('Note: Could not update issue updatedAt: $e'));

      // 3. Dispatch Notification in background (Unawaited)
      _dispatchNotification(
        issueId: issueId,
        text: text,
        senderName: senderName,
        isAdmin: isAdmin,
      );

    } catch (e) {
      debugPrint('--- [CHAT-CRITICAL-ERR] Fail at sendMessage level: $e ---');
    }
  }

  /// Handles the complex notification logic without blocking the UI
  Future<void> _dispatchNotification({
    required String issueId,
    required String text,
    required String senderName,
    required bool isAdmin,
  }) async {
    try {
      final List<String> targetTokens = [];
      
      // Get the issue for context
      final issueDoc = await _db.collection('issues').doc(issueId).get();
      if (!issueDoc.exists) return;
      final issueData = issueDoc.data()!;
      final title = issueData['title'] ?? 'New Message';

      if (isAdmin) {
        // CASE: Staff/Admin sends message -> notify Student
        final studentId = issueData['createdBy'];
        if (studentId != null) {
          final studentDoc = await _db.collection('users').doc(studentId).get();
          final token = studentDoc.data()?['fcmToken'];
          if (token != null) targetTokens.add(token);
        }
      } else {
        // CASE: Student sends message -> notify Assigned Staff AND All Admins (Escalation)
        
        // 1. Get Assigned Staff
        final staffId = issueData['assignedStaffId'];
        if (staffId != null) {
          final staffDoc = await _db.collection('users').doc(staffId).get();
          final token = staffDoc.data()?['fcmToken'];
          if (token != null) targetTokens.add(token);
        }

        // 2. Fetch All Admins (Escalation)
        final adminSnapshot = await _db
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .get();
        
        for (var doc in adminSnapshot.docs) {
          final token = doc.data()['fcmToken'];
          if (token != null && !targetTokens.contains(token)) {
            targetTokens.add(token);
          }
        }
      }

      if (targetTokens.isEmpty) {
        debugPrint('--- [NOTIF-SKIP] No recipients found to notify ---');
        return;
      }

      final accessToken = await _getAccessToken();
      if (accessToken == null) return;

      // Send to all targets
      for (var token in targetTokens) {
        _sendV1Notification(
          token: token,
          title: title,
          body: '$senderName: $text',
          accessToken: accessToken,
          issueId: issueId,
        );
      }
    } catch (e) {
      debugPrint('--- [NOTIF-BACKGROUND-ERR] $e ---');
    }
  }

  Future<void> _sendV1Notification({
    required String token,
    required String title,
    required String body,
    required String accessToken,
    required String issueId,
  }) async {
    try {
      if (_cachedProjectId == null) {
        debugPrint('--- [NOTIF-ERR] Missing Project ID ---');
        return;
      }
      
      final fcmUrl = 'https://fcm.googleapis.com/v1/projects/$_cachedProjectId/messages:send';

      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': token,
            'notification': {'title': title, 'body': body},
            'data': {'issueId': issueId},
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': 'chat_messages',
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'sound': 'default',
              },
            },
          }
        }),
      );
      
      if (response.statusCode == 200) {
        debugPrint('--- [NOTIF-SUCCESS] Notification delivered to FCM ---');
      } else {
        debugPrint('--- [NOTIF-ERR] FCM returned: ${response.body} ---');
      }
    } catch (e) {
      debugPrint('--- [NOTIF-ERR] Connection Error: $e ---');
    }
  }
}
