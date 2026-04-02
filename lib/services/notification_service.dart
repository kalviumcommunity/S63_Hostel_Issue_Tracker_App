import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../app/app.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {
    print("--- [NOTIFICATION] Initializing Service... ---");
    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print("--- [NOTIFICATION] Permission Status: ${settings.authorizationStatus} ---");

    // 2. Initialize Local Notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        print("--- [NOTIFICATION] Notification Tapped! Payload: ${details.payload} ---");
        if (details.payload != null) {
          HostelIssueTrackerApp.navigateTo(details.payload!);
        }
      },
    );

    // 3. Define Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Handle Notification Clicks (App in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("--- [NOTIFICATION] App opened via notification: ${message.messageId} ---");
      _handleMessage(message);
    });

    // 5. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("--- [NOTIFICATION] NEW MESSAGE RECEIVED IN FOREGROUND! ---");
      print("Title: ${message.notification?.title}");
      print("Body: ${message.notification?.body}");
      print("Data: ${message.data}");
      
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        final issueId = message.data['issueId'];
        final type = message.data['type'];
        final String path = (type == 'chat') ? '/issue/$issueId/chat' : '/issue/$issueId';

        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
            ),
          ),
          payload: path,
        );
      }
    });

    // 6. Setup Background Handler & Token
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await updateFCMToken();
    FirebaseMessaging.instance.onTokenRefresh.listen((token) => updateFCMToken());
    // 7. NEW: Self-Reliant Listener (Works without the JS script!)
    _setupDirectMessageListener();
    _setupIssueActivityListener();
  }

  StreamSubscription<QuerySnapshot>? _messageSubscription;
  StreamSubscription<QuerySnapshot>? _issueSubscription;

  void _setupIssueActivityListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // We need to know the user's role to notify them correctly
    FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get().then((userDoc) {
      if (!userDoc.exists) return;
      final role = userDoc.data()?['role'];

      _issueSubscription?.cancel();
      _issueSubscription = FirebaseFirestore.instance
          .collection('issues')
          .where('createdAt', isGreaterThan: DateTime.now())
          .snapshots()
          .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data == null) continue;

            // 1. Notify ADMINS about NEW issues
            if (role == 'admin') {
              print("--- [NOTIFICATION] Admin: New Issue Detected! ---");
              _showLocalNotification(
                title: "New Issue Reported",
                body: "${data['userName']} reported: ${data['title']}",
                payload: '/issue/${change.doc.id}',
              );
            }
          } else if (change.type == DocumentChangeType.modified) {
            final data = change.doc.data();
            if (data == null) continue;

            // 2. Notify STUDENTS about completion/assignment
            if (role == 'student' && data['createdBy'] == currentUser.uid) {
               print("--- [NOTIFICATION] Student: Status Update Detected! ---");
               _showLocalNotification(
                  title: "Issue Update",
                  body: "Your issue '${data['title']}' is now ${data['status'].toString().toUpperCase()}",
                  payload: '/issue/${change.doc.id}',
               );
            }
            
            // 3. Notify STAFF about assignment
            if (role == 'staff' && data['assignedStaffId'] == currentUser.uid) {
               print("--- [NOTIFICATION] Staff: New Assignment Detected! ---");
                _showLocalNotification(
                  title: "Job Assigned",
                  body: "You have a new task: ${data['title']}",
                  payload: '/issue/${change.doc.id}',
               );
            }
          }
        }
      });
    });
  }

  void _setupDirectMessageListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Cancel existing to avoid duplicates
    _messageSubscription?.cancel();

    print("--- [NOTIFICATION] Starting Direct Message Listener for: ${currentUser.uid} ---");

    _messageSubscription = FirebaseFirestore.instance
        .collectionGroup('messages')
        .where('timestamp', isGreaterThan: DateTime.now()) // Only new ones
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          // Don't notify if I am the sender
          if (data != null && data['senderId'] != currentUser.uid) {
            print("--- [NOTIFICATION] Direct Message Detected! ---");
            _showLocalNotification(
              title: "New Message",
              body: "${data['senderName']}: ${data['text']}",
              payload: change.doc.reference.path.contains('issues') 
                ? '/issue/${change.doc.reference.parent.parent?.id}/chat' 
                : null,
            );
          }
        }
      }
    });
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: payload,
    );
  }

  void _handleMessage(RemoteMessage message) {
    final issueId = message.data['issueId'];
    final type = message.data['type'];
    if (issueId != null) {
      final path = (type == 'chat') ? '/issue/$issueId/chat' : '/issue/$issueId';
      HostelIssueTrackerApp.navigateTo(path);
    }
  }

  Future<void> updateFCMToken() async {
    try {
      String? token = await _fcm.getToken();
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      
      // Also ensure the direct listeners are running whenever we update tokens (likely after login)
      _setupDirectMessageListener();
      _setupIssueActivityListener();

      print("--- [NOTIFICATION] Current Token: $token ---");
      if (token != null && uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print("--- [NOTIFICATION] Token synced to Firestore for user: $uid ---");
      }
    } catch (e) {
      print("--- [NOTIFICATION] Token sync FAILED: $e ---");
    }
  }

  Future<void> deleteToken() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
      });
    }
    await _fcm.deleteToken();
  }
}
