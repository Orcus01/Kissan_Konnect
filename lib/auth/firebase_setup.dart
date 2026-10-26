import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Only explicit, project-specific build settings are used. No legacy fallback.
class FirebaseSetup {
  static bool ready = false;
  static const emulatorMode =
      String.fromEnvironment('KISSAN_AUTH_EMULATOR_HOST') != '';
  static Future<void> initialize() async {
    const project = String.fromEnvironment('KISSAN_FIREBASE_PROJECT_ID');
    if (project.isEmpty) return;
    if (project == 'seatsandspaces') {
      throw StateError('Use a dedicated personal Firebase project.');
    }
    await Firebase.initializeApp(
        options: const FirebaseOptions(
      apiKey: String.fromEnvironment('KISSAN_FIREBASE_API_KEY'),
      appId: String.fromEnvironment('KISSAN_FIREBASE_APP_ID'),
      messagingSenderId: String.fromEnvironment('KISSAN_FIREBASE_SENDER_ID'),
      projectId: project,
      authDomain: String.fromEnvironment('KISSAN_FIREBASE_AUTH_DOMAIN'),
    ));
    const emulator = String.fromEnvironment('KISSAN_AUTH_EMULATOR_HOST');
    if (emulator.isNotEmpty && project.startsWith('demo-')) {
      await FirebaseAuth.instance.useAuthEmulator(emulator, 9099);
    }
    if (kIsWeb) {
      await FirebaseAuth.instance
          .setPersistence(emulatorMode ? Persistence.NONE : Persistence.LOCAL);
    }
    ready = true;
  }
}
