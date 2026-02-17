// File generated based on google-services.json
// Replace all values below with your actual Firebase project values
// Found in: android/app/google-services.json

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ======================================================
  // REPLACE THESE VALUES WITH YOUR google-services.json
  // ======================================================
  // Open android/app/google-services.json and find:
  // - project_id        → projectId
  // - mobilesdk_app_id  → appId
  // - current_key       → apiKey (under api_key array)
  // - storage_bucket    → storageBucket
  // - project_number    → messagingSenderId
  // ======================================================
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY', // current_key
    appId: 'YOUR_APP_ID', // mobilesdk_app_id
    messagingSenderId: 'YOUR_SENDER_ID', // project_number
    projectId: 'YOUR_PROJECT_ID', // project_id
    storageBucket: 'YOUR_STORAGE_BUCKET', // storage_bucket
  );
}
