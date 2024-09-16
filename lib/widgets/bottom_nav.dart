// BottomNavBar.dart
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:kissan_konnect/page/home_page.dart';
import 'package:kissan_konnect/page/community_page.dart';
import 'package:kissan_konnect/page/camera_page.dart';
import 'package:kissan_konnect/page/diagnosis_page.dart';
import 'package:kissan_konnect/page/profile_page.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({Key? key}) : super(key: key);

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _page = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  void _openCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraPage(openCameraOnLoad: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _page,
        children: [
          HomePage(),
          ChatPage(),
          CameraPage(openCameraOnLoad: false), // Pass false if the camera shouldn't open directly.
          DiagnosisPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _page,
        items: <Widget>[
          Icon(Icons.home, size: 30, color: _page == 0 ? Colors.white : Colors.grey),
          Icon(Icons.group, size: 30, color: _page == 1 ? Colors.white : Colors.grey),
          GestureDetector(
            onTap: _openCamera, // Open camera directly when tapped
            child: Icon(Icons.camera_alt, size: 30, color: _page == 2 ? Colors.white : Colors.grey),
          ),
          Icon(Icons.medical_services, size: 30, color: _page == 3 ? Colors.white : Colors.grey),
          Icon(Icons.person, size: 30, color: _page == 4 ? Colors.white : Colors.grey),
        ],
        color: const Color.fromARGB(255, 34, 150, 83),
        buttonBackgroundColor: const Color.fromARGB(255, 76, 175, 80),
        backgroundColor: const Color.fromARGB(0, 255, 253, 253),
        onTap: (index) {
          setState(() {
            _page = index;
          });
        },
        animationCurve: Curves.easeInOut,
        animationDuration: Duration(milliseconds: 300),
      ),
    );
  }
}
