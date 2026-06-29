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
    apiKey: 'AIzaSyCgAFVlazJmUNr27C32-A0JGerOnrLx2AU',
    authDomain: 'couple-apllication.firebaseapp.com',
    projectId: 'couple-apllication',
    storageBucket: 'couple-apllication.firebasestorage.app',
    messagingSenderId: '155274300125',
    appId: '1:155274300125:web:64a20ba1a10d239e45e934',
    measurementId: 'G-81TQKN508R',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBVvuh7TZl5Sgzgo0sEZ2m_lL4Wkvoq5vc',
    appId: '1:155274300125:android:d173ff0dd62bca7945e934',
    messagingSenderId: '155274300125',
    projectId: 'couple-apllication',
    storageBucket: 'couple-apllication.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR-IOS-API-KEY',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'your-firebase-project-id',
    storageBucket: 'your-firebase-project-id.appspot.com',
    iosClientId: 'YOUR-IOS-CLIENT-ID',
    iosBundleId: 'com.couple.coupleApp',
  );
}
