import 'package:flutter/material.dart';

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF24563F)),
  scaffoldBackgroundColor: const Color(0xFFF7F7F0),
  fontFamily: 'gilroy',
  appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF7F7F0),
      foregroundColor: Color(0xFF173B2B),
      centerTitle: false),
  filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
    minimumSize: const Size(0, 52),
    backgroundColor: const Color(0xFF24563F),
  )),
  outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52))),
);
