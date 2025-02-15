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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAcw89kbwmKvevWYThayS-9RZGFBOM-u1Y',
    appId: '1:796398190152:android:6fa4de1aaf63be0c3c227d',
    messagingSenderId: '796398190152',
    projectId: 'gyansetu-6e83b',
    authDomain: 'gyansetu-6e83b.firebaseapp.com',
    storageBucket: 'gyansetu-6e83b.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAcw89kbwmKvevWYThayS-9RZGFBOM-u1Y',
    appId: '1:796398190152:android:6fa4de1aaf63be0c3c227d',
    messagingSenderId: '796398190152',
    projectId: 'gyansetu-6e83b',
    storageBucket: 'gyansetu-6e83b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAcw89kbwmKvevWYThayS-9RZGFBOM-u1Y',
    appId: '1:796398190152:ios:YOUR_IOS_APP_ID',
    messagingSenderId: '796398190152',
    projectId: 'gyansetu-6e83b',
    storageBucket: 'gyansetu-6e83b.firebasestorage.app',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.example.gyansetu_client',
  );
}
