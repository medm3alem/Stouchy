import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not configured');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS not configured');
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBr322UudRjJJbVuz0rvkU3IIGLBYby9fM',
    appId: '1:841062706518:android:336c2194a4f42f6b73faf7',
    messagingSenderId: '841062706518',
    projectId: 'stouchy-5ac9c',
    storageBucket: 'stouchy-5ac9c.firebasestorage.app',
  );
}
