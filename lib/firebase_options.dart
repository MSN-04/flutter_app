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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC1_ZRyvRyyx4iPWJfQqhftadk4Ak4w9Ac',
    appId: '1:355661409196:web:d5822639733ca6c5a1e809',
    messagingSenderId: '355661409196',
    projectId: 'nk-push-app-prod',
    authDomain: 'nk-push-app-prod.firebaseapp.com',
    storageBucket: 'nk-push-app-prod.firebasestorage.app',
    measurementId: 'G-2NEHHE7KS5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAMFebI6ziqsONY2TNzMxnqMDuEqC3UGiI',
    appId: '1:355661409196:android:d6bfcb3626c75005a1e809',
    messagingSenderId: '355661409196',
    projectId: 'nk-push-app-prod',
    storageBucket: 'nk-push-app-prod.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCFLKiUwYMs0AFzBKrOXXcR_7xlWtnZfzc',
    appId: '1:355661409196:ios:bbe196355a8c5795a1e809',
    messagingSenderId: '355661409196',
    projectId: 'nk-push-app-prod',
    storageBucket: 'nk-push-app-prod.firebasestorage.app',
    iosBundleId: 'com.nk.pushApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCFLKiUwYMs0AFzBKrOXXcR_7xlWtnZfzc',
    appId: '1:355661409196:ios:bbe196355a8c5795a1e809',
    messagingSenderId: '355661409196',
    projectId: 'nk-push-app-prod',
    storageBucket: 'nk-push-app-prod.firebasestorage.app',
    iosBundleId: 'com.nk.pushApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyApVqeKVAGyEa6zPkcjNyn8WOwn2IeKHo4',
    appId: '1:355661409196:web:99aba9e8df9cb583a1e809',
    messagingSenderId: '355661409196',
    projectId: 'nk-push-app-prod',
    authDomain: 'nk-push-app-prod.firebaseapp.com',
    storageBucket: 'nk-push-app-prod.firebasestorage.app',
    measurementId: 'G-1Z3077KYH8',
  );

}