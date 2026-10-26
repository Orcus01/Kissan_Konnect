import 'auth/firebase_setup.dart';
import 'core/app_theme.dart';
import 'auth/auth_gate.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseSetup.initialize();

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
      home: const AuthGate(),
    );
  }
}
