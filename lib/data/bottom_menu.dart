import 'package:flutter/material.dart';

class BottomMenu {
  final int id;
  final IconData iconData;
  final String label;

  BottomMenu(this.id, this.iconData, this.label);
}

List<BottomMenu> bottomMenu = [
  BottomMenu(0, Icons.home, 'Home'),       // Home
  BottomMenu(1, Icons.group, 'Community'),  // Community
  BottomMenu(2, Icons.camera_alt, 'Camera'), // Camera
  BottomMenu(3, Icons.medical_services, 'Diagnosis'), // Diagnosis
  BottomMenu(4, Icons.person, 'Profile'),   // Profile
];
