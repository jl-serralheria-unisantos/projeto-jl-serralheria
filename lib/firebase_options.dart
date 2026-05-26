// Arquivo gerado automaticamente a partir do google-services.json e Firebase Console
// Projeto: jl-serralheria-unisantos

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
        throw UnsupportedError(
          'DefaultFirebaseOptions não configurado para iOS. '
          'Adicione o GoogleService-Info.plist e reconfigure.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions não suporta a plataforma: '
          '$defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDdTGA7Hsa8GpstM9UkoXly_uPt-Z6bO8Q',
    authDomain: 'jl-serralheria-unisantos.firebaseapp.com',
    appId: '1:358998490076:web:5f4eb2a31072f61fa42d19',
    messagingSenderId: '358998490076',
    projectId: 'jl-serralheria-unisantos',
    storageBucket: 'jl-serralheria-unisantos.firebasestorage.app',
    measurementId: 'G-D4C0T7PGTM',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB8zUEYWaPOqUNceA_BHAouJbKRH_ISN7s',
    appId: '1:358998490076:android:aa27f771348068d0a42d19',
    messagingSenderId: '358998490076',
    projectId: 'jl-serralheria-unisantos',
    storageBucket: 'jl-serralheria-unisantos.firebasestorage.app',
  );
}
