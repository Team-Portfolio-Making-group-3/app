// File: lib/firebase_options.dart
// ✅ Firebase configuration using environment variables

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// 🔹 Web configuration
  static FirebaseOptions get web => FirebaseOptions(
    apiKey: dotenv.env['WEB_API_KEY'] ?? '',
    appId: dotenv.env['WEB_APP_ID'] ?? '',
    messagingSenderId: dotenv.env['MESSAGING_SENDER_ID'] ?? '',
    projectId: dotenv.env['PROJECT_ID'] ?? '',
    authDomain: dotenv.env['WEB_AUTH_DOMAIN'] ?? '',
    storageBucket: dotenv.env['WEB_STORAGE_BUCKET'] ?? '',
  );

  /// 🔹 Android configuration
  static FirebaseOptions get android => FirebaseOptions(
    apiKey: dotenv.env['ANDROID_API_KEY'] ?? '',
    appId: dotenv.env['ANDROID_APP_ID'] ?? '',
    messagingSenderId: dotenv.env['MESSAGING_SENDER_ID'] ?? '',
    projectId: dotenv.env['PROJECT_ID'] ?? '',
    storageBucket: dotenv.env['ANDROID_STORAGE_BUCKET'] ?? '',
  );

  /// 🔹 iOS configuration
  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: dotenv.env['IOS_API_KEY'] ?? '',
    appId: dotenv.env['IOS_APP_ID'] ?? '',
    messagingSenderId: dotenv.env['MESSAGING_SENDER_ID'] ?? '',
    projectId: dotenv.env['PROJECT_ID'] ?? '',
    storageBucket: dotenv.env['IOS_STORAGE_BUCKET'] ?? '',
    iosClientId: dotenv.env['IOS_CLIENT_ID'] ?? '',
    iosBundleId: dotenv.env['IOS_BUNDLE_ID'] ?? '',
  );

  /// 🔹 macOS configuration
  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: dotenv.env['MACOS_API_KEY'] ?? '',
    appId: dotenv.env['MACOS_APP_ID'] ?? '',
    messagingSenderId: dotenv.env['MESSAGING_SENDER_ID'] ?? '',
    projectId: dotenv.env['PROJECT_ID'] ?? '',
    storageBucket: dotenv.env['MACOS_STORAGE_BUCKET'] ?? '',
  );

  /// 🔹 Windows configuration
  static FirebaseOptions get windows => FirebaseOptions(
    apiKey: dotenv.env['WINDOWS_API_KEY'] ?? '',
    appId: dotenv.env['WINDOWS_APP_ID'] ?? '',
    messagingSenderId: dotenv.env['MESSAGING_SENDER_ID'] ?? '',
    projectId: dotenv.env['PROJECT_ID'] ?? '',
    storageBucket: dotenv.env['WINDOWS_STORAGE_BUCKET'] ?? '',
  );

  /// 🔹 Linux configuration
  static FirebaseOptions get linux => FirebaseOptions(
    apiKey: dotenv.env['LINUX_API_KEY'] ?? '',
    appId: dotenv.env['LINUX_APP_ID'] ?? '',
    messagingSenderId: dotenv.env['MESSAGING_SENDER_ID'] ?? '',
    projectId: dotenv.env['PROJECT_ID'] ?? '',
    storageBucket: dotenv.env['LINUX_STORAGE_BUCKET'] ?? '',
  );
}
