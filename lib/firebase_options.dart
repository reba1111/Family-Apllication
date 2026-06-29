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
    apiKey: 'AIzaSyASGbFVXN-ST2Wtu3SfCoRbxJY_ktuAb8w',
    appId: '1:476301803579:web:eeddf214f4ed5af0561c1e',
    messagingSenderId: '476301803579',
    projectId: 'family-application-f5070',
    authDomain: 'family-application-f5070.firebaseapp.com',
    storageBucket: 'family-application-f5070.firebasestorage.app',
    measurementId: 'G-0XZN4QYK0J',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAGTWR-Wqr27ldZSCRAg5BFyFs29Uib-Vg',
    appId: '1:476301803579:android:985292e0943d7814561c1e',
    messagingSenderId: '476301803579',
    projectId: 'family-application-f5070',
    storageBucket: 'family-application-f5070.firebasestorage.app',
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
