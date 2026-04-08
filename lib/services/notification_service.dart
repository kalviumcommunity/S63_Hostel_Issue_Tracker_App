import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app/app.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("[FCM] Background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// The notification channel — defined once, reused everywhere.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    print("[FCM] Initializing...");

    // 1. Request permission (required for Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print("[FCM] Permission: ${settings.authorizationStatus}");

    // 2. Initialize flutter_local_notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print("[FCM] Notification tapped. Payload: ${details.payload}");
        if (details.payload != null) {
          HostelIssueTrackerApp.navigateTo(details.payload!);
        }
      },
    );

    // 3. Create the Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 4. Foreground messages — MUST show manually via local notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("[FCM] FOREGROUND message received!");
      print("[FCM] Title: ${message.notification?.title}");
      print("[FCM] Body: ${message.notification?.body}");
      print("[FCM] Data: ${message.data}");

      final notification = message.notification;
      if (notification != null) {
        final issueId = message.data['issueId'];
        final type = message.data['type'];
        final path =
            (type == 'chat') ? '/issue/$issueId/chat' : '/issue/$issueId';

        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
            ),
          ),
          payload: path,
        );
      }
    });

    // 5. Background tap — app was in background, user tapped notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("[FCM] App opened from background notification");
      _handleMessage(message);
    });

    // 6. Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 7. Terminated tap — app was killed, user tapped notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) _handleMessage(initialMessage);

    // 8. Token management
    await updateFCMToken();
    _fcm.onTokenRefresh.listen((_) => updateFCMToken());
  }

  void _handleMessage(RemoteMessage message) {
    final issueId = message.data['issueId'];
    final type = message.data['type'];
    if (issueId != null) {
      final path =
          (type == 'chat') ? '/issue/$issueId/chat' : '/issue/$issueId';
      HostelIssueTrackerApp.navigateTo(path);
    }
  }

  Future<void> updateFCMToken() async {
    try {
      final token = await _fcm.getToken();
      final uid = FirebaseAuth.instance.currentUser?.uid;

      print("\n=== [FCM DEBUG] ===");
      print("TOKEN: $token");
      print("UID: $uid");
      print("===================\n");

      if (token != null && uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print("[FCM] Token saved to Firestore for $uid");
      }
    } catch (e) {
      print("[FCM] Token sync FAILED: $e");
    }
  }

  Future<void> deleteToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
      });
    }
    await _fcm.deleteToken();
  }
}
