import 'package:firebase_core/firebase_core.dart';
import 'core/app_theme.dart';
import 'workspace/workspace_page.dart';
import 'package:flutter/material.dart';
import 'page/splash_page.dart';
import 'firebase_options.dart'; // Ensure this is generated with correct Firebase options.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Legacy accounts remain available explicitly; the local workspace does not
  // require or access the historical Firebase project.
  if (const bool.fromEnvironment('LEGACY_FIREBASE_APP')) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kissan Konnect', // Updated app name
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const bool.fromEnvironment('LEGACY_FIREBASE_APP')
          ? const SafeArea(child: SplashPage())
          : const WorkspacePage(),
    );
  }
}
