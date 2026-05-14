import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  // Ces valeurs seront écrasées par 'flutterfire configure'
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'A REMPLACER',
    appId: 'A REMPLACER',
    messagingSenderId: '841062706518',
    projectId: 'stouchy-5ac9c',
    storageBucket: 'stouchy-5ac9c.firebasestorage.app',
    iosBundleId: 'com.stouchy.stouchy',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'A REMPLACER',
    appId: 'A REMPLACER',
    messagingSenderId: '841062706518',
    projectId: 'stouchy-5ac9c',
    storageBucket: 'stouchy-5ac9c.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBtZLgTilq7YHXeZxydSK_qO1vRNQ5GIfU',
    appId: '1:841062706518:web:471690cea078f17873faf7',
    messagingSenderId: '841062706518',
    projectId: 'stouchy-5ac9c',
    authDomain: 'stouchy-5ac9c.firebaseapp.com',
    storageBucket: 'stouchy-5ac9c.firebasestorage.app',
    measurementId: 'G-3WLMYHEPRY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBr322UudRjJJbVuz0rvkU3IIGLBYby9fM',
    appId: '1:841062706518:android:336c2194a4f42f6b73faf7',
    messagingSenderId: '841062706518',
    projectId: 'stouchy-5ac9c',
    storageBucket: 'stouchy-5ac9c.firebasestorage.app',
  );
}
