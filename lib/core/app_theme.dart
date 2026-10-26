import 'package:flutter/material.dart';

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF24563F), surface: const Color(0xFFF5F7F2)),
  scaffoldBackgroundColor: const Color(0xFFF5F7F2),
  fontFamily: 'gilroy',
  textTheme: const TextTheme(
      bodyMedium:
          TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF263C30)),
      bodyLarge: TextStyle(fontSize: 16, height: 1.6)),
  appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF5F7F2),
      foregroundColor: Color(0xFF173B2B),
      centerTitle: false,
      scrolledUnderElevation: 0),
  inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDCE3DA))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDCE3DA)))),
  filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          backgroundColor: const Color(0xFF24563F),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontFamily: 'gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w700))),
  outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
  dividerTheme: const DividerThemeData(color: Color(0xFFDDE4D9), thickness: 1),
);
