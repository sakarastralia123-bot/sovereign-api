import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions have not been configured for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDummyKeyForWebTestingReplaceWithReal',
    appId: '1:439662008644:web:dummy_app_id',
    messagingSenderId: '439662008644',
    projectId: 'matrixnepal21-9a1a2',
    authDomain: 'matrixnepal21-9a1a2.firebaseapp.com',
    databaseURL: 'https://matrixnepal21-9a1a2-default-rtdb.firebaseio.com',
    storageBucket: 'matrixnepal21-9a1a2.appspot.com',
  );
}