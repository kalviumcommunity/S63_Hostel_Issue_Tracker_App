// Firebase configuration - auto-filled from google-services.json
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCMUuqb1AOcMfibf7ElbmHh-JQGq9Qi1Eo',
    appId: '1:558988080281:android:6dcec10122eccfd5a7b408',
    messagingSenderId: '558988080281',
    projectId: 'hostel-issue-tracker-app',
    storageBucket: 'hostel-issue-tracker-app.firebasestorage.app',
  );

  // Fill this when you add an iOS app in Firebase Console
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '558988080281',
    projectId: 'hostel-issue-tracker-app',
    storageBucket: 'hostel-issue-tracker-app.firebasestorage.app',
    iosBundleId: 'com.hosteltracker.hostelIssueTracker',
  );

  // Fill this when you add a Web app in Firebase Console
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: '558988080281',
    projectId: 'hostel-issue-tracker-app',
    storageBucket: 'hostel-issue-tracker-app.firebasestorage.app',
    authDomain: 'hostel-issue-tracker-app.firebaseapp.com',
  );
}
