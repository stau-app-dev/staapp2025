import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Bootstraps Firebase across web and mobile with consistent behavior.
/// - Web: initializes with explicit options and sets LOCAL persistence.
/// - iOS/Android: initializes using platform config files (plist/json).
Future<void> bootstrapFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  if (kIsWeb) {
    const options = FirebaseOptions(
      apiKey: 'AIzaSyD6g_zu-fCz86WRbsqkJlmVlhK5nxB9UVM',
      authDomain: 'staugustinechsapp.firebaseapp.com',
      databaseURL: 'https://staugustinechsapp.firebaseio.com',
      projectId: 'staugustinechsapp',
      storageBucket: 'staugustinechsapp.appspot.com',
      messagingSenderId: '448336593725',
      appId: '1:448336593725:web:689321db00ef6fbb24fb54',
      measurementId: 'G-60YM5QL4QX',
    );
    try {
      await Firebase.initializeApp(options: options);
      await fb.FirebaseAuth.instance.setPersistence(fb.Persistence.LOCAL);
    } catch (_) {}
    return;
  }
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}
