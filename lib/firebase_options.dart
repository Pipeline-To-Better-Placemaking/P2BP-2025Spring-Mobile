// File generated by FlutterFire CLI.
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
        'you can reconfigure this by running the FlutterFire CLI again.',
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
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBuMhDdJxGHTEXrRWdYiL3piMlxGBaBrJA',
    appId: '1:15566872110:android:21f0ca765e3d8ce70509bf',
    messagingSenderId: '15566872110',
    projectId: 'better-placemaking',
    databaseURL: 'https://better-placemaking-default-rtdb.firebaseio.com',
    storageBucket: 'better-placemaking.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCg_pohYqzYxp7BZYu4Zyu2fGw_JTIapwc',
    appId: '1:15566872110:ios:47ff6ab573f8bf080509bf',
    messagingSenderId: '15566872110',
    projectId: 'better-placemaking',
    databaseURL: 'https://better-placemaking-default-rtdb.firebaseio.com',
    storageBucket: 'better-placemaking.appspot.com',
    iosBundleId: 'com.pipelinetobetterplacemaking.p2bp2025springMobile',
  );

}