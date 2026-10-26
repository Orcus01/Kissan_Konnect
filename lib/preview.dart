import 'package:flutter/material.dart';
import 'auth/firebase_setup.dart';
import 'core/app_theme.dart';
import 'auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseSetup.initialize();
  runApp(const CapturePreview());
}

class CapturePreview extends StatelessWidget {
  const CapturePreview({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Kissan Konnect',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: const AuthGate(),
      );
}
