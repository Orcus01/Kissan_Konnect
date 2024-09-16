import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'page/splash_page.dart';
import 'firebase_options.dart'; // Ensure this is generated with correct Firebase options.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Make sure firebase_options.dart is included
  );

  // Initialize Firebase App Check with reCAPTCHA for web
  // await FirebaseAppCheck.instance.activate(
  //   webProvider: RecaptchaV3Provider('6LcmYzgqAAAAAI7utDqXI90RyLoFnF1v6bjhw7_F'),
  //   androidProvider: AndroidProvider.playIntegrity,
  //   appleProvider: AppleProvider.deviceCheck,
  // );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kissan Konnect', // Updated app name
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Gilroy', // Ensure this font is correctly added to pubspec.yaml
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SafeArea(
        child: SplashPage(),
      ),
    );
  }
}
