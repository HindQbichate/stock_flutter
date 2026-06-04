// ⚠️  CE FICHIER EST UN TEMPLATE — À REMPLACER PAR LA VRAIE CONFIGURATION
//
// Pour générer ce fichier avec vos vraies clés Firebase :
//
//   1. Installez FlutterFire CLI :
//      dart pub global activate flutterfire_cli
//
//   2. Connectez-vous à Firebase :
//      firebase login
//
//   3. Configurez le projet :
//      flutterfire configure --project=VOTRE_PROJECT_ID
//
//   Ce fichier sera regénéré automatiquement avec vos vraies clés.
//   NE PAS commiter le vrai fichier (il est dans .gitignore).
//
// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Plateforme non supportée: $defaultTargetPlatform\n'
          'Lancez "flutterfire configure" pour configurer toutes les plateformes.',
        );
    }
  }

  // ── Android ────────────────────────────────────────────────────────────
  // Remplacez par les valeurs de votre google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'VOTRE_ANDROID_API_KEY',
    appId: '1:XXXXXXXXXX:android:XXXXXXXXXXXXXXXXXXXX',
    messagingSenderId: 'XXXXXXXXXX',
    projectId: 'VOTRE_PROJECT_ID',
    storageBucket: 'VOTRE_PROJECT_ID.appspot.com',
  );

  // ── iOS ────────────────────────────────────────────────────────────────
  // Remplacez par les valeurs de votre GoogleService-Info.plist
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'VOTRE_IOS_API_KEY',
    appId: '1:XXXXXXXXXX:ios:XXXXXXXXXXXXXXXXXXXX',
    messagingSenderId: 'XXXXXXXXXX',
    projectId: 'VOTRE_PROJECT_ID',
    storageBucket: 'VOTRE_PROJECT_ID.appspot.com',
    iosBundleId: 'com.votrenom.stockFlutter',
  );

  // ── Web (optionnel) ────────────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'VOTRE_WEB_API_KEY',
    appId: '1:XXXXXXXXXX:web:XXXXXXXXXXXXXXXXXXXX',
    messagingSenderId: 'XXXXXXXXXX',
    projectId: 'VOTRE_PROJECT_ID',
    authDomain: 'VOTRE_PROJECT_ID.firebaseapp.com',
    storageBucket: 'VOTRE_PROJECT_ID.appspot.com',
  );
}
