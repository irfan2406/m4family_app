// File generated for Firebase project m4core.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'run FlutterFire CLI again to add support for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'run FlutterFire CLI again to add support for macos.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'run FlutterFire CLI again to add support for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'run FlutterFire CLI again to add support for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCpe9nsdaVLj67oZg62r5_VTG9c8iidsMQ',
    appId: '1:693947989069:android:9a2649c03452a21c873004',
    messagingSenderId: '693947989069',
    projectId: 'm4core',
    storageBucket: 'm4core.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC42svgA4TRjaQ7wUvLN8hvlOb5l1TdDwQ',
    appId: '1:693947989069:ios:3b11201ac5921ec9873004',
    messagingSenderId: '693947989069',
    projectId: 'm4core',
    storageBucket: 'm4core.firebasestorage.app',
    iosBundleId: 'com.m4family.m4Mobile',
  );
}
